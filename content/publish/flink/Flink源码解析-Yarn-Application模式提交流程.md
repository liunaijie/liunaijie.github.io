---
title: Flink源码解析-Yarn-Application模式提交流程
date: 2026-05-26
categories:
  - publish
tags:
  - Flink
  - Yarn
---
# TL;DR
本文基于 `Flink 1.20` 源码，梳理 `yarn-application` 模式下一个任务从提交到运行起来的完整过程。

重点会放在这几件事上：
- 命令是怎么启动的
- Client 侧到底做了什么
- Yarn 上的 ApplicationMaster / JobManager 是怎么启动的
- TaskManager 是怎么向 Yarn 申请并拉起的
- 用户 `main()`、`JobGraph` 生成、`submitJob()` 分别发生在哪个角色里

为了避免范围过大，本文只聚焦 `run-application -t yarn-application` 这条主链路，不展开 Web 提交、Session 模式以及 SQL Gateway。

以一个最常见的启动命令为例：

```shell
./bin/flink run-application \
  -t yarn-application \
  -Djobmanager.memory.process.size=2048m \
  -Dtaskmanager.memory.process.size=4096m \
  -c com.example.WordCount \
  /path/to/job.jar \
  arg1 arg2
```

<!--more-->

# Application 模式下的职责划分
在 `yarn-application` 模式下：
- Client 不是 Driver
- Yarn 上的 ApplicationMaster 同时也是 Flink 集群入口
- 用户 Jar 会被先上传到 Yarn 可见的位置，然后在集群内执行

---

# 一、启动入口：`bin/flink` 到 `CliFrontend`

## 1.1 Shell 脚本入口
命令最终先进入脚本 `bin/flink`。

这个脚本本身做的事情并不复杂，核心就两步：
- 读取 `config.sh`，组装 Flink Client 启动所需的 classpath
- 用 Java 进程启动 `org.apache.flink.client.cli.CliFrontend`

所以从 Java 代码角度看，真正的入口类就是：
- `org.apache.flink.client.cli.CliFrontend`

## 1.2 `CliFrontend#mainInternal`
在 `CliFrontend#mainInternal()` 中，主要做了 3 件事：
- 读取 `FLINK_CONF_DIR`
- 加载全局配置 `GlobalConfiguration.loadConfiguration(...)`
- 通过 `loadCustomCommandLines(...)` 加载不同部署模式对应的 CLI

这里会加载几个关键的 `CustomCommandLine`：
- `GenericCLI`
- `FlinkYarnSessionCli`
- `DefaultCLI`

## 1.3 为什么 `-t yarn-application` 会走到 Yarn
`run-application -t yarn-application` 这条命令，激活的通常不是 `FlinkYarnSessionCli`，而是 `GenericCLI`。

原因是：
- `GenericCLI#isActive()` 只要发现命令里显式传了 `-t` / `--target`，就会生效
- `GenericCLI#toConfiguration()` 会把 `-t yarn-application` 写入配置项 `DeploymentOptions.TARGET`

对应关系如下：

```text
-t yarn-application
      ↓
DeploymentOptions.TARGET = yarn-application
```

后续根据这个 target 选择具体提交实现的是 `ClusterClientFactory`。

## 1.4 `parseAndRun()` 进入 `runApplication()`
`CliFrontend#parseAndRun()` 会根据 action 分发：
- `run`
- `run-application`
- `list`
- `cancel`
- ...

本文场景会走：
- `CliFrontend#runApplication()`

这个方法里主要有几步：
- 解析参数，生成 `ProgramOptions`
- 构造 `ApplicationConfiguration`
- 创建 `ApplicationClusterDeployer`
- 调用 `deployer.run(effectiveConfiguration, applicationConfiguration)`

到这里，Client 已经进入 application cluster 部署阶段。

---

# 二、Client 角色：创建 Yarn 集群并启动 ApplicationMaster

