---
title: Flink源码解析-流式计算核心机制
date: 2026-05-25
categories:
  - publish
tags:
  - Flink
  - Streaming
---
# TL;DR
本文基于 `Flink 1.20` 源码，不再泛泛讨论“什么是流式计算”，而是聚焦两个问题：

1. 为什么 Flink 会成为主流流式处理引擎？
2. Flink 到底靠哪些关键机制，把无界数据流变成可按时间计算、可故障恢复、可做到 `exactly-once` 的系统？

如果把答案压缩成一句话，那就是：

> Flink 真正领先的地方，不是单独提出了 window 或 watermark，而是把 `事件时间`、`watermark`、`window`、`trigger`、`state`、`checkpoint` 这些能力拼成了一套完整且能落地的运行时体系。

本文重点看两条主线：

- Flink 如何处理时间：`event time`、`watermark`、`window`、`trigger`
- Flink 如何保证精准一次：`state`、`checkpoint barrier`、`snapshot`、`恢复`

<!--more-->

# 一、Flink 为什么会成为主流流式处理引擎
Flink 之所以从一众流处理系统里跑出来，并不是因为它“也能处理流”，而是因为它把流处理里最难的几个问题，做成了统一的系统能力。

我认为核心有四点。

## 1.1 它不是用小批次模拟流，而是把流作为一等模型
Flink 的默认计算方式不是“先攒一批再处理”，而是：

- 数据持续到来
- 算子持续消费
- 状态持续更新
- 满足条件就持续输出

这使它在模型上天然适合：

- 低延迟计算
- 长时间运行任务
- 持续更新结果

也正因为它不是把批处理缩小，而是直接把无界流当作基本对象，所以后面的时间处理、状态管理、容错语义才能自然接上。

## 1.2 它把事件时间处理做成了系统能力
真正复杂的流任务，难点从来不是“数据会一直来”，而是：

> 数据可能乱序、可能迟到、可能跨机器延迟，系统怎么知道某个时间段该不该算、能不能算、算到什么程度？

Flink 的答案是：

- 用 `Event Time` 表达业务时间
- 用 `Watermark` 推进事件时间
- 用 `Window` 在无界流上定义逻辑边界
- 用 `Trigger` 决定何时输出

这套组合，使 Flink 可以严肃地处理“按业务时间统计”这类任务，而不只是按机器时钟粗略切分。

## 1.3 它把状态做成了流计算的内建能力
流式计算不是一条记录一条记录地独立执行，而是要“记住过去”。

例如：

- 去重需要记住见过哪些 key
- 聚合需要记住当前累积值
- Join 需要记住另一侧流的中间状态
- 窗口需要记住窗口内已到达的数据

Flink 的优势在于，状态不是额外外挂的组件，而是计算模型的一部分。窗口、定时器、聚合、恢复，都围绕 state 展开。

## 1.4 它把 exactly-once 做到了工程可用
很多系统都能说自己“支持容错”，但真正难的是：

- 故障之后状态能不能恢复到一致点
- 输入重放后会不会重复算
- 输出到外部系统时会不会重复写

Flink 的 checkpoint 体系把这些问题系统化了：

- `CheckpointCoordinator` 负责全局协调
- `CheckpointBarrier` 把一致性边界嵌入数据流
- task 侧做本地 `snapshot`
- 恢复时从统一 checkpoint 点继续

这就是 Flink 能把“强一致流处理”做成主流方案的原因。

# 二、Flink 如何处理时间：从 Event Time 到 Trigger
Flink 在流式处理中最有代表性的能力，就是它对“时间”的建模方式。

如果没有这一层，窗口统计只能退化成：

- 按机器当前时间切
- 到点就算
- 对乱序和迟到数据几乎没有办法

而 Flink 走的是另一条路：让事件时间成为运行时的一部分。

## 2.1 Event Time：Flink 处理的不是“看到数据的时间”，而是“事件发生的时间”
在真实业务里，算子看到一条数据的时间，往往不等于事件发生的时间。

例如：

- 上游积压会导致延迟
- 网络抖动会导致乱序
- 同一个分区、不同分区的数据到达速度可能不同

所以如果只按处理时间算，结果会偏离业务真实时间线。

Flink 的窗口分配接口 `WindowAssigner` 直接体现了这一点：

- [WindowAssigner.java](/Users/jarvis/code/opensource/flink/release-1.20/flink-streaming-java/src/main/java/org/apache/flink/streaming/api/windowing/assigners/WindowAssigner.java)

关键方法：

