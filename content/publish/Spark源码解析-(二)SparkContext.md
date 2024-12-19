---
title: Spark源码解析-(二)SparkContext
date: 2023-07-30
categories:
  - publish
tags:
  - spark
---
继上一篇分析完Spark的提交流程之后, 这次继续分析下SparkContext的源码.
# 创建
当Spark通过反射调用用户提交类的主函数时, 用户的主函数内会完成SparkContext的创建.
还是以`JavaWordCount`为例
```java
public static void main(String[] args) throws Exception {  
  ...
  SparkSession spark = SparkSession  
    .builder()  
    .appName("JavaWordCount")  
    .getOrCreate();  
  
  JavaRDD<String> lines = spark.read().textFile(args[0]).javaRDD();  
	...  
  List<Tuple2<String, Integer>> output = counts.collect();  
  for (Tuple2<?,?> tuple : output) {  
    System.out.println(tuple._1() + ": " + tuple._2());  
  }  
  spark.stop();  
}
```
在这里是手动创建了SparkSession, SparkContext由SparkSession间接完成创建.

# 主要代码分析
`SparkContext`维护了`DAGScheduler`和`TaskScheduler`, 在创建`SparkContext`时会完成这两个类的创建及初始化.

```java
try {  
  _conf = config.clone()  
  _conf.validateSettings()  
  _conf.set("spark.app.startTime", startTime.toString)  
  ...   
  
  _listenerBus = new LiveListenerBus(_conf)  
  _resourceProfileManager = new ResourceProfileManager(_conf, _listenerBus)  
  
  // Initialize the app status store and listener before SparkEnv is created so that it gets  
  // all events.  val appStatusSource = AppStatusSource.createSource(conf)  
  _statusStore = AppStatusStore.createLiveStore(conf, appStatusSource)  
  listenerBus.addToStatusQueue(_statusStore.listener.get)  
  
  // Create the Spark execution environment (cache, map output tracker, etc)  
  _env = createSparkEnv(_conf, isLocal, listenerBus)  
  SparkEnv.set(_env)  
  ...
  _statusTracker = new SparkStatusTracker(this, _statusStore)  
  
  _progressBar =  
    if (_conf.get(UI_SHOW_CONSOLE_PROGRESS)) {  
      Some(new ConsoleProgressBar(this))  
    } else {  
      None  
    }  
  
  _ui =  
    if (conf.get(UI_ENABLED)) {  
      Some(SparkUI.create(Some(this), _statusStore, _conf, _env.securityManager, appName, "",  
        startTime))  
    } else {  
      // For tests, do not enable the UI  
      None  
    }  
	...
  _hadoopConfiguration = SparkHadoopUtil.get.newConfiguration(_conf)  
    ...
  _executorMemory = SparkContext.executorMemoryInMb(_conf)  
   ...
  _shuffleDriverComponents = ShuffleDataIOUtils.loadShuffleDataIO(config).driver()  
  _shuffleDriverComponents.initializeApplication().asScala.foreach { case (k, v) =>  
    _conf.set(ShuffleDataIOUtils.SHUFFLE_SPARK_CONF_PREFIX + k, v)  
  }  
  
  // We need to register "HeartbeatReceiver" before "createTaskScheduler" because Executor will  
  // retrieve "HeartbeatReceiver" in the constructor. (SPARK-6640)  _heartbeatReceiver = env.rpcEnv.setupEndpoint(  
    HeartbeatReceiver.ENDPOINT_NAME, new HeartbeatReceiver(this))  
  
  // Initialize any plugins before the task scheduler is initialized.  
  _plugins = PluginContainer(this, _resources.asJava)  
  
  // Create and start the scheduler  
  val (sched, ts) = SparkContext.createTaskScheduler(this, master)  
  _schedulerBackend = sched  
  _taskScheduler = ts  
  _dagScheduler = new DAGScheduler(this)  
  _heartbeatReceiver.ask[Boolean](TaskSchedulerIsSet)  
  
  val _executorMetricsSource =  
    if (_conf.get(METRICS_EXECUTORMETRICS_SOURCE_ENABLED)) {  
      Some(new ExecutorMetricsSource)  
    } else {  
      None  
    }  
  
  // create and start the heartbeater for collecting memory metrics  
  _heartbeater = new Heartbeater(  
    () => SparkContext.this.reportHeartBeat(_executorMetricsSource),  
    "driver-heartbeater",  
    conf.get(EXECUTOR_HEARTBEAT_INTERVAL))  
  _heartbeater.start()  
  
  // start TaskScheduler after taskScheduler sets DAGScheduler reference in DAGScheduler's  
  // constructor  _taskScheduler.start()  
  
  _applicationId = _taskScheduler.applicationId()  
  _applicationAttemptId = _taskScheduler.applicationAttemptId()  
  _conf.set("spark.app.id", _applicationId)  
  _applicationAttemptId.foreach { attemptId =>  
    _conf.set(APP_ATTEMPT_ID, attemptId)  
    _env.blockManager.blockStoreClient.setAppAttemptId(attemptId)  
  }  
  if (_conf.get(UI_REVERSE_PROXY)) {  
    val proxyUrl = _conf.get(UI_REVERSE_PROXY_URL).getOrElse("").stripSuffix("/")  
    System.setProperty("spark.ui.proxyBase", proxyUrl + "/proxy/" + _applicationId)  
  }  
  _ui.foreach(_.setAppId(_applicationId))  
  _env.blockManager.initialize(_applicationId)  
  FallbackStorage.registerBlockManagerIfNeeded(_env.blockManager.master, _conf)  
   
  ...  
  
  _cleaner =  
    if (_conf.get(CLEANER_REFERENCE_TRACKING)) {  
      Some(new ContextCleaner(this, _shuffleDriverComponents))  
    } else {  
      None  
    }  
  _cleaner.foreach(_.start())  
  
  val dynamicAllocationEnabled = Utils.isDynamicAllocationEnabled(_conf)  
  _executorAllocationManager =  
    if (dynamicAllocationEnabled) {  
      schedulerBackend match {  
        case b: ExecutorAllocationClient =>  
          Some(new ExecutorAllocationManager(  
            schedulerBackend.asInstanceOf[ExecutorAllocationClient], listenerBus, _conf,  
            cleaner = cleaner, resourceProfileManager = resourceProfileManager))  
        case _ =>  
          None  
      }  
    } else {  
      None  
    }  
  _executorAllocationManager.foreach(_.start())  
  
  setupAndStartListenerBus()  
  postEnvironmentUpdate()  
  postApplicationStart()  
  
  // After application started, attach handlers to started server and start handler.  
  _ui.foreach(_.attachAllHandler())  
  // Attach the driver metrics servlet handler to the web ui after the metrics system is started.  
  _env.metricsSystem.getServletHandlers.foreach(handler => ui.foreach(_.attachHandler(handler)))  
  
  // Make sure the context is stopped if the user forgets about it. This avoids leaving  
  // unfinished event logs around after the JVM exits cleanly. It doesn't help if the JVM  // is killed, though.  logDebug("Adding shutdown hook") // force eager creation of logger  
  _shutdownHookRef = ShutdownHookManager.addShutdownHook(  
    ShutdownHookManager.SPARK_CONTEXT_SHUTDOWN_PRIORITY) { () =>  
    logInfo("Invoking stop() from shutdown hook")  
    try {  
      stop()  
    } catch {  
      case e: Throwable =>  
        logWarning("Ignoring Exception while stopping SparkContext from shutdown hook", e)  
    }  
  }  
  
  // Post init  
  _taskScheduler.postStartHook()  
  if (isLocal) {  
    _env.metricsSystem.registerSource(Executor.executorSourceLocalModeOnly)  
  }  
  _env.metricsSystem.registerSource(_dagScheduler.metricsSource)  
  _env.metricsSystem.registerSource(new BlockManagerSource(_env.blockManager))  
  _env.metricsSystem.registerSource(new JVMCPUSource())  
  _executorMetricsSource.foreach(_.register(_env.metricsSystem))  
  _executorAllocationManager.foreach { e =>  
    _env.metricsSystem.registerSource(e.executorAllocationManagerSource)  
  }  
  appStatusSource.foreach(_env.metricsSystem.registerSource(_))  
  _plugins.foreach(_.registerMetrics(applicationId))  
} catch {  
	...  
}
```
通过`SparkContext.createTaskScheduler(this, master)`创建了`SchedulerBackend`与`TaskScheduler`. 之后又创建了`DAGScheduler`.
先来看`TaskScheduler`的创建过程:
```java
private def createTaskScheduler(  
    sc: SparkContext,  
    master: String): (SchedulerBackend, TaskScheduler) = {  
  import SparkMasterRegex._  
   ...
  master match {  
    case "local" =>  
      checkResourcesPerTask(1)  
      val scheduler = new TaskSchedulerImpl(sc, MAX_LOCAL_TASK_FAILURES, isLocal = true)  
      val backend = new LocalSchedulerBackend(sc.getConf, scheduler, 1)  
      scheduler.initialize(backend)  
      (backend, scheduler)  
  
    case LOCAL_N_REGEX(threads) =>  
      def localCpuCount: Int = Runtime.getRuntime.availableProcessors()  
      // local[*] estimates the number of cores on the machine; local[N] uses exactly N threads.  
      val threadCount = if (threads == "*") localCpuCount else threads.toInt  
      if (threadCount <= 0) {  
        throw new SparkException(s"Asked to run locally with $threadCount threads")  
      }  
      checkResourcesPerTask(threadCount)  
      val scheduler = new TaskSchedulerImpl(sc, MAX_LOCAL_TASK_FAILURES, isLocal = true)  
      val backend = new LocalSchedulerBackend(sc.getConf, scheduler, threadCount)  
      scheduler.initialize(backend)  
      (backend, scheduler)  
  
    case LOCAL_N_FAILURES_REGEX(threads, maxFailures) =>  
      def localCpuCount: Int = Runtime.getRuntime.availableProcessors()  
      // local[*, M] means the number of cores on the computer with M failures  
      // local[N, M] means exactly N threads with M failures      val threadCount = if (threads == "*") localCpuCount else threads.toInt  
      checkResourcesPerTask(threadCount)  
      val scheduler = new TaskSchedulerImpl(sc, maxFailures.toInt, isLocal = true)  
      val backend = new LocalSchedulerBackend(sc.getConf, scheduler, threadCount)  
      scheduler.initialize(backend)  
      (backend, scheduler)  
  
    case SPARK_REGEX(sparkUrl) =>  
      val scheduler = new TaskSchedulerImpl(sc)  
      val masterUrls = sparkUrl.split(",").map("spark://" + _)  
      val backend = new StandaloneSchedulerBackend(scheduler, sc, masterUrls)  
      scheduler.initialize(backend)  
      (backend, scheduler)  
  
    case LOCAL_CLUSTER_REGEX(numWorkers, coresPerWorker, memoryPerWorker) =>  
      checkResourcesPerTask(coresPerWorker.toInt)  
      // Check to make sure memory requested <= memoryPerWorker. Otherwise Spark will just hang.  
      val memoryPerWorkerInt = memoryPerWorker.toInt  
      if (sc.executorMemory > memoryPerWorkerInt) {  
        throw new SparkException(  
          "Asked to launch cluster with %d MiB/worker but requested %d MiB/executor".format(  
            memoryPerWorkerInt, sc.executorMemory))  
      }  
  
      // For host local mode setting the default of SHUFFLE_HOST_LOCAL_DISK_READING_ENABLED  
      // to false because this mode is intended to be used for testing and in this case all the      // executors are running on the same host. So if host local reading was enabled here then      // testing of the remote fetching would be secondary as setting this config explicitly to      // false would be required in most of the unit test (despite the fact that remote fetching      // is much more frequent in production).   
	  sc.conf.setIfMissing(SHUFFLE_HOST_LOCAL_DISK_READING_ENABLED, false)  
  
      val scheduler = new TaskSchedulerImpl(sc)  
      val localCluster = LocalSparkCluster(  
        numWorkers.toInt, coresPerWorker.toInt, memoryPerWorkerInt, sc.conf)  
      val masterUrls = localCluster.start()  
      val backend = new StandaloneSchedulerBackend(scheduler, sc, masterUrls)  
      scheduler.initialize(backend)  
      backend.shutdownCallback = (backend: StandaloneSchedulerBackend) => {  
        localCluster.stop()  
      }  
      (backend, scheduler)  
  
    case masterUrl =>  
      val cm = getClusterManager(masterUrl) match {  
        case Some(clusterMgr) => clusterMgr  
        case None => throw new SparkException("Could not parse Master URL: '" + master + "'")  
      }  
      try {  
        val scheduler = cm.createTaskScheduler(sc, masterUrl)  
        val backend = cm.createSchedulerBackend(sc, masterUrl, scheduler)  
        cm.initialize(scheduler, backend)  
        (backend, scheduler)  
      } catch {  
        case se: SparkException => throw se  
        case NonFatal(e) =>  
          throw new SparkException("External scheduler cannot be instantiated", e)  
      }  
  }  
}
```
这里其实是对我们任务提交类型的判断, 从而选择不同的实现类.
而后续的`DAGScheduler`创建, 传入了`SparkContext`与`TaskScheduler`参数, 在DAGScheduler内部做了`TaskScheduler`与`DAGScheduler`的绑定
`taskScheduler.setDAGScheduler(this)`
SparkContext初始化时, 相当于完成了基础的准备工作. 

