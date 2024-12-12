---
title: SeaTunnel源码解析-(三)Zeta引擎执行解析
date: 2024-11-25
categories:
  - publish
tags:
  - seatunnel
---
# 这篇文章会聊些什么
SeaTunnel作为一款数据集成工具, 那么它最终的目的是来做数据同步的, 可以将数据从某个存储同步到另外一个存储中. 
但是这篇文档并不会聊它使用层面的事情, 而是去聊一下这个工具/框架的设计, 任务的执行等.对于某个连接器(数据库)的实现不会深入的了解.
基于的源码版本: `2.3.6-release`

# 任务是如何被执行的
在我的另外一篇文章[2.Zeta引擎源码讲解](2.Zeta引擎源码讲解.md)中有一些关于Zeta引擎的分析, 聊了一下Zeta引擎的客户端, 服务端都会做一些什么事情, 也笼统的带了一点任务执行的内容, 想了解相关内容的朋友可以去看一下.
在下面的内容, 则主要是记录一下在SeaTunnel中, 一个任务是如何与连接器中的各种类进行关联的.


要聊任务与连接器的关联, 就要回到物理计划生成的这一部分(`PhysicalPlanGenerator#generate()`).

```java
Stream<SubPlan> subPlanStream =  
        pipelines.stream()  
                .map(  
                        pipeline -> {  
                            this.pipelineTasks.clear();  
                            this.startingTasks.clear();  
                            this.subtaskActions.clear();  
                            final int pipelineId = pipeline.getId();  
                            final List<ExecutionEdge> edges = pipeline.getEdges();  
  
                            List<SourceAction<?, ?, ?>> sources = findSourceAction(edges);  
  
                            List<PhysicalVertex> coordinatorVertexList =  
                                    getEnumeratorTask(  
                                            sources, pipelineId, totalPipelineNum);  
                            coordinatorVertexList.addAll(  
                                    getCommitterTask(edges, pipelineId, totalPipelineNum));  
  
                            List<PhysicalVertex> physicalVertexList =  
                                    getSourceTask(  
                                            edges, sources, pipelineId, totalPipelineNum);  
  
                            physicalVertexList.addAll(  
                                    getShuffleTask(edges, pipelineId, totalPipelineNum));  
  
                            CompletableFuture<PipelineStatus> pipelineFuture =  
                                    new CompletableFuture<>();  
                            waitForCompleteBySubPlanList.add(  
                                    new PassiveCompletableFuture<>(pipelineFuture));  
  
                            checkpointPlans.put(  
                                    pipelineId,  
                                    CheckpointPlan.builder()  
                                            .pipelineId(pipelineId)  
                                            .pipelineSubtasks(pipelineTasks)  
                                            .startingSubtasks(startingTasks)  
                                            .pipelineActions(pipeline.getActions())  
                                            .subtaskActions(subtaskActions)  
                                            .build());  
                            return new SubPlan(  
                                    pipelineId,  
                                    totalPipelineNum,  
                                    initializationTimestamp,  
                                    physicalVertexList,  
                                    coordinatorVertexList,  
                                    jobImmutableInformation,  
                                    executorService,  
                                    runningJobStateIMap,  
                                    runningJobStateTimestampsIMap,  
                                    tagFilter);  
                        });
```

这是将执行计划转换为物理计划时的相关代码，里面有这样4行代码。
生成`EnumeratorTask`, `CommitterTask`将其添加到协调器任务列表中
生成`SourceTask`，`ShuffleTask`将其添加到物理任务列表中。
```java
List<PhysicalVertex> coordinatorVertexList =  
        getEnumeratorTask(  
                sources, pipelineId, totalPipelineNum);  
coordinatorVertexList.addAll(  
        getCommitterTask(edges, pipelineId, totalPipelineNum));  
  
List<PhysicalVertex> physicalVertexList =  
        getSourceTask(  
                edges, sources, pipelineId, totalPipelineNum);  
  
physicalVertexList.addAll(  
        getShuffleTask(edges, pipelineId, totalPipelineNum));

```

生成计划图的过程的大致在第二篇文章中也有记录[2.Zeta引擎源码讲解](2.Zeta引擎源码讲解.md)
我们这篇文章看下这四行代码以及他们与上面的`Source`，`Transform`，`Sink`有什么关系。接口中定义的`reader`，`enumerator`，`writer`是如何被执行的。

## Task
在看这几个之前先看下他们实现的公共接口`Task`
从物理计划解析的代码可以知道，一个同步任务的执行过程都会被转换为`Task`。
`Task`是执行层面的最小单位，一个同步任务配置`DAG`，可以包括多个不相关，可以并行的`Pipeline`，一个`Pipeline`中可以包括多个类型的`Task`，`Task`之间存在依赖关系，可以认为是一个图中的一个顶点。
任务的容错也是基于最小粒度的Task来进行恢复的，而无需恢复整个DAG或Pipeline。可以实现最小粒度的容错。