```java
public abstract Collection<W> assignWindows(
        T element, long timestamp, WindowAssignerContext context);
```

这里传入的不是“当前机器时间”，而是 `timestamp`。这说明窗口归属从一开始就是围绕事件时间定义的。

## 2.2 Watermark：Flink 如何推进事件时间
只有事件时间戳还不够，系统还需要知道：

> 某个时间点之前的数据，是否已经大体到齐？

否则窗口永远无法安全关闭，因为理论上旧时间戳的数据可能一直迟到。

Watermark 的作用，就是给运行时一个“事件时间进度”的判断依据。

你可以把它理解成一句话：

> watermark 表示系统认为，某个时间点之前的大多数事件已经到达，因此可以开始触发对应时间区间上的计算。

这也是为什么 Flink 的事件时间处理不是静态规则，而是一种持续推进的运行时过程。

## 2.3 Window：Flink 如何在无界流上定义“可计算边界”
无界流最大的难点在于它不会自然结束，因此很多聚合都无法直接成立。

例如：

- 一个持续到来的订单流，不能直接做“全量平均值”
- 一个永不结束的点击流，也不能天然知道“这次统计什么时候该输出”

所以 Flink 要先做一件事：

> 把无界流切成逻辑上的有限区间。

窗口就是这个逻辑区间。

### 2.3.1 滚动窗口
滚动窗口的实现可以直接看：

- [TumblingEventTimeWindows.java](/Users/jarvis/code/opensource/flink/release-1.20/flink-streaming-java/src/main/java/org/apache/flink/streaming/api/windowing/assigners/TumblingEventTimeWindows.java)

关键代码：

```java
long start =
        TimeWindow.getWindowStartWithOffset(
                timestamp, (globalOffset + staggerOffset) % size, size);
return Collections.singletonList(new TimeWindow(start, start + size));
```

这段代码说明：

- 对每条数据，先用它的 `timestamp` 定位窗口起点
- 再生成 `[start, start + size)` 这个窗口
- 每条数据只属于一个滚动窗口

也就是说，滚动窗口本质上是在事件时间轴上做等宽切分。

### 2.3.2 滑动窗口
滑动窗口的实现看：

- [SlidingEventTimeWindows.java](/Users/jarvis/code/opensource/flink/release-1.20/flink-streaming-java/src/main/java/org/apache/flink/streaming/api/windowing/assigners/SlidingEventTimeWindows.java)

关键代码：

```java
long lastStart = TimeWindow.getWindowStartWithOffset(timestamp, offset, slide);
for (long start = lastStart; start > timestamp - size; start -= slide) {
    windows.add(new TimeWindow(start, start + size));
}
```

这里的含义是：

- 先找出当前事件能落入的最近一个滑动窗口起点
- 再按 `slide` 向前回溯
- 只要窗口还能覆盖当前事件，就把这个窗口加进去

因此滑动窗口与滚动窗口最大的不同是：

- 滚动窗口里一条数据通常只属于一个窗口
- 滑动窗口里一条数据可能属于多个窗口

## 2.4 Trigger：窗口不是“定义了就自动输出”，而是“被触发才输出”
窗口只定义边界，不定义输出时机。

真正决定“什么时候出结果”的，是 `Trigger`。

默认事件时间窗口使用的是 `EventTimeTrigger`：

- [EventTimeTrigger.java](/Users/jarvis/code/opensource/flink/release-1.20/flink-streaming-java/src/main/java/org/apache/flink/streaming/api/windowing/triggers/EventTimeTrigger.java)

最关键的逻辑是：

```java
if (window.maxTimestamp() <= ctx.getCurrentWatermark()) {
    return TriggerResult.FIRE;
} else {
    ctx.registerEventTimeTimer(window.maxTimestamp());
    return TriggerResult.CONTINUE;
}
```

以及：

```java
return time == window.maxTimestamp() ? TriggerResult.FIRE : TriggerResult.CONTINUE;
```

这段逻辑说明了 Flink 的时间驱动模型：

- 元素到来时，先看当前 watermark 是否已经越过窗口结束边界
- 如果没有越过，就注册一个 event-time timer
- 等 watermark 推进到 `window.maxTimestamp()` 时，再真正触发计算

所以 Flink 的输出不是靠“扫表”或“轮询”，而是靠 `watermark + timer + trigger` 联动推进。

## 2.5 WindowOperator：时间语义如何落到真正的运行时
窗口分配和触发最终不是停留在抽象接口里，而是要落到运行时算子。

真正执行窗口逻辑的是：