后续当用户的action算子触发计算时, 会调用`dagScheduler`来做任务的划分与分配.
 在`JavaWordCount`这个例子中, 当调用`collect`算子时, 最终会调用到`SparkContext`类中的`runJob`方法. 
```java
def runJob[T, U: ClassTag](  
    rdd: RDD[T],  
    func: (TaskContext, Iterator[T]) => U,  
    partitions: Seq[Int],  
    resultHandler: (Int, U) => Unit): Unit = {  
  if (stopped.get()) {  
    throw new IllegalStateException("SparkContext has been shutdown")  
  }  
  val callSite = getCallSite  
  val cleanedFunc = clean(func)  
  logInfo("Starting job: " + callSite.shortForm)  
  if (conf.getBoolean("spark.logLineage", false)) {  
    logInfo("RDD's recursive dependencies:\n" + rdd.toDebugString)  
  }  
  dagScheduler.runJob(rdd, cleanedFunc, partitions, callSite, resultHandler, localProperties.get)  
  progressBar.foreach(_.finishAll())  
  rdd.doCheckpoint()  
}
```
## DAGScheduler
通过上面的代码可以知道, 这里调用了`dagScheduler`来提交任务.
```java
def runJob[T, U](  
    rdd: RDD[T],  
    func: (TaskContext, Iterator[T]) => U,  
    partitions: Seq[Int],  
    callSite: CallSite,  
    resultHandler: (Int, U) => Unit,  
    properties: Properties): Unit = {  
  val start = System.nanoTime  
  val waiter = submitJob(rdd, func, partitions, callSite, resultHandler, properties)  
  ThreadUtils.awaitReady(waiter.completionFuture, Duration.Inf)  
  waiter.completionFuture.value.get match {  
    case scala.util.Success(_) =>  
      logInfo("Job %d finished: %s, took %f s".format  
        (waiter.jobId, callSite.shortForm, (System.nanoTime - start) / 1e9))  
    case scala.util.Failure(exception) =>  
      logInfo("Job %d failed: %s, took %f s".format  
        (waiter.jobId, callSite.shortForm, (System.nanoTime - start) / 1e9))  
      // SPARK-8644: Include user stack trace in exceptions coming from DAGScheduler.  
      val callerStackTrace = Thread.currentThread().getStackTrace.tail  
      exception.setStackTrace(exception.getStackTrace ++ callerStackTrace)  
      throw exception  
  }  
}
```
在`DAGScheduler`里又调用了`submitJob`
```java
def submitJob[T, U](  
    rdd: RDD[T],  
    func: (TaskContext, Iterator[T]) => U,  
    partitions: Seq[Int],  
    callSite: CallSite,  
    resultHandler: (Int, U) => Unit,  
    properties: Properties): JobWaiter[U] = {  
  ...
  val jobId = nextJobId.getAndIncrement()  
  ...  
  val func2 = func.asInstanceOf[(TaskContext, Iterator[_]) => _]  
  val waiter = new JobWaiter[U](this, jobId, partitions.size, resultHandler)  
  eventProcessLoop.post(JobSubmitted(  
    jobId, rdd, func2, partitions.toArray, callSite, waiter,  
    Utils.cloneProperties(properties)))  
  waiter  
}
```
向`eventProcessLoop`发送了`JobSubmitted`的消息, 消息内包含了任务的基础信息.
**这里的调用采用了消息传递, 而不是直接的方法调用.**
```java
private def doOnReceive(event: DAGSchedulerEvent): Unit = event match {  
  case JobSubmitted(jobId, rdd, func, partitions, callSite, listener, properties) =>  
    dagScheduler.handleJobSubmitted(jobId, rdd, func, partitions, callSite, listener, properties)
	...
}
```
当`DagScheduler`收到消息后, 做模式匹配, 我们上面提交的`JobSubmitter`消息会调用`handleJobSubmitter`方法来处理.