一个`Task`在执行时会被`worker`上线程池里面的一个线程拿去执行，在`SeaTunnel`中对于数据同步的场景，某些Task可能暂时没有数据需要进行同步，如果一直占用某个线程资源，可能会造成浪费的情况，做了共享资源的优化。关于这部分的内容，可以参考这个[Pull Request](https://github.com/apache/seatunnel/issues/2279)以及`TaskExecutionService#BlockingWorker`和`TaskExecutionService#CooperativeTaskWorker`相关代码(此功能也默认没有开启，不过这部分代码的设计确实值得了解学习一下。)

一个`Task`被分类为`CoordinatorTask`协调任务和`SeaTunnelTask`同步任务。
这篇内容里面不会对`CoordinatorTask`协调任务里面的`checkpoint`进行探讨, 只会关注`SeaTunnelTask`同步任务.
### SourceSplitEnumeratorTask
在生成物理计划时，会对所有的`source`进行遍历，为每个`source`都创建一个
`SourceSplitEnumeratorTask`
```java
private List<PhysicalVertex> getEnumeratorTask(  
        List<SourceAction<?, ?, ?>> sources, int pipelineIndex, int totalPipelineNum) {  
    AtomicInteger atomicInteger = new AtomicInteger(-1);  
  
    return sources.stream()  
            .map(  
                    sourceAction -> {  
                        long taskGroupID = idGenerator.getNextId();  
                        long taskTypeId = idGenerator.getNextId();  
                        TaskGroupLocation taskGroupLocation =  
                                new TaskGroupLocation(  
                                        jobImmutableInformation.getJobId(),  
                                        pipelineIndex,  
                                        taskGroupID);  
                        TaskLocation taskLocation =  
                                new TaskLocation(taskGroupLocation, taskTypeId, 0);  
                        SourceSplitEnumeratorTask<?> t =  
                                new SourceSplitEnumeratorTask<>(  
                                        jobImmutableInformation.getJobId(),  
                                        taskLocation,  
                                        sourceAction);  
                        ...
                        ...
                    })  
            .collect(Collectors.toList());  
}
```

我们先看下这个数据源切入任务类的成员变量和构造方法：
```java
public class SourceSplitEnumeratorTask<SplitT extends SourceSplit> extends CoordinatorTask {  
  
    private static final long serialVersionUID = -3713701594297977775L;  
  
    private final SourceAction<?, SplitT, Serializable> source;  
    private SourceSplitEnumerator<SplitT, Serializable> enumerator;  
    private SeaTunnelSplitEnumeratorContext<SplitT> enumeratorContext;  
  
    private Serializer<Serializable> enumeratorStateSerializer;  
    private Serializer<SplitT> splitSerializer;  
  
    private int maxReaderSize;  
    private Set<Long> unfinishedReaders;  
    private Map<TaskLocation, Address> taskMemberMapping;  
    private Map<Long, TaskLocation> taskIDToTaskLocationMapping;  
    private Map<Integer, TaskLocation> taskIndexToTaskLocationMapping;  
  
    private volatile SeaTunnelTaskState currState;  
  
    private volatile boolean readerRegisterComplete;  
  
    private volatile boolean prepareCloseTriggered;  
  
    @SuppressWarnings("unchecked")  
    public SourceSplitEnumeratorTask(  
            long jobID, TaskLocation taskID, SourceAction<?, SplitT, ?> source) {  
        super(jobID, taskID);  
        this.source = (SourceAction<?, SplitT, Serializable>) source;  
        this.currState = SeaTunnelTaskState.CREATED;  
    }

}
```

可以看到这个类中持有了几个关键的成员变量，`SourceAction`，`SourceSplitEnumerator`, `SeaTunnelSplitEnumeratorContext` 这些都是与`enumerator`相关的类。
还有几个`map`，`set`等容器存放了任务信息，任务执行地址等等的映射关系。

在构造方法的最后会将当前任务的状态初始化为`CREATED`

再来看下这个任务的其他方法：
- 初始化
```java
@Override  
public void init() throws Exception {  
    currState = SeaTunnelTaskState.INIT;  
    super.init();  
    readerRegisterComplete = false;  
    log.info(  
            "starting seatunnel source split enumerator task, source name: "  
                    + source.getName());  
    enumeratorContext =  
            new SeaTunnelSplitEnumeratorContext<>(  
                    this.source.getParallelism(),  
                    this,  
                    getMetricsContext(),  
                    new JobEventListener(taskLocation, getExecutionContext()));  
    enumeratorStateSerializer = this.source.getSource().getEnumeratorStateSerializer();  
    splitSerializer = this.source.getSource().getSplitSerializer();  
    taskMemberMapping = new ConcurrentHashMap<>();  
    taskIDToTaskLocationMapping = new ConcurrentHashMap<>();  
    taskIndexToTaskLocationMapping = new ConcurrentHashMap<>();  
    maxReaderSize = source.getParallelism();  
    unfinishedReaders = new CopyOnWriteArraySet<>();  
}


```
在初始化时，会将状态修改为`INIT`，并且创建`enumeratorContext`，以及对其他几个变量进行初始化操作。
不知道大家有没有注意到，到执行完`init`方法，`enumerator`实例都没有被创建出来，
当搜索一下代码，会发现`enumerator`实例会在`restoreState(List<ActionSubtaskState> actionStateList)`这个方法中进行初始化。
当我们看完状态切换后就可以看到这个方法什么时候被调用了。
- 状态切换
```java
private void stateProcess() throws Exception {  
    switch (currState) {  
        case INIT:  
            currState = WAITING_RESTORE;  
            reportTaskStatus(WAITING_RESTORE);  
            break;  
        case WAITING_RESTORE:  
            if (restoreComplete.isDone()) {  
                currState = READY_START;  
                reportTaskStatus(READY_START);  
            } else {  
                Thread.sleep(100);  
            }  
            break;  
        case READY_START:  
            if (startCalled && readerRegisterComplete) {  
                currState = STARTING;  
                enumerator.open();  
                enumeratorContext.getEventListener().onEvent(new EnumeratorOpenEvent());  
            } else {  
                Thread.sleep(100);  
            }  
            break;  
        case STARTING:  
            currState = RUNNING;  
            log.info("received enough reader, starting enumerator...");  
            enumerator.run();  
            break;  
        case RUNNING:  
            // The reader closes automatically after reading  
            if (prepareCloseStatus) {  
                this.getExecutionContext()  
                        .sendToMaster(new LastCheckpointNotifyOperation(jobID, taskLocation));  
                currState = PREPARE_CLOSE;  
            } else if (prepareCloseTriggered) {  
                currState = PREPARE_CLOSE;  
            } else {  
                Thread.sleep(100);  
            }  
            break;  
        case PREPARE_CLOSE:  
            if (closeCalled) {  
                currState = CLOSED;  
            } else {  
                Thread.sleep(100);  
            }  
            break;  
        case CLOSED:  
            this.close();  
            return;  
            // TODO support cancel by outside  
        case CANCELLING:  
            this.close();  
            currState = CANCELED;  
            return;  
        default:  
            throw new IllegalArgumentException("Unknown Enumerator State: " + currState);  
    }  
}
```
1.  当调用`init`方法，会将状态设置为`INIT`，进入分支判断
2. 当状态为`INIT`时，将状态切换为`WAITING_RESTORE`
3. 当状态为`WAITING_RESTORE`时，进行`restoreComplete.isDone()`条件判断，当不满足时，睡眠100毫秒后重试。当满足时，会将状态设置为`READY_START`
> `restoreComplete`在执行`init`方法时，会完成初始化操作，所以这里的睡眠等待就是等待`init`方法调用完成。
4. 当状态为`READY_START`时，会判断是否所有的reader都注册完成，如果都注册完成则将状态修改为`STARTING`，并且调用`enumerator.open()`方法。如果没有全部注册完成，则是继续休眠等待，一直到全部注册完成为止。
> `readerRegisterComplete`变量在什么时候会变成true：
>  在初始化时，可以获取到source的并行度，也就是最终需要多少个reader，保存为maxReaderSize
>  reader在启动时，会向enumerator注册自己的地址，在SourceSplitEnumeratorTask中内部维护了一个map结构，保存了reader的信息，每当有新reader注册时就会判断是否达到maxReaderSize，当达到数量后，会将readerRegisterComplete置为true
5. 当状态为`STARTING`时，将状态切换为`RUNNING`，同时调用`enumerator.run()`方法。
当调用run方法后，enumerator会真正去执行切分任务，根据配置，实际数据等等方式来将数据读取任务切分成多个小任务。然后将任务分发到不同的reader上。
6. 当状态为`RUNNING`时，会检查状态是否需要关闭，如果需要关闭则将状态修改为`PREPARE_CLOSE`, 否则休眠等待一直等到需要关闭。
> prepareCloseStatus, prepareCloseTriggered变量什么时候会变为true：
> prepareCloseStatus变量会在所有的reader都完成读取任务时将状态置为true，也就是说enumerator任务是在所有reader任务结束之后才能结束的。
> prepareCloseTriggered 变量则是当接收到系统任务完成或者是接收到需要做savepoint时才会将状态置为true
> 当两个变量被置为true时，表示当前任务已经结束或者需要手动结束了
7. 当状态为`PREPARE_CLOSE`时，会判断`closeCalled`变量是否为true，如果是则将状态修改为`CLOSED`，否则休眠等待
8. CLOSED/CANCELLING状态时，则调用close方法对当前任务进行资源关闭清理工作。

刚刚在上面有写到`enumerator`实例没有被初始化，那么当调用`enumerator`相关方法时应该会得到空指针异常，所以初始化操作也就是`restoreState`的调用肯定是在`READY_START`状态前。
在最开始的两个状态`INIT`,`WAITING_RESTORE`中，有两个上报更新任务状态的方法调用.
- `reportTaskStatus(WAITING_RESTORE);`
- `reportTaskStatus(READY_START);`
这个方法里，会向集群的Master发送一条`TaskReportStatusOperation`消息，消息里包含当前任务的位置和状态信息
```Java
protected void reportTaskStatus(SeaTunnelTaskState status) {  
    getExecutionContext()  
            .sendToMaster(new TaskReportStatusOperation(taskLocation, status))  
            .join();  
}
```

我们看下`TaskReportStatusOperation`这个类的代码
```Java
@Override  
public void run() throws Exception {  
    CoordinatorService coordinatorService =  
            ((SeaTunnelServer) getService()).getCoordinatorService();  
    RetryUtils.retryWithException(  
            () -> {  
                coordinatorService  
                        .getJobMaster(location.getJobId())  
                        .getCheckpointManager()  
                        .reportedTask(this);  
                return null;  
            },  
            new RetryUtils.RetryMaterial(  
                    Constant.OPERATION_RETRY_TIME,  
                    true,  
                    e -> true,  
                    Constant.OPERATION_RETRY_SLEEP));  
}
```
可以看到在这个类中，会根据当前任务的id获取到`JobMaster`，然后调用其`checkpointManager.reportTask()`方法
再来看下`checkpointManager.reportTask()`方法
```Java
public void reportedTask(TaskReportStatusOperation reportStatusOperation) {  
    // task address may change during restore.  
    log.debug(  
            "reported task({}) status {}",  
            reportStatusOperation.getLocation().getTaskID(),  
            reportStatusOperation.getStatus());  
    getCheckpointCoordinator(reportStatusOperation.getLocation())  
            .reportedTask(reportStatusOperation);  
}


protected void reportedTask(TaskReportStatusOperation operation) {  
    pipelineTaskStatus.put(operation.getLocation().getTaskID(), operation.getStatus());  
    CompletableFuture.runAsync(  
                    () -> {  
                        switch (operation.getStatus()) {  
                            case WAITING_RESTORE:  
                                restoreTaskState(operation.getLocation());  
                                break;  
                            case READY_START:  
                                allTaskReady();  
                                break;  
                            default:  
                                break;  
                        }  
                    },  
                    executorService)  
            .exceptionally(  
                    error -> {  
                        handleCoordinatorError(  
                                "task running failed",  
                                error,  
                                CheckpointCloseReason.CHECKPOINT_INSIDE_ERROR);  
                        return null;  
                    });  
}

```
在`CheckpointCoordinator`中，会根据状态分别调用`restoreTaskState()`和`allTaskReady()`两个方法。
先看下`restoreTaskState()`方法
```Java
private void restoreTaskState(TaskLocation taskLocation) {  
    List<ActionSubtaskState> states = new ArrayList<>();  
    if (latestCompletedCheckpoint != null) {  
        if (!latestCompletedCheckpoint.isRestored()) {  
            latestCompletedCheckpoint.setRestored(true);  
        }  
        final Integer currentParallelism = pipelineTasks.get(taskLocation.getTaskVertexId());  
        plan.getSubtaskActions()  
                .get(taskLocation)  
                .forEach(  
                        tuple -> {  
                            ActionState actionState =  
                                    latestCompletedCheckpoint.getTaskStates().get(tuple.f0());  
                            if (actionState == null) {  
                                LOG.info(  
                                        "Not found task({}) state for key({})",  
                                        taskLocation,  
                                        tuple.f0());  
                                return;  
                            }  
                            if (COORDINATOR_INDEX.equals(tuple.f1())) {  
                                states.add(actionState.getCoordinatorState());  
                                return;  
                            }  
                            for (int i = tuple.f1();  
                                    i < actionState.getParallelism();  
                                    i += currentParallelism) {  
                                ActionSubtaskState subtaskState =  
                                        actionState.getSubtaskStates().get(i);  
                                if (subtaskState != null) {  
                                    states.add(subtaskState);  
                                }  
                            }  
                        });  
    }  
    checkpointManager  
            .sendOperationToMemberNode(new NotifyTaskRestoreOperation(taskLocation, states))  
            .join();  
}
```
在这个方法里，首先会判断`latestCompletedCheckpoint`是否为null，那么我们在任务最开始的时候，这个状态肯定是空的，那么就会直接调用最下面的一段代码，发送一个`NotifyTaskRestoreOperation`到具体的任务节点.
既然看到这段代码，那么就再多想一下，如果`latestCompletedCheckpoint`不为null，那么就表示之前有过`checkpoint`记录，那么就表示了该任务是由历史状态进行恢复的，需要查询出历史状态，从历史状态进行恢复，这里的`List<ActionSubtaskState>`就存储了这些状态信息。

继续看下`NotifyTaskRestoreOperation`的代码
```Java
public void run() throws Exception {  
    SeaTunnelServer server = getService();  
    RetryUtils.retryWithException(  
            () -> {  
                log.debug("NotifyTaskRestoreOperation " + taskLocation);  
                TaskGroupContext groupContext =  
                        server.getTaskExecutionService()  
                                .getExecutionContext(taskLocation.getTaskGroupLocation());  
                Task task = groupContext.getTaskGroup().getTask(taskLocation.getTaskID());  
                try {  
                    ClassLoader classLoader = Thread.currentThread().getContextClassLoader();  
                    task.getExecutionContext()  
                            .getTaskExecutionService()  
                            .asyncExecuteFunction(  
                                    taskLocation.getTaskGroupLocation(),  
                                    () -> {  
                                        Thread.currentThread()  
                                                .setContextClassLoader(  
                                                        groupContext.getClassLoader());  
                                        try {  
                                            log.debug(  
                                                    "NotifyTaskRestoreOperation.restoreState "  
                                                            + restoredState);  
                                            task.restoreState(restoredState);  
                                            log.debug(  
                                                    "NotifyTaskRestoreOperation.finished "  
                                                            + restoredState);  
                                        } catch (Throwable e) {  
                                            task.getExecutionContext()  
                                                    .sendToMaster(  
                                                            new CheckpointErrorReportOperation(  
                                                                    taskLocation, e));  
                                        } finally {  
                                            Thread.currentThread()  
                                                    .setContextClassLoader(classLoader);  
                                        }  
                                    });  
  
                } catch (Exception e) {  
                    throw new SeaTunnelException(e);  
                }  
                return null;  
            },  
            new RetryUtils.RetryMaterial(  
                    Constant.OPERATION_RETRY_TIME,  
                    true,  
                    exception ->  
                            exception instanceof TaskGroupContextNotFoundException  
                                    && !server.taskIsEnded(taskLocation.getTaskGroupLocation()),  
                    Constant.OPERATION_RETRY_SLEEP));  
}
```
从上面的代码中可以看出最终是调用了`task.restoreState(restoredState)`方法。在这个方法调用中，`enumerator`实例也就被初始化了。

在上面还有一个当状态为`READY_START`时，调用`allTaskReady()`的分支。
我们先回到分支切换时，看下当什么情况下会是`READY_START`的状态。
```Java
case WAITING_RESTORE:  
    if (restoreComplete.isDone()) {  
        currState = READY_START;  
        reportTaskStatus(READY_START);  
    } else {  
        Thread.sleep(100);  
    }  
    break;
```
这里会判断一个`restoreComplete`是否是完成状态，而这个变量会在`restoreState`方法内标记为完成
```Java
@Override  
public void restoreState(List<ActionSubtaskState> actionStateList) throws Exception {  
    log.debug("restoreState for split enumerator [{}]", actionStateList);  
    Optional<Serializable> state =  .....;  
    if (state.isPresent()) {  
        this.enumerator =  
                this.source.getSource().restoreEnumerator(enumeratorContext, state.get());  
    } else {  
        this.enumerator = this.source.getSource().createEnumerator(enumeratorContext);  
    }  
    restoreComplete.complete(null);  
    log.debug("restoreState split enumerator [{}] finished", actionStateList);  
}
```
也就是当初始化真正完成时，会标记为`READY_START`的状态。
看下`allTaskReady`的方法
```Java
private void allTaskReady() {  
    if (pipelineTaskStatus.size() != plan.getPipelineSubtasks().size()) {  
        return;  
    }  
    for (SeaTunnelTaskState status : pipelineTaskStatus.values()) {  
        if (READY_START != status) {  
            return;  
        }  
    }  
    isAllTaskReady = true;  
    InvocationFuture<?>[] futures = notifyTaskStart();  
    CompletableFuture.allOf(futures).join();  
    notifyCompleted(latestCompletedCheckpoint);  
    if (coordinatorConfig.isCheckpointEnable()) {  
        LOG.info("checkpoint is enabled, start schedule trigger pending checkpoint.");  
        scheduleTriggerPendingCheckpoint(coordinatorConfig.getCheckpointInterval());  
    } else {  
        LOG.info(  
                "checkpoint is disabled, because in batch mode and 'checkpoint.interval' of env is missing.");  
    }  
}
```
这个方法内调用`notifyTaskStart()`方法，在此方法内会发送一个`NotifyTaskStartOperation`消息，在`NotifyTaskStartOperation`中，会获取到`Task`，调用`startCall`方法，在`startCall`中，将`startCalled`变量置为`true`

只有这里被执行了，状态切换中的`READY_START`状态才会切换为`STARTING` 
```Java
case READY_START:  
    // 当任务启动并且所有reader节点也都启动注册完成后  
    // 改为STARTING状态，并且调用enumerate的open方法  
    // 否则一直等待
    // 直到自身启动完成，以及所有reader注册完成  
    if (startCalled && readerRegisterComplete) {  
        currState = STARTING;  
        enumerator.open();  
    } else {  
        Thread.sleep(100);  
    }  
    break;
```

其他的任务类型也都会有这样一段逻辑。


接着按照顺序先看下`committer task`，这是另外一个协调任务
### SinkAggregatedCommitterTask
这个类的代码与enumerator的代码类似，
```java
public class SinkAggregatedCommitterTask<CommandInfoT, AggregatedCommitInfoT>  
        extends CoordinatorTask {  
  
    private static final long serialVersionUID = 5906594537520393503L;  
  
    private volatile SeaTunnelTaskState currState;  
    private final SinkAction<?, ?, CommandInfoT, AggregatedCommitInfoT> sink;  
    private final int maxWriterSize;  
  
    private final SinkAggregatedCommitter<CommandInfoT, AggregatedCommitInfoT> aggregatedCommitter;  
  
    private transient Serializer<AggregatedCommitInfoT> aggregatedCommitInfoSerializer;  
    @Getter private transient Serializer<CommandInfoT> commitInfoSerializer;  
  
    private Map<Long, Address> writerAddressMap;  
  
    private ConcurrentMap<Long, List<CommandInfoT>> commitInfoCache;  
  
    private ConcurrentMap<Long, List<AggregatedCommitInfoT>> checkpointCommitInfoMap;  
  
    private Map<Long, Integer> checkpointBarrierCounter;  
    private CompletableFuture<Void> completableFuture;  
  
    private MultiTableResourceManager resourceManager;  
    private volatile boolean receivedSinkWriter;  
  
    public SinkAggregatedCommitterTask(  
            long jobID,  
            TaskLocation taskID,  
            SinkAction<?, ?, CommandInfoT, AggregatedCommitInfoT> sink,  
            SinkAggregatedCommitter<CommandInfoT, AggregatedCommitInfoT> aggregatedCommitter) {  
        super(jobID, taskID);  
        this.sink = sink;  
        this.aggregatedCommitter = aggregatedCommitter;  
        this.maxWriterSize = sink.getParallelism();  
        this.receivedSinkWriter = false;  
    }
	...
}
```
成员变量存储了`sink`的`action`，`committer`的实例引用。
使用几个容器存储`writer`的地址，`checkpoint id`与`commit`信息的映射等。

接下来再看下初始化方法
```java
@Override  
public void init() throws Exception {  
    super.init();  
    currState = INIT;  
    this.checkpointBarrierCounter = new ConcurrentHashMap<>();  
    this.commitInfoCache = new ConcurrentHashMap<>();  
    this.writerAddressMap = new ConcurrentHashMap<>();  
    this.checkpointCommitInfoMap = new ConcurrentHashMap<>();  
    this.completableFuture = new CompletableFuture<>();  
    this.commitInfoSerializer = sink.getSink().getCommitInfoSerializer().get();  
    this.aggregatedCommitInfoSerializer =  
            sink.getSink().getAggregatedCommitInfoSerializer().get();  
    if (this.aggregatedCommitter instanceof SupportResourceShare) {  
        resourceManager =  
                ((SupportResourceShare) this.aggregatedCommitter)  
                        .initMultiTableResourceManager(1, 1);  
    }  
    aggregatedCommitter.init();  
    if (resourceManager != null) {  
        ((SupportResourceShare) this.aggregatedCommitter)  
                .setMultiTableResourceManager(resourceManager, 0);  
    }  
    log.debug(  
            "starting seatunnel sink aggregated committer task, sink name[{}] ",  
            sink.getName());  
}
```
在初始化时，会对几个容器进行初始化，将状态置为`INIT`状态，对`aggregatedCommitter`进行初始化。这里会`source split enumerator`不同，`sink committer`是通过构造方法在外部初始化完成后传递进来的。

- 状态转换的方法
```java
protected void stateProcess() throws Exception {  
    switch (currState) {  
        case INIT:  
            currState = WAITING_RESTORE;  
            reportTaskStatus(WAITING_RESTORE);  
            break;  
        case WAITING_RESTORE:  
            if (restoreComplete.isDone()) {  
                currState = READY_START;  
                reportTaskStatus(READY_START);  
            } else {  
                Thread.sleep(100);  
            }  
            break;  
        case READY_START:  
            if (startCalled) {  
                currState = STARTING;  
            } else {  
                Thread.sleep(100);  
            }  
            break;  
        case STARTING:  
            if (receivedSinkWriter) {  
                currState = RUNNING;  
            } else {  
                Thread.sleep(100);  
            }  
            break;  
        case RUNNING:  
            if (prepareCloseStatus) {  
                currState = PREPARE_CLOSE;  
            } else {  
                Thread.sleep(100);  
            }  
            break;  
        case PREPARE_CLOSE:  
            if (closeCalled) {  
                currState = CLOSED;  
            } else {  
                Thread.sleep(100);  
            }  
            break;  
        case CLOSED:  
            this.close();  
            return;  
            // TODO support cancel by outside  
        case CANCELLING:  
            this.close();  
            currState = CANCELED;  
            return;  
        default:  
            throw new IllegalArgumentException("Unknown Enumerator State: " + currState);  
    }  
}

```
这里的状态转换比较简单，基本上都是直接进入下一个状态，但是这里有一点与eunmerator不太一样，在source enumerator中，需要等待全部的reader都启动完成，才会切换到running状态，这里稍有不同，这里只要有一个writer注册就会将receivedSinkWriter置为true，从而可以切换到running状态。
> source eunmerator需要等待全部的reader节点才能启动是需要避免分配时，任务分配不均匀，早启动的任务分配了全部或者较多的任务。
> 而sink committer的任务则不一样，它是二次提交时使用，所以只要有一个writer启动，就有可能会有二次提交的任务产生，所以不需要等待全部writer启动。

这里的`RUNNING`状态到`PREPARE_CLOSE`状态的切换，会判断`prepareCloseStatus`是否为true，而这个变量只有在接收到任务结束的信号时才会被置为true，所以这个任务会在任务全部完成时才会被关闭。

现在就看完了数据拆分任务`SourceSplitEnumerator`以及数据提交任务`SinkAggregatedCommitter`的相关内容
接下来我们看下几个数据读取，写入。即reader，writer的相关任务执行过程。

### SourceSeaTunnelTask

```Java
public class SourceSeaTunnelTask<T, SplitT extends SourceSplit> extends SeaTunnelTask {  
  
    private static final ILogger LOGGER = Logger.getLogger(SourceSeaTunnelTask.class);  
  
    private transient SeaTunnelSourceCollector<T> collector;  
  
    private transient Object checkpointLock;  
    @Getter private transient Serializer<SplitT> splitSerializer;  
    private final Map<String, Object> envOption;  
    private final PhysicalExecutionFlow<SourceAction, SourceConfig> sourceFlow;  
  
    public SourceSeaTunnelTask(  
            long jobID,  
            TaskLocation taskID,  
            int indexID,  
            PhysicalExecutionFlow<SourceAction, SourceConfig> executionFlow,  
            Map<String, Object> envOption) {  
        super(jobID, taskID, indexID, executionFlow);  
        this.sourceFlow = executionFlow;  
        this.envOption = envOption;  
    }
    ...
}
```
`SourceSeaTunnelTask`与`TransformSeaTunnelTask`都继承了`SeaTunnelTask`，这里的构造方法调用了父类的构造方法，这一部分我们统一在后面在看，先看下这个类中的其他方法。
- 一些其他方法
```Java    
@Override  
protected void collect() throws Exception {  
    ((SourceFlowLifeCycle<T, SplitT>) startFlowLifeCycle).collect();  
}  
  
@NonNull @Override  
public ProgressState call() throws Exception {  
    stateProcess();  
    return progress.toState();  
}  
  
public void receivedSourceSplit(List<SplitT> splits) {  
    ((SourceFlowLifeCycle<T, SplitT>) startFlowLifeCycle).receivedSplits(splits);  
}  
  
@Override  
public void triggerBarrier(Barrier barrier) throws Exception {  
    SourceFlowLifeCycle<T, SplitT> sourceFlow =  
            (SourceFlowLifeCycle<T, SplitT>) startFlowLifeCycle;  
    sourceFlow.triggerBarrier(barrier);  
}
```
这几个方法中，都是将调用转给了`startFlowLifeCycle`去进行调用。

在这个类中，还重新了父类的`createSourceFlowLifeCycle`方法，会去创建一个`SourceFlowLifeCycle`
```Java
@Override  
protected SourceFlowLifeCycle<?, ?> createSourceFlowLifeCycle(  
        SourceAction<?, ?, ?> sourceAction,  
        SourceConfig config,  
        CompletableFuture<Void> completableFuture,  
        MetricsContext metricsContext) {  
    return new SourceFlowLifeCycle<>(  
            sourceAction,  
            indexID,  
            config.getEnumeratorTask(),  
            this,  
            taskLocation,  
            completableFuture,  
            metricsContext);  
}
```

- 初始化方法
```java
@Override  
public void init() throws Exception {  
    super.init();  
    this.checkpointLock = new Object();  
    this.splitSerializer = sourceFlow.getAction().getSource().getSplitSerializer();  
  
    LOGGER.info("starting seatunnel source task, index " + indexID);  
    if (!(startFlowLifeCycle instanceof SourceFlowLifeCycle)) {  
        throw new TaskRuntimeException(  
                "SourceSeaTunnelTask only support SourceFlowLifeCycle, but get "  
                        + startFlowLifeCycle.getClass().getName());  
    } else {  
        SeaTunnelDataType sourceProducedType;  
        List<TablePath> tablePaths = new ArrayList<>();  
        try {  
            List<CatalogTable> producedCatalogTables =  
                    sourceFlow.getAction().getSource().getProducedCatalogTables();  
            sourceProducedType = CatalogTableUtil.convertToDataType(producedCatalogTables);  
            tablePaths =  
                    producedCatalogTables.stream()  
                            .map(CatalogTable::getTableId)  
                            .map(TableIdentifier::toTablePath)  
                            .collect(Collectors.toList());  
        } catch (UnsupportedOperationException e) {  
            // TODO remove it when all connector use `getProducedCatalogTables`  
            sourceProducedType = sourceFlow.getAction().getSource().getProducedType();  
        }  
        this.collector =  
                new SeaTunnelSourceCollector<>(  
                        checkpointLock,  
                        outputs,  
                        this.getMetricsContext(),  
                        FlowControlStrategy.fromMap(envOption),  
                        sourceProducedType,  
                        tablePaths);  
        ((SourceFlowLifeCycle<T, SplitT>) startFlowLifeCycle).setCollector(collector);  
    }  
}  
```
初始化方法也是先调用父类的初始化方法，一并放到后面再看。
其他的内容则是通过调用Source的API获取到所产生数据的表结构，数据类型，表路径信息等。
在这里还会初始化一个`SeaTunnelSourceCollector`，并赋值给`startFlowLifeCycle`.
我们看下这个类的相关代码
#### SeaTunnelSourceCollector

```Java
public class SeaTunnelSourceCollector<T> implements Collector<T> {  
  
    private final Object checkpointLock;  
  
    private final List<OneInputFlowLifeCycle<Record<?>>> outputs;  
  
    private final MetricsContext metricsContext;  
  
    private final AtomicBoolean schemaChangeBeforeCheckpointSignal = new AtomicBoolean(false);  
  
    private final AtomicBoolean schemaChangeAfterCheckpointSignal = new AtomicBoolean(false);  
  
    private final Counter sourceReceivedCount;  
  
    private final Map<String, Counter> sourceReceivedCountPerTable = new ConcurrentHashMap<>();  
  
    private final Meter sourceReceivedQPS;  
    private final Counter sourceReceivedBytes;  
  
    private final Meter sourceReceivedBytesPerSeconds;  
  
    private volatile boolean emptyThisPollNext;  
    private final DataTypeChangeEventHandler dataTypeChangeEventHandler =  
            new DataTypeChangeEventDispatcher();  
    private Map<String, SeaTunnelRowType> rowTypeMap = new HashMap<>();  
    private SeaTunnelDataType rowType;  
    private FlowControlGate flowControlGate;  
  
    public SeaTunnelSourceCollector(  
            Object checkpointLock,  
            List<OneInputFlowLifeCycle<Record<?>>> outputs,  
            MetricsContext metricsContext,  
            FlowControlStrategy flowControlStrategy,  
            SeaTunnelDataType rowType,  
            List<TablePath> tablePaths) {  
        this.checkpointLock = checkpointLock;  
        this.outputs = outputs;  
        this.rowType = rowType;  
        this.metricsContext = metricsContext;  
        if (rowType instanceof MultipleRowType) {  
            ((MultipleRowType) rowType)  
                    .iterator()  
                    .forEachRemaining(type -> this.rowTypeMap.put(type.getKey(), type.getValue()));  
        }  
        if (CollectionUtils.isNotEmpty(tablePaths)) {  
            tablePaths.forEach(  
                    tablePath ->  
                            sourceReceivedCountPerTable.put(  
                                    getFullName(tablePath),  
                                    metricsContext.counter(  
                                            SOURCE_RECEIVED_COUNT + "#" + getFullName(tablePath))));  
        }  
        sourceReceivedCount = metricsContext.counter(SOURCE_RECEIVED_COUNT);  
        sourceReceivedQPS = metricsContext.meter(SOURCE_RECEIVED_QPS);  
        sourceReceivedBytes = metricsContext.counter(SOURCE_RECEIVED_BYTES);  
        sourceReceivedBytesPerSeconds = metricsContext.meter(SOURCE_RECEIVED_BYTES_PER_SECONDS);  
        flowControlGate = FlowControlGate.create(flowControlStrategy);  
    }  
```
从变量可以看到这个类里面是实现了指标的统计，从`source`读到了多少数据，平均每秒读取的速度等都是在这个类中维护计算的。
还有记录了该任务下游的任务列表`List<OneInputFlowLifeCycle<Record<?>>> outputs`

在构造方法中，则是一些指标的初始化。

再看下这个类中的关键方法: `collect`
```Java  
    @Override  
    public void collect(T row) {  
        try {  
            if (row instanceof SeaTunnelRow) {  
                String tableId = ((SeaTunnelRow) row).getTableId();  
                int size;  
                if (rowType instanceof SeaTunnelRowType) {  
                    size = ((SeaTunnelRow) row).getBytesSize((SeaTunnelRowType) rowType);  
                } else if (rowType instanceof MultipleRowType) {  
                    size = ((SeaTunnelRow) row).getBytesSize(rowTypeMap.get(tableId));  
                } else {  
                    throw new SeaTunnelEngineException(  
                            "Unsupported row type: " + rowType.getClass().getName());  
                }  
                sourceReceivedBytes.inc(size);  
                sourceReceivedBytesPerSeconds.markEvent(size);  
                flowControlGate.audit((SeaTunnelRow) row);  
                if (StringUtils.isNotEmpty(tableId)) {  
                    String tableName = getFullName(TablePath.of(tableId));  
                    Counter sourceTableCounter = sourceReceivedCountPerTable.get(tableName);  
                    if (Objects.nonNull(sourceTableCounter)) {  
                        sourceTableCounter.inc();  
                    } else {  
                        Counter counter =  
                                metricsContext.counter(SOURCE_RECEIVED_COUNT + "#" + tableName);  
                        counter.inc();  
                        sourceReceivedCountPerTable.put(tableName, counter);  
                    }  
                }  
            }  
            sendRecordToNext(new Record<>(row));  
            emptyThisPollNext = false;  
            sourceReceivedCount.inc();  
            sourceReceivedQPS.markEvent();  
        } catch (IOException e) {  
            throw new RuntimeException(e);  
        }  
    }  
  
    @Override  
    public void collect(SchemaChangeEvent event) {  
        try {  
            if (rowType instanceof SeaTunnelRowType) {  
                rowType = dataTypeChangeEventHandler.reset((SeaTunnelRowType) rowType).apply(event);  
            } else if (rowType instanceof MultipleRowType) {  
                String tableId = event.tablePath().toString();  
                rowTypeMap.put(  
                        tableId,  
                        dataTypeChangeEventHandler.reset(rowTypeMap.get(tableId)).apply(event));  
            } else {  
                throw new SeaTunnelEngineException(  
                        "Unsupported row type: " + rowType.getClass().getName());  
            }  
            sendRecordToNext(new Record<>(event));  
        } catch (IOException e) {  
            throw new RuntimeException(e);  
        }  
    }  

}
```
在这个类中有两个`collect`方法，一个是接收数据，一个是接收表结构变更事件。
对于接收数据方法，当数据是读取到的数据`SeaTunnelRow`时，则会进行一些指标计算，更新。然后调用`sendRecordToNext`方法，将数据封装为Record发送给下游。

对于表结构变更方法，则是先将内部存储的表结构信息进行更新，然后再同样是调用`sendRecordToNext`方法发送给下游.

```Java
    public void sendRecordToNext(Record<?> record) throws IOException {  
        synchronized (checkpointLock) {  
            for (OneInputFlowLifeCycle<Record<?>> output : outputs) {  
                output.received(record);  
            }  
        }  
    }
```
在这个方法中，则是将数据发送给全部的下游任务。这里如何获取的下游任务是在父类中获取的，这一部分后面在`SeaTunnelTask`中再继续介绍。

可以看出这个`SeaTunnelSourceCollector`会被传递给`reader`实例，reader读取到数据转换完成之后，再由这个类进行指标统计后发送给所有的下游任务。

### TransformSeaTunnelTask

```Java
public class TransformSeaTunnelTask extends SeaTunnelTask {  
  
    private static final ILogger LOGGER = Logger.getLogger(TransformSeaTunnelTask.class);  
  
    public TransformSeaTunnelTask(  
            long jobID, TaskLocation taskID, int indexID, Flow executionFlow) {  
        super(jobID, taskID, indexID, executionFlow);  
    }
  
    private Collector<Record<?>> collector;  
  
    @Override  
    public void init() throws Exception {  
        super.init();  
        LOGGER.info("starting seatunnel transform task, index " + indexID);  
        collector = new SeaTunnelTransformCollector(outputs);  
        if (!(startFlowLifeCycle instanceof OneOutputFlowLifeCycle)) {  
            throw new TaskRuntimeException(  
                    "TransformSeaTunnelTask only support OneOutputFlowLifeCycle, but get "  
                            + startFlowLifeCycle.getClass().getName());  
        }  
    }  
  
    @Override  
    protected SourceFlowLifeCycle<?, ?> createSourceFlowLifeCycle(  
            SourceAction<?, ?, ?> sourceAction,  
            SourceConfig config,  
            CompletableFuture<Void> completableFuture,  
            MetricsContext metricsContext) {  
        throw new UnsupportedOperationException(  
                "TransformSeaTunnelTask can't create SourceFlowLifeCycle");  
    }  
  
    @Override  
    protected void collect() throws Exception {  
        ((OneOutputFlowLifeCycle<Record<?>>) startFlowLifeCycle).collect(collector);  
    }  
  
    @NonNull @Override  
    public ProgressState call() throws Exception {  
        stateProcess();  
        return progress.toState();  
    }
    
}
```
这个类相比较于`SourceSeaTunnelTask`则比较简单，在初始化时会创建一个`SeaTunnelTransformCollector`，当调用`collect`方法时也是转交给`startFlowLifeCycle`执行

#### SeaTunnelTransformCollector
```Java
public class SeaTunnelTransformCollector implements Collector<Record<?>> {  
  
    private final List<OneInputFlowLifeCycle<Record<?>>> outputs;  
  
    public SeaTunnelTransformCollector(List<OneInputFlowLifeCycle<Record<?>>> outputs) {  
        this.outputs = outputs;  
    }  
  
    @Override  
    public void collect(Record<?> record) {  
        for (OneInputFlowLifeCycle<Record<?>> output : outputs) {  
            try {  
                output.received(record);  
            } catch (IOException e) {  
                throw new TaskRuntimeException(e);  
            }  
        }  
    }  
  
    @Override  
    public void close() {}  
}
```
`SeaTunnelTransformCollector`的内容也很简单，收到数据后将数据转发给所有的下游任务。

好了，接下来我们看下`SeaTunnelTask`的相关内容
### SeaTunnelTask
```Java
public abstract class SeaTunnelTask extends AbstractTask {  
    private static final long serialVersionUID = 2604309561613784425L;  
  
    protected volatile SeaTunnelTaskState currState;  
    private final Flow executionFlow;  
  
    protected FlowLifeCycle startFlowLifeCycle;  
  
    protected List<FlowLifeCycle> allCycles;  
  
    protected List<OneInputFlowLifeCycle<Record<?>>> outputs;  
  
    protected List<CompletableFuture<Void>> flowFutures;  
  
    protected final Map<Long, List<ActionSubtaskState>> checkpointStates =  
            new ConcurrentHashMap<>();  
  
    private final Map<Long, Integer> cycleAcks = new ConcurrentHashMap<>();  
  
    protected int indexID;  
  
    private TaskGroup taskBelongGroup;  
  
    private SeaTunnelMetricsContext metricsContext;  
  
    public SeaTunnelTask(long jobID, TaskLocation taskID, int indexID, Flow executionFlow) {  
        super(jobID, taskID);  
        this.indexID = indexID;  
        this.executionFlow = executionFlow;  
        this.currState = SeaTunnelTaskState.CREATED;  
    }
	...
}
```

在`SeaTunnelTask`中，`executionFlow`就表示一个物理执行节点，是在`PhysicalPlanGenerator`中产生传递过来的。这里需要与执行计划图一起对比看下。
![image.png](https://raw.githubusercontent.com/liunaijie/images/master/202411081515868.png)

在构造方法中没有做太多的事情，仅仅是将变量赋值，将状态初始化为`CREATED`状态。
看下其他的方法

- init
```Java
@Override  
public void init() throws Exception {  
    super.init();  
    metricsContext = getExecutionContext().getOrCreateMetricsContext(taskLocation);  
    this.currState = SeaTunnelTaskState.INIT;  
    flowFutures = new ArrayList<>();  
    allCycles = new ArrayList<>();  
    startFlowLifeCycle = convertFlowToActionLifeCycle(executionFlow);  
    for (FlowLifeCycle cycle : allCycles) {  
        cycle.init();  
    }  
    CompletableFuture.allOf(flowFutures.toArray(new CompletableFuture[0]))  
            .whenComplete((s, e) -> closeCalled = true);  
}
```
初始化方法内，调用了`convertFlowToActionLifeCycle`方法来获取当前任务的开始任务的lifecycle对象。
```Java
private FlowLifeCycle convertFlowToActionLifeCycle(@NonNull Flow flow) throws Exception {  
  
    FlowLifeCycle lifeCycle;  
    // 局部变量存储当前节点的所有下游节点的lifecycle对象
    List<OneInputFlowLifeCycle<Record<?>>> flowLifeCycles = new ArrayList<>();  
    if (!flow.getNext().isEmpty()) {  
        for (Flow f : flow.getNext()) {  
            flowLifeCycles.add(  
            // 递归调用 将所有节点都进行转换
                    (OneInputFlowLifeCycle<Record<?>>) convertFlowToActionLifeCycle(f));  
        }  
    }  
    CompletableFuture<Void> completableFuture = new CompletableFuture<>();
    // 加到全部变量中  
    flowFutures.add(completableFuture);  
    if (flow instanceof PhysicalExecutionFlow) {  
        PhysicalExecutionFlow f = (PhysicalExecutionFlow) flow; 
        // 根据不同的action类型创建不同的 FlowLifecycle 
        if (f.getAction() instanceof SourceAction) {  
            lifeCycle =  
                    createSourceFlowLifeCycle(  
                            (SourceAction<?, ?, ?>) f.getAction(),  
                            (SourceConfig) f.getConfig(),  
                            completableFuture,  
                            this.getMetricsContext());  
            // 当前节点的下游输出已经存储在 flowLifeCycles中了，赋值
            outputs = flowLifeCycles;  
        } else if (f.getAction() instanceof SinkAction) {  
            lifeCycle =  
                    new SinkFlowLifeCycle<>(  
                            (SinkAction) f.getAction(),  
                            taskLocation,  
                            indexID,  
                            this,  
                            ((SinkConfig) f.getConfig()).getCommitterTask(),  
                            ((SinkConfig) f.getConfig()).isContainCommitter(),  
                            completableFuture,  
                            this.getMetricsContext());  
			// sink已经是最后的节点，所以不需要设置outputs                            
        } else if (f.getAction() instanceof TransformChainAction) {  
	        // 对于transform，outputs通过在构造`SeaTunnelTransformCollector`时通过参数传递进入
            lifeCycle =  
                    new TransformFlowLifeCycle<SeaTunnelRow>(  
                            (TransformChainAction) f.getAction(),  
                            this,  
                            new SeaTunnelTransformCollector(flowLifeCycles),  
                            completableFuture);  
        } else if (f.getAction() instanceof ShuffleAction) {  
            ShuffleAction shuffleAction = (ShuffleAction) f.getAction();  
            HazelcastInstance hazelcastInstance = getExecutionContext().getInstance();  
            if (flow.getNext().isEmpty()) {  
                lifeCycle =  
                        new ShuffleSinkFlowLifeCycle(  
                                this,  
                                indexID,  
                                shuffleAction,  
                                hazelcastInstance,  
                                completableFuture);  
            } else {  
                lifeCycle =  
                        new ShuffleSourceFlowLifeCycle(  
                                this,  
                                indexID,  
                                shuffleAction,  
                                hazelcastInstance,  
                                completableFuture);  
            }  
            outputs = flowLifeCycles;  
        } else {  
            throw new UnknownActionException(f.getAction());  
        }  
    } else if (flow instanceof IntermediateExecutionFlow) {  
        IntermediateQueueConfig config =  
                ((IntermediateExecutionFlow<IntermediateQueueConfig>) flow).getConfig();  
        lifeCycle =  
                new IntermediateQueueFlowLifeCycle(  
                        this,  
                        completableFuture,  
                        ((AbstractTaskGroupWithIntermediateQueue) taskBelongGroup)  
                                .getQueueCache(config.getQueueID()));  
        outputs = flowLifeCycles;  
    } else {  
        throw new UnknownFlowException(flow);  
    }  
    allCycles.add(lifeCycle);  
    return lifeCycle;  
}
```
在这个方法中，对一个物理执行节点进行遍历，对每一个下游任务都进行转换，转换为对于的`FlowLifecycle`，然后将其添加到全部变量`allCycles`中。
在转换`FlowLifecycle` 时，会根据不同的类型进行相应的转换。并且在每次转换时，都可以获取到当前节点的下游所有节点的LifeCycle，可以将其设置到output中，从而在`Collector`中发送的时候可以知道下游的信息。
这里的`PhysicalExecutionFlow`与`IntermediateExecutionFlow`区别我们先不关心，我们先认为都只有`PhysicalExecutionFlow`。

回到`init`方法，当全部转换完成后，会对所有的`FlowLifecycle`调用初始化方法进行初始化
```Java
@Override  
public void init() throws Exception {  
    super.init();  
    metricsContext = getExecutionContext().getOrCreateMetricsContext(taskLocation);  
    this.currState = SeaTunnelTaskState.INIT;  
    flowFutures = new ArrayList<>();  
    allCycles = new ArrayList<>();  
    startFlowLifeCycle = convertFlowToActionLifeCycle(executionFlow);  
    for (FlowLifeCycle cycle : allCycles) {  
        cycle.init();  
    }  
    CompletableFuture.allOf(flowFutures.toArray(new CompletableFuture[0]))  
            .whenComplete((s, e) -> closeCalled = true);  
}
```

我们对其中提到的几个`FlowLifyCycle`看下源码
#### SourceFlowLifeCycle

```Java
public class SourceFlowLifeCycle<T, SplitT extends SourceSplit> extends ActionFlowLifeCycle  
        implements InternalCheckpointListener {  
  
    private final SourceAction<T, SplitT, ?> sourceAction;  
    private final TaskLocation enumeratorTaskLocation;  
  
    private Address enumeratorTaskAddress;  
  
    private SourceReader<T, SplitT> reader;  
  
    private transient Serializer<SplitT> splitSerializer;  
  
    private final int indexID;  
  
    private final TaskLocation currentTaskLocation;  
  
    private SeaTunnelSourceCollector<T> collector;  
  
    private final MetricsContext metricsContext;  
    private final EventListener eventListener;  
  
    private final AtomicReference<SchemaChangePhase> schemaChangePhase = new AtomicReference<>();  
  
    public SourceFlowLifeCycle(  
            SourceAction<T, SplitT, ?> sourceAction,  
            int indexID,  
            TaskLocation enumeratorTaskLocation,  
            SeaTunnelTask runningTask,  
            TaskLocation currentTaskLocation,  
            CompletableFuture<Void> completableFuture,  
            MetricsContext metricsContext) {  
        super(sourceAction, runningTask, completableFuture);  
        this.sourceAction = sourceAction;  
        this.indexID = indexID;  
        this.enumeratorTaskLocation = enumeratorTaskLocation;  
        this.currentTaskLocation = currentTaskLocation;  
        this.metricsContext = metricsContext;  
        this.eventListener =  
                new JobEventListener(currentTaskLocation, runningTask.getExecutionContext());  
    }
    
}
```
在这个类的几个成员变量有`source enumerator`的地址，用来`reader`与`enumerator`进行通信交互，还有`SourceReader`的实例，在这个类里去创建`reader`并进行实际的读取。

再来看下其他的方法：
- 初始化
```Java
@Override  
public void init() throws Exception {  
    this.splitSerializer = sourceAction.getSource().getSplitSerializer();  
    this.reader =  
            sourceAction  
                    .getSource()  
                    .createReader(  
                            new SourceReaderContext(  
                                    indexID,  
                                    sourceAction.getSource().getBoundedness(),  
                                    this,  
                                    metricsContext,  
                                    eventListener));  
    this.enumeratorTaskAddress = getEnumeratorTaskAddress();  
}  
```
初始化时会去创建`reader`实例，创建时会将自身作为参数设置到`context`中。还要去获取切分任务的地址，后续的通信需要这个地址。
- collect方法
```Java
public void collect() throws Exception {  
    if (!prepareClose) {  
        if (schemaChanging()) {  
            log.debug("schema is changing, stop reader collect records");  
  
            Thread.sleep(200);  
            return;  
        }  
  
        reader.pollNext(collector);  
        if (collector.isEmptyThisPollNext()) {  
            Thread.sleep(100);  
        } else {  
            collector.resetEmptyThisPollNext();            
             Thread.sleep(0L);  
        }  
  
        if (collector.captureSchemaChangeBeforeCheckpointSignal()) {  
            if (schemaChangePhase.get() != null) {  
                throw new IllegalStateException(  
                        "previous schema changes in progress, schemaChangePhase: "  
                                + schemaChangePhase.get());  
            }  
            schemaChangePhase.set(SchemaChangePhase.createBeforePhase());  
            runningTask.triggerSchemaChangeBeforeCheckpoint().get();  
            log.info("triggered schema-change-before checkpoint, stopping collect data");  
        } else if (collector.captureSchemaChangeAfterCheckpointSignal()) {  
            if (schemaChangePhase.get() != null) {  
                throw new IllegalStateException(  
                        "previous schema changes in progress, schemaChangePhase: "  
                                + schemaChangePhase.get());  
            }  
            schemaChangePhase.set(SchemaChangePhase.createAfterPhase());  
            runningTask.triggerSchemaChangeAfterCheckpoint().get();  
            log.info("triggered schema-change-after checkpoint, stopping collect data");  
        }  
    } else {  
        Thread.sleep(100);  
    }  
}
```
当调用collect方法时，会调用reader的`pollNext`方法来进行真正的数据读取。
当reader的pollNext方法被调用时，reader会真正的从数据源进行读取数据，转换成内部的`SeaTunnelRow`数据类型，放到`collector`中。
而这个`collector`就是我们上面刚刚看的`SeaTunnelSourceCollector`， 当它接收到一条数据后，又会将数据发送给所有的下游任务。

- 一些其他方法
```Java
@Override  
public void open() throws Exception {  
    reader.open();  
    // 在open方法里，会将自己向enumerator进行注册
    register();  
}

private void register() {  
    try {  
        runningTask  
                .getExecutionContext()  
                .sendToMember(  
                        new SourceRegisterOperation(  
                                currentTaskLocation, enumeratorTaskLocation),  
                        enumeratorTaskAddress)  
                .get();  
    } catch (InterruptedException | ExecutionException e) {  
        log.warn("source register failed.", e);  
        throw new RuntimeException(e);  
    }  
}

  
@Override  
public void close() throws IOException {  
    reader.close();  
    super.close();  
}    

// 当reader读取完全部数据后，会调用此方法
// 此方法会向enumerator发送消息
public void signalNoMoreElement() {  
    // ready close this reader  
    try {  
        this.prepareClose = true;  
        runningTask  
                .getExecutionContext()  
                .sendToMember(  
                        new SourceNoMoreElementOperation(  
                                currentTaskLocation, enumeratorTaskLocation),  
                        enumeratorTaskAddress)  
                .get();  
    } catch (Exception e) {  
        log.warn("source close failed {}", e);  
        throw new RuntimeException(e);  
    }  
}  
  
  
public void requestSplit() {  
    try {  
        runningTask  
                .getExecutionContext()  
                .sendToMember(  
                        new RequestSplitOperation(currentTaskLocation, enumeratorTaskLocation),  
                        enumeratorTaskAddress)  
                .get();  
    } catch (InterruptedException | ExecutionException e) {  
        log.warn("source request split failed.", e);  
        throw new RuntimeException(e);  
    }  
}  
  
public void sendSourceEventToEnumerator(SourceEvent sourceEvent) {  
    try {  
        runningTask  
                .getExecutionContext()  
                .sendToMember(  
                        new SourceReaderEventOperation(  
                                enumeratorTaskLocation, currentTaskLocation, sourceEvent),  
                        enumeratorTaskAddress)  
                .get();  
    } catch (InterruptedException | ExecutionException e) {  
        log.warn("source request split failed.", e);  
        throw new RuntimeException(e);  
    }  
}  
  
public void receivedSplits(List<SplitT> splits) {  
    if (splits.isEmpty()) {  
        reader.handleNoMoreSplits();  
    } else {  
        reader.addSplits(splits);  
    }  
}
```


#### TransformFlowLifeCycle
```Java
public class TransformFlowLifeCycle<T> extends ActionFlowLifeCycle  
        implements OneInputFlowLifeCycle<Record<?>> {  
  
    private final TransformChainAction<T> action;  
  
    private final List<SeaTunnelTransform<T>> transform;  
  
    private final Collector<Record<?>> collector;  
  
    public TransformFlowLifeCycle(  
            TransformChainAction<T> action,  
            SeaTunnelTask runningTask,  
            Collector<Record<?>> collector,  
            CompletableFuture<Void> completableFuture) {  
        super(action, runningTask, completableFuture);  
        this.action = action;  
        this.transform = action.getTransforms();  
        this.collector = collector;  
    }  
  
    @Override  
    public void open() throws Exception {  
        super.open();  
        for (SeaTunnelTransform<T> t : transform) {  
            try {  
                t.open();  
            } catch (Exception e) {  
                log.error(  
                        "Open transform: {} failed, cause: {}",  
                        t.getPluginName(),  
                        e.getMessage(),  
                        e);  
            }  
        }  
    }  
  
    @Override  
    public void received(Record<?> record) {  
        if (record.getData() instanceof Barrier) {  
            CheckpointBarrier barrier = (CheckpointBarrier) record.getData();  
            if (barrier.prepareClose(this.runningTask.getTaskLocation())) {  
                prepareClose = true;  
            }  
            if (barrier.snapshot()) {  
                runningTask.addState(barrier, ActionStateKey.of(action), Collections.emptyList());  
            }  
            // ack after #addState  
            runningTask.ack(barrier);  
            collector.collect(record);  
        } else {  
            if (prepareClose) {  
                return;  
            }  
            T inputData = (T) record.getData();  
            T outputData = inputData;  
            for (SeaTunnelTransform<T> t : transform) {  
                outputData = t.map(inputData);  
                log.debug("Transform[{}] input row {} and output row {}", t, inputData, outputData);  
                if (outputData == null) {  
                    log.trace("Transform[{}] filtered data row {}", t, inputData);  
                    break;  
                }  
  
                inputData = outputData;  
            }  
            if (outputData != null) {  
                // todo log metrics  
                collector.collect(new Record<>(outputData));  
            }  
        }  
    }  
    ...  
}
```
在`TransformFlowLifeCycle`中，存储了所需要用到的`SeaTunnelTransform`，当被调用`open`方法时，会调用具体使用到的`transform`实现的`open`方法，由该实现进行相关的一些初始化操作。
当接收到数据后，会调用`Transform`接口的`map`方法，对数据进行处理，处理完成后，会判断是否会被过滤掉，如果没有被过滤（数据不为null）则会发送给下游。

#### SinkFlowLifeCycle
```Java
public class SinkFlowLifeCycle<T, CommitInfoT extends Serializable, AggregatedCommitInfoT, StateT>  
        extends ActionFlowLifeCycle  
        implements OneInputFlowLifeCycle<Record<?>>, InternalCheckpointListener {  
  
    private final SinkAction<T, StateT, CommitInfoT, AggregatedCommitInfoT> sinkAction;  
    private SinkWriter<T, CommitInfoT, StateT> writer;  
  
    private transient Optional<Serializer<CommitInfoT>> commitInfoSerializer;  
    private transient Optional<Serializer<StateT>> writerStateSerializer;  
  
    private final int indexID;  
  
    private final TaskLocation taskLocation;  
  
    private Address committerTaskAddress;  
  
    private final TaskLocation committerTaskLocation;  
  
    private Optional<SinkCommitter<CommitInfoT>> committer;  
  
    private Optional<CommitInfoT> lastCommitInfo;  
  
    private MetricsContext metricsContext;  
  
    private Counter sinkWriteCount;  
  
    private Map<String, Counter> sinkWriteCountPerTable = new ConcurrentHashMap<>();  
  
    private Meter sinkWriteQPS;  
  
    private Counter sinkWriteBytes;  
  
    private Meter sinkWriteBytesPerSeconds;  
  
    private final boolean containAggCommitter;  
  
    private MultiTableResourceManager resourceManager;  
  
    private EventListener eventListener;  
  
    public SinkFlowLifeCycle(  
            SinkAction<T, StateT, CommitInfoT, AggregatedCommitInfoT> sinkAction,  
            TaskLocation taskLocation,  
            int indexID,  
            SeaTunnelTask runningTask,  
            TaskLocation committerTaskLocation,  
            boolean containAggCommitter,  
            CompletableFuture<Void> completableFuture,  
            MetricsContext metricsContext) {  
        super(sinkAction, runningTask, completableFuture);  
        this.sinkAction = sinkAction;  
        this.indexID = indexID;  
        this.taskLocation = taskLocation;  
        this.committerTaskLocation = committerTaskLocation;  
        this.containAggCommitter = containAggCommitter;  
        this.metricsContext = metricsContext;  
        this.eventListener = new JobEventListener(taskLocation, runningTask.getExecutionContext());  
        sinkWriteCount = metricsContext.counter(SINK_WRITE_COUNT);  
        sinkWriteQPS = metricsContext.meter(SINK_WRITE_QPS);  
        sinkWriteBytes = metricsContext.counter(SINK_WRITE_BYTES);  
        sinkWriteBytesPerSeconds = metricsContext.meter(SINK_WRITE_BYTES_PER_SECONDS);  
        if (sinkAction.getSink() instanceof MultiTableSink) {  
            List<TablePath> sinkTables = ((MultiTableSink) sinkAction.getSink()).getSinkTables();  
            sinkTables.forEach(  
                    tablePath ->  
                            sinkWriteCountPerTable.put(  
                                    getFullName(tablePath),  
                                    metricsContext.counter(  
                                            SINK_WRITE_COUNT + "#" + getFullName(tablePath))));  
        }  
    }
	...
}
```
与`SourceFlowLifeCycle`类似，这个`SinkFlowLifeCycle`中维护了`SinkWriter`的实例，当接收到一条数据后，会交给`writer`的具体实现来进行真正的数据写入。
同时在这个类中维护了一些指标数据，会进行写入数据，每个表写入数据等指标的统计。

接下来看下其他的一些方法
```Java
@Override  
public void init() throws Exception {  
    this.commitInfoSerializer = sinkAction.getSink().getCommitInfoSerializer();  
    this.writerStateSerializer = sinkAction.getSink().getWriterStateSerializer();  
    this.committer = sinkAction.getSink().createCommitter();  
    this.lastCommitInfo = Optional.empty();  
}  
  
@Override  
public void open() throws Exception {  
    super.open();  
    if (containAggCommitter) {  
        committerTaskAddress = getCommitterTaskAddress();  
    }  
    registerCommitter();  
}

private void registerCommitter() {  
    if (containAggCommitter) {  
        runningTask  
                .getExecutionContext()  
                .sendToMember(  
                        new SinkRegisterOperation(taskLocation, committerTaskLocation),  
                        committerTaskAddress)  
                .join();  
    }  
}
```
在初始化方法中，会创建`committer`，通过API可以知道，`committer`并不是一定需要的，所以这里的值也有可能为空，在open方法中当存在committer时，会获取地址然后进行注册。

这里有一点与`SourceFlowLifeCycle`不同的点是, `SourceReader`的创建是在`init`方法中去创建的
```Java
@Override  
public void init() throws Exception {  
    this.splitSerializer = sourceAction.getSource().getSplitSerializer();  
    this.reader =  
            sourceAction  
                    .getSource()  
                    .createReader(  
                            new SourceReaderContext(  
                                    indexID,  
                                    sourceAction.getSource().getBoundedness(),  
                                    this,  
                                    metricsContext,  
                                    eventListener));  
    this.enumeratorTaskAddress = getEnumeratorTaskAddress();  
}
```
但是在这里`SinkWriter`的创建并没有在这里去创建。查看代码之后发现是在`restoreState`这个方法中进行创建的
```Java
public void restoreState(List<ActionSubtaskState> actionStateList) throws Exception {  
    List<StateT> states = new ArrayList<>();  
    if (writerStateSerializer.isPresent()) {  
        states =  
                actionStateList.stream()  
                        .map(ActionSubtaskState::getState)  
                        .flatMap(Collection::stream)  
                        .filter(Objects::nonNull)  
                        .map(  
                                bytes ->  
                                        sneaky(  
                                                () ->  
                                                        writerStateSerializer  
                                                                .get()  
                                                                .deserialize(bytes)))  
                        .collect(Collectors.toList());  
    }  
    if (states.isEmpty()) {  
        this.writer =  
                sinkAction  
                        .getSink()  
                        .createWriter(  
                                new SinkWriterContext(indexID, metricsContext, eventListener));  
    } else {  
        this.writer =  
                sinkAction  
                        .getSink()  
                        .restoreWriter(  
                                new SinkWriterContext(indexID, metricsContext, eventListener),  
                                states);  
    }  
    if (this.writer instanceof SupportResourceShare) {  
        resourceManager =  
                ((SupportResourceShare) this.writer).initMultiTableResourceManager(1, 1);  
        ((SupportResourceShare) this.writer).setMultiTableResourceManager(resourceManager, 0);  
    }  
}
```
至于这个方法什么时候会被调用，会在下面任务状态转换的时候在介绍。

```Java
public void received(Record<?> record) {  
    try {  
        if (record.getData() instanceof Barrier) {  
            long startTime = System.currentTimeMillis();  
  
            Barrier barrier = (Barrier) record.getData();  
            if (barrier.prepareClose(this.taskLocation)) {  
                prepareClose = true;  
            }  
            if (barrier.snapshot()) {  
                try {  
                    lastCommitInfo = writer.prepareCommit();  
                } catch (Exception e) {  
                    writer.abortPrepare();  
                    throw e;  
                }  
                List<StateT> states = writer.snapshotState(barrier.getId());  
                if (!writerStateSerializer.isPresent()) {  
                    runningTask.addState(  
                            barrier, ActionStateKey.of(sinkAction), Collections.emptyList());  
                } else {  
                    runningTask.addState(  
                            barrier,  
                            ActionStateKey.of(sinkAction),  
                            serializeStates(writerStateSerializer.get(), states));  
                }  
                if (containAggCommitter) {  
                    CommitInfoT commitInfoT = null;  
                    if (lastCommitInfo.isPresent()) {  
                        commitInfoT = lastCommitInfo.get();  
                    }  
                    runningTask  
                            .getExecutionContext()  
                            .sendToMember(  
                                    new SinkPrepareCommitOperation<CommitInfoT>(  
                                            barrier,  
                                            committerTaskLocation,  
                                            commitInfoSerializer.isPresent()  
                                                    ? commitInfoSerializer  
                                                            .get()  
                                                            .serialize(commitInfoT)  
                                                    : null),  
                                    committerTaskAddress)  
                            .join();  
                }  
            } else {  
                if (containAggCommitter) {  
                    runningTask  
                            .getExecutionContext()  
                            .sendToMember(  
                                    new BarrierFlowOperation(barrier, committerTaskLocation),  
                                    committerTaskAddress)  
                            .join();  
                }  
            }  
            runningTask.ack(barrier);  
  
            log.debug(  
                    "trigger barrier [{}] finished, cost {}ms. taskLocation [{}]",  
                    barrier.getId(),  
                    System.currentTimeMillis() - startTime,  
                    taskLocation);  
        } else if (record.getData() instanceof SchemaChangeEvent) {  
            if (prepareClose) {  
                return;  
            }  
            SchemaChangeEvent event = (SchemaChangeEvent) record.getData();  
            writer.applySchemaChange(event);  
        } else {  
            if (prepareClose) {  
                return;  
            }  
            writer.write((T) record.getData());  
            sinkWriteCount.inc();  
            sinkWriteQPS.markEvent();  
            if (record.getData() instanceof SeaTunnelRow) {  
                long size = ((SeaTunnelRow) record.getData()).getBytesSize();  
                sinkWriteBytes.inc(size);  
                sinkWriteBytesPerSeconds.markEvent(size);  
                String tableId = ((SeaTunnelRow) record.getData()).getTableId();  
                if (StringUtils.isNotBlank(tableId)) {  
                    String tableName = getFullName(TablePath.of(tableId));  
                    Counter sinkTableCounter = sinkWriteCountPerTable.get(tableName);  
                    if (Objects.nonNull(sinkTableCounter)) {  
                        sinkTableCounter.inc();  
                    } else {  
                        Counter counter =  
                                metricsContext.counter(SINK_WRITE_COUNT + "#" + tableName);  
                        counter.inc();  
                        sinkWriteCountPerTable.put(tableName, counter);  
                    }  
                }  
            }  
        }  
    } catch (Exception e) {  
        throw new RuntimeException(e);  
    }  
}
```
在接收数据的方法中，会对数据进行一些判断，会进行这几种类型的判断
- 是否是snapshot
当触发snapshot时，会产生预提交信息，这个信息后面会在提交时使用
以及调用writer的snapshot方法，将现在的状态进行存储，从而在后面恢复时可以根据当前状态进行恢复。
然后再判断是否有committer的存在，如果有，则向其发送消息，让其根据刚刚产生的commit信息进行预提交。
- 是否是表结构变更的事件
当接收到表结构变更事件，也直接调用writer的相关方法，交由writer去实现
- 其他情况下
调用`writer.writer()`方法，进行真正的数据写入。并进行一些数据统计。

这个地方只是将数据交给了具体的`writer`实现，至于`writer`有没有实时的将数据写入到具体的存储里面，也是根据连接器的实现来决定，有些连接器可能为了性能考虑会将数据进行攒批或者其他策略来进行发送写入，那么这里的调用与真正的数据写入还是会有一定的延迟的。

```Java
@Override  
public void notifyCheckpointComplete(long checkpointId) throws Exception {  
    if (committer.isPresent() && lastCommitInfo.isPresent()) {  
        committer.get().commit(Collections.singletonList(lastCommitInfo.get()));  
    }  
}  
  
@Override  
public void notifyCheckpointAborted(long checkpointId) throws Exception {  
    if (committer.isPresent() && lastCommitInfo.isPresent()) {  
        committer.get().abort(Collections.singletonList(lastCommitInfo.get()));  
    }  
}
```
这两个方法是checkpoint的成功与失败的方法，当成功时，如果`committer`存在，则进行真正的提交操作。否则则回滚这次提交。

#### IntermediateQueueFlowLifeCycle
![image.png](https://raw.githubusercontent.com/liunaijie/images/master/202411081514999.png)
在生成任务时, 会在任务之间添加`IntermediateExecutionFlow`来进行切分.
一个`IntermediateExecutionFlow`的`Flow`, 在生成`lifeCycle`阶段, 会生成一个`IntermediateQueueFlowLifeCycle`
```Java
else if (flow instanceof IntermediateExecutionFlow) {  
        IntermediateQueueConfig config =  
                ((IntermediateExecutionFlow<IntermediateQueueConfig>) flow).getConfig();  
        lifeCycle =  
                new IntermediateQueueFlowLifeCycle(  
                        this,  
                        completableFuture,  
                        ((AbstractTaskGroupWithIntermediateQueue) taskBelongGroup)  
                                .getQueueCache(config.getQueueID()));  
        outputs = flowLifeCycles;  
    }
```

来看一下`IntermediateQueueFlowLifeCycle`的代码
```Java
public class IntermediateQueueFlowLifeCycle<T extends AbstractIntermediateQueue<?>>  
        extends AbstractFlowLifeCycle  
        implements OneInputFlowLifeCycle<Record<?>>, OneOutputFlowLifeCycle<Record<?>> {  
  
    private final AbstractIntermediateQueue<?> queue;  
  
    public IntermediateQueueFlowLifeCycle(  
            SeaTunnelTask runningTask,  
            CompletableFuture<Void> completableFuture,  
            AbstractIntermediateQueue<?> queue) {  
        super(runningTask, completableFuture);  
        this.queue = queue;  
        queue.setIntermediateQueueFlowLifeCycle(this);  
        queue.setRunningTask(runningTask);  
    }  
  
    @Override  
    public void received(Record<?> record) {  
        queue.received(record);  
    }  
  
    @Override  
    public void collect(Collector<Record<?>> collector) throws Exception {  
        queue.collect(collector);  
    }  
  
    @Override  
    public void close() throws IOException {  
        queue.close();  
        super.close();  
    }  
}
```
在这个里面有一个成员变量`AbstractIntermediateQueue`, 在初始化时会传递过来, 当被调用`received`或`collect`时, 都会调用`AbstractIntermediateQueue`的相应方法.

#### 状态切换
```Java
protected void stateProcess() throws Exception {  
    switch (currState) {
	    // 当调用init方法时，都会将任务的状态置为INIT  
        case INIT:  
	        // 切换为WAITING_RESTORE
            currState = WAITING_RESTORE;  
            // 报告任务的状态为WAITING_RESTORE
            reportTaskStatus(WAITING_RESTORE);  
            break;  
        case WAITING_RESTORE:  
	        // 当init方法执行结束后，会对所有的下游任务调用open方法
            if (restoreComplete.isDone()) {  
                for (FlowLifeCycle cycle : allCycles) {  
                    cycle.open();  
                }  
                // 切换为READY_START,并且上报更新状态
                currState = READY_START;  
                reportTaskStatus(READY_START);  
            } else {  
                Thread.sleep(100);  
            }  
            break;  
        case READY_START:  
            if (startCalled) {  
                currState = STARTING;  
            } else {  
                Thread.sleep(100);  
            }  
            break;  
        case STARTING:  
            currState = RUNNING;  
            break;  
        case RUNNING:  
	        // 在RUNNING状态会调用collect方法
	        // 这个方法在SourceTask中会调用reader.pollNext方法，从而开始真正的数据读取，读取完成后会发送到SeaTunnelSourceCollector中，在SeaTunnelSourceCollector中接收到一条数据后，又会将数据发送给所有的下游任务
	        // 在TransformTask中，会调用transform的map方法，进行数据转换，转换完成后，将数据发送给SeaTunnelTransformCollector，同样在SeaTunnelTransformCollector中也会将数据发送给所有的下游
            collect();  
            if (prepareCloseStatus) {  
                currState = PREPARE_CLOSE;  
            }  
            break;  
        case PREPARE_CLOSE:  
            if (closeCalled) {  
                currState = CLOSED;  
            } else {  
                Thread.sleep(100);  
            }  
            break;  
        case CLOSED:  
            this.close();  
            progress.done();  
            return;  
            // TODO support cancel by outside  
        case CANCELLING:  
            this.close();  
            currState = CANCELED;  
            progress.done();  
            return;  
        default:  
            throw new IllegalArgumentException("Unknown Enumerator State: " + currState);  
    }  
}
```

### Collector
在`API`的章节, 有描述`Collector`的功能, 是在单进程内多个线程间的数据管道.
![image.png](https://raw.githubusercontent.com/liunaijie/images/master/202411081514999.png)

在任务拆分阶段, 会将`sink`单独拆离出来, 通过`IntermediateExecutionFlow`进行关联. 
而`source`和`transform`则是放到了一起.
也就是说这里涉及到的数据传递涉及到的节点是`sink`和它的上游任务.
在`IntermediateQueueFlowLifeCycle`中, 有一个`AbstractIntermediateQueue`队列变量, 多个线程之间通过这个队列来实现生产者/消费者的消费模型来进行数据传递.
`AbstractIntermediateQueue`有两个实现类:
- `IntermediateBlockingQueue`
- `IntermediateDisruptor`
它们两个的区别是消息队列的实现有所不同, `IntermediateBlockingQueue`是默认的实现, 是通过`ArrayBlockingQueue`来实现的.
而`IntermediateDisruptor`则是通过`Disruptor`来实现的, 如果需要开启此功能, 需要在`seatunnel.yaml`中修改配置项`engine.queue-type=DISRUPTOR`来开启.

其实在代码中也有一些关于`Shuffle`的实现, 它实现的数据传递是基于`hazelcast`的`IQueue`队列来实现的, 可以实现跨进程的数据传递, 但是这一部分请教了社区的大佬之后, 说这一部分后续也废弃了.

## TaskExecution
在上面分析了一个任务的执行过程，这个章节会记录一下，一个具体的任务/Task/Class，是如何被运行起来的。

## TaskExecutionService
在Zeta引擎启动后，在服务端会启动一个`TaskExecutionService`服务，这个服务内会有一个缓存线程池来执行任务。
![](https://raw.githubusercontent.com/liunaijie/images/master/202411081457994.png)

在`PhysicalVertex`的状态切换中，当状态为`DEPLOYING`时，
```Java
case DEPLOYING:  
    TaskDeployState deployState =  
            deploy(jobMaster.getOwnedSlotProfiles(taskGroupLocation));  
    if (!deployState.isSuccess()) {  
        makeTaskGroupFailing(  
                new TaskGroupDeployException(deployState.getThrowableMsg()));  
    } else {  
        updateTaskState(ExecutionState.RUNNING);  
    }  
    break;
```
会将作业进行部署，部署到之前所申请到的worker节点上。
这个类里有这样一个方法来生成`TaskGroupImmutableInformation`
```Java
public TaskGroupImmutableInformation getTaskGroupImmutableInformation() {  
    List<Data> tasksData =  
            this.taskGroup.getTasks().stream()  
                    .map(task -> (Data) nodeEngine.getSerializationService().toData(task))  
                    .collect(Collectors.toList());  
    return new TaskGroupImmutableInformation(  
            this.taskGroup.getTaskGroupLocation().getJobId(),  
            flakeIdGenerator.newId(),  
            this.taskGroup.getTaskGroupType(),  
            this.taskGroup.getTaskGroupLocation(),  
            this.taskGroup.getTaskGroupName(),  
            tasksData,  
            this.pluginJarsUrls,  
            this.connectorJarIdentifiers);  
}
```
这里可以看出，会将当前节点上的所有任务进行序列化，然后设置相应的字段值。
生成这个信息后，会进行网络调用，将这个信息发送给具体的Worker上。
**从这个地方也可以得知，一个`TaskGroup`内的所有任务都会被分发到同一个节点上运行.**

而`Worker`接收到这个信息后，会调用`TaskExecutionService`的`deployTask(@NonNull Data taskImmutableInformation)`方法。这个方法内会进行网络传输数据的反序列化，之后再调用`TaskDeployState deployTask(@NonNull TaskGroupImmutableInformation taskImmutableInfo)`

我们来具体看下这个方法
```Java
public TaskDeployState deployTask(@NonNull TaskGroupImmutableInformation taskImmutableInfo) {  
    logger.info(  
            String.format(  
                    "received deploying task executionId [%s]",  
                    taskImmutableInfo.getExecutionId()));  
    TaskGroup taskGroup = null;  
    try {  
        List<Set<ConnectorJarIdentifier>> connectorJarIdentifiersList =  
                taskImmutableInfo.getConnectorJarIdentifiers();  
        List<Data> taskData = taskImmutableInfo.getTasksData();  
        ConcurrentHashMap<Long, ClassLoader> classLoaders = new ConcurrentHashMap<>();  
        List<Task> tasks = new ArrayList<>();  
        ConcurrentHashMap<Long, Collection<URL>> taskJars = new ConcurrentHashMap<>();  
        for (int i = 0; i < taskData.size(); i++) {  
            Set<URL> jars = new HashSet<>();  
            Set<ConnectorJarIdentifier> connectorJarIdentifiers =  
                    connectorJarIdentifiersList.get(i);  
            if (!CollectionUtils.isEmpty(connectorJarIdentifiers)) {  
                jars = serverConnectorPackageClient.getConnectorJarFromLocal(  
                                connectorJarIdentifiers);  
            } else if (!CollectionUtils.isEmpty(taskImmutableInfo.getJars().get(i))) {  
                jars = taskImmutableInfo.getJars().get(i);  
            }  
            ClassLoader classLoader =  
                    classLoaderService.getClassLoader(  
                            taskImmutableInfo.getJobId(), Lists.newArrayList(jars));  
            Task task;  
            if (jars.isEmpty()) {  
                task = nodeEngine.getSerializationService().toObject(taskData.get(i));  
            } else {  
                task =  
                        CustomClassLoadedObject.deserializeWithCustomClassLoader(  
                                nodeEngine.getSerializationService(),  
                                classLoader,  
                                taskData.get(i));  
            }  
            tasks.add(task);  
            classLoaders.put(task.getTaskID(), classLoader);  
            taskJars.put(task.getTaskID(), jars);  
        }  
        taskGroup =  
                TaskGroupUtils.createTaskGroup(  
                        taskImmutableInfo.getTaskGroupType(),  
                        taskImmutableInfo.getTaskGroupLocation(),  
                        taskImmutableInfo.getTaskGroupName(),  
                        tasks);  
  
        logger.info(  
                String.format(  
                        "deploying task %s, executionId [%s]",  
                        taskGroup.getTaskGroupLocation(), taskImmutableInfo.getExecutionId()));  
		// 上面获取一些信息后重新构建taskGroup
        synchronized (this) { 
			// 首先会判断当前是否已经运行了该任务，如果已经运行过则不再提交任务
			// 同时这里也对当前实例添加了全局锁，避免同时调用的问题
            if (executionContexts.containsKey(taskGroup.getTaskGroupLocation())) {  
                throw new RuntimeException(  
                        String.format(  
                                "TaskGroupLocation: %s already exists",  
                                taskGroup.getTaskGroupLocation()));  
            }
            // 没有运行过当前任务则进行提交  
            deployLocalTask(taskGroup, classLoaders, taskJars);  
            return TaskDeployState.success();  
        }  
    } catch (Throwable t) {  
		... 
        return TaskDeployState.failed(t);  
    }  
}
```
这个方法内会根据`TaskGroupImmutableInformation`信息来重新构建`TaskGroup`，然后调用`deployLocalTask()`进行部署任务。


```Java
public PassiveCompletableFuture<TaskExecutionState> deployLocalTask(  
        @NonNull TaskGroup taskGroup,  
        @NonNull ConcurrentHashMap<Long, ClassLoader> classLoaders,  
        ConcurrentHashMap<Long, Collection<URL>> jars) {  
    CompletableFuture<TaskExecutionState> resultFuture = new CompletableFuture<>();  
    try {
		// 初始化操作  
        taskGroup.init();  
        logger.info(  
                String.format(  
                        "deploying TaskGroup %s init success",  
                        taskGroup.getTaskGroupLocation()));  
        // 获取到当前任务组中的所有任务
        Collection<Task> tasks = taskGroup.getTasks();  
        CompletableFuture<Void> cancellationFuture = new CompletableFuture<>();  
        TaskGroupExecutionTracker executionTracker =  
                new TaskGroupExecutionTracker(cancellationFuture, taskGroup, resultFuture);  
        ConcurrentMap<Long, TaskExecutionContext> taskExecutionContextMap =  
                new ConcurrentHashMap<>();  
        final Map<Boolean, List<Task>> byCooperation =  
                tasks.stream()  
                        .peek(
                        // 设置context信息  
                                task -> {  
                                    TaskExecutionContext taskExecutionContext =  
                                            new TaskExecutionContext(task, nodeEngine, this);  
                                    task.setTaskExecutionContext(taskExecutionContext);  
                                    taskExecutionContextMap.put(  
                                            task.getTaskID(), taskExecutionContext);  
                                })  
                        .collect(
                        // 会根据是否需要线程共享来进行分组
                        // 目前默认是不共享的，也就是全部都会是false  
                                partitioningBy(  
                                        t -> {  
                                            ThreadShareMode mode =  
                                                    seaTunnelConfig  
                                                            .getEngineConfig()  
                                                            .getTaskExecutionThreadShareMode();  
                                            if (mode.equals(ThreadShareMode.ALL)) {  
                                                return true;  
                                            }  
                                            if (mode.equals(ThreadShareMode.OFF)) {  
                                                return false;  
                                            }  
                                            if (mode.equals(ThreadShareMode.PART)) {  
                                                return t.isThreadsShare();  
                                            }  
                                            return true;  
                                        }));  
        executionContexts.put(  
                taskGroup.getTaskGroupLocation(),  
                new TaskGroupContext(taskGroup, classLoaders, jars));  
        cancellationFutures.put(taskGroup.getTaskGroupLocation(), cancellationFuture);  
        // 这里全部是空，如果用户修改了，这里会找出来需要线程共享的任务
        submitThreadShareTask(executionTracker, byCooperation.get(true)); 
        // 提交任务 
        submitBlockingTask(executionTracker, byCooperation.get(false));  
        taskGroup.setTasksContext(taskExecutionContextMap);  
        // 打印成功的日志
        logger.info(  
                String.format(  
                        "deploying TaskGroup %s success", taskGroup.getTaskGroupLocation()));  
    } catch (Throwable t) {  
        logger.severe(ExceptionUtils.getMessage(t));  
        resultFuture.completeExceptionally(t);  
    }  
    resultFuture.whenCompleteAsync(  
            withTryCatch(  
                    logger,  
                    (r, s) -> {  
                        if (s != null) {  
                            logger.severe(  
                                    String.format(  
                                            "Task %s complete with error %s",  
                                            taskGroup.getTaskGroupLocation(),  
                                            ExceptionUtils.getMessage(s)));  
                        }  
                        if (r == null) {  
                            r =  
                                    new TaskExecutionState(  
                                            taskGroup.getTaskGroupLocation(),  
                                            ExecutionState.FAILED,  
                                            s);  
                        }  
                        logger.info(  
                                String.format(  
                                        "Task %s complete with state %s",  
                                        r.getTaskGroupLocation(), r.getExecutionState()));  
         // 报告部署的状态给master               notifyTaskStatusToMaster(taskGroup.getTaskGroupLocation(), r);  
                    }),  
            MDCTracer.tracing(executorService));  
    return new PassiveCompletableFuture<>(resultFuture);  
}
```

- submitBlockingTask
```Java
private void submitBlockingTask(  
        TaskGroupExecutionTracker taskGroupExecutionTracker, List<Task> tasks) {  
    MDCExecutorService mdcExecutorService = MDCTracer.tracing(executorService);  
  
    CountDownLatch startedLatch = new CountDownLatch(tasks.size());  
    taskGroupExecutionTracker.blockingFutures =  
            tasks.stream()  
                    .map(  
                            t ->  
                                    new BlockingWorker(  
                                            new TaskTracker(t, taskGroupExecutionTracker),  
                                            startedLatch))  
                    .map(  
                            r ->  
                                    new NamedTaskWrapper(  
                                            r,  
                                            "BlockingWorker-"  
                                                    + taskGroupExecutionTracker.taskGroup  
                                                            .getTaskGroupLocation()))  
                    .map(mdcExecutorService::submit)  
                    .collect(toList());  
  
    // Do not return from this method until all workers have started. Otherwise,  
    // on cancellation there is a race where the executor might not have started    // the worker yet. This would result in taskletDone() never being called for    // a worker.    uncheckRun(startedLatch::await);  
}
```
这里的`MDCExecutorService`是`ExecutorService`实现，`BlockWorking`是`Runnable`的实现。

```Java
private final class BlockingWorker implements Runnable {  
  
    private final TaskTracker tracker;  
    private final CountDownLatch startedLatch;  
  
    private BlockingWorker(TaskTracker tracker, CountDownLatch startedLatch) {  
        this.tracker = tracker;  
        this.startedLatch = startedLatch;  
    }  
  
    @Override  
    public void run() {  
        TaskExecutionService.TaskGroupExecutionTracker taskGroupExecutionTracker =  
                tracker.taskGroupExecutionTracker;  
        ClassLoader classLoader =  
                executionContexts  
                        .get(taskGroupExecutionTracker.taskGroup.getTaskGroupLocation())  
                        .getClassLoaders()  
                        .get(tracker.task.getTaskID());  
        ClassLoader oldClassLoader = Thread.currentThread().getContextClassLoader();  
        Thread.currentThread().setContextClassLoader(classLoader);  
        // 获取到SeaTunnel的Task
        final Task t = tracker.task;  
        ProgressState result = null;  
        try {  
            startedLatch.countDown();  
            // 调用Task的init方法
            t.init();  
            do { 
	            // 循环调用 call()方法 
                result = t.call();  
            } while (!result.isDone()  
                    && isRunning  
                    && !taskGroupExecutionTracker.executionCompletedExceptionally());  
        } catch (InterruptedException e) {  
            logger.warning(String.format("Interrupted task %d - %s", t.getTaskID(), t));  
            if (taskGroupExecutionTracker.executionException.get() == null  
                    && !taskGroupExecutionTracker.isCancel.get()) {  
                taskGroupExecutionTracker.exception(e);  
            }  
        } catch (Throwable e) {  
            logger.warning("Exception in " + t, e);  
            taskGroupExecutionTracker.exception(e);  
        } finally {  
            taskGroupExecutionTracker.taskDone(t);  
            if (result == null || !result.isDone()) {  
                try {  
                    tracker.task.close();  
                } catch (IOException e) {  
                    logger.severe("Close task error", e);  
                }  
            }  
        }  
        Thread.currentThread().setContextClassLoader(oldClassLoader);  
    }  
}
```
从这几部分代码可以看出，每一个Task都会作为一个单独的线程任务，被放到`Worker`的`newCachedThreadPool`线程池中来进行运行。

![image.png](https://raw.githubusercontent.com/liunaijie/images/master/202411081500558.png)


我们如果将上面的任务放大来看，将每个线程所做的任务以及任务之间的通信也画出来，大致是这样
![image.png](https://raw.githubusercontent.com/liunaijie/images/master/202411081500210.png)

如果将上面的图缩小看一下，仅关注数据的传输过程，大致是这样

![image.png](https://raw.githubusercontent.com/liunaijie/images/master/202411081532399.png)


# 参考
- https://github.com/apache/seatunnel/issues/2272
本文是对SeaTunnel Zeta引擎的解析，这个pr中记录了当时Zeta引擎的一些设计文档，强烈推荐阅读下相关的pr及设计文档