- [WindowOperator.java](/Users/jarvis/code/opensource/flink/release-1.20/flink-streaming-java/src/main/java/org/apache/flink/streaming/runtime/operators/windowing/WindowOperator.java)

在 `processElement()` 中，第一步就是：

```java
final Collection<W> elementWindows =
        windowAssigner.assignWindows(
                element.getValue(), element.getTimestamp(), windowAssignerContext);
```

也就是说，每条记录到来时，Flink 会：

1. 用 `WindowAssigner` 计算它属于哪些窗口
2. 把数据写入对应窗口的 state
3. 调用 trigger 的 `onElement`
4. 在需要时注册 timer
5. 在触发时输出窗口结果

这也是为什么说 Flink 的时间处理不是单点概念，而是一套协同机制：

- `timestamp` 决定事件的业务时间
- `watermark` 决定时间推进
- `window` 决定逻辑边界
- `trigger` 决定输出时机
- `operator` 决定如何把这些规则实际执行起来

## 2.6 迟到数据处理：为什么 Flink 的时间语义是可运营的
真实流任务里，迟到数据不是例外，而是常态。

Flink 在 API 上直接提供了：

- `allowedLateness(...)`
- `sideOutputLateData(...)`

对应代码在：

- [WindowedStream.java](/Users/jarvis/code/opensource/flink/release-1.20/flink-streaming-java/src/main/java/org/apache/flink/streaming/api/datastream/WindowedStream.java)

这意味着 Flink 对迟到数据不是“硬丢弃”，而是明确提供了：

- 允许一段延迟补写
- 超过阈值后丢弃或旁路输出

这一点非常重要。因为一个能进入生产的流处理系统，不只是“能算”，还必须“能解释迟到和修正”。

# 三、Flink 如何保证精准一次：State、Checkpoint 与恢复
如果说时间处理能力让 Flink 适合做复杂流统计，那么 `exactly-once` 则让它真正具备了生产级可信度。

而 `exactly-once` 的核心，不是某个神奇开关，而是：

> 状态必须有一致快照，输入输出必须围绕同一个边界恢复。

## 3.1 State：为什么流处理必须围绕状态设计
流式系统之所以难，是因为计算不是一次性结束的。

很多操作都需要跨时间记忆：

- 聚合要记住当前累计值
- 去重要记住历史 key
- 窗口要记住窗口内容
- Join 要记住另一侧尚未匹配的数据

所以在 Flink 里，state 不是附属能力，而是核心运行时结构。

从窗口算子的实现也能直接看到这一点。在 `WindowOperator` 中，每条数据进入窗口后都会写入 `windowState`，后续触发计算时，再从这个状态里取出内容输出。

换句话说，Flink 不是“重新扫描历史数据得到窗口结果”，而是：

- 数据来时不断更新状态
- 触发时从状态读取结果
- 恢复时从状态继续

这就是高吞吐、低延迟与可恢复能够同时成立的前提。

## 3.2 Checkpoint：Flink 不是定期备份，而是在做一致性快照
很多人第一次接触 checkpoint，会把它理解成“定时把内存写盘”。这个理解太粗糙了。

Flink 真正做的是：

> 为整个 job 构造一个全局一致的快照点。

JobManager 侧负责全局协调的类是：

- [CheckpointCoordinator.java](/Users/jarvis/code/opensource/flink/release-1.20/flink-runtime/src/main/java/org/apache/flink/runtime/checkpoint/CheckpointCoordinator.java)

从类成员就能看出 checkpoint 的关键组成：

- `pendingCheckpoints`
- `completedCheckpointStore`
- `checkpointStorageView`
- `checkpointIdCounter`
- `isExactlyOnceMode`

这说明 checkpoint 的本质不是 task 各自拍一张本地快照，而是全局统一编号、统一协调、统一完成的一致性快照过程。

## 3.3 CheckpointBarrier：Flink 如何把一致性边界嵌入数据流
Flink 的经典设计之一，是把 checkpoint 边界编码进数据流网络本身。

对应类：

- [CheckpointBarrier.java](/Users/jarvis/code/opensource/flink/release-1.20/flink-runtime/src/main/java/org/apache/flink/runtime/io/network/api/CheckpointBarrier.java)

类注释已经把语义写得非常直接：

- barrier 由 source 发出
- 算子在某个输入上收到 barrier，知道这是 pre-checkpoint 与 post-checkpoint 数据的边界
- 当算子在所有输入上都收到同一个 barrier，就知道当前 checkpoint 已经在本算子处对齐完成

这里的关键价值是：

