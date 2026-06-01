---
title: 使用Rust+OpenRaft简单实现的分布式KV系统
date: 2026-05-12
categories:
  - publish
tags:
  - Raft
  - Rust
---
# TL;DR
简单实现了一个基于 Rust 实现的分布式 KV 系统，底层共识算法使用 Raft，具体实现依赖 [OpenRaft](https://github.com/databendlabs/openraft)。  

代码地址： [distribute_kv_openraft](https://github.com/liunaijie/distribute_kv_openraft)

<!--more-->

# OpenRaft 是什么

OpenRaft 可以理解为一个 Rust 生态里的 Raft 实现框架。它负责处理 Raft 协议中的核心一致性逻辑，比如：

- leader election
- log replication
- membership 变更
- snapshot 协议
- 线性一致性读相关机制

但 OpenRaft 并不会替你做完一个分布式系统的所有事情。它更像是把 Raft 的“协议内核”实现好了，而把和具体业务强相关的部分留给你自己补：

- 节点之间如何通信
- 日志如何持久化
- 状态机如何应用日志
- 快照如何生成与安装
- 业务请求如何编码成 Raft log
- 集群中节点的动态扩缩容

这也是为什么在工程实践里，接入 OpenRaft 只是开始，不是结束。真正的工作，是围绕它补齐一套完整的分布式存储运行时。

# 这个仓库实现了什么

这个仓库是一个学习性质的分布式 KV 项目，技术栈比较清晰：

- 使用 Rust 作为实现语言
- 使用 OpenRaft 作为 Raft 协议实现
- 使用 RocksDB 作为持久化存储后端
- 使用 Axum 提供 HTTP 接口
## 相关命令
使用如下命令，启动3个节点的集群。
```shell
cargo run -- \
--node-id 1 \
--port 9901 \
--storage-path /tmp/kv-node-1 \
--member-list "1@127.0.0.1:9901,2@127.0.0.1:9902,3@127.0.0.1:9903"


cargo run -- \
--node-id 2 \
--port 9902 \
--storage-path /tmp/kv-node-2 \
--member-list "1@127.0.0.1:9901,2@127.0.0.1:9902,3@127.0.0.1:9903"



cargo run -- \
--node-id 3 \
--port 9903 \
--storage-path /tmp/kv-node-3 \
--member-list "1@127.0.0.1:9901,2@127.0.0.1:9902,3@127.0.0.1:9903"
```

然后可以直接通过 `curl` 调用业务接口。下面假设当前 leader 监听在 `127.0.0.1:9901`。

写入一个 KV：

```shell
curl "http://127.0.0.1:9901/api/v1/set?key=name&value=raft"
```

读取一个 KV：

```shell
curl "http://127.0.0.1:9901/api/v1/get/name"
```

如果希望走线性一致性读，可以显式带上 `linearize=true`（仅能在leader节点读，follower节点会报错）：

```shell
curl "http://127.0.0.1:9901/api/v1/get/name?linearize=true"
```

删除一个 KV：

```shell
curl "http://127.0.0.1:9901/api/v1/del/name"
```

如果请求打到了 follower，写请求会返回类似“请访问 leader 节点”的错误信息，需要根据返回信息中的leader信息，向leader节点进行请求。

# 做一个 Raft KV 系统，到底需要补哪些内容

如果只从算法论文角度理解 Raft，很容易觉得事情很简单：选主、复制日志、提交日志、应用状态机。  
但一旦进入工程实现，就会发现中间还有很多空白层需要自己补。

结合这个仓库，我认为一个最小可运行的 Raft KV，至少要补齐下面 5 件事。

## 1. 定义业务请求如何进入 Raft

Raft 只关心“复制日志”，并不理解你的业务语义。  
因此第一件事，就是把业务操作编码成 Raft 可以复制的日志命令。
我们定义OpenRaft节点通信的请求与响应结构体
- `RaftRpcRequest`
- `RaftRpcResponse`
在`RaftRpcRequest`中包含两个字段，一个是`RaftRpcRequestType`，暂时仅支持两种类型
- `KvSet`
- `KvDelete`
另外一个字段是`Vec<u8>`类型的`value`字段，这个将不同类型的实际消息序列化之后的内容，在节点通信时，接收到request后，需要再根据不同type将值反序列化为不同的消息体进行处理。
当接收到请求后，对于这两类消息，我们需要将其写入raft中，这是通过`raft_node.client_write(...)`来把业务操作写入 Raft。  
这里有一个很典型的工程分层：

- 业务层只关心“我要写一个 key/value”
- Raft 层负责把它复制成一致日志
- 状态机层在日志提交后再真正落地到 RocksDB

这个分层很重要，因为它明确区分了“收到请求”和“状态真正生效”不是同一件事。

## 2. 实现节点之间的 Raft 通信

在集群中，Raft协议需要与其他节点进行通信，来进行选举，消息推送等。
在OpenRaft中，通信层交给了用户自己来实现，在这个示例中，我直接使用了`Axum + reqwest + HTTP JSON`这样的方式来实现。
在网络层，需要实现：
1. 当OpenRaft需要与其他节点通信时，消息如何发送？
2. 节点如何接收其他节点发送过来的信息，接收后又该如何处理？

### 出站请求
在OpenRaft的Network实现中，它必须实现三个方法
- `append_entries()`
- `vote()`
- `full_snapshot()`
在本次的实例中，我使用`reqwest`直接将这些信息通过HTTP POST发送到其他节点上。

### 入站请求
对应地，在 `axum` 中，也需要实现响应的路由接口，来接收其他节点发送过来的消息。
收到请求后，处理逻辑也很直接：把请求继续交给 `raft_node.append_entries()`、`raft_node.vote()` 或 `raft_node.install_full_snapshot()`。

这一步的关键在于，OpenRaft 负责协议语义，而业务工程只负责把协议请求可靠地送达本地 Raft 实例。

## 3. 实现日志存储
Raft的日志，需要存储Raft节点交互的信息记录，将每一次通信都记录下来。
其中包含了我们的业务请求`RaftRpcRequest`，以及内部的MemberShip等消息。
这是消息体，除此之外还会有LogId，表示这条日志的编号。

Raft 的日志不是普通缓存，而是整个一致性系统的基础事实来源。  
只要你想让节点重启后还能恢复，日志就必须持久化。

这个仓库在 `src/raft/store/log_store.rs` 中实现了 `RaftLogReader` 和 `RaftLogStorage`，底层使用 RocksDB 存储。

它实际持久化了几类关键数据：
- raft log entries （也就是节点之间发送的消息，包括业务消息与内部消息）
- 当前 vote  （当前节点投票给了哪个节点）
- `last_purged_log_id` （上一次commit的日志id，从这个id向后表示未commit的日志）

## 4. 实现状态机应用
这个部分是真正的状态存储，日志最终会被提交，保存到状态机中。

日志复制成功，并不代表系统状态已经更新。  
只有当日志被提交并应用到状态机之后，KV 数据才算真正生效。

这个仓库在 `src/raft/store/state_machine.rs` 里实现了 `RaftStateMachine<TypeConfig>`。  
这里是真正把 Raft 日志变成业务状态的地方。

### 写请求如何应用

在 `apply()` 里，代码会遍历已经提交的 entry：

- 遇到 `KvSet`，就把 `DataEntity` 写入 `sm_data`
- 遇到 `KvDelete`，就从 `sm_data` 中删除对应 key
- 遇到 membership entry，则更新 `last_membership`

这里状态机不仅保存业务数据，还保存两类状态机元信息：

- `last_applied_log`
- `last_membership`

这两者都放在 `sm_meta` column family 中。

### 为什么这里要做原子写

这个实现里一个非常关键的工程点，是使用 RocksDB `WriteBatch` 把下面几类数据一次性提交：

- 业务数据变更
- `last_applied_log`
- `last_membership`

这样做的意义是：状态机数据和它对应的进度元信息必须一致。  
如果业务数据写成功了，但 `last_applied_log` 没写进去，重启恢复后就会出现状态不一致；反过来也一样。

因此这里的“原子写”并不是性能优化，而是正确性要求。

## 5. 实现快照构建与安装

只靠日志无限增长不是长久方案。  
当日志越来越多时，系统需要通过 snapshot 压缩状态，把“历史日志”折叠成一个新的状态基线。

这个仓库在 `state_machine.rs` 中把 snapshot 的主流程补齐了：

- `build_snapshot()`
- `begin_receiving_snapshot()`
- `install_snapshot()`
- `get_current_snapshot()`

### 构建快照

`build_snapshot()` 会从 RocksDB 中遍历 `sm_data`，把当前状态机内容提取出来，和 snapshot metadata 一起序列化。  
这里的 metadata 包括：

- `last_log_id`
- `last_membership`
- `snapshot_id`

实现里还会把 snapshot 文件写入 `snapshots/` 目录，方便后续恢复当前最新快照。

### 安装快照

`install_snapshot()` 的核心逻辑是：

- 反序列化快照数据
- 清空当前 `sm_data`
- 重新写入快照中的所有 KV 数据
- 恢复 `last_applied_log` 与 `last_membership`

同样，这里也使用了批量写，确保快照恢复过程在持久化层面尽量保持一致。

### 为什么快照不是“可选功能”

很多人在第一次做 Raft 工程实现时，会把 snapshot 看成后期优化项。  
实际上不是。

只要系统需要：

- 降低日志回放成本
- 支持慢节点追赶
- 缩短重启恢复时间

那么快照就是必做项。  
这个仓库把 snapshot 整体链路补上，是它比“只会选主和复制日志”的 demo 更进一步的地方。

## Rust 里的几个实现细节

由于使用的是Rust来进行编写，这个语言也是刚开始学习，所以也记录下一些使用心得。

首先Rust是强类型，静态类型的语言。在编译期就确定了变量类型。
Rust目前没法像`Spring`中那样直接调用`@Autowired`来获取一个bean单例，所以这里也采取了一些其他方法（使用OnceLock静态变量，来设置或获取）来使程序运行起来（但是感觉这个应该不是一个正确的使用方法）。

## 这个仓库当前的完成度与边界

从实践角度看，这个项目已经具备一个最小可运行 Raft KV 的主路径：

- 节点可通过命令行参数启动
- 集群成员列表可在启动时初始化
- 写请求能进入 Raft 日志复制
- 状态机能把提交后的日志落到 RocksDB
- 节点间支持 append/vote/snapshot RPC
- 读请求支持可选的线性一致性读取

但它同时也有很多功能没有实现。

例如
- 集群的扩缩容机制，新节点启动时如何自动加入集群，成员变更的流程。
- 更完整的 leader redirect 机制
- 更丰富的错误模型
- metrics 与观测能力

