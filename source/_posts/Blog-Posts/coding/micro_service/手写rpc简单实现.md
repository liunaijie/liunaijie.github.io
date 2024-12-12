---
title: 手写rpc简单实现
date: 2019-07-26
categories:
  - notes
tags:
  - RPC
---

# 背景

当单体项目逐渐扩大后，一个项目编译，发布可能需要很久的时间，如果其中一个文件出现 bug，那么需要对整个项目进行打包发布。微服务就是对项目进行拆分，拆分成多个小项目，由这些小项目组成大项目。并且拆分成小项目后，其他单体项目中需要相同功能的地方就不用再次编写，直接用这个就可以了。有种`分治`的思想。

那么原来单体项目拆分后，随之而来就会出现一些问题。原来一个项目中直接调用即可，现在请求的类被拆分到其他项目中，如何进行请求，是采用 http 这种请求还是rpc？多个模块如果进行管理等等一系列问题。这里主要写一下 rpc 的理解。

在微服务中rpc又是重要的一环，现在主流的rpc框架有很多，比如阿里的`dubbo`，微博的`Motan`,谷歌的`gRpc`，还有`Thrift`，现在主流的应该就这几种吧。按照文档学习了一下`dubbo`如何使用后，发现并没有了解rpc是如何具体实现的。所以这篇文章记录了自己对rpc的一些理解与实战代码。  