## 2.1 `ApplicationClusterDeployer#run`
`ApplicationClusterDeployer` 的逻辑很直白：

1. 通过 `ClusterClientServiceLoader` 找到匹配当前 target 的 `ClusterClientFactory`
2. 由 factory 创建 `ClusterDescriptor`
3. 调用 `clusterDescriptor.deployApplicationCluster(...)`

这一步里，最关键的分发点是：
- `ClusterClientServiceLoader#getClusterClientFactory(configuration)`

对于 `DeploymentOptions.TARGET = yarn-application`，最终会选中：
- `org.apache.flink.yarn.YarnClusterClientFactory`

## 2.2 `YarnClusterClientFactory`
这个类相当于 Yarn 部署入口工厂。

它做两件关键事：
- `isCompatibleWith(configuration)`：判断 target 是否是合法的 Yarn target
- `createClusterDescriptor(configuration)`：创建 `YarnClusterDescriptor`

其中 `createClusterDescriptor()` 内部会：
- 创建 `YarnClient`
- 初始化 Hadoop/Yarn 配置
- 构造 `YarnClusterDescriptor`

所以后面所有真正和 Yarn RM 打交道的逻辑，基本都在：
- `org.apache.flink.yarn.YarnClusterDescriptor`

## 2.3 `YarnClusterDescriptor#deployApplicationCluster`
`deployApplicationCluster(...)` 是 application 模式提交的正式入口。

它主要做了几件事：
- 检查 `deployment.target` 必须是 `yarn-application`
- `applicationConfiguration.applyToConfiguration(flinkConfiguration)`，把应用主类和参数写回配置
- 校验普通 Java/Scala 作业只有一个主 Jar
- 调用 `deployInternal(...)`

这里传给 `deployInternal(...)` 的几个重要参数是：
- application name: `Flink Application Cluster`
- Yarn entrypoint class: `YarnApplicationClusterEntryPoint.class.getName()`
- `jobGraph = null`

关键点：

> Application 模式下，Client 此时还没有生成 `JobGraph`。

这和 `run / per-job` 模式非常不一样。

## 2.4 `YarnClusterDescriptor#deployInternal`
这个方法是整个 Client 提交流程的核心。

它大致分成四段。

### 第一段：部署前检查
主要包括：
- Kerberos 凭证检查
- Yarn queue 检查
- 向 Yarn RM 申请一个新的 `ApplicationId`
- 检查集群剩余资源、最大容器资源、最小分配单位
- 根据资源规则校验并修正 `ClusterSpecification`

这里和 Yarn 的第一轮交互是：
- `yarnClient.createApplication()`
- `yarnClient.getNodeReports(...)`

### 第二段：确定集群执行模式
这里会设置：

```java
ClusterEntrypoint.INTERNAL_CLUSTER_EXECUTION_MODE
```

如果是 detached 就是 `DETACHED`，否则是 `NORMAL`。

### 第三段：真正启动 AM
接下来调用：
- `startAppMaster(...)`

后续的 Yarn 资源上传、AM 启动和 application 提交都在这个方法链里完成。

### 第四段：回填集群访问信息
AM 启动成功以后，会通过 `ApplicationReport` 把这些信息写回 Flink 配置：
- `JobManagerOptions.ADDRESS`
- `JobManagerOptions.PORT`
- `RestOptions.ADDRESS`
- `RestOptions.PORT`
- `YarnConfigOptions.APPLICATION_ID`

最后返回：
- `RestClusterClient`

这意味着 Client 后续和集群的交互，会通过 REST Client 进行。

---

# 三、Client 与 Yarn 的关键交互：`startAppMaster()`

## 3.1 这个方法干了什么
`YarnClusterDescriptor#startAppMaster(...)` 的职责是：

> 为 Yarn ApplicationMaster 组装一个完整的 `ApplicationSubmissionContext` 和 `ContainerLaunchContext`，把 Flink 运行所需的 jar、配置、环境变量、命令行全部准备好，然后提交给 Yarn RM。