```java
private[scheduler] def handleJobSubmitted(jobId: Int,  
    finalRDD: RDD[_],  
    func: (TaskContext, Iterator[_]) => _,  
    partitions: Array[Int],  
    callSite: CallSite,  
    listener: JobListener,  
    properties: Properties): Unit = {  
  var finalStage: ResultStage = null  
  try {  
    // New stage creation may throw an exception if, for example, jobs are run on a  
    // HadoopRDD whose underlying HDFS files have been deleted.    
    finalStage = createResultStage(finalRDD, func, partitions, jobId, callSite)  
  } catch {  
    ...  
  }  
  // Job submitted, clear internal data.  
  barrierJobIdToNumTasksCheckFailures.remove(jobId)  
  
  val job = new ActiveJob(jobId, finalStage, callSite, listener, properties)  
  clearCacheLocs()  
  ...
  val jobSubmissionTime = clock.getTimeMillis()  
  jobIdToActiveJob(jobId) = job  
  activeJobs += job  
  finalStage.setActiveJob(job)  
  val stageIds = jobIdToStageIds(jobId).toArray  
  val stageInfos = stageIds.flatMap(id => stageIdToStage.get(id).map(_.latestInfo))  
  listenerBus.post(  
    SparkListenerJobStart(job.jobId, jobSubmissionTime, stageInfos,  
      Utils.cloneProperties(properties)))  
  submitStage(finalStage)  
}
```
根据传入的RDD获取最后一步的`Stage`信息, 最后调用`submitStage`方法. 
先来看下如何获取的`finalStage`
```java
private def createResultStage(  
    rdd: RDD[_],  
    func: (TaskContext, Iterator[_]) => _,  
    partitions: Array[Int],  
    jobId: Int,  
    callSite: CallSite): ResultStage = {  
  val (shuffleDeps, resourceProfiles) = getShuffleDependenciesAndResourceProfiles(rdd)  
  val resourceProfile = mergeResourceProfilesForStage(resourceProfiles)  
  checkBarrierStageWithDynamicAllocation(rdd)  
  checkBarrierStageWithNumSlots(rdd, resourceProfile)  
  checkBarrierStageWithRDDChainPattern(rdd, partitions.toSet.size)  
  val parents = getOrCreateParentStages(shuffleDeps, jobId)  
  val id = nextStageId.getAndIncrement()  
  val stage = new ResultStage(id, rdd, func, partitions, parents, jobId,  
    callSite, resourceProfile.id)  
  stageIdToStage(id) = stage  
  updateJobIdStageIdMaps(jobId, stage)  
  stage  
}
```
其实我们知道Spark里根据是否需要做Shuffle来划分Stage, 那么这里就会根据一个RDD的所有依赖做划分, 这个切分就是在这里根据RDD的dependency信息做的.
当切分完成后, 会创建一个`ResultStage`表示这是最后一个`Stage`. 这个`Stage`里会有一个`parents`的Stage信息.

