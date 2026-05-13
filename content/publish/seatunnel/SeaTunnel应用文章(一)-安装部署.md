---
title: SeaTunnel应用文章(一)-安装部署
date: 2024-12-24
categories:
  - publish
tags:
  - SeaTunnel
---
# 前言
这篇文章会介绍一下, `SeaTunnel`如何在不同环境下进行安装部署, 以及一些可以去调节的参数配置.
这里仅设计`Zeta`引擎的相关内容, `Spark`, `Flink`引擎的提交不需要搭建集群, 所以不会涉及.
<!--more-->

# SeaTunnel的集群原理
我想先提一下`SeaTunnel`的集群工作原理, 再来将如何安装, 这样在后面安装的时候就可以了解每一个步骤是干什么用的.
当启动多个节点搭建集群时, 主要的一件事情就是组网. 只有组网成功, 才能构成一个集群, 当多个节点构成一个集群后, 才能去选举.
`SeaTunnel`依赖`hazelcast`这样一个分布式内存组件来进行组网和选举, 没有引入类似`Zookeeper`这样的额外组件, 也没有自己去实现单独的通信机制, 复用了`hazelcast`的功能.
所以搭建`SeaTunnel`集群其实就是如何去搭建`hazelcast`的集群.

# 配置文件说明
在集群部署时, 总共会用到一下几类配置文件:
- `hazelcast`的配置 - 用于组网
	- `hazelcast.yaml` 混合模式下使用的配置文件
	- `hazelcast-master.yaml` 分离模式下, `master`使用的配置文件
	- `hazelcast-worker.yaml` 分离模式下, `worker`使用的配置文件
	- `hazelcast-client.yaml` 命令行提交时, 客户端使用的配置文件
- `seatunnel`的配置 - 用于设置`Zeta`引擎的一些功能
	- `seatunnel.yaml` 设置`Zeta`引擎功能的一些配置文件
- `log4j`的配置 - 用于设置日志的输出
	- `log4j2.properties` 集群使用的日志配置文件
	- `log4j2_client.properties` 命令行提交任务时, 客户端使用的配置文件
- `jvm`的配置 
	- `jvm_options` 混合模式下, 会添加到`jvm`的配置
	- `jvm_master_options` 分离模型下, 会添加到`master`的`jvm`配置
	- `jvm_worker_options` 分离模型下, 会添加到`worker`的`jvm`配置

如果需要集成`Flink`, `Spark`, 你还需要注意下这个配置文件
- `seatunnel-env.sh` 设置`Flink`, `Spark`的安装路径

## hazelcast相关配置

在`hazelcast`中, 一个节点, 根据是否需要存储数据, 分为数据节点和精简节点.
顾名思义数据节点会分布式的存储数据, 而精简节点不会去存储数据, 仅会去执行任务. 在`SeaTunnel`中使用该特性来在主从分离架构中区分`master`节点和`worker`节点.

```yaml
hazelcast:  
  cluster-name: seatunnel  
  network:  
    rest-api:  
      enabled: true  
      endpoint-groups:  
        CLUSTER_WRITE:  
          enabled: true  
        DATA:  
          enabled: true  
    join:  
      tcp-ip:  
        enabled: true  
        member-list:  
          - localhost  
    port:  
      auto-increment: false  
      port: 5801  
  properties:  
    hazelcast.invocation.max.retry.count: 20  
    hazelcast.tcp.join.port.try.count: 30  
    hazelcast.logging.type: log4j2  
    hazelcast.operation.generic.thread.count: 50  
    hazelcast.heartbeat.failuredetector.type: phi-accrual  
    hazelcast.heartbeat.interval.seconds: 2  
    hazelcast.max.no.heartbeat.seconds: 180  
    hazelcast.heartbeat.phiaccrual.failuredetector.threshold: 10  
    hazelcast.heartbeat.phiaccrual.failuredetector.sample.size: 200  
	hazelcast.heartbeat.phiaccrual.failuredetector.min.std.dev.millis: 100
	member-attributes:  
	  group:    
		  type: string    
		  value: platform  

```
这个是一个官方提供的配置文件. 
这里一个有这几个配置项:
- `cluster-name` 
当需要连接到一个集群时, 名称必须一致. 
你如果需要在一个或一组机器上部署多个集群, 则只有名称一致的才会加入一个集群, 名称不一致时不会进入一个集群

- `network.rest-api` 
这个选项, 不要去修改.
这个选项开启后, 就可以在外部通过`rest-api`来提交任务, 查询状态等等.
>在`2.3.9`版本中, 引入了`Jetty`来作为`rest-api`的实现, 所以这部分功能可能在后续的几个版本中移除掉, 当移除后, 这部分可以删除. 就目前版本来说, 不需要变动

