---
title: Spark中的提交流程
date: 2023-07-22 11:10:23
categories:
  - - publish
    - coding
    - big_data
    - spark
tags:
  - big_data/spark
---

本文以Spark3.4版本，提交任务方式为Yarn Cluster，以`JavaWordCount`这个应用程序为例来分析一下一个Spark任务的提交过程。
过程中会对代码做一些删减，主要目的是了解从用户提交任务开始到一个任务如何开始运行.
本文主要记录两种提交任务的方式，`spark-submit.sh`与`SparkLauncher`.  
 

# Spark-submit.sh
以需要执行JavaWordCount为例，启动命令为：
```shell
./bin/spark-submit \
--master yarn \
--deploy-mode cluster \
--class org.apache.spark.examples.JavaWordCount \
/path/to/examples.jar \
/tmp/file1.txt
```
我们指定了在yarn上以cluster模式启动JavaWordCount程序， 指定了jar包位置，以及要读取的文件
## spark-submit
```shell
......

exec "${SPARK_HOME}"/bin/spark-class org.apache.spark.deploy.SparkSubmit "$@"
```
这个脚本最后调用了`spark-class`脚本，第一个参数为`SparkSubmit`的全类名，再加上我们本来的参数
## spark-class
这个脚本做了这几件事：
- 查找spark的jar包
```shell
# Find Spark jars.  
if [ -d "${SPARK_HOME}/jars" ]; then  
SPARK_JARS_DIR="${SPARK_HOME}/jars"  
else  
SPARK_JARS_DIR="${SPARK_HOME}/assembly/target/scala-$SPARK_SCALA_VERSION/jars"  
fi  
  
if [ ! -d "$SPARK_JARS_DIR" ] && [ -z "$SPARK_TESTING$SPARK_SQL_TESTING" ]; then  
echo "Failed to find Spark jars directory ($SPARK_JARS_DIR)." 1>&2  
echo "You need to build Spark with the target \"package\" before running this program." 1>&2  
exit 1  
else  
LAUNCH_CLASSPATH="$SPARK_JARS_DIR/*"  
fi  
  
# Add the launcher build dir to the classpath if requested.  
if [ -n "$SPARK_PREPEND_CLASSES" ]; then  
LAUNCH_CLASSPATH="${SPARK_HOME}/launcher/target/scala-$SPARK_SCALA_VERSION/classes:$LAUNCH_CLASSPATH"  
fi
```
- 调用SparkLauncher里面的Main进行参数注入
```shell
build_command() {  
"$RUNNER" -Xmx128m $SPARK_LAUNCHER_OPTS -cp "$LAUNCH_CLASSPATH" org.apache.spark.launcher.Main "$@"  
printf "%d\0" $?  
}
```
- 执行被修改过的命令
```shell
CMD=("${CMD[@]:0:$LAST}")  
exec "${CMD[@]}"
```
经过修改后最终的命令为：
```shell
java -cp
....(一些参数修改)
org.apache.spark.deploy.SparkSubmit \ 
--master yarn \
--deploy-mode cluster \
--class org.apache.spark.examples.JavaWordCount \
/path/to/examples.jar \
/tmp/file1.txt
```
可以看到这里最终会去调用`SparkSubmit`这个类
## SparkSubmit
```scala
override def main(args: Array[String]): Unit = {  
	val submit = new SparkSubmit() {  
		self =>  
			override def doSubmit(args: Array[String]): Unit = {  
		try {  
			// 调用 doSubmit方法  
			super.doSubmit(args)  
			} catch {  
			case e: SparkUserAppException =>  
				exitFn(e.exitCode)  
			}  
		}  
	}  
	submit.doSubmit(args)  
}

private[spark] class SparkSubmit extends Logging {
	def doSubmit(args: Array[String]): Unit = {  
		// Initialize logging if it hasn't been done yet. Keep track of whether logging needs to  
		// be reset before the application starts.  
		val uninitLog = initializeLogIfNecessary(true, silent = true)  
		  
		val appArgs = parseArguments(args)  
		if (appArgs.verbose) {  
			logInfo(appArgs.toString)  
		}  
		// action默认为submit，则会到submit方法  
		appArgs.action match {  
			case SparkSubmitAction.SUBMIT => submit(appArgs, uninitLog)  
			case SparkSubmitAction.KILL => kill(appArgs)  
			case SparkSubmitAction.REQUEST_STATUS => requestStatus(appArgs)  
			case SparkSubmitAction.PRINT_VERSION => printVersion()  
		}  
	}
	...


	private def submit(args: SparkSubmitArguments, uninitLog: Boolean): Unit = {  
		doRunMain()  
	
		def doRunMain(): Unit = {  
			...
			runMain(args, uninitLog)  
		}
	 
	}
}

```
在Main方法中调用伴生类中的`doSubmit`方法，在`doSubmit`方法中先进行了参数解析，然后模式匹配，调用不同类型的方法。默认的action为submit，所以会调用到submit方法，而submit方法中又会调用到runMain方法中去.  

