---
title: Flink学习(一)
date: 2022-12-04 10:08:12
tags: 
	- big_data
	- Flink
---
# 时间语义
Flink中的时间有三种:
- 事件时间 Event Time.  事件真实发生的时间. 
-  摄入时间 Ingestion time. 事件接入到Flink系统的时间
- 处理时间 Processing Time. 事件到到当前算子的时间
举一个夸张点的例子: 有一条记录, 它与`11:00:00`这个时间点产生. 我们的Flink系统在`12:00:00`这个时间点接入并进入第一个算子. 在Flink系统中又有很多个算子, 到达最后一个算子的时间为`13:00:00`.
那么在这种情况下: 事件时间是`11:00:00`. 这个是不会变的. 对于第一个算子而言, 这时的摄入时间和处理时间都为`12:00:00`.  对于最后一个算子而言, 这时这条时间的摄入时间为`12:00:00`. 处理时间为`13:00:00`

**设置时间语义**
我们需要在Job中设置执行时采用哪种时间语义. 
``` java
env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime);

env.setStreamTimeCharacteristic(TimeCharacteristic.ProcessingTime);

env.setStreamTimeCharacteristic(TimeCharacteristic.IngestionTime);
```

<!--more-->

## Processing Time & Ingestion Time
这两个时间都由Flink系统自己生成.
Processing Time是由每个算子自己生成, 实现起来非常简单, 延迟也是最小的. 但是由于每个时间都是获取的当前算子的时钟, 时钟可能不一致, 并且由于集群中不同机器的执行性能不同, 每个算子也有一定的耗时, 对于第N个算子来说的相同Processing Time, 可能到第N+1个算子上就会有改变. 因此Processing Time在时间窗口下的计算会有不确定性.
Ingestion Time是指事件到底Flink Source的时间. 一个事件在整个处理过程中都使用这个时间. 但是Ingestion Time也还是无法解决事件乱序问题.

这两个时间语义如果对事件进行重新消费, 也不能保证幂等性.