## 3.2 上传和注册本次应用需要的资源
这个方法里先创建：
- `YarnApplicationFileUploader`

然后把下面这些内容注册成 Yarn LocalResource：
- Flink lib 目录
- 用户 Jar
- `flink-conf.yaml`
- 可选的 plugin、archive、log 配置
- Kerberos 相关文件

Application 模式下还有一个很重要的处理：
- 会从 `PipelineOptions.JARS` 中取出用户 Jar
- 把用户 Jar 也加入本次 Application 的资源集合里

这一阶段提交到 Yarn 的内容不是 `JobGraph`，而是执行应用所需的运行时资源和配置。

## 3.3 ApplicationMaster 的启动命令从哪来
AM 容器的启动命令来自：
- `setupApplicationMasterContainer(...)`

这个方法会组装一条 Yarn 容器启动命令，核心变量包括：
- `java`
- `jvmmem`
- `jvmopts`
- `logging`
- `class`
- `args`
- `redirects`

启动命令中的关键配置是：
- `class = YarnApplicationClusterEntryPoint`

Yarn AM 容器拉起后执行的主类是：
- `org.apache.flink.yarn.entrypoint.YarnApplicationClusterEntryPoint`

## 3.4 AM 容器环境变量
AM 的环境变量由：
- `generateApplicationMasterEnv(...)`

这个方法负责注入几类关键变量：
- `ENV_FLINK_CLASSPATH`
- `FLINK_DIST_JAR`
- `ENV_APP_ID`
- `ENV_CLIENT_HOME_DIR`
- `ENV_CLIENT_SHIP_FILES`
- `FLINK_YARN_FILES`
- `HADOOP_USER_NAME`

这些环境变量后面会被：
- `YarnApplicationClusterEntryPoint`
- `YarnResourceManagerDriver`
- `Utils.createTaskExecutorContext(...)`

继续消费。

## 3.5 提交到 Yarn RM
一切准备好以后，Client 会调用：
- `yarnClient.submitApplication(appContext)`

然后不断轮询：
- `yarnClient.getApplicationReport(appId)`

直到 Yarn Application 状态变成：
- `RUNNING`

这一阶段完成后：

> Flink 集群已经作为一个 Yarn Application 被拉起来了。

---

# 四、JM/AM 角色：`YarnApplicationClusterEntryPoint` 如何把集群跑起来

## 4.1 入口类：`YarnApplicationClusterEntryPoint`
Yarn AM 容器启动后，会进入：
- `YarnApplicationClusterEntryPoint#main`

这个 `main()` 做的事情很标准：
- 打印环境信息
- 注册信号处理和 shutdown hook
- 读取当前工作目录
- 从动态参数、环境变量、工作目录中加载最终配置
- 构造 `PackagedProgram`
- 调用 `configureExecution(configuration, program)`
- 创建 `YarnApplicationClusterEntryPoint`
- 执行 `ClusterEntrypoint.runClusterEntrypoint(...)`

其中与 application 模式直接相关的是前两步：
- `getPackagedProgram(configuration)`
- `configureExecution(configuration, program)`

## 4.2 `getPackagedProgram()`：在集群内恢复用户程序
`getPackagedProgram()` 会从配置中拿到：
- 应用主类
- 应用参数
- 用户 Jar

然后通过：
- `DefaultPackagedProgramRetriever.create(...)`

构造出一个 `PackagedProgram`。

这一步完成后，用户程序被恢复为 `PackagedProgram`。

## 4.3 `configureExecution()`：把执行目标切成 `embedded`
`ApplicationClusterEntryPoint#configureExecution(...)` 会把：

```text
DeploymentOptions.TARGET = embedded
```

同时把：
- `PipelineOptions.JARS`
- `PipelineOptions.CLASSPATHS`

重新编码进配置。

关键点：

> 后续在集群内部执行用户 `main()` 时，不再走外部提交逻辑，而是直接使用嵌入式执行器，把生成出来的 Job 提交给当前集群内的 Dispatcher。