```scala
private def runMain(args: SparkSubmitArguments, uninitLog: Boolean): Unit = {

	val (childArgs, childClasspath, sparkConf, childMainClass) = prepareSubmitEnvironment(args)

	val loader = getSubmitClassLoader(sparkConf)

	for (jar <- childClasspath) {
		addJarToClasspath(jar, loader)
	}

	var mainClass: Class[_] = null

	try {
	mainClass = Utils.classForName(childMainClass)
	} catch {
	}

	val app: SparkApplication = if (classOf[SparkApplication].isAssignableFrom(mainClass)) {
	mainClass.getConstructor().newInstance().asInstanceOf[SparkApplication]
	} else {
	new JavaMainApplication(mainClass)
	}
	
	try {
		app.start(childArgs.toArray, sparkConf)
	} catch {
	} finally {
	}

}
```
在这个方法中，我们可以看到做了这样几件事：
- 获取class loader
- 获取mainClass并进行初始化
- 调用实例的start方法
我们这里需要关注的点是实例化了那个类，也就是childMainClass是什么，看一下`prepareSubmitEnvironment`方法
```scala
private[deploy] def prepareSubmitEnvironment(  
args: SparkSubmitArguments,  
conf: Option[HadoopConfiguration] = None)  
: (Seq[String], Seq[String], SparkConf, String) = {

	if (deployMode == CLIENT) {  
		childMainClass = args.mainClass 
	}
	if (isYarnCluster) {  
		childMainClass = YARN_CLUSTER_SUBMIT_CLASS
	}
	// Load any properties specified through --conf and the default properties file  
	for ((k, v) <- args.sparkProperties) {  
		sparkConf.setIfMissing(k, v)  
	}  
	// Ignore invalid spark.driver.host in cluster modes.  
	if (deployMode == CLUSTER) {  
		sparkConf.remove(DRIVER_HOST_ADDRESS)  
	}

```
这个方法比较复杂，我只摘出来了与这次分析相关或比较重要的几句代码。
首先，如果我们使用的是client模式来提交任务，这里的childMainClass就是我们参数中的class，也就是`JavaWordCount`的全类名。
如果我们使用的是Yarn Cluster模式，这里的childMainClass则为`org.apache.spark.deploy.yarn.YarnClusterApplication`.
后续还会将我们参数中的spark配置读取并进行配置。

再回到`runMain`这个方法中，
```scala
private def runMain(args: SparkSubmitArguments, uninitLog: Boolean): Unit = {

	val (childArgs, childClasspath, sparkConf, childMainClass) = prepareSubmitEnvironment(args)

	val loader = getSubmitClassLoader(sparkConf)

	for (jar <- childClasspath) {
		addJarToClasspath(jar, loader)
	}

	var mainClass: Class[_] = null

	try {
		mainClass = Utils.classForName(childMainClass)
	} catch {
	}

	val app: SparkApplication = if (classOf[SparkApplication].isAssignableFrom(mainClass)) {
	mainClass.getConstructor().newInstance().asInstanceOf[SparkApplication]
	} else {
	new JavaMainApplication(mainClass)
	}
	
	try {
		app.start(childArgs.toArray, sparkConf)
	} catch {
	} finally {
	}

}
```
先来分析Client模式，这里得到的childMainClass为我们提交的任务类，在我们的例子中为`JavaWordCount`. 这个在初始化时会使用`JavaMainApplication`做一下封装。
```scala
private[deploy] class JavaMainApplication(klass: Class[_]) extends SparkApplication {  
  
override def start(args: Array[String], conf: SparkConf): Unit = {  
val mainMethod = klass.getMethod("main", new Array[String](0).getClass)  
if (!Modifier.isStatic(mainMethod.getModifiers)) {  
throw new IllegalStateException("The main method in the given main class must be static")  
}  
  
val sysProps = conf.getAll.toMap  
sysProps.foreach { case (k, v) =>  
sys.props(k) = v  
}  
  
mainMethod.invoke(null, args)  
}  
  
}
```
当我们调用`app.start`时，其实就是调用了`JavaWordCount`这个类的main方法。
可以看到在Client模式下，直接在本地启动了我们的程序，也就是Driver是在本地进行启动。

