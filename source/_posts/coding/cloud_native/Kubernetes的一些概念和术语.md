---
title: Kubetnetes的一些概念和术语
date: 2019-08-30 10:05:39
tags: 
- cloud_native/kubetnetes
---

此篇文章来自《Kubernetes权威指南：从Docker到Kubernetes实践全接触（第4版） 》

- Master
- Node
- Pod
- Replication Controller
- Service

k8s里面的大部分资源都可以被看作一种资源对象，这些对象大部分也都可以通过`kubectl`工具（或者是API调用）执行增删改查等操作，并将其状态保存在etcd中持久化存储。

在这个调用中，有一个版本的概念：`apiVersion`。对于一个接口有时候会进行升级，从而会有不同的版本存在，我们调用不同版本的接口从而对应不同版本的实现。在`k8s`里面也是如此，需要在调用时指明现在调用的版本号。

# Master，Node

master，node的概念是对于机器的，可是是一台物理主机，也可以是一台虚拟机，在不同的机器上部署k8s服务，这个服务实例可能是master或者是node。

## Master

k8s里面的master指的是集群控制节点，在每个k8s集群里都需要有一个master来负责整个集群的管理和控制，基本上k8s的所有控制命令都发给它，它负责具体的执行过程，

在master上运行着以下关键进程：

-  kubernetes API Server：提供了HTTP Rest接口的关键服务进程，是k8s里所有资源的增删改查等操作的唯一入口，也是集群控制的入口进程。
- kubernetes Controller Manager：kubernetes里所有资源对象的自动化控制中心，可以将其理解为资源对象的“大总管”。
- kubernetes Scheduler：负责资源调度（Pod调度）的进程

另外，在master上通常还需要部署etcd服务，因为kubernetes里的所有资源对象的数据都被保存在etcd中。

## Node

在k8s集群中，除了master的集群被称为node，node是集群中的工作负载节点，每个node都会被master分配一些工作负载（docker容器），当某个node宕机后，其上的工作负载会被master自动转移到其他节点上。

每个node上都运行着以下关键进程：

- kubelet：负载pod对应容器的创建，启停等任务，同时与master密切协作，实现集群管理等基本功能。
- kube-proxy：实现kubernetes service的通信与负载均衡的重要组件
- docker engine：docker引擎，负责本机的容器创建和管理工作

node可以在运行期间动态增加到k8s集群总，前提是在这个节点上已经正确安装、配置和启动了上述关键进程，在默认情况下kubelet会向master注册自己，这也是k8s推荐的node管理方式。一旦node被纳入集群管理范围，kubelet进程就会定时向master汇报自身的情况，例如操作系统，docker版本，机器的cpu和内存情况，以及当前有哪些pod在运行等。这样master就可以获知每个node的资源使用情况，并实现高效均衡的资源调度策略。

在node超过指定时间不上报信息时，会被master判定为“失联”，node的状态被标记为不可用（not ready），随后master会触发“工作负载大转移”的自动流程。

可以通过执行如下命令查看在集群上有多少个node：

 ```shell
kubectl get nodes
 ```

当想查看node的具体信息时，可以通过这个命令：

```shell
kubectl describe node <node-name>
```

这个命令可以展示Node的如下关键信息。

- Node的基本信息：名称、标签、创建时间等。
- Node当前的运行状态：Node启动后会做一系列的自检工作，比如磁盘空间是否不足（DiskPressure）、内存是否不足（MemoryPressure）、网络是否正常（NetworkUnavailable）、PID资源是否充足（PIDPressure）。在一切正常时设置Node为Ready状态（Ready=True），该状态表示Node处于健康状态，Master将可以在其上调度新的任务了（如启动Pod）。
- Node的主机地址与主机名。
- Node上的资源数量：描述Node可用的系统资源，包括CPU、内存数量、最大可调度Pod数量等。
-  Node可分配的资源量：描述Node当前可用于分配的资源量。
- 主机系统信息：包括主机ID、系统UUID、Linux kernel版本号、操作系统类型与版本、Docker版本号、kubelet与kube-proxy的版本号等。
- 当前运行的Pod列表概要信息。
- 已分配的资源使用概要信息，例如资源申请的最低、最大允许使用量占系统总量的百分比。
- Node相关的Event信息。



**master与node是集群中服务实例的一个描述，它对应的都是一个物理主机或者是虚拟机，是机器级别的一个概念**

# Pod