后续对应的执行器是：
- `EmbeddedExecutor`

## 4.4 `ClusterEntrypoint`：拉起 Flink Master 组件
`ClusterEntrypoint#startCluster()` / `runCluster()` 是所有集群入口的公共骨架。

它主要做这些事情：
- 安装安全上下文
- 初始化文件系统
- 初始化 RPC、HA、BlobServer、Heartbeat、Metrics 等基础服务
- 把当前 RPC 地址写回配置
- 创建 `DispatcherResourceManagerComponent`

这一阶段会完成 Flink Master 侧基础组件初始化：
- Dispatcher
- ResourceManager
- REST endpoint
- HA services

## 4.5 Application 模式下，为什么创建出来的是“带应用语义”的 Dispatcher
这是由 `ApplicationClusterEntryPoint#createDispatcherResourceManagerComponentFactory(...)` 决定的。

它没有使用普通的 session 入口，而是构造了：
- `DefaultDispatcherResourceManagerComponentFactory`
- `ApplicationDispatcherLeaderProcessFactoryFactory.create(...)`

底层仍然是 Dispatcher + ResourceManager 结构，只是 Dispatcher 的引导逻辑切换成了 application 模式实现。

---

# 五、执行用户 `main()` 的入口：`ApplicationDispatcherBootstrap`

## 5.1 为什么会走到它
`ApplicationDispatcherLeaderProcessFactoryFactory` 会创建：
- `ApplicationDispatcherGatewayServiceFactory`

继续往下，最终会用：
- `ApplicationDispatcherBootstrap`

来引导这个 Application Cluster。

在 `yarn-application` 模式下，用户 `main()` 由这个类触发执行。

## 5.2 `ApplicationDispatcherBootstrap` 的职责
它负责：
- 异步执行用户程序入口
- 收集本次 application 提交出来的 `JobID`
- 等待 application 的 job 执行完成
- 根据结果决定是否关闭整个集群

核心入口是：
- `fixJobIdAndRunApplicationAsync(...)`
- `runApplicationAsync(...)`
- `runApplicationEntryPoint(...)`

## 5.3 `runApplicationEntryPoint()`：用户代码开始执行
在 `runApplicationEntryPoint(...)` 中，会创建：
- `EmbeddedExecutorServiceLoader`

然后调用：
- `ClientUtils.executeProgram(...)`

这个方法会：
- 把执行上下文切换成 Flink 的 Context Environment
- 调用 `program.invokeInteractiveModeForExecution()`

用户自己的：
- `public static void main(String[] args)`

是在这里执行的。

> 用户 `main()` 不是在最初的 Client 进程里执行，而是在 Yarn 上的 ApplicationMaster/JobManager 进程里执行。

## 5.4 `EmbeddedExecutor`：在集群内部提交 JobGraph
用户代码里一旦调用：
- `env.execute()`
- `tableEnv.executeSql(...)`

最终会走到 `EmbeddedExecutor#execute(...)`。

这个类做了几件关键事：
- 把 `Pipeline` 转成 `JobGraph`
- 调用 `ClientUtils.extractAndUploadJobGraphFiles(...)`
- 通过 `DispatcherGateway.submitJob(jobGraph, timeout)` 提交作业

这一阶段的角色划分如下：
- `JobGraph` 的生成发生在 JM/AM 进程内
- `submitJob()` 也是直接通过 Dispatcher RPC 完成
- 不再依赖外部 Client 远程生成再上传

---

# 六、ResourceManager 角色：Flink 如何和 Yarn RM / NM 打交道

## 6.1 `YarnResourceManagerFactory`
在 `YarnApplicationClusterEntryPoint` 里，传给父类的 ResourceManagerFactory 是：
- `YarnResourceManagerFactory.getInstance()`

这个工厂会创建：
- `YarnResourceManagerDriver`

它就是 Flink ResourceManager 在 Yarn 场景下的“适配器”。