再来分析一下Cluster模式下的启动，`childMainClass`得到的值是`YarnClusterApplication`.

## YarnClusterApplication
```scala
private[spark] class YarnClusterApplication extends SparkApplication {  
  
	override def start(args: Array[String], conf: SparkConf): Unit = {  
		// SparkSubmit would use yarn cache to distribute files & jars in yarn mode,  
		// so remove them from sparkConf here for yarn mode.  
		conf.remove(JARS)  
		conf.remove(FILES)  
		conf.remove(ARCHIVES)  
		new Client(new ClientArguments(args), conf, null).run()  
	}  
}
```
由于`YarnClusterApplication`是`SparkApplication`的子类，所以会直接构建实例，然后调用start方法。 在`YarnClusterApplication`的start方法中，我们看到是初始化了`Client`然后调用run方法，接下来我们看下`Client`的实现
```scala
def run(): Unit = {
	submitApplication()
	...
}

def submitApplication(): Unit = {
	ResourceRequestHelper.validateResources(sparkConf)
	try {
		launcherBackend.connect()
		yarnClient.init(hadoopConf)
		yarnClient.start()
		// Get a new application from our RM
		val newApp = yarnClient.createApplication()
		val newAppResponse = newApp.getNewApplicationResponse()
		this.appId = newAppResponse.getApplicationId()
		// The app staging dir based on the STAGING_DIR configuration if configured
		// otherwise based on the users home directory.
		// scalastyle:off FileSystemGet
		val appStagingBaseDir = sparkConf.get(STAGING_DIR)
		.map {
			new Path(_, UserGroupInformation.getCurrentUser.getShortUserName)
		}.getOrElse(FileSystem.get(hadoopConf).getHomeDirectory())
		stagingDirPath = new Path(appStagingBaseDir, getAppStagingDir(appId))
		// scalastyle:on FileSystemGet
		new CallerContext("CLIENT", sparkConf.get(APP_CALLER_CONTEXT),
		Option(appId.toString)).setCurrentContext()
		
		// Verify whether the cluster has enough resources for our AM
		verifyClusterResources(newAppResponse)
		// Set up the appropriate contexts to launch our AM
		val containerContext = createContainerLaunchContext()
		val appContext = createApplicationSubmissionContext(newApp, containerContext)
		// Finally, submit and monitor the application
		logInfo(s"Submitting application $appId to ResourceManager")
		// 提交application
		yarnClient.submitApplication(appContext)
		launcherBackend.setAppId(appId.toString)
		reportLauncherState(SparkAppHandle.State.SUBMITTED)
	} catch {
		case e: Throwable =>
			if (stagingDirPath != null) {
				cleanupStagingDir()
			}
		throw e
	}

}
```
分析这一段代码后我们可以知道，这里做的事情就是向Yarn集群申请启动了一个Application，也就是Application Master。在spark里就是Driver。
我们看一下这个app的具体信息，`createContainerLaunchContext`这个方法里面。
```scala
private def createContainerLaunchContext(): ContainerLaunchContext = {

logInfo("Setting up container launch context for our AM")

val launchEnv = setupLaunchEnv(stagingDirPath, pySparkArchives)

val localResources = prepareLocalResources(stagingDirPath, pySparkArchives)

val amContainer = Records.newRecord(classOf[ContainerLaunchContext])

amContainer.setLocalResources(localResources.asJava)

amContainer.setEnvironment(launchEnv.asJava)

val javaOpts = ListBuffer[String]()


javaOpts += s"-Djava.net.preferIPv6Addresses=${Utils.preferIPv6}"

// SPARK-37106: To start AM with Java 17, `JavaModuleOptions.defaultModuleOptions`

// is added by default. It will not affect Java 8 and Java 11 due to existence of

// `-XX:+IgnoreUnrecognizedVMOptions`.

javaOpts += JavaModuleOptions.defaultModuleOptions()

// Set the environment variable through a command prefix

// to append to the existing value of the variable

var prefixEnv: Option[String] = None

// Add Xmx for AM memory

javaOpts += "-Xmx" + amMemory + "m"

val tmpDir = new Path(Environment.PWD.$$(), YarnConfiguration.DEFAULT_CONTAINER_TEMP_DIR)

javaOpts += "-Djava.io.tmpdir=" + tmpDir

// Include driver-specific java options if we are launching a driver

if (isClusterMode) {

sparkConf.get(DRIVER_JAVA_OPTIONS).foreach { opts =>

javaOpts ++= Utils.splitCommandString(opts)

.map(Utils.substituteAppId(_, this.appId.toString))

.map(YarnSparkHadoopUtil.escapeForShell)

}

val libraryPaths = Seq(sparkConf.get(DRIVER_LIBRARY_PATH),

sys.props.get("spark.driver.libraryPath")).flatten

if (libraryPaths.nonEmpty) {

prefixEnv = Some(createLibraryPathPrefix(libraryPaths.mkString(File.pathSeparator),

sparkConf))

}

if (sparkConf.get(AM_JAVA_OPTIONS).isDefined) {

logWarning(s"${AM_JAVA_OPTIONS.key} will not take effect in cluster mode")

}

} else {

// Validate and include yarn am specific java options in yarn-client mode.

sparkConf.get(AM_JAVA_OPTIONS).foreach { opts =>

if (opts.contains("-Dspark")) {

val msg = s"${AM_JAVA_OPTIONS.key} is not allowed to set Spark options (was '$opts')."

throw new SparkException(msg)

}

if (opts.contains("-Xmx")) {

val msg = s"${AM_JAVA_OPTIONS.key} is not allowed to specify max heap memory settings " +

s"(was '$opts'). Use spark.yarn.am.memory instead."

throw new SparkException(msg)

}

javaOpts ++= Utils.splitCommandString(opts)

.map(Utils.substituteAppId(_, this.appId.toString))

.map(YarnSparkHadoopUtil.escapeForShell)

}

sparkConf.get(AM_LIBRARY_PATH).foreach { paths =>

prefixEnv = Some(createLibraryPathPrefix(paths, sparkConf))

}

}


// For log4j2 configuration to reference

javaOpts += ("-Dspark.yarn.app.container.log.dir=" + ApplicationConstants.LOG_DIR_EXPANSION_VAR)


val userClass =

if (isClusterMode) {

Seq("--class", YarnSparkHadoopUtil.escapeForShell(args.userClass))

} else {

Nil

}

val userJar =

if (args.userJar != null) {

Seq("--jar", args.userJar)

} else {

Nil

}

val primaryPyFile =

if (isClusterMode && args.primaryPyFile != null) {

Seq("--primary-py-file", new Path(args.primaryPyFile).getName())

} else {

Nil

}

val primaryRFile =

if (args.primaryRFile != null) {

Seq("--primary-r-file", args.primaryRFile)

} else {

Nil

}

val amClass =

if (isClusterMode) {

Utils.classForName("org.apache.spark.deploy.yarn.ApplicationMaster").getName

} else {

Utils.classForName("org.apache.spark.deploy.yarn.ExecutorLauncher").getName

}

if (args.primaryRFile != null &&

(args.primaryRFile.endsWith(".R") || args.primaryRFile.endsWith(".r"))) {

args.userArgs = ArrayBuffer(args.primaryRFile) ++ args.userArgs

}

val userArgs = args.userArgs.flatMap { arg =>

Seq("--arg", YarnSparkHadoopUtil.escapeForShell(arg))

}

val amArgs =

Seq(amClass) ++ userClass ++ userJar ++ primaryPyFile ++ primaryRFile ++ userArgs ++

Seq("--properties-file",

buildPath(Environment.PWD.$$(), LOCALIZED_CONF_DIR, SPARK_CONF_FILE)) ++

Seq("--dist-cache-conf",

buildPath(Environment.PWD.$$(), LOCALIZED_CONF_DIR, DIST_CACHE_CONF_FILE))

  

// Command for the ApplicationMaster

val commands = prefixEnv ++

Seq(Environment.JAVA_HOME.$$() + "/bin/java", "-server") ++

javaOpts ++ amArgs ++

Seq(

"1>", ApplicationConstants.LOG_DIR_EXPANSION_VAR + "/stdout",

"2>", ApplicationConstants.LOG_DIR_EXPANSION_VAR + "/stderr")

  

// TODO: it would be nicer to just make sure there are no null commands here

val printableCommands = commands.map(s => if (s == null) "null" else s).toList

amContainer.setCommands(printableCommands.asJava)

  

// send the acl settings into YARN to control who has access via YARN interfaces

val securityManager = new SecurityManager(sparkConf)

amContainer.setApplicationACLs(

YarnSparkHadoopUtil.getApplicationAclsForYarn(securityManager).asJava)

setupSecurityToken(amContainer)

setTokenConf(amContainer)

amContainer

}
```
我们看一下这段代码，他其实也是在构建启动的命令。我们重点关注下这几句代码
```scala

val userClass =
if (isClusterMode) {
	Seq("--class", YarnSparkHadoopUtil.escapeForShell(args.userClass))
} else {
	Nil
}

val amClass =
if (isClusterMode) {
	Utils.classForName("org.apache.spark.deploy.yarn.ApplicationMaster").getName
} else {
	Utils.classForName("org.apache.spark.deploy.yarn.ExecutorLauncher").getName
}
```
userClass 用户真实要启动的类，在cluster模式下，从参数中解析。
amClass 启动类，在cluster模式下，为`ApplicationMaster`. 在我们的这个例子中，就会在Yarn中启动一个Application，启动类为`ApplicationMaster`. 接下来我们要看`ApplicationMaster`这个类的代码。
还有一点要注意一下，以上所有的代码都是在本地执行的，也就是在执行submit-shell脚本的这个机器上执行的。后续的操作都是在Yarn集群上执行的