我们再来看下`submitStage`的代码部分
```java
private def submitStage(stage: Stage): Unit = {  
  val jobId = activeJobForStage(stage)  
  if (jobId.isDefined) {  
    logDebug(s"submitStage($stage (name=${stage.name};" +  
      s"jobs=${stage.jobIds.toSeq.sorted.mkString(",")}))")  
    if (!waitingStages(stage) && !runningStages(stage) && !failedStages(stage)) {  
      val missing = getMissingParentStages(stage).sortBy(_.id)  
      logDebug("missing: " + missing)  
      if (missing.isEmpty) {  
        logInfo("Submitting " + stage + " (" + stage.rdd + "), which has no missing parents")  
        submitMissingTasks(stage, jobId.get)  
      } else {  
        for (parent <- missing) {  
          submitStage(parent)  
        }  
        waitingStages += stage  
      }  
    }  
  } else {  
    abortStage(stage, "No active job for stage " + stage.id, None)  
  }  
}
```
当收到`finialStage`后, 可以看到做的事情是先获取`Parent Stage`. 当`Parent Stage`为空时才会提交自身的Stage, 不然会先计算`Parent Stage`. 
`Stage`是有依赖关系的, 所有当计算最后一个Stage时需要先完成之前所有Stage的计算. 
注意当有上游依赖时, 循环提交完成后还向 `waitingStages`添加了自身的`Stage`. 