## 6.2 `YarnResourceManagerDriver#initializeInternal`
初始化时主要做两件事：

1. 创建并启动和 Yarn RM 通信的客户端
   - `AMRMClientAsync`
2. 创建并启动和 Yarn NM 通信的客户端
   - `NMClientAsync`

然后会调用：
- `registerApplicationMaster()`

这里对应的是 Flink AM 向 Yarn RM 注册：
- 我是谁
- 我的 RPC 地址是什么
- Web UI 地址是什么

这一步之后，Yarn 才真正知道这个 ApplicationMaster 已经上线了。

## 6.3 Flink 什么时候向 Yarn 申请 TaskManager 容器
当 Dispatcher 开始调度作业，Flink ResourceManager 感知到需要更多 slot / worker 时，最终会调用到：
- `YarnResourceManagerDriver#requestResource(...)`

这个方法会：
- 根据 `TaskExecutorProcessSpec` 计算 YARN `Resource`
- 生成不同优先级的 `ContainerRequest`
- 调用 `resourceManagerClient.addContainerRequest(...)`

这就是 Flink 向 Yarn RM 申请 TM 容器的核心动作。

## 6.4 Yarn RM 分配到容器后会发生什么
当 Yarn RM 分配容器后，回调会进入：
- `YarnContainerEventHandler#onContainersAllocated(...)`

接着会调用：
- `onContainersOfPriorityAllocated(...)`

这个方法会做几件事：
- 把 Yarn 返回的 `Container` 与 Flink 的待申请请求对上
- 为容器生成 `ResourceID`
- 调用 `startTaskExecutorInContainerAsync(...)`

后续进入 TM 启动链路。

---

# 七、TM 角色：TaskManager 容器如何被拉起来

## 7.1 `startTaskExecutorInContainerAsync()`
这个方法异步构造 TM 的 `ContainerLaunchContext`，核心调用是：
- `createTaskExecutorLaunchContext(...)`

## 7.2 `createTaskExecutorLaunchContext()`
这个方法会：
- 按 `TaskExecutorProcessSpec` 计算 TM 启动参数
- 克隆并修正 Flink 配置
- 生成 TM 动态参数字符串
- 调用 `Utils.createTaskExecutorContext(...)`

同时还会把 Yarn 分配到的节点 host 写入环境变量：
- `_FLINK_NODE_ID`

这个值后面会被 TM 进程读取，用来设置自己的 hostname。

## 7.3 `Utils.createTaskExecutorContext()`
这个方法负责组装 TM 容器启动上下文：
- 注册本地资源
- 填充环境变量
- 注入安全凭证
- 生成最终启动命令

最终的启动主类是：
- `org.apache.flink.yarn.YarnTaskExecutorRunner`

TM 启动命令由：
- `Utils.getTaskManagerShellCommand(...)`

生成，里面同样会填充：
- `java`
- `jvmmem`
- `jvmopts`
- `logging`
- `class`
- `args`
- `redirects`

## 7.4 `YarnTaskExecutorRunner`
Yarn NM 真正拉起容器后，TM 进程入口就是：
- `YarnTaskExecutorRunner#main`

它会先：
- 读取工作目录
- `TaskManagerRunner.loadConfiguration(args)`
- `setupAndModifyConfiguration(...)`

其中 `setupAndModifyConfiguration(...)` 会做几件很 Yarn 化的事情：
- 根据 `LOCAL_DIRS` 更新 tmp 目录
- 从环境变量读取 Kerberos 信息
- 从 `_FLINK_NODE_ID` 设置 `TaskManagerOptions.HOST`

TM 进程会在这里把 Yarn 容器环境转换成 Flink TaskExecutor 所需配置。

## 7.5 `TaskManagerRunner`
之后进入：
- `TaskManagerRunner.runTaskManagerProcessSecurely(configuration)`

再继续：
- `runTaskManager(...)`
- `new TaskManagerRunner(...).start()`