[代码链接](https://github.com/liunaijie/learn-demo/tree/master/learn-demo-rpc)

# HTTP 与 RPC 的对比

其实就像一些技术一样，没有绝对好的技术，不然大家都去使用它了。都只是在不同场景下有各自的优势。

- rpc一般是自带负载均衡策略，而 http 一般是通过 nginx 这种来实现负载均衡
- rpc可以使用 tcp 协议也可以使用 http 协议，而 http 就只能使用 http 协议
- rpc可以自定义传输信息和序列化方法，减少传输报文大小。

所以RPC主要用于公司内部的服务调用。HTTP主要用于对外的环境，浏览器接口调用，APP接口调用，第三方接口调用等。

# RPC的主要实现步骤

![RPC调用流程](https://raw.githubusercontent.com/liunaijie/images/master/RPC调用.png)

<!--more-->

# 各个模块的作用

-   封装rpc请求

    我们在调用其他代码的时候要让别人知道我们调用的是什么类的什么方法，传递了什么参数等信息。所以我们需要将这些信息进行封装起来，然后进行传输。

-   序列化与反序列化

    这个主要是传输数据的大小和跨语言的实现，不同的序列化方式会导致我们在网络传输中传输大小不同的信息，所以这个也是影响性能的一部分    

    跨语言：这个就像我们说话的方言一样，我们说的方言怎么能让其他人听懂呢，那我们就都说普通话吧，这样大家就比较好理解你的意思了。在编程语言的世界里，`java`说的话怎么能让`go`,`php`等语言听懂呢？我们就定一个协议吧，大家都遵守这个协议，就能明白干什么了，所以`gRpc`和`Thrift`就使用了这种的序列化规则。那么有人就说了，既然能使用`*普通话*`这个标准，为什么其他的框架不用呢？其实这就看公司使用的技术了，如果各个部门都使用的是同一种技术框架，也没有发展其他语言的项目（都是一个地方的人说同一种方言），就没有必要非去弄`*普通话*`了。

-   网络传输

    序列化完成的数据在网络进行传输，比如现在大部分都在使用的`netty`技术。

-   负载均衡

    消费者从注册中心（如果有）获取生产者的ip地址要进行通信了，但是这些生产者的性能可能不一样，我们可以对性能好的多访问几次，性能差的少访问几次。最简单的方式就是轮询，有几个生产者就轮着来，这个基本上都是针对自己公司情况来实现。

-   动态代理

    在消费者调用生产者时，我们只需调用接口就能接收到返回信息，那么什么时候封装rpc请求了呢，怎么从注册中心找的节点信息等。这里就用到了aop的原理。并且我们不可能仅仅调用一个方法，如果使用静态代理，那么我们有多少个类就要有多个的代理，并且框架也不知道我们会有什么类，所以就需要使用动态代理。动态代理的作用主要是：**在不改变目标对象方法的情况下对方法进行增强**

-   反射

    动态代理其实也是基于反射实现的，常见的动态代理有：**JDK动态代理**，**Cglib**。  

    jdk动态代理就是基于反射机制实现的。这些东西我也没有具体去理解去看这一块，我想应该是类似这样的：并不清楚调用的具体类是什么，使用一个`Object`类型来接收，只有当你真正调用的时候才知道这个类是`student`还是`teacher`，知道了之后再去调用。

# 项目模块

这里在网络传输使用`bio`的方式，序列化就使用`java`默认的序列化方式。

```
learn-demo-rpc
├── bio-socket
├── nio-socket
├── simple-api
├── rpc-common
├── simple-rpc
	├── simple-rpc-consumer
	├── simple-rpc-provider
	└── simple-rpc-core
└── zookeeper-register-rpc
	├── zookeeper-register-consumer
	├── zookeeper-register-provider
	└── zookeeper-register-core
```

*   bio-socket 以bio的方式实现生产者与消费者之间的通信模块
*   nio-socket 以nio的方式实现生产者与消费者之间的通信模块
*   simple-api 是定义的公共接口模块
*   rpc-common 对rpc请求和响应包装的一些实体类
*   simple-rpc 无注册中心的简单rpc调用实现
*   Zookeeper-register-rpc 通过zookeeper注册中心的rpc调用实现
    1.  -core 是核心实现模块
    2.  -provider 是生产者的实现模块
    3.  -consumer 是消费者的调用模块

# 定义接口模块和对应请求响应的包装类

## 接口模块

这个模块就比较简单了，写个接口，写个方法就可以了

```java
public interface ISayHello {

	String sayHello(String name);

}
```

## 包装请求和响应信息

这里就要考虑了，我们如果调用一个方法，需要知道一些什么东西才能调用呢。我们在本地调用一个的时候是这样调用的`ClassA.methodB(paramC,paramD)`，那现在我们知道了classA，所以其他的就是下面这几个了：方法名，参数类型，参数。  

返回信息的时候需要返回一些什么信息呢。首先肯定有个请求方法的返回值，其他的还需要什么呢，参考了一下网络调用的返回信息，我又添加了状态码，提示信息这两个字段。  

然后序列化方式就用默认的方式即可，实现个接口然后定义id就可以了。  

### 请求信息

```java
public class RpcRequest implements Serializable {

	private static final long serialVersionUID = 5837872617706737632L;

	/**
	 * 方法名称
	 */
	private String methodName;

	/**
	 * 参数列表
	 */
	private Object[] parameters;

	/**
	 * 参数类型
	 */
	private Class<?>[] parameterTypes;

	public String getMethodName() {
		return methodName;
	}

	public RpcRequest setMethodName(String methodName) {
		this.methodName = methodName;
		return this;
	}

	public Object[] getParameters() {
		return parameters;
	}

	public RpcRequest setParameters(Object[] parameters) {
		this.parameters = parameters;
		return this;
	}

	public Class<?>[] getParameterTypes() {
		return parameterTypes;
	}

	public RpcRequest setParameterTypes(Class<?>[] parameterTypes) {
		this.parameterTypes = parameterTypes;
		return this;
	}

	@Override
	public String toString() {
		return "RpcRequest{" +
				"methodName='" + methodName + '\'' +
				", parameters=" + Arrays.toString(parameters) +
				", parameterTypes=" + Arrays.toString(parameterTypes) +
				'}';
	}

}

```

### 响应信息

```java
public class RpcResponse implements Serializable {

	private static final long serialVersionUID = -4129585144798112980L;

	/**
	 * 请求成功的响应码
	 */
	public static int SUCCEED = 200;
	/**
	 * 请求失败的响应码
	 */
	public static int FAILED = 500;

	/**
	 * 响应状态，默认就是成功的
	 */
	private int status = 200;
	/**
	 * 响应信息，如异常信息
	 */
	private String message;

	/**
	 * 响应数据，返回值
	 */
	private Object data;


	public int getStatus() {
		return status;
	}

	public RpcResponse setStatus(int status) {
		this.status = status;
		return this;
	}

	public String getMessage() {
		return message;
	}

	public RpcResponse setMessage(String message) {
		this.message = message;
		return this;
	}

	public Object getData() {
		return data;
	}

	public RpcResponse setData(Object data) {
		this.data = data;
		return this;
	}

	@Override
	public String toString() {
		return "RpcResponse{" +
				"status='" + status + '\'' +
				", message='" + message + '\'' +
				", data=" + data +
				'}';
	}

}

```

# 定义bio的socket通信模块

也试过使用nio的方式，但是返回信息在子线程里面返回了，需要使用线程通知机制，后面研究后会再更新。

## 服务端代码

提供了一个开启服务端的方法，传入端口，请求的类名和实现类即可  

收到客户端发送的消息后先将其转换为对象，判断客户端发送的信息是不是我们包装好的rpc请求信息，如果是rpc请求那么我们再进行处理，并将结果进行返回

```java
public class BioServer<T> {

	private static final Logger log = LoggerFactory.getLogger(BioServer.class);

	public void export(int port, Class<?> interfaceClass, T ref) {
		try {
			log.info(" bio rpc server is starting,address:{},port:{} ", InetAddress.getLocalHost().getHostAddress(), port);

			ServerSocket serverSocket = new ServerSocket(port);

			while (true) {
				// 获取客户端的连接
				Socket client = serverSocket.accept();

				// 获取客户端发送的数据
				ObjectInputStream objectInputStream = new ObjectInputStream(client.getInputStream());

				Object object = objectInputStream.readObject();

				if (object instanceof RpcRequest) {
					RpcRequest request = (RpcRequest) object;
					log.info("bio rpc server get the client request:{}", request);
					// 处理请求
					RpcResponse response = handleRequest(request, interfaceClass, ref);
					//将请求结果返回客户端
					ObjectOutputStream objectOutputStream = new ObjectOutputStream(client.getOutputStream());
					objectOutputStream.writeObject(response);
				}

			}
		} catch (Exception e) {
			log.error("bio rpc server start failed:{}", e.toString());
		}
	}

	/**
	 * 处理请求
	 *
	 * @param request        rpc请求包装类
	 * @param interfaceClass 接口类
	 * @param ref            实现类
	 * @return
	 */
	public RpcResponse handleRequest(RpcRequest request, Class<?> interfaceClass, T ref) {
		RpcResponse response = new RpcResponse();
		try {
			Method method = interfaceClass.getMethod(request.getMethodName(), request.getParameterTypes());
			Object data = method.invoke(ref, request.getParameters());
			response.setData(data);
		} catch (Exception e) {
			response.setStatus(RpcResponse.FAILED).setMessage(e.getMessage());
		}
		return response;
	}

}
```

## 客户端代码

客户端的调用在设置好服务端的ip和端口后就可以直接发送数据了，发送的数据格式也是我们进行封装过的，返回信息格式也是我们进行封装完成的。

```java
public class BioClient {

	private static final Logger log = LoggerFactory.getLogger(BioClient.class);

	private String address;

	private int port;

	public String getAddress() {
		return address;
	}

	public void setAddress(String address) {
		this.address = address;
	}

	public int getPort() {
		return port;
	}

	public void setPort(int port) {
		this.port = port;
	}

	public RpcResponse send(RpcRequest rpcRequest) {
		try {
			Socket socket = new Socket(address, port);
			// 发送rpc请求
			ObjectOutputStream objectOutputStream = new ObjectOutputStream(socket.getOutputStream());
			objectOutputStream.writeObject(rpcRequest);

			// 接收响应
			ObjectInputStream objectInputStream = new ObjectInputStream(socket.getInputStream());
			Object object = objectInputStream.readObject();
			if (object instanceof RpcResponse) {
				return (RpcResponse) object;
			}
		} catch (Exception e) {
			log.error("the rpc client start failed:{}", e.toString());
		}
		return null;
	}

}
```

# 无注册中心的简单rpc调用

## 核心实现

### 生产者：

```java
	private static final Logger log = LoggerFactory.getLogger(RpcProvider.class);

	/**
	 * 接口类
	 */
	private Class<?> interfaceClass;

	/**
	 * 具体实现类
	 */
	private T interfaceImpl;

	public void setInterfaceImpl(T ref) {
		this.interfaceImpl = ref;
	}

	public RpcProvider<T> setInterfaceClass(Class<?> interfaceClass) {
		this.interfaceClass = interfaceClass;
		return this;
	}

	public void export(int port) {
		BioServer bioServer = new BioServer();
		bioServer.export(port, interfaceClass, interfaceImpl);
	}

}
```

### 消费者

```java
public class RpcConsumer {

	private String address;

	private int port;

	private Class<?> interfaceClass;

	public RpcConsumer setAddress(String address) {
		this.address = address;
		return this;
	}

	public RpcConsumer setPort(int port) {
		this.port = port;
		return this;
	}

	public RpcConsumer setInterface(Class<?> interfaceClass) {
		this.interfaceClass = interfaceClass;
		return this;
	}

	public <T> T get() {
		BioClient client = new BioClient();
		client.setAddress(address);
		client.setPort(port);
		// 实例化RPC代理处理器
		RpcInvocationHandler handler = new RpcInvocationHandler(client);
		return (T) Proxy.newProxyInstance(interfaceClass.getClassLoader(), new Class[]{interfaceClass}, handler);
	}

}

```

### 代理类：

```java
public class RpcInvocationHandler implements InvocationHandler {

	private BioClient bioClient;

	public RpcInvocationHandler(BioClient bioClient) {
		this.bioClient = bioClient;
	}


	@Override
	public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
		//构建rpc请求对象
		RpcRequest rpcRequest = new RpcRequest();
		rpcRequest.setMethodName(method.getName())
				.setParameterTypes(method.getParameterTypes())
				.setParameters(args);
		//发送请求
		RpcResponse rpcResponse = bioClient.send(rpcRequest);
		// 返回响应结果
		if (RpcResponse.SUCCEED == rpcResponse.getStatus()) {
			return rpcResponse.getData();
		}
		throw new RuntimeException(rpcResponse.getMessage());
	}


}

```

## 生产者

### 实现接口

```java
public class SimpleRpcProviderImpl implements ISayHello {

	@Override
	public String sayHello(String name) {
		return "hello," + name + "\n I am simple rpc provider.";
	}

}
```

### 调用类

```java
public class SimpleRpcBioProvider {

	public static void main(String[] args) {
		// 初始化实现类
		SimpleRpcProviderImpl simpleRpcProvider = new SimpleRpcProviderImpl();

		//初始化rpc请求类
		RpcProvider<ISayHello> provider = new RpcProvider<>();
		// 设置 接口类 和 具体实现类
		provider.setInterfaceClass(ISayHello.class)
				.setInterfaceImpl(simpleRpcProvider);
		// 设置通信端口
		provider.export(9090);
	}

}

```

## 消费者

### 调用类

```java
public class SimpleRpcBioConsumer {

	public static void main(String[] args) {
		// 初始化消费者对象并设置参数
		RpcConsumer rpcConsumer = new RpcConsumer();
		rpcConsumer.setAddress("127.0.0.1")
				.setPort(9090)
				// 设置请求消费的接口
				.setInterface(ISayHello.class);

		ISayHello iSayHello = rpcConsumer.get();
		System.out.println(iSayHello.sayHello("niki"));
	}

}

```

这样就实现了一个简单的rpc调用。

# 使用zookeeper作为注册中心的简单实现

使用zookeeper后主要添加的东西是：

-   生产者启动后向注册中心注册
-   消费者调用时先向注册中心请求节点信息（没有加缓存）
-   负载就使用随机访问。

## 核心实现

### 生产者

定义了几个参数，主要是实现类，接口类，注册中心的类。  

定义了启动`bio socket`通信的方法。

```java
public class RpcProvider<T> {

	private static final Logger log = LoggerFactory.getLogger(RpcProvider.class);

	private T interfaceImpl;

	private Class<?> interfaceClass;

	private RpcZKRegistryService rpcZKRegistryService;

	public void setInterfaceImpl(T interfaceImpl) {
		this.interfaceImpl = interfaceImpl;
	}

	public RpcProvider<T> setInterfaceClass(Class<?> interfaceClass) {
		this.interfaceClass = interfaceClass;
		return this;
	}

	public RpcProvider<T> setRpcZKRegistryService(String zkConnectString) {
		this.rpcZKRegistryService = new RpcZKRegistryService(zkConnectString);
		return this;
	}

	public void export(int port) {
		ProviderInfo providerInfo = new ProviderInfo();
		try {
			providerInfo.setAddress(InetAddress.getLocalHost().getHostAddress())
					.setPort(port)
					.setId(interfaceClass.getName());
			// 将生产者信息注册到zk注册中心
			rpcZKRegistryService.register(providerInfo);
			BioServer bioServer = new BioServer();
			bioServer.export(port, interfaceClass, interfaceImpl);
		} catch (Exception e) {
			log.error(" zookeeper server start failed:{}", e.toString());
		}
	}

}
```

### 消费者

定义了要请求的接口类，注册中心的调用类   

定义了请求，获取节点，负载等方法。

```java
public class RpcConsumer {

	private String azConnectString;

	/**
	 * 请求的接口类
	 */
	private Class<?> interfaceClass;

	private RpcZKRegistryService rpcZKRegistryService;

	public RpcConsumer setZKConnectString(String zkConnectString) {
		this.rpcZKRegistryService = new RpcZKRegistryService(zkConnectString);
		return this;
	}

	public RpcConsumer setInterface(Class<?> interfaceClass) {
		this.interfaceClass = interfaceClass;
		return this;
	}

	public <T> T get() {
		List<ProviderInfo> providers = getProviders();
		ProviderInfo provider = chooseTarget(providers);
		BioClient bioClient = new BioClient();
		bioClient.setAddress(provider.getAddress());
		bioClient.setPort(provider.getPort());
		RpcInvocationHandler handler = new RpcInvocationHandler(bioClient);
		return (T) Proxy.newProxyInstance(interfaceClass.getClassLoader(), new Class[]{interfaceClass}, handler);
	}

	/**
	 * 获取所有的生产者信息
	 *
	 * @return
	 */
	private List<ProviderInfo> getProviders() {
		//订阅服务
		rpcZKRegistryService.subscribe(interfaceClass.getName());
		//获取所有的生产者信息
		Map<String, ProviderInfo> providers = rpcZKRegistryService.getRemoteProviders();
		return new ArrayList<>(providers.values());
	}

	/**
	 * 模拟负载均衡
	 *
	 * @param providerInfos 生产者列表
	 * @return
	 */
	private static ProviderInfo chooseTarget(List<ProviderInfo> providerInfos) {
		if (providerInfos == null || providerInfos.isEmpty()) {
			throw new RuntimeException("providers is empty");
		}
		int index = new Random().nextInt(providerInfos.size());
		return providerInfos.get(index);
	}

}
```

#### 代理类

```java
public class RpcInvocationHandler implements InvocationHandler {

	private BioClient bioClient;

	public RpcInvocationHandler(BioClient bioClient) {
		this.bioClient = bioClient;
	}

	@Override
	public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
		//构建请求对象
		RpcRequest rpcRequest = new RpcRequest();
		rpcRequest.setMethodName(method.getName())
				.setParameterTypes(method.getParameterTypes())
				.setParameters(args);
		//发送rpc请求
		RpcResponse rpcResponse = bioClient.send(rpcRequest);
		if (RpcResponse.SUCCEED == rpcResponse.getStatus()) {
			return rpcResponse.getData();
		}
		throw new RuntimeException(rpcResponse.getMessage());
	}
}
```

### 注册中心

每个节点的信息

```java
public class ProviderInfo {

	/**
	 * 提供者id
	 */
	private String id;

	/**
	 * 提供者的地址
	 */
	private String address;

	/**
	 * 提供者的端口
	 */
	private int port;

	public String getId() {
		return id;
	}

	public ProviderInfo setId(String id) {
		this.id = id;
		return this;
	}

	public String getAddress() {
		return address;
	}

	public ProviderInfo setAddress(String address) {
		this.address = address;
		return this;
	}

	public int getPort() {
		return port;
	}

	public ProviderInfo setPort(int port) {
		this.port = port;
		return this;
	}

	public String toJsonString() {
		return JSON.toJSONString(this);
	}

	@Override
	public String toString() {
		return "ProviderInfo{" +
				"id='" + id + '\'' +
				", address='" + address + '\'' +
				", port=" + port +
				'}';
	}
}
```

java调用zk的类

```java
public class RpcZKRegistryService {

	private static final Logger log = LoggerFactory.getLogger(RpcZKRegistryService.class);

	/**
	 * 注册的名称
	 */
	private static final String NAME_SPACE = "zk-rpc";
	/**
	 * 节点信息
	 */
	private static final String RPC_PROVIDER_NODE = "/provider";
	/**
	 * 保存多个生产者信息
	 */
	private final Map<String, ProviderInfo> remoteProviders = new HashMap<>();
	/**
	 * 客户端
	 */
	private CuratorFramework zkClient;

	public RpcZKRegistryService(String zkConnectString) {
		// 设置重试次数和两次重试间隔时间
		RetryPolicy retryPolicy = new RetryNTimes(3, 5000);
		//获取客户端
		this.zkClient = CuratorFrameworkFactory.builder()
				.connectString(zkConnectString)
				.sessionTimeoutMs(10000)
				.retryPolicy(retryPolicy)
				.namespace(NAME_SPACE)
				.build();
		this.zkClient.start();
	}

	/**
	 * 注册服务
	 *
	 * @param providerInfo 生产者的信息
	 */
	public void register(ProviderInfo providerInfo) {
		String nodePath = RPC_PROVIDER_NODE + "/" + providerInfo.getId();
		try {
			// 判断节点是否存在，如果不存在则创建
			Stat stat = zkClient.checkExists().forPath(nodePath);
			if (stat == null) {
				zkClient.create()
						.creatingParentsIfNeeded()
						.withMode(CreateMode.EPHEMERAL_SEQUENTIAL)
						.withACL(ZooDefs.Ids.OPEN_ACL_UNSAFE)
						.forPath(nodePath, providerInfo.toJsonString().getBytes());
			} else {
				log.error(" thr provider already exists,{} ", providerInfo);
			}
		} catch (Exception e) {
			log.error("zookeeper register provider failed,{}", e.toString());
		}
	}

	/**
	 * 订阅服务
	 *
	 * @param id 生产者的id或者接口名称
	 */
	public void subscribe(String id) {
		try {
			List<String> providerIds = zkClient.getChildren().forPath(RPC_PROVIDER_NODE);
			for (String providerId : providerIds) {
				//如果与订阅服务相同，则获取节点信息
				if (providerId.contains(id)) {
					String nodePath = RPC_PROVIDER_NODE + "/" + providerId;
					byte[] data = zkClient.getData().forPath(nodePath);
					ProviderInfo providerInfo = JSON.parseObject(data, ProviderInfo.class);
					this.remoteProviders.put(providerId, providerInfo);
				}
			}
			//添加监听事件
			addProviderWatch(id);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	public void addProviderWatch(String id) {
		try {
			//创建子节点缓存
			final PathChildrenCache childrenCache = new PathChildrenCache(this.zkClient, RPC_PROVIDER_NODE, true);
			childrenCache.start(PathChildrenCache.StartMode.BUILD_INITIAL_CACHE);
			//添加子节点监听事件
			childrenCache.getListenable().addListener((client, event) -> {
				String nodePath = event.getData().getPath();
				if (nodePath.contains(id)) {
					if (event.getType().equals(PathChildrenCacheEvent.Type.CHILD_REMOVED)) {
						//节点移除
						this.remoteProviders.remove(nodePath);
					} else if (event.getType().equals(PathChildrenCacheEvent.Type.CHILD_ADDED)) {
						byte[] data = event.getData().getData();
						ProviderInfo providerInfo = JSON.parseObject(data, ProviderInfo.class);
						//添加节点
						this.remoteProviders.put(nodePath, providerInfo);
					}
				}
			});
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	/**
	 * 获取节点列表
	 *
	 * @return
	 */
	public Map<String, ProviderInfo> getRemoteProviders() {
		return remoteProviders;
	}
}

```



## 生产者

### 实现接口

```java
public class ZkProviderImpl implements ISayHello {
	@Override
	public String sayHello(String name) {
		return "hello " + name + "\n i am zookeeper provider";
	}
}
```

### 调用类

通过传入调用的类，zk的地址，实现的类进行注册中心注册。然后启动连接。

```java
public class ZKProvider {

	public static void main(String[] args) {
		ZkProviderImpl zkProviderImpl = new ZkProviderImpl();
		RpcProvider<ISayHello> provider = new RpcProvider<>();
		provider.setInterfaceClass(ISayHello.class)
				.setRpcZKRegistryService("localhost:2181")
				.setInterfaceImpl(zkProviderImpl);
		provider.export(9090);
	}

}
```



## 消费者

### 调用类

传入zk的地址，接口类。然后调用方法即可。

```java
public class ZKConsumer {

	public static void main(String[] args) {
		RpcConsumer rpcConsumer = new RpcConsumer();
		rpcConsumer.setZKConnectString("localhost:2181");
		rpcConsumer.setInterface(ISayHello.class);
		ISayHello iSayHello = rpcConsumer.get();
		System.out.println(iSayHello.sayHello("zookeeper"));

	}

}
```