```java
private def submitMissingTasks(stage: Stage, jobId: Int): Unit = {  
  logDebug("submitMissingTasks(" + stage + ")")  
  ...  
  // Figure out the indexes of partition ids to compute.  
  val partitionsToCompute: Seq[Int] = stage.findMissingPartitions()  
  ...
  runningStages += stage  
  // SparkListenerStageSubmitted should be posted before testing whether tasks are  
  // serializable. If tasks are not serializable, a SparkListenerStageCompleted event  // will be posted, which should always come after a corresponding SparkListenerStageSubmitted  // event.  
  stage match {  
    case s: ShuffleMapStage =>  
      outputCommitCoordinator.stageStart(stage = s.id, maxPartitionId = s.numPartitions - 1)  
      // Only generate merger location for a given shuffle dependency once.  
      if (s.shuffleDep.shuffleMergeAllowed) {  
        if (!s.shuffleDep.isShuffleMergeFinalizedMarked) {  
          prepareShuffleServicesForShuffleMapStage(s)  
        } else {  
          // Disable Shuffle merge for the retry/reuse of the same shuffle dependency if it has  
          // already been merge finalized. If the shuffle dependency was previously assigned          // merger locations but the corresponding shuffle map stage did not complete          // successfully, we would still enable push for its retry.  
          s.shuffleDep.setShuffleMergeAllowed(false)  
          logInfo(s"Push-based shuffle disabled for $stage (${stage.name}) since it" +  
            " is already shuffle merge finalized")  
        }  
      }  
    case s: ResultStage =>  
      outputCommitCoordinator.stageStart(  
        stage = s.id, maxPartitionId = s.rdd.partitions.length - 1)  
  }  
  val taskIdToLocations: Map[Int, Seq[TaskLocation]] = try {  
    stage match {  
      case s: ShuffleMapStage =>  
        partitionsToCompute.map { id => (id, getPreferredLocs(stage.rdd, id))}.toMap  
      case s: ResultStage =>  
        partitionsToCompute.map { id =>  
          val p = s.partitions(id)  
          (id, getPreferredLocs(stage.rdd, p))  
        }.toMap  
    }  
  } catch {  
    case NonFatal(e) =>  
      stage.makeNewStageAttempt(partitionsToCompute.size)  
      listenerBus.post(SparkListenerStageSubmitted(stage.latestInfo,  
        Utils.cloneProperties(properties)))  
      abortStage(stage, s"Task creation failed: $e\n${Utils.exceptionString(e)}", Some(e))  
      runningStages -= stage  
      return  
  }  
  
  stage.makeNewStageAttempt(partitionsToCompute.size, taskIdToLocations.values.toSeq)  
  
  // If there are tasks to execute, record the submission time of the stage. Otherwise,  
  // post the even without the submission time, which indicates that this stage was  // skipped.  if (partitionsToCompute.nonEmpty) {  
    stage.latestInfo.submissionTime = Some(clock.getTimeMillis())  
  }  
  listenerBus.post(SparkListenerStageSubmitted(stage.latestInfo,  
    Utils.cloneProperties(properties)))  
  
  // TODO: Maybe we can keep the taskBinary in Stage to avoid serializing it multiple times.  
  // Broadcasted binary for the task, used to dispatch tasks to executors. Note that we broadcast  
  // the serialized copy of the RDD and for each task we will deserialize it, which means each  // task gets a different copy of the RDD. This provides stronger isolation between tasks that  // might modify state of objects referenced in their closures. This is necessary in Hadoop  // where the JobConf/Configuration object is not thread-safe.  var taskBinary: Broadcast[Array[Byte]] = null  
  var partitions: Array[Partition] = null  
  try {  
    // For ShuffleMapTask, serialize and broadcast (rdd, shuffleDep).  
    // For ResultTask, serialize and broadcast (rdd, func).    var taskBinaryBytes: Array[Byte] = null  
    // taskBinaryBytes and partitions are both effected by the checkpoint status. We need  
    // this synchronization in case another concurrent job is checkpointing this RDD, so we get a    // consistent view of both variables.    RDDCheckpointData.synchronized {  
      taskBinaryBytes = stage match {  
        case stage: ShuffleMapStage =>  
          JavaUtils.bufferToArray(  
            closureSerializer.serialize((stage.rdd, stage.shuffleDep): AnyRef))  
        case stage: ResultStage =>  
          JavaUtils.bufferToArray(closureSerializer.serialize((stage.rdd, stage.func): AnyRef))  
      }  
  
      partitions = stage.rdd.partitions  
    }  
  
    if (taskBinaryBytes.length > TaskSetManager.TASK_SIZE_TO_WARN_KIB * 1024) {  
      logWarning(s"Broadcasting large task binary with size " +  
        s"${Utils.bytesToString(taskBinaryBytes.length)}")  
    }  
    taskBinary = sc.broadcast(taskBinaryBytes)  
  } catch {  
    // In the case of a failure during serialization, abort the stage.  
    case e: NotSerializableException =>  
      abortStage(stage, "Task not serializable: " + e.toString, Some(e))  
      runningStages -= stage  
  
      // Abort execution  
      return  
    case e: Throwable =>  
      abortStage(stage, s"Task serialization failed: $e\n${Utils.exceptionString(e)}", Some(e))  
      runningStages -= stage  
  
      // Abort execution  
      return  
  }  
  
  val tasks: Seq[Task[_]] = try {  
    val serializedTaskMetrics = closureSerializer.serialize(stage.latestInfo.taskMetrics).array()  
    stage match {  
      case stage: ShuffleMapStage =>  
        stage.pendingPartitions.clear()  
        partitionsToCompute.map { id =>  
          val locs = taskIdToLocations(id)  
          val part = partitions(id)  
          stage.pendingPartitions += id  
          new ShuffleMapTask(stage.id, stage.latestInfo.attemptNumber, taskBinary,  
            part, stage.numPartitions, locs, properties, serializedTaskMetrics, Option(jobId),  
            Option(sc.applicationId), sc.applicationAttemptId, stage.rdd.isBarrier())  
        }  
  
      case stage: ResultStage =>  
        partitionsToCompute.map { id =>  
          val p: Int = stage.partitions(id)  
          val part = partitions(p)  
          val locs = taskIdToLocations(id)  
          new ResultTask(stage.id, stage.latestInfo.attemptNumber,  
            taskBinary, part, stage.numPartitions, locs, id, properties, serializedTaskMetrics,  
            Option(jobId), Option(sc.applicationId), sc.applicationAttemptId,  
            stage.rdd.isBarrier())  
        }  
    }  
  } catch {  
    case NonFatal(e) =>  
      abortStage(stage, s"Task creation failed: $e\n${Utils.exceptionString(e)}", Some(e))  
      runningStages -= stage  
      return  
  }  
  
  if (tasks.nonEmpty) {  
    logInfo(s"Submitting ${tasks.size} missing tasks from $stage (${stage.rdd}) (first 15 " +  
      s"tasks are for partitions ${tasks.take(15).map(_.partitionId)})")  
    val shuffleId = stage match {  
      case s: ShuffleMapStage => Some(s.shuffleDep.shuffleId)  
      case _: ResultStage => None  
    }  
  
    taskScheduler.submitTasks(new TaskSet(  
      tasks.toArray, stage.id, stage.latestInfo.attemptNumber, jobId, properties,  
      stage.resourceProfileId, shuffleId))  
  } else {  
    // Because we posted SparkListenerStageSubmitted earlier, we should mark  
    // the stage as completed here in case there are no tasks to run    markStageAsFinished(stage, None)  
  
    stage match {  
      case stage: ShuffleMapStage =>  
        logDebug(s"Stage ${stage} is actually done; " +  
            s"(available: ${stage.isAvailable}," +  
            s"available outputs: ${stage.numAvailableOutputs}," +  
            s"partitions: ${stage.numPartitions})")  
        markMapStageJobsAsFinished(stage)  
      case stage : ResultStage =>  
        logDebug(s"Stage ${stage} is actually done; (partitions: ${stage.numPartitions})")  
    }  
    submitWaitingChildStages(stage)  
  }  
}
```
这段代码上面的部分是如何去创建`Task`, 当`tasks`不为空是会调用`taskScheduler.submitTask`来提交Task. `Task`的信息是通过`sparkContext.broadcast`来广播到每个executor上的.
注意当有上游依赖时,`finialStage`还在`waitingStages`中.