在 `startTaskManagerRunnerServices()` 中会初始化：
- RPC
- HA
- Heartbeat
- BlobCache
- Metrics
- `TaskExecutorService`

最终真正启动：
- `taskExecutorService.start()`

后续 TaskManager 会向 ResourceManager / JobMaster 完成注册，并接收任务部署。

---

# 八、把四个角色串起来看

## 8.1 Client
Client 的职责非常明确：
- 解析命令
- 识别 target = `yarn-application`
- 创建 `YarnClusterDescriptor`
- 上传依赖和配置
- 组装 AM 启动命令
- 向 Yarn RM 提交 Application

Client 关键类/方法：
- `CliFrontend#runApplication`
- `ApplicationClusterDeployer#run`
- `YarnClusterClientFactory#createClusterDescriptor`
- `YarnClusterDescriptor#deployApplicationCluster`
- `YarnClusterDescriptor#deployInternal`
- `YarnClusterDescriptor#startAppMaster`

## 8.2 JM / AM
ApplicationMaster 容器起来以后，同时承担了 Flink 集群入口角色。

它负责：
- 恢复 `PackagedProgram`
- 把执行目标切成 `embedded`
- 启动 Dispatcher / ResourceManager / REST
- 在集群内执行用户 `main()`
- 生成并提交 `JobGraph`

关键类/方法：
- `YarnApplicationClusterEntryPoint#main`
- `ApplicationClusterEntryPoint#configureExecution`
- `ClusterEntrypoint#startCluster`
- `ApplicationDispatcherLeaderProcessFactoryFactory#createFactory`
- `ApplicationDispatcherBootstrap#runApplicationEntryPoint`
- `EmbeddedExecutor#execute`
- `DispatcherGateway#submitJob`

## 8.3 TM
TaskManager 的职责是：
- 作为 Yarn 容器被 Flink RM 申请出来
- 在 Yarn NodeManager 上启动 JVM
- 初始化 TaskExecutor 运行时
- 注册到 Flink 集群并执行 task

关键类/方法：
- `YarnResourceManagerDriver#requestResource`
- `YarnContainerEventHandler#onContainersAllocated`
- `YarnResourceManagerDriver#createTaskExecutorLaunchContext`
- `Utils#createTaskExecutorContext`
- `YarnTaskExecutorRunner#main`
- `TaskManagerRunner#start`

## 8.4 Yarn 集群
Yarn 在整个过程中主要扮演资源与容器管理者：
- RM 负责接收 application、分配 AM / TM 容器
- NM 负责在节点上真正启动容器进程

Flink 与 Yarn 的主要交互点：
- Client -> Yarn RM：`createApplication`、`submitApplication`
- AM -> Yarn RM：`registerApplicationMaster`、`addContainerRequest`
- Yarn RM -> AM：`onContainersAllocated`
- AM -> Yarn NM：`startContainerAsync`
- Yarn NM -> TM JVM：拉起 `YarnTaskExecutorRunner`

---

# 九、用一张图总结整条链路
![](Pasted%20image%2020260531141940.png)

---

# 十、最后总结
如果只记 4 个点，我觉得最值得记住的是：

1. `yarn-application` 模式下，Client 主要负责“建集群”，不是“执行用户 main”
2. 用户 `main()` 真正执行的位置，在 Yarn 上的 `ApplicationDispatcherBootstrap`
3. `JobGraph` 的生成和 `DispatcherGateway.submitJob(...)` 的调用，都发生在集群内部
4. TaskManager 不是 Client 直接拉起的，而是 Flink ResourceManager 通过 `YarnResourceManagerDriver` 向 Yarn RM 申请，再由 Yarn NM 启动

所以从源码视角看，`yarn-application` 更像是：

> Client 先把一个“可执行应用”投递成 Yarn Application，再由 Yarn 上的 Flink Master 自己完成应用执行与作业提交。

这也是它和传统 client 提交模式最本质的区别。