## ApplicationMaster

```scala
def main(args: Array[String]): Unit = {
	SignalUtils.registerLogger(log)
	val amArgs = new ApplicationMasterArguments(args)
	val sparkConf = new SparkConf()
	if (amArgs.propertiesFile != null) {
		Utils.getPropertiesFromFile(amArgs.propertiesFile).foreach { case (k, v) =>
		sparkConf.set(k, v)
	}
}

	// Both cases create a new SparkConf object which reads these configs from system properties.
	sparkConf.getAll.foreach { case (k, v) =>
		sys.props(k) = v
	}

	val yarnConf = new YarnConfiguration(SparkHadoopUtil.newConfiguration(sparkConf))
	master = new ApplicationMaster(amArgs, sparkConf, yarnConf)

	val ugi = sparkConf.get(PRINCIPAL) match {
		case Some(principal) if master.isClusterMode =>
		val originalCreds = UserGroupInformation.getCurrentUser().getCredentials()
		SparkHadoopUtil.get.loginUserFromKeytab(principal, sparkConf.get(KEYTAB).orNull)
		val newUGI = UserGroupInformation.getCurrentUser()
		if (master.appAttemptId == null || master.appAttemptId.getAttemptId > 1) {
			Utils.withContextClassLoader(master.userClassLoader) {
			val credentialManager = new HadoopDelegationTokenManager(sparkConf, yarnConf, null)
			credentialManager.obtainDelegationTokens(originalCreds)
		}
	}

		newUGI.addCredentials(originalCreds)
		newUGI
	case _ =>
		SparkHadoopUtil.get.createSparkUser()
}

ugi.doAs(new PrivilegedExceptionAction[Unit]() {
	override def run(): Unit = System.exit(master.run())
	})
}
```
这段代码的主要逻辑为构建`ApplicationMaster`并调用其`run`方法。根据其返回值做响应。
```scala
final def run(): Int = {
	try {
		val attemptID = if (isClusterMode) {
		} else {
			None
		}
		new CallerContext("APPMASTER", sparkConf.get(APP_CALLER_CONTEXT),
			Option(appAttemptId.getApplicationId.toString), attemptID).setCurrentContext()
		
		logInfo("ApplicationAttemptId: " + appAttemptId)
		val stagingDirPath = new Path(System.getenv("SPARK_YARN_STAGING_DIR"))
		val stagingDirFs = stagingDirPath.getFileSystem(yarnConf)
		val priority = ShutdownHookManager.SPARK_CONTEXT_SHUTDOWN_PRIORITY - 1
		ShutdownHookManager.addShutdownHook(priority) { () =>
			...
		}
	
		if (isClusterMode) {
			runDriver()
		} else {
			runExecutorLauncher()
		}
	} catch {
		case e: Exception =>
		logError("Uncaught exception: ", e)
		finish(FinalApplicationStatus.FAILEDApplicationMaster.EXIT_UNCAUGHT_EXCEPTION,"Uncaught exception: " + StringUtils.stringifyException(e))
	} finally {
		try {
			metricsSystem.foreach { ms =>
				ms.report()
				ms.stop()
			}
		} catch {
		case e: Exception =>
		logWarning("Exception during stopping of the metric system: ", e)
		}
	}
	exitCode
}





private def runDriver(): Unit = {

addAmIpFilter(None, System.getenv(ApplicationConstants.APPLICATION_WEB_PROXY_BASE_ENV))

userClassThread = startUserApplication()

  

// This a bit hacky, but we need to wait until the spark.driver.port property has

// been set by the Thread executing the user class.

logInfo("Waiting for spark context initialization...")

val totalWaitTime = sparkConf.get(AM_MAX_WAIT_TIME)

try {

val sc = ThreadUtils.awaitResult(sparkContextPromise.future,

Duration(totalWaitTime, TimeUnit.MILLISECONDS))

if (sc != null) {

val rpcEnv = sc.env.rpcEnv

  

val userConf = sc.getConf

val host = userConf.get(DRIVER_HOST_ADDRESS)

val port = userConf.get(DRIVER_PORT)

registerAM(host, port, userConf, sc.ui.map(_.webUrl), appAttemptId)

  

val driverRef = rpcEnv.setupEndpointRef(

RpcAddress(host, port),

YarnSchedulerBackend.ENDPOINT_NAME)

createAllocator(driverRef, userConf, rpcEnv, appAttemptId, distCacheConf)

} else {

// Sanity check; should never happen in normal operation, since sc should only be null

// if the user app did not create a SparkContext.

throw new IllegalStateException("User did not initialize spark context!")

}

resumeDriver()

userClassThread.join()

} catch {

case e: SparkException if e.getCause().isInstanceOf[TimeoutException] =>

logError(

s"SparkContext did not initialize after waiting for $totalWaitTime ms. " +

"Please check earlier log output for errors. Failing the application.")

finish(FinalApplicationStatus.FAILED,

ApplicationMaster.EXIT_SC_NOT_INITED,

"Timed out waiting for SparkContext.")

} finally {

resumeDriver()

}

}


private def startUserApplication(): Thread = {  
logInfo("Starting the user application in a separate Thread")  
  
var userArgs = args.userArgs  
if (args.primaryPyFile != null && args.primaryPyFile.endsWith(".py")) {  
// When running pyspark, the app is run using PythonRunner. The second argument is the list  
// of files to add to PYTHONPATH, which Client.scala already handles, so it's empty.  
userArgs = Seq(args.primaryPyFile, "") ++ userArgs  
}  
if (args.primaryRFile != null &&  
(args.primaryRFile.endsWith(".R") || args.primaryRFile.endsWith(".r"))) {  
// TODO(davies): add R dependencies here  
}  
  
val mainMethod = userClassLoader.loadClass(args.userClass)  
.getMethod("main", classOf[Array[String]])  
  
val userThread = new Thread {  
override def run(): Unit = {  
try {  
if (!Modifier.isStatic(mainMethod.getModifiers)) {  
logError(s"Could not find static main method in object ${args.userClass}")  
finish(FinalApplicationStatus.FAILED, ApplicationMaster.EXIT_EXCEPTION_USER_CLASS)  
} else {  
mainMethod.invoke(null, userArgs.toArray)  
finish(FinalApplicationStatus.SUCCEEDED, ApplicationMaster.EXIT_SUCCESS)  
logDebug("Done running user class")  
}  
} catch {  
case e: InvocationTargetException =>  
e.getCause match {  
case _: InterruptedException =>  
// Reporter thread can interrupt to stop user class  
case SparkUserAppException(exitCode) =>  
val msg = s"User application exited with status $exitCode"  
logError(msg)  
finish(FinalApplicationStatus.FAILED, exitCode, msg)  
case cause: Throwable =>  
logError("User class threw exception: ", cause)  
finish(FinalApplicationStatus.FAILED,  
ApplicationMaster.EXIT_EXCEPTION_USER_CLASS,  
"User class threw exception: " + StringUtils.stringifyException(cause))  
}  
sparkContextPromise.tryFailure(e.getCause())  
} finally {  
// Notify the thread waiting for the SparkContext, in case the application did not  
// instantiate one. This will do nothing when the user code instantiates a SparkContext  
// (with the correct master), or when the user code throws an exception (due to the  
// tryFailure above).  
sparkContextPromise.trySuccess(null)  
}  
}  
}  
userThread.setContextClassLoader(userClassLoader)  
userThread.setName("Driver")  
userThread.start()  
userThread  
}

```