## TaskScheduler
```java
override def submitTasks(taskSet: TaskSet): Unit = {  
  val tasks = taskSet.tasks  
  logInfo("Adding task set " + taskSet.id + " with " + tasks.length + " tasks "  
    + "resource profile " + taskSet.resourceProfileId)  
  this.synchronized {  
    val manager = createTaskSetManager(taskSet, maxTaskFailures)  
    val stage = taskSet.stageId  
    val stageTaskSets =  
      taskSetsByStageIdAndAttempt.getOrElseUpdate(stage, new HashMap[Int, TaskSetManager])  
   
    stageTaskSets.foreach { case (_, ts) =>  
      ts.isZombie = true  
    }  
    stageTaskSets(taskSet.stageAttemptId) = manager  
    schedulableBuilder.addTaskSetManager(manager, manager.taskSet.properties)  
  
    if (!isLocal && !hasReceivedTask) {  
      starvationTimer.scheduleAtFixedRate(new TimerTask() {  
        override def run(): Unit = {  
          if (!hasLaunchedTask) {  
            logWarning("Initial job has not accepted any resources; " +  
              "check your cluster UI to ensure that workers are registered " +  
              "and have sufficient resources")  
          } else {  
            this.cancel()  
          }  
        }  
      }, STARVATION_TIMEOUT_MS, STARVATION_TIMEOUT_MS)  
    }  
    hasReceivedTask = true  
  }  
  backend.reviveOffers()  
}
```
创建完`TaskSetManager`后, 调用了`SchedulerBackend.reviverOffers`.
`SchedulerBackend`的实现类为`CoarseGrainedSchedulerBackend`
```java
override def reviveOffers(): Unit = Utils.tryLogNonFatalError {  
  driverEndpoint.send(ReviveOffers)  
}

override def receive: PartialFunction[Any, Unit] = {
	...
	case ReviveOffers =>  
	  makeOffers()
	...
}


private def makeOffers(): Unit = {  
  // Make sure no executor is killed while some task is launching on it  
  val taskDescs = withLock {  
    // Filter out executors under killing  
    val activeExecutors = executorDataMap.filterKeys(isExecutorActive)  
    val workOffers = activeExecutors.map {  
      case (id, executorData) => buildWorkerOffer(id, executorData)  
    }.toIndexedSeq  
    scheduler.resourceOffers(workOffers, true)  
  }  
  if (taskDescs.nonEmpty) {  
    launchTasks(taskDescs)  
  }  
}

private def launchTasks(tasks: Seq[Seq[TaskDescription]]): Unit = {  
  for (task <- tasks.flatten) {  
    val serializedTask = TaskDescription.encode(task)  
    if (serializedTask.limit() >= maxRpcMessageSize) {  
      Option(scheduler.taskIdToTaskSetManager.get(task.taskId)).foreach { taskSetMgr =>  
        try {  
          var msg = "Serialized task %s:%d was %d bytes, which exceeds max allowed: " +  
            s"${RPC_MESSAGE_MAX_SIZE.key} (%d bytes). Consider increasing " +  
            s"${RPC_MESSAGE_MAX_SIZE.key} or using broadcast variables for large values."          msg = msg.format(task.taskId, task.index, serializedTask.limit(), maxRpcMessageSize)  
          taskSetMgr.abort(msg)  
        } catch {  
          case e: Exception => logError("Exception in error callback", e)  
        }  
      }  
    }  
    else {  
      val executorData = executorDataMap(task.executorId)  
      // Do resources allocation here. The allocated resources will get released after the task  
      // finishes.      executorData.freeCores -= task.cpus  
      task.resources.foreach { case (rName, rInfo) =>  
        assert(executorData.resourcesInfo.contains(rName))  
        executorData.resourcesInfo(rName).acquire(rInfo.addresses)  
      }  
  
      logDebug(s"Launching task ${task.taskId} on executor id: ${task.executorId} hostname: " +  
        s"${executorData.executorHost}.")  
  
      executorData.executorEndpoint.send(LaunchTask(new SerializableBuffer(serializedTask)))  
    }  
  }  
}

```
这里将task编码后, 发送到每个executor上. 