- `network.port` 
这个是`hazelcast`对外交互的端口, `hazelast`的默认端口是`5701`, 在`seatunnel`中修改为`5801`, 如果这个端口被占用, 可以修改为其他端口. 
`auto-increment`这个配置, 推荐设置为`false`, 否则当设置的端口被占用后, 会递增100个端口进行尝试, 在生产环节中, 不要去修改, 否则你的端口很可能就变成随机的了.
如果在同一个机器上启动多个实例, 这里就需要人工去修改.

- `network.join` 这个是最重要的一个配置, 这里就是如何去组网的关键配置.
这个部分在不同的部署策略上, 有所不同, 具体需要设置成什么, 在下面具体部署时再看详细的设置.

- `member-attributes` 对这个/这组节点添加属性, 后续在提交任务时, 可以根据这个值来选择相应的节点去运行任务 (这一部分, 具体文档可以参考 https://seatunnel.apache.org/docs/2.3.8/seatunnel-engine/resource-isolation/)

# 混合部署VS分离部署
在2.3.6版本中,推出了主从分离部署的架构, 推出这个架构要解决的问题是在混合部署中, `master`节点即负责任务的分配, 管理工作, 也需要进行任务的同步工作. 当`master`负载较高后, 对整体的集群都会有影响.
采用主从分离架构后, master, worker的工作职责分离开来, 不太容易产生高负载的情况, 但需要有一个备用master节点在没出问题时空闲在那里, 出问题后会接管master的状态. 这个资源的使用与集群的稳定性相比, 问题不大.
推荐使用分离模式来进行部署.

# 物理机部署
这里以在本地部署两个服务, 一个master服务, 一个worker服务为例, 讲述下如何在物理机环境下进行部署.
需要改动的文件有:
- `hazelcast-master.yaml
- `hazelcast-worker.yaml`
- `hazelcast-client.yaml`
在一个机器上部署两个服务, 就需要将其中一个服务的端口修改为一个不同的端口, 这里将`worker`的端口修改为`5901`, 而`master`仍然使用`5801`端口.
`hazelcast-master.yaml`的配置文件为:
```yaml
xxx
	join:  
		tcp-ip:  
			enabled: true  
			member-list:  
				- localhost:5801
				- localhost:5901
	port:  
		auto-increment: false  
		port: 5801
xxx
```

`hazelcast-worker.yaml`的配置文件为:
```yaml
xxx
	join:  
		tcp-ip:  
			enabled: true  
			member-list:  
				- localhost:5801
				- localhost:5901
	port:  
		auto-increment: false  
		port: 5901
xxx
```

然后运行这两个命令:
```
./bin/seatunnel-cluster.sh -r master
./bin/seatunnel-cluster.sh -r worker
```
分别查看两个`logs/seatunnel-engine-master.log`和`logs/seatunnel-engine-worker.log`日志文件, 检查是否部署成功, 是否有报错信息.

然后修改`hazelcast-client.yaml`配置
```yaml
hazelcast-client:  
  cluster-name: seatunnel  
  properties:  
    hazelcast.logging.type: log4j2  
  connection-strategy:  
    connection-retry:  
      cluster-connect-timeout-millis: 3000  
  network:  
    cluster-members:  
      - localhost:5801
      - localhost:5901
```
修改完成后, 使用`./bin/seatunnel.sh -c <要提交的配置文件>` 即可将该任务提交到集群中运行.

# K8S环境部署
在K8S中部署, 与物理机部署, 不同的点主要是K8S中`pod`重启后, `IP`地址就会变化, 当使用`TCP/IP`的方式配置时, 就无法指定每个节点的地址. 
要解决这个问题有两种方式:
1. 使用`StatefulSet`来进行部署, 在结合`headless service`, 可以实现固定域名来实现`member-list`不需要改动
2. 使用`K8S`的组网方式, 不需要指定每个节点的`IP/域名`.
个人经验是推荐使用第二种`K8S`的组网方式, 更加简洁一点

需要修改的地方为:
```yaml
join:  
  kubernetes:  
    enabled: true  
    service-dns: <将headless的域名填到这里即可>  
    service-port: 5801  
port:  
  auto-increment: false  
  port: 5801
```

另外有一个地方可以去修改一下, 默认设置中, 日志会打印到文件中, 如果`pod`的磁盘容量有限, 或者日志采集服务无法对文件进行采集, 可以将打印方式修改为`Console`, 这样部署完成后可以直接运行命令`kubectl logs xxx-pod`来查看日志, 不需要再进入容器查看文件.
具体修改的文件为:
- `log4j2.properties`
将`rootLogger.appenderRef.consoleStdout.ref`, `rootLogger.appenderRef.consoleStderr.ref`配置前的注释打开, 将`rootLogger.appenderRef.file.ref`配置添加注释, 从而将日志打印到控制台

提交任务, 一种是进入到容器内, 执行`seatunnel.sh`命令去提交任务.
而另外一种方式则是使用`Rest API`来提交任务