在`ApplicationMaster`的`run`方法中，我们可以看到它做了这样几件事：构建上下文，添加钩子函数， 在我们这个例子中调用`runDriver`方法。
在`runDriver`方法中，我们可以看到上面就会调用`startUserApplication`这个方法，从这个函数名称我们也可以看到，这里才真正调用到了用户程序，使用反射调用到了用户的程序，在用户的程序中会做SparkContext的初始化，如果用户的主程序没有做SparkContext的初始化，在`runDriver`中也会进行检测，从而抛出异常。用户程序是新启动一个线程来运行，主程序会等待用户程序结束。

## JavaWordCount
我们再来看下我们的这个example程序。
```java
public static void main(String[] args) throws Exception {  
  
if (args.length < 1) {  
System.err.println("Usage: JavaWordCount <file>");  
System.exit(1);  
}  
  
SparkSession spark = SparkSession  
.builder()  
.appName("JavaWordCount")  
.getOrCreate();  
  
JavaRDD<String> lines = spark.read().textFile(args[0]).javaRDD();  
  
JavaRDD<String> words = lines.flatMap(s -> Arrays.asList(SPACE.split(s)).iterator());  
  
JavaPairRDD<String, Integer> ones = words.mapToPair(s -> new Tuple2<>(s, 1));  
  
JavaPairRDD<String, Integer> counts = ones.reduceByKey((i1, i2) -> i1 + i2);  
  
List<Tuple2<String, Integer>> output = counts.collect();  
for (Tuple2<?,?> tuple : output) {  
System.out.println(tuple._1() + ": " + tuple._2());  
}  
spark.stop();  
}
```
在这里初始化了SparkSession，然后从文件读取，转化，然后调用`collect`算子后打印结果。
最终关闭SparkSession。
```scala
def collect(): Array[T] = withScope {  
val results = sc.runJob(this, (iter: Iterator[T]) => iter.toArray)  
Array.concat(results: _*)  
}
```
在这个例子中，是最后的collect这个action算子，最终调用了`runJob`。
到这里就完成了整个任务的部署。