# Executor
在executor上, 当接受到`LauncherTask`类型的消息时
```java
override def receive: PartialFunction[Any, Unit] = {  
  ..  
  case LaunchTask(data) =>  
    if (executor == null) {  
      exitExecutor(1, "Received LaunchTask command but executor was null")  
    } else {  
      val taskDesc = TaskDescription.decode(data.value)  
      logInfo("Got assigned task " + taskDesc.taskId)  
      taskResources(taskDesc.taskId) = taskDesc.resources  
      executor.launchTask(this, taskDesc)  
    }
}
```
反序列化化Task信息, 然后交到线程池中执行. 
当任务完成后, `TaskSetManager`中的方法会将信息发送给`DagScheduler`.
```java
def handleSuccessfulTask(tid: Long, result: DirectTaskResult[_]): Unit = {
	sched.dagScheduler.taskEnded(tasks(index), Success, result.value(), result.accumUpdates,  
  result.metricPeaks, info)
}
```

 在`DAGScheduler`中, 
```java
def taskEnded(  
    task: Task[_],  
    reason: TaskEndReason,  
    result: Any,  
    accumUpdates: Seq[AccumulatorV2[_, _]],  
    metricPeaks: Array[Long],  
    taskInfo: TaskInfo): Unit = {  
  eventProcessLoop.post(  
    CompletionEvent(task, reason, result, accumUpdates, metricPeaks, taskInfo))  
}


private[scheduler] def handleTaskCompletion(event: CompletionEvent): Unit = {
event.reason match {  
  case Success =>  
	...
    task match {  
	  ...
      case smt: ShuffleMapTask =>  
        val shuffleStage = stage.asInstanceOf[ShuffleMapStage]  
        shuffleStage.pendingPartitions -= task.partitionId  
        val status = event.result.asInstanceOf[MapStatus]  
        val execId = status.location.executorId  
        logDebug("ShuffleMapTask finished on " + execId)  
        if (executorFailureEpoch.contains(execId) &&  
            smt.epoch <= executorFailureEpoch(execId)) {  
          logInfo(s"Ignoring possibly bogus $smt completion from executor $execId")  
        } else {  
          // The epoch of the task is acceptable (i.e., the task was launched after the most  
          // recent failure we're aware of for the executor), so mark the task's output as          // available.          mapOutputTracker.registerMapOutput(  
            shuffleStage.shuffleDep.shuffleId, smt.partitionId, status)  
        }  
  
        if (runningStages.contains(shuffleStage) && shuffleStage.pendingPartitions.isEmpty) {  
          if (!shuffleStage.shuffleDep.isShuffleMergeFinalizedMarked &&  
            shuffleStage.shuffleDep.getMergerLocs.nonEmpty) {  
            checkAndScheduleShuffleMergeFinalize(shuffleStage)  
          } else {  
            processShuffleMapStageCompletion(shuffleStage)  
          }  
        }  
    }

}
```
这里有一句`processShuffleMapStageCompletion(shuffleStage)`, 当有上游依赖时`ResultStage`会被放到`waitingStages`, 还未被执行. 
```java
private def processShuffleMapStageCompletion(shuffleStage: ShuffleMapStage): Unit = {  
  markStageAsFinished(shuffleStage)  
  logInfo("looking for newly runnable stages")  
  logInfo("running: " + runningStages)  
  logInfo("waiting: " + waitingStages)  
  logInfo("failed: " + failedStages)  
  
  mapOutputTracker.incrementEpoch()  
  
  clearCacheLocs()  
  
  if (!shuffleStage.isAvailable) {  
    // Some tasks had failed; let's resubmit this shuffleStage.  
    // TODO: Lower-level scheduler should also deal with this  
    logInfo("Resubmitting " + shuffleStage + " (" + shuffleStage.name +  
      ") because some of its tasks had failed: " +  
      shuffleStage.findMissingPartitions().mkString(", "))  
    submitStage(shuffleStage)  
  } else {  
    markMapStageJobsAsFinished(shuffleStage)  
    submitWaitingChildStages(shuffleStage)  
  }  
}


private def submitWaitingChildStages(parent: Stage): Unit = {  
  logTrace(s"Checking if any dependencies of $parent are now runnable")  
  logTrace("running: " + runningStages)  
  logTrace("waiting: " + waitingStages)  
  logTrace("failed: " + failedStages)  
  val childStages = waitingStages.filter(_.parents.contains(parent)).toArray  
  waitingStages --= childStages  
  for (stage <- childStages.sortBy(_.firstJobId)) {  
    submitStage(stage)  
  }  
}
```
这里会将Stage从`waitingStages`中拿出来, 然后重新提交. 