- checkpoint 不需要全局停机
- 一致性边界直接沿着数据流传播
- 多输入算子可以围绕同一个 checkpoint id 对齐

这就是 Flink 分布式快照机制的核心。

## 3.4 Task 侧如何真正执行快照
子任务级 checkpoint 的执行器是：

- [SubtaskCheckpointCoordinatorImpl.java](/Users/jarvis/code/opensource/flink/release-1.20/flink-streaming-java/src/main/java/org/apache/flink/streaming/runtime/tasks/SubtaskCheckpointCoordinatorImpl.java)

这个类里维护了很多关键对象：

- `checkpointStorage`
- `channelStateWriter`
- `AsyncCheckpointRunnable`
- `abortedCheckpointIds`

这说明 task 侧不是同步阻塞地“一把存完”，而是包含：

- 快照写入位置
- 通道状态处理
- 异步落盘
- checkpoint 取消与清理

这也是 Flink 能在强一致和高吞吐之间找到平衡的原因之一。

## 3.5 operator 的 `snapshotState()` 为什么重要
Flink 的算子在 checkpoint 时会走 `snapshotState(...)` 这条链路。

它的意义是：

- 正常处理数据时，算子不断更新当前状态
- checkpoint 到来时，算子把当前一致状态导出为快照
- 恢复时，再从这个快照点继续

这套模型对不同类型的算子都适用：

- source 保存读取进度或 split 状态
- 普通有状态算子保存 keyed/operator state
- sink 保存未完成提交或 writer 状态

所以 checkpoint 并不是单独属于 source 或 storage 的概念，而是整个算子运行时协议的一部分。

## 3.6 Exactly-Once：为什么恢复后可以不重不漏
`exactly-once` 的关键不在于“失败后继续跑”，而在于：

> 恢复后的输入位置、内部状态、输出提交语义，必须共同回到同一个一致边界。

Flink 之所以能做到这一点，是因为：

- barrier 定义了统一 checkpoint 边界
- 各 task 在同一 checkpoint id 上保存状态
- source 可以从对应位置恢复
- operator 可以从对应状态恢复

于是恢复后系统不是“尽量接着跑”，而是明确回到某一个一致的历史切面。

这正是 `exactly-once` 和“尽量少丢数据”的本质区别。

## 3.7 端到端 exactly-once 还需要 sink 配合
这里必须补一个边界条件。

Flink 内部状态一致，不自动等于外部系统也一定是 `exactly-once`。

要实现端到端精准一次，sink 侧通常还需要：

- 事务提交协议
- checkpoint 完成后再提交
- 或者严格可靠的幂等语义

因此更准确的表述应该是：

> Flink 通过 state、checkpoint barrier、snapshot 与恢复机制保证内部计算的一致性，再结合支持提交协议的 sink，实现端到端 exactly-once。

# 四、从源码视角看，Flink 流式处理真正领先的是什么
如果把前面的内容收束一下，Flink 能成为主流流式处理引擎，核心不是某一个单独名词，而是这两条链路真正闭环了。

第一条链路是时间处理链路：

- `Event Time`
- `Watermark`
- `Window`
- `Trigger`
- `Timer`
- `WindowOperator`

它解决的是：

> 无界流在乱序、迟到条件下，如何按业务时间稳定地产出结果。

第二条链路是一致性链路：

- `State`
- `CheckpointCoordinator`
- `CheckpointBarrier`
- `snapshotState`
- `恢复`

它解决的是：

> 作业长时间运行、途中故障时，如何恢复到一致计算边界，并继续保证结果不重不漏。

从工程角度看，这两条链路恰好对应了流处理最难的两件事：

- 时间语义
- 一致性语义

而 Flink 的价值，就是把这两件事都做成了运行时能力，而不是留给业务代码手工拼装。

# 五、结语
如果只看表面，Flink 常被概括成：

- 支持 watermark
- 支持窗口
- 支持 checkpoint

但从 Flink 1.20 源码往里看，会发现真正重要的不是“支持这些概念”，而是：

> 它把这些概念做成了一个彼此联动的系统。

在时间处理上：

- `watermark` 不是单独存在，它要和 `window`、`trigger`、`timer`、`operator` 一起工作

在一致性处理上：

- `checkpoint` 也不是单独存在，它要和 `state`、`barrier`、`snapshot`、`恢复`、`sink 提交` 一起工作

这也是为什么 Flink 最终会成为主流流式处理引擎。

因为它解决的不是“怎么把流数据过一遍算子”，而是：

> 怎么在一条永远不会自然结束、还可能乱序和失败的数据流上，持续地产出正确结果。