Pod是k8s中管理的最小单元, 一个pod中有一个与业务并且不容易死亡的Pause容器, 可以根据Pause容器的状态来判断整个容器组的状态.

对于同一个Pod中的多个container, 它们之间共享Pause容器的IP，共享Pause容器挂载的Volume. k8s为每个Pod都分配来一个唯一的IP地址, 称为Pod IP.

在K8s中, 一个Pod里的容器与另外主机上的Pod容器能够直接通信.

![](https://raw.githubusercontent.com/liunaijie/images/master/202308082017748.png)

## 分类

Pod有两种类型: 普通的Pod以及静态Pod(Static Pod). 静态Pod一般作为系统级别的定义来实现一些系统级别的功能.

## 访问

对于Pod中的容器, 可以通过(Pod IP + Container port)来进行访问.

![](https://raw.githubusercontent.com/liunaijie/images/master/202308082018230.png)

# Label

Label(标签)是K8s系统中的一个核心概念, 很多东西的实现都依赖于Label. 一个Label是一个key=value的键值对, 其中的key与value都可以由用户自己指定. Label可以被添加到任意的资源对象上, 例如Node, Pod, Service等等. 一个资源对象可以定义任意数量的Label.

我们可以对任意对象上添加和修改任意数量的label, label的名称和值都是我们自己定义的.

当我们打上标签后, 可以通过Label Selector(标签选择器)查询和筛选这些资源对象.

```bash
kubectl get pod -l 'name=name1,project=projectA'

kubectl get pods -l 'environment in (production),tier in (frontend)'
```

```yaml
selector:
	name: name1
	project: projectA
```

```yaml
selector:
	matchLabels:
		name: name1
	matchExpressions:
		- {key: project, operator: In, values: [projectrA]}
```

matchExpression用于定义一组基于集合的筛选条件, 支持的操作符有: `In, NotIn, Exists, DoesNotExist`

matchLabels用于定义一组Label, 与直接写在Selector中的作用相同.

如果同时设置了`matchLabels`和`matchExpressions`, 则两组条件为`AND`关系.
![](https://raw.githubusercontent.com/liunaijie/images/master/202308082022097.png)

![](https://raw.githubusercontent.com/liunaijie/images/master/202308082024519.png)

# Annotation
annotation(注解)与Label类似, 也是使用key=value的形式进行定义. 但是key, value值必须是字符串, 不可以是其他类型的值

annotation不属于k8s管理的元数据信息, 但是可以通过添加某个注解来实现某项功能.

# ConfigMap

存放配置文件, 当我们更新配置文件后, Pod可以拿到最新的配置文件.

![](https://raw.githubusercontent.com/liunaijie/images/master/202308082024769.png)

所有的配置项都当作key-value字符串, 其中的value可以是一整个配置文件. 也可以是一个具体值.

```yaml
site.xml: |
	<xml>
		<a>a</a>
	</xml>
val: 123
```

## 创建

```yaml
# 将folder文件夹下所有文件以文件名为key, 值为value的方式创建出configmap
kubectl create configmap <NAME> --from-file=<folder_name> 
```

## 使用

可以使用四种方式来使用ConfigMap配置Pod中的容器

1.  在容器命令和参数内
2.  容器的环境变量
3.  将ConfigMap挂载成文件, 让应用来读取
4.  使用代码访问Kubernetes API来读取ConfigMap

如果在ConfigMap中的key使用`.`作为前缀, 在挂载成文件后, 文件将为隐藏格式

# Secret

存放密码等需要加密的信息, 功能与Configmap类似, 只不过在secret中的值需要进行Base64加密

# ReplicaSet-RS

ReplicaSet的前身是Replication Controller. 它是k8s系统中的一个核心概念, 由它来控制Pod的副本数量在任意时刻都符合某个期望值. 但是我们现在基本不主动使用RS来管理Pod, 而是使用更高级的对象Deployment来管理.

主要的组成部分为:

-   期望的Pod副本数量
-   用于筛选目标Pod的Label Selector
-   当Pod的副本数量小于期望值时, 用于创建新Pod的模板(template)

需要注意的是, 删除RC, RS并不会影响通过该RC,RS已创建好的Pod. 如果需要删除所有的Pod, 可以设置replicas的值为0先将Pod数量减至0后再进行删除.

RS与RC的区别

RS支持基于集合的Label Selector, 而RC只支持基于等式的Label Selector