---
title: Kubetnetes的一些概念和术语
date: 2019-08-30 10:05:39
categories: "编程"
toc: true
tags: 
	- kubetnetes
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

pod是kubernetes里最小的单位，也是一个最重要的概念。