## Event Time
事件时间是这个事件真实产生的时间, 发生时伴随其他信息一起写入到时间中.
但是由于在网络中的传输或其他问题, 可能导致事件到底Flink系统时发生乱序、迟到等现象.
![](https://raw.githubusercontent.com/liunaijie/images/master/20221204203917.svg)
真实情况中的数据大概如上图所示, 我们可以知道在Flink中进行处理的时间必然是大于等于事件发生的时间, 也就是事件都应该在这条红色虚线以下. 
对于红色虚线上的点, 如上图的红色事件, 在12:10收到了12:20的事件, 这是一条未来的事件, 必须要对这条事件进行处理, 比如忽略或者对事件时间进行修改等, 不然会造成后续计算上的错误.
而对于蓝色的事件, 在12:10收到了11:50的事件, 这个事件是历史事件, 如果使用Flink作为批处理系统或者重置Offset后重刷历史, 这个都属于正常事件.
再来看一下事件时间发生在12:10的一系列事件, 它可以在12:10之后的任一时间到达Flink系统

### Watermark
当使用Event Time来进行处理时, 通过上图可知某个时间点的数据会在未来的任意时间到达, 我们需要设置一个界限从而避免无限制的等待, 也就是需要知道我们接入的数据需要何时去触发计算.
watermark是一条特殊的记录, 从代码中可以看到它继承自`StreamElement`
```java
public final class Watermark extends StreamElement {
	...
}
```
#### 如何生成Watermark:
在Flink中, 可以直接在Source算子上生成Watermark, 也可以在其他算子上生成. 推荐是在Source算子上直接生成, 因为这样可以更加准确.
在Source算子中可以调用SourceContext中的方法直接生成Watermark.
```java
public interface SourceFunction<T> extends Function, Serializable {  
  
	void run(SourceContext<T> ctx) throws Exception;

	interface SourceContext<T> {  
	  
	    void collect(T element);  
	  
	    void collectWithTimestamp(T element, long timestamp);  
	  
	    void emitWatermark(Watermark mark);
	}
}
```
亦可在其他算子上调用`assignTimestampsAndWatermarks(watermarkStrategy)`生成, `watermarkStrategy`中接口中包含了很多的默认方法, 其中只有一个方法需要实现即
`WatermarkGenerator<T> createWatermarkGenerator(WatermarkGeneratorSupplier.Context context);`
`WaermarkGenerator`的代码如下
```java
public interface WatermarkGenerator<T> {  
	// 每条事件调用一次
	void onEvent(T event, long eventTimestamp, WatermarkOutput output);  
    
    // 间隔ExecutionConfig setAutoWatermarkInterval(long interval)调用一次该方法
	void onPeriodicEmit(WatermarkOutput output);  
}
```
通过代码可以看出, 这两个方法都可以实现watermark的生成. 但是watermark如果太多也不是一件很好的事情, 很用可能造成下游算子压力过大. 影响整体性能.

看一个Flink内部的实现:
```java
public class BoundedOutOfOrdernessWatermarks<T> implements WatermarkGenerator<T> {  
  
    /** The maximum timestamp encountered so far. */  
    private long maxTimestamp;  
  
    /** The maximum out-of-orderness that this watermark generator assumes. */  
    private final long outOfOrdernessMillis;  
  
	public BoundedOutOfOrdernessWatermarks(Duration maxOutOfOrderness) {  
        ... 
    }  
  
    @Override  
    public void onEvent(T event, long eventTimestamp, WatermarkOutput output) {  
        maxTimestamp = Math.max(maxTimestamp, eventTimestamp);  
    }  
  
    @Override  
    public void onPeriodicEmit(WatermarkOutput output) {  
        output.emitWatermark(new Watermark(maxTimestamp - outOfOrdernessMillis - 1));  
    }  
}
```
该实现中, 定义了一个超时时间, 在`onEvent`中并没有生成Watermark, 只是进行了内部的计算保存了一个当前时刻的最大事件时间, 而在`onPeriodicEmit`方法中才真正的生成Watermark
从该实现中, 我们可以看到Flink会定时得到一个Watermark, 这个Watermark的时间是当前最大事件时间减去一个容忍时间.
![](https://raw.githubusercontent.com/liunaijie/images/master/20221204203613.svg)
如果我们设置`maxOutOfOrderness`为10分钟, 在橙色事件(eventTime为12:10)到来时, 就会生成一个12:00的Watermark, 后续再接收到的紫色事件(12:00)则被认为是迟到事件, 不会参与到后续的计算中. 同样在黄色事件(eventTime为12:20)的事件到来时会生成一个12:10的Watermark, 后续再收到的小于12:10的事件都会被认为是迟到事件

当我们设置的窗口为滚动窗口, 时间大小为10分钟, 容忍时间为10分钟, 时间语义为事件时间时
当黄色事件(eventTime=12:20)的事件到达时会生成一个12:10的Watermark, 这时会触发(12:00-12:10)窗口的计算(因为窗口大小为10分钟), 即计算图中黄色框中部分
当蓝色事件(eventTime=12:30)的事件到达时会生成一个12:20的Watermark, 这时会计算图中蓝色框中的数据, 这部分的数据事件时间都是12:10~12:20.
![](https://raw.githubusercontent.com/liunaijie/images/master/20221204204255.svg)
# WindowAssigner
WindowAssigner的作用是对数据进行窗口的划分
来看下这个抽象类的方法:
```java
public abstract Collection<W> assignWindows(  
        T element, long timestamp, WindowAssignerContext context);  

public abstract boolean isEventTime();

public abstract Trigger<T, W> getDefaultTrigger(StreamExecutionEnvironment env);  
  
public abstract TypeSerializer<W> getWindowSerializer(ExecutionConfig executionConfig);    
```
主要的方法为`assignWindow`, 对传入的element划分到一个或多个窗口内.
看几个主要的实现类:
- TumblingProcessingTimeWindows
```java
public Collection<TimeWindow> assignWindows(  
        Object element, long timestamp, WindowAssignerContext context) {  
    final long now = context.getCurrentProcessingTime();  
    if (staggerOffset == null) {  
        staggerOffset =  
                windowStagger.getStaggerOffset(context.getCurrentProcessingTime(), size);  
    }  
    long start =  
            TimeWindow.getWindowStartWithOffset(  
                    now, (globalOffset + staggerOffset) % size, size);  
    return Collections.singletonList(new TimeWindow(start, start + size));  
}
```
获取当前的处理时间, 然后计算出当前窗口的开始时间start, 返回一个时间窗口

- SlidingProcessingTimeWindows
```java
public Collection<TimeWindow> assignWindows(  
        Object element, long timestamp, WindowAssignerContext context) {  
    timestamp = context.getCurrentProcessingTime();  
    List<TimeWindow> windows = new ArrayList<>((int) (size / slide));  
    long lastStart = TimeWindow.getWindowStartWithOffset(timestamp, offset, slide);  
    for (long start = lastStart; start > timestamp - size; start -= slide) {  
        windows.add(new TimeWindow(start, start + size));  
    }  
    return windows;  
}
```
获取当前的处理时间, 然后根据size和slide计算出一个元素会处于多少个窗口, 然后计算并设置每个窗口的起止时间.

## Flink中内置的一些窗口类型:
Flink里面的时间默认从1970年1月1日0点0分开始计算，可以手动指定offset

### 滑动窗口（Sliding Windows）

```java
.window(SlidingEventTimeWindows.of(Time.seconds(10), Time.seconds(5)))

-- 手动指定offset
.window(SlidingProcessingTimeWindows.of(Time.hours(12), Time.hours(1), Time.hours(-8)))
```

每5秒计算一次，每次计算的窗口大小为10秒

![](https://raw.githubusercontent.com/liunaijie/images/master/sliding-windows.svg)

### 滚动窗口（Tumbling Windows）

滚动窗口是一种特殊的滑动窗口，步长跟窗口大小一致

```sql
.window(TumblingEventTimeWindows.of(Time.seconds(5)))
```

每5秒计算一次，每次窗口大小为5秒
![](https://raw.githubusercontent.com/liunaijie/images/master/tumbling-windows.svg)


### 会话窗口（Session Windows）

进行keyBy之后，这组数据如果超过一定时长后没有新的数据产生则会触发窗口计算，这个窗口内的时间长度无法确定，数据数量也无法确定

```sql
.keyBy(<key selector>)
.window(EventTimeSessionWindows.withGap(Time.minutes(1)))
```

一个user如果超过1分钟没有数据则触发计算

![](https://raw.githubusercontent.com/liunaijie/images/master/session-windows.svg)
# Trigger
Trigger的作用是来计算窗口内的元素是否需要被计算.
首先来看一下Trigger类的几个主要方法:
```java
public abstract TriggerResult onElement(T element, long timestamp, W window, TriggerContext ctx)  
        throws Exception;

public abstract TriggerResult onProcessingTime(long time, W window, TriggerContext ctx)  
        throws Exception;

public abstract TriggerResult onEventTime(long time, W window, TriggerContext ctx)  
        throws Exception;
```
这三个方法的作用从名称就可以看出来, 分别是当一条数据到来时调用, 当Processing Time触发时调用, 当Event Time触发时调用.
先看一下返回结果, 返回结果都是`TriggerResult`这个类. 这个类是一个枚举类, 包含了以下几个值:
- CONTINUE
- FIRE
- PURGE
-  FIRE_AND_PURGE
这几个枚举的作用表明了后续的计算方式.
如果是CONTINUE, 则表示不进行处理.
如果是FIRE, 则表示需要进行计算
如果是PURGE, 则表示需要清空当前窗口内的元素. **不会触发计算**
如果是FIRE_AND_PURGE, 则表示计算的同时也清空窗口内的元素.

Flink内置了以下几个内置的触发器:
- CountTrigger
当事件条数达到设定的阈值后触发
- DeltaTrigger
预先给定一个DeltaFunction和阈值, 每条事件到达后都会根据DeltaFunction进行计算, 如果计算结果超过阈值, 则触发计算
- ProcessingTimeTrigger
当处理时间超过窗口结束时间时触发
- EventTimeTrigger
当事件事件(Watermark)超过窗口结束时间时触发
- ContinuousProcessingTimeTrigger
给定一个时间间隔, 按照处理时间连续触发
- ContinuousEventTimeTrigger
给定一个时间间隔, 按照事件事件连续触发
- PurgingTrigger
包装其他的触发器, 使其触发之后, 清除窗口内的数据和状态

通过代码来看一下具体的实现:
先来看一下CountTrigger的实现:
```java   
@Override  
public TriggerResult onEventTime(long time, W window, TriggerContext ctx) {  
    return TriggerResult.CONTINUE;  
}  
  
@Override  
public TriggerResult onProcessingTime(long time, W window, TriggerContext ctx)  
        throws Exception {  
    return TriggerResult.CONTINUE;  
}

private final long maxCount;  
  
private final ReducingStateDescriptor<Long> stateDesc =  
        new ReducingStateDescriptor<>("count", new Sum(), LongSerializer.INSTANCE);  
  
private CountTrigger(long maxCount) {  
    this.maxCount = maxCount;  
}  
  
@Override  
public TriggerResult onElement(Object element, long timestamp, W window, TriggerContext ctx)  
        throws Exception {  
    ReducingState<Long> count = ctx.getPartitionedState(stateDesc);  
    count.add(1L);  
    if (count.get() >= maxCount) {  
        count.clear();  
        return TriggerResult.FIRE;  
    }  
    return TriggerResult.CONTINUE;  
} 

```
可以看到在CountTrigger的`onEventTime`和`onProcessingTime`方法中都没有做任何逻辑处理, 直接返回CONTINUE.
在`onElement`方法中, 做了一个计数器, 当条数超过阈值后, 首先将计数器进行清零, 然后触发计算.
再看一下`ProcessingTimeTrigger`的代码具体实现:
```java
public TriggerResult onEventTime(long time, TimeWindow window, TriggerContext ctx)  
        throws Exception {  
    return TriggerResult.CONTINUE;  
} 

public TriggerResult onElement(  
        Object element, long timestamp, TimeWindow window, TriggerContext ctx) {  
    ctx.registerProcessingTimeTimer(window.maxTimestamp());  
    return TriggerResult.CONTINUE;  
}  
  
public TriggerResult onProcessingTime(long time, TimeWindow window, TriggerContext ctx) {  
    return TriggerResult.FIRE;  
}
```
在`onEventTime`方法中不做任何处理, 直接返回`CONTINUE`
在`onElement`中向context中注册一个`ProcessingTimeTimer`, 触发的事件为当前window的最大时间
当context中注册的ProcessingTimeTimer到时后, 会调用`onProcessingTime`方法, 这个方法直接返回`FIRE`

## 自定义触发器
有时官方提供的这些触发器可能无法满足我们的需求, 我们可以自己来实现一些自定义的触发器, 从上面的几个源码中, 我们可以看到主要需要实现的三个方法.`onElement`, `onProcessingTime`,`onEventTime`.
假如我们需要实现一个如下的触发器: *每10s触发一次, 并且如果10s内的数据量超过100条,则进行触发, 触发后重新计时, 按照ProcessingTime处理*
这个类似于上面两个`CountTrigger`与`ProcessingTimeTrigger`的结合. 可以写出如下的代码:
```java
public class CustomTrigger<W extends Window> extends Trigger<Object, W> {  
  
   // 触发的条数  
   private final long size;  
   // 触发的间隔时长  
   private final long interval;  
  
   private static final long serialVersionUID = 1L;  
   // 条数计数器  
   private final ReducingStateDescriptor<Long> countStateDesc = new ReducingStateDescriptor<>("count", new ReduceSum(), LongSerializer.INSTANCE);  
   // 时间计数器，保存下一次触发的时间  
   private final ReducingStateDescriptor<Long> timeStateDesc = new ReducingStateDescriptor<>("fire-interval", new ReduceMin(), LongSerializer.INSTANCE);  
  
   public CustomTrigger(long size, long interval) {  
      this.size = size;  
      this.interval = interval;  
   }  
  
   @Override  
   public TriggerResult onElement(Object element, long timestamp, W window, TriggerContext ctx) throws Exception {  
      // 获取当前的条数  
      ReducingState<Long> count = ctx.getPartitionedState(countStateDesc);  
      // 获取下次的触发时间  
      ReducingState<Long> fireTimestamp = ctx.getPartitionedState(timeStateDesc);  
      // 每条数据 counter + 1  
      count.add(1L);  
      if (count.get() >= size) {  
         // 满足条数的触发条件，先清零条数计数器  
         count.clear();  
         // 满足条数时也需要清除时间的触发器  
         ctx.deleteProcessingTimeTimer(fireTimestamp.get());  
         fireTimestamp.clear();  
         // fire 触发计算  
         return TriggerResult.FIRE;  
      }  
      // 如果条数没有达到阈值，并且下次触发时间为空，则注册下次的触发时间  
      timestamp = ctx.getCurrentProcessingTime();  
      if (fireTimestamp.get() == null) {  
         long nextFireTimestamp = timestamp + interval;  
         ctx.registerProcessingTimeTimer(nextFireTimestamp);  
         fireTimestamp.add(nextFireTimestamp);  
      }  
      return TriggerResult.CONTINUE;  
   }  
  
	@Override  
	public TriggerResult onProcessingTime(long time, W window, TriggerContext ctx) throws Exception {  
	   // 获取当前的条数  
	   ReducingState<Long> count = ctx.getPartitionedState(countStateDesc);  
	   // 获取设置的触发时间  
	   ReducingState<Long> fireTimestamp = ctx.getPartitionedState(timeStateDesc);  
	   count.clear();  
	   fireTimestamp.clear();  
	   return TriggerResult.FIRE;  
	}  
  
   @Override  
   public TriggerResult onEventTime(long time, W window, TriggerContext ctx) throws Exception {  
      return TriggerResult.CONTINUE;  
   }  
  
   @Override  
   public void clear(W window, TriggerContext ctx) throws Exception {  
      ReducingState<Long> fireTimestamp = ctx.getPartitionedState(timeStateDesc);  
      ReducingState<Long> count = ctx.getPartitionedState(countStateDesc);  
      long timestamp = fireTimestamp.get();  
      ctx.deleteProcessingTimeTimer(timestamp);  
      fireTimestamp.clear();  
      count.clear();  
   }  
  
   @Override  
   public boolean canMerge() {  
      return true;  
   }  
  
   @Override  
   public void onMerge(W window,  
                  OnMergeContext ctx) {  
      ctx.mergePartitionedState(timeStateDesc);  
      ctx.mergePartitionedState(countStateDesc);  
   }  
  
}  
  
  
class ReduceSum implements ReduceFunction<Long> {  
   @Override  
   public Long reduce(Long value1, Long value2) throws Exception {  
      return value1 + value2;  
   }  
}  
  
  
class ReduceMin implements ReduceFunction<Long> {  
   @Override  
   public Long reduce(Long value1, Long value2) throws Exception {  
      return Math.min(value1, value2);  
   }  
}
```
主要的实现的两个方法:`onElement`, `onProcessingTime`.
在`onElement`方法中, 每一条记录进入条数计数器加一, 当超过阈值时清空两个状态变量, 同时取消下次的ProcessingTime触发时间. 如果没有达到阈值, 并且下次下次触发时间还未设置时, 计算得到下次触发时间注册到context中.
在`onProcessingTime`方法中, 清空两个状态变量后进行触发.

这里的返回结果都是FIRE, 不会清空窗口内的元素, 如果需要清空可以修改为`FIRE_AND_PURGE` 或者使用`PurgingTrigger`类来进行封装.
看一下`PurgingTrigger`的代码
```java
private Trigger<T, W> nestedTrigger;  
  
private PurgingTrigger(Trigger<T, W> nestedTrigger) {  
    this.nestedTrigger = nestedTrigger;  
}  
  
@Override  
public TriggerResult onElement(T element, long timestamp, W window, TriggerContext ctx)  
        throws Exception {  
    TriggerResult triggerResult = nestedTrigger.onElement(element, timestamp, window, ctx);  
    return triggerResult.isFire() ? TriggerResult.FIRE_AND_PURGE : triggerResult;  
}
```
调用包装的其他触发器, 如果是结果`FIRE`则返回`FIRE_AND_PURGE`

# WindowOperator
触发器Trigger只是返回了一个是否要触发计算的结果, 谁来调用了触发器以及进行后续的计算呢? 就是WindowOperator.
在`WindowedStream`中, 会进行WindowOperator的构建.
```java
public WindowOperator(  
        WindowAssigner<? super IN, W> windowAssigner,  
        TypeSerializer<W> windowSerializer,  
        KeySelector<IN, K> keySelector,  
        TypeSerializer<K> keySerializer,  
        StateDescriptor<? extends AppendingState<IN, ACC>, ?> windowStateDescriptor,  
        InternalWindowFunction<ACC, OUT, K, W> windowFunction,  
        Trigger<? super IN, ? super W> trigger,  
        long allowedLateness,  
        OutputTag<IN> lateDataOutputTag) {
		...
}
```
在WindowOperator类中, 可以看到包含了计算所需要的信息, 窗口如何进行划分, key的选择器, 窗口的计算函数, 触发器等.
在这个类中, 也有三个方法:
```java
public void processElement(StreamRecord<IN> element) throws Exception {}

public void onEventTime(InternalTimer<K, W> timer) throws Exception {}

public void onProcessingTime(InternalTimer<K, W> timer) throws Exception {}
```
先来看一下`processElement`方法, 我们将源码简化一下
```java
public void processElement(StreamRecord<IN> element) throws Exception {  
    // 先调用窗口划分器, 进行窗口的划分
    final Collection<W> elementWindows =  
            windowAssigner.assignWindows(  
                    element.getValue(), element.getTimestamp(), windowAssignerContext);  
  
    // if element is handled by none of assigned elementWindows  
    boolean isSkippedElement = true;  
  
    final K key = this.<K>getKeyedStateBackend().getCurrentKey();  
  
    if (windowAssigner instanceof MergingWindowAssigner) {  
	      ...
    } else {  
        for (W window : elementWindows) {  
			// 先判断窗口是否已经过期, 如果过期则不进行后续的处理
            if (isWindowLate(window)) {  
                continue;  
            }  
		    ... 
			// 调用触发器, 得到是否要计算的结果
            TriggerResult triggerResult = triggerContext.onElement(element);  
  
            if (triggerResult.isFire()) {  
	            // 获取窗口的元素
                ACC contents = windowState.get();  
                if (contents == null) {  
                    continue;  
                }  
                // 进行计算
                emitWindowContents(window, contents);  
            }  
			  
            if (triggerResult.isPurge()) {  
                windowState.clear();  
            }  
            registerCleanupTimer(window);  
        }  
    }  
	...  
    }  
}

protected boolean isWindowLate(W window) {  
    return (windowAssigner.isEventTime()  
            && (cleanupTime(window) <= internalTimerService.currentWatermark()));  
}

private void emitWindowContents(W window, ACC contents) throws Exception {  
    timestampedCollector.setAbsoluteTimestamp(window.maxTimestamp());  
    processContext.window = window;  
    // 调用函数进行计算
    userFunction.process(  
            triggerContext.key, window, processContext, contents, timestampedCollector);  
}

```