总结一下：
当我们执行`spark-submit.sh`时，会先执行`SparkSubmit`然后根据`master`和`deploy-mode`启动不同的提交类。如果是local mode则直接启动用户的主类，否则启动不同集群模式的类。
在集群提交类中，此例中为`YarnClusterApplication`. 在这个类中做的事情是在Yarn集群上启动一个Application也就是`ApplicationMaster`，这个Application启动后会在一个新线程启动user application。user application也就是我们任务的主类。

# SparkLauncher
Spark还提供了一种方式，可以将提交任务集成到Java代码中。用户可以使用一个Service来集中化做任务提交，可以方便的管理集群中提交的任务数量等等。

```java
SparkLauncher launcher = new SparkLauncher();
launcher.setMaster(“yarn”);
launcher.setDeployMode(“cluster”);
launcher.setMainClass(“...”);
launcher.setAppResource(“...”);
launcher.addAppArgs(“...”);
...
SparkAppHandle.Listener listener = new SparkAppHandle.Listener(){...}
launcher.startApplication(listener);
```
我们可以以一个大概这样的代码就可以提交并启动一个Spark任务。并且添加了Listener，可以对任务的状态进行感知。
我们来看一下这个的具体实现：
```java
public SparkAppHandle startApplication(SparkAppHandle.Listener... listeners) throws IOException {  
LauncherServer server = LauncherServer.getOrCreateServer();  
ChildProcAppHandle handle = new ChildProcAppHandle(server);  
for (SparkAppHandle.Listener l : listeners) {  
handle.addListener(l);  
}  
  
String secret = server.registerHandle(handle);  
  
String loggerName = getLoggerName();  
ProcessBuilder pb = createBuilder();  
if (LOG.isLoggable(Level.FINE)) {  
LOG.fine(String.format("Launching Spark application:%n%s", join(" ", pb.command())));  
}  
  
boolean outputToLog = outputStream == null;  
boolean errorToLog = !redirectErrorStream && errorStream == null;  
  
// Only setup stderr + stdout to logger redirection if user has not otherwise configured output  
// redirection.  
if (loggerName == null && (outputToLog || errorToLog)) {  
String appName;  
if (builder.appName != null) {  
appName = builder.appName;  
} else if (builder.mainClass != null) {  
int dot = builder.mainClass.lastIndexOf(".");  
if (dot >= 0 && dot < builder.mainClass.length() - 1) {  
appName = builder.mainClass.substring(dot + 1, builder.mainClass.length());  
} else {  
appName = builder.mainClass;  
}  
} else if (builder.appResource != null) {  
appName = new File(builder.appResource).getName();  
} else {  
appName = String.valueOf(COUNTER.incrementAndGet());  
}  
String loggerPrefix = getClass().getPackage().getName();  
loggerName = String.format("%s.app.%s", loggerPrefix, appName);  
}  
  
if (outputToLog && errorToLog) {  
pb.redirectErrorStream(true);  
}  
  
pb.environment().put(LauncherProtocol.ENV_LAUNCHER_PORT, String.valueOf(server.getPort()));  
pb.environment().put(LauncherProtocol.ENV_LAUNCHER_SECRET, secret);  
try {  
Process child = pb.start();  
InputStream logStream = null;  
if (loggerName != null) {  
logStream = outputToLog ? child.getInputStream() : child.getErrorStream();  
}  
handle.setChildProc(child, loggerName, logStream);  
} catch (IOException ioe) {  
handle.kill();  
throw ioe;  
}  
  
return handle;  
}
```
这段代码中的主要逻辑是调用了`ProcessBuilder.start()`方法，我们先看一下这个`ProcessBuilder`创建逻辑：
```java
private ProcessBuilder createBuilder() throws IOException {  
List<String> cmd = new ArrayList<>();  
cmd.add(findSparkSubmit());  
cmd.addAll(builder.buildSparkSubmitArgs());  
  
// Since the child process is a batch script, let's quote things so that special characters are  
// preserved, otherwise the batch interpreter will mess up the arguments. Batch scripts are  
// weird.  
if (isWindows()) {  
List<String> winCmd = new ArrayList<>();  
for (String arg : cmd) {  
winCmd.add(quoteForBatchScript(arg));  
}  
cmd = winCmd;  
}  
  
ProcessBuilder pb = new ProcessBuilder(cmd.toArray(new String[cmd.size()]));  
for (Map.Entry<String, String> e : builder.childEnv.entrySet()) {  
pb.environment().put(e.getKey(), e.getValue());  
}  
  
if (workingDir != null) {  
pb.directory(workingDir);  
}  
  
// Only one of redirectError and redirectError(...) can be specified.  
// Similarly, if redirectToLog is specified, no other redirections should be specified.  
checkState(!redirectErrorStream || errorStream == null,  
"Cannot specify both redirectError() and redirectError(...) ");  
checkState(getLoggerName() == null ||  
((!redirectErrorStream && errorStream == null) || outputStream == null),  
"Cannot used redirectToLog() in conjunction with other redirection methods.");  
  
if (redirectErrorStream) {  
pb.redirectErrorStream(true);  
}  
if (errorStream != null) {  
pb.redirectError(errorStream);  
}  
if (outputStream != null) {  
pb.redirectOutput(outputStream);  
}  
  
return pb;  
}
```
通过这段代码可以看出它其实也是在构建一段`spark-submit`命令。
通过`ProcessBuilder`构建并运行`spark-submit`命令，然后将其作为子进程进行监控。



