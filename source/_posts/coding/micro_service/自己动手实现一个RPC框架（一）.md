---
title: 自己动手实现一个RPC框架（一）
date: 2020-03-12 09:08:48
categories: 
	- [code, java, rpc]
tags:
	- rpc
---

# 前言

现在微服务体系流行，而RPC框架作为微服务中重要的一环，为了弄明白RPC的整体过程，决定要自己动手实现一个RPC框架。

我们先了解一下什么是RPC，RPC全程是Remote Procedure Call，翻译过来就是远程过程调用，我们先思考一下没有使用rpc的项目的调用流程：

1. 通过`@Autoware`注解注入另外的类
2. 在需要调用的地方直接调用即可

当需要调用其他功能的接口时，比如调用其他公司的接口，或者调用自己公司内部的其他业务或功能接口。这时一般需要使用`http`来进行网络调用。

那么使用http调用其他的功能接口算不算是rpc调用呢？我感觉也是算的，因为这也是一种通过网络从计算机程序上请求服务的过程。

只不过由于调用的功能不严格意义上属于一个大项目，所以不算一个程序直接的内部调用，所以这里只讨论 一个大项目拆分成不同模块后，不同模块直接调用的过程。

RPC是原来一个程序分为多个不同的程序，分别运行在不同的jvm上。部署在多台机器上后，就涉及到网络通信，需要将调用的信息发送到被调用的机器上，调用完成后再进行返回。

rpc的流程图如下所示，

![RPC调用流程](https://raw.githubusercontent.com/liunaijie/images/master/RPC调用.png)

牵扯到网络请求，那么就可以使用之前的`http`请求，但是由于`http`请求需要封装一些对于我们而言无用的信息，所以使用`http`的方式可以采用，比如`springcloud`就采用了`http`来进行通信的方式，而这次我准备使用其他的网络通信方式，这一篇中先使用`bio`来实现网络通信。

还有一个序列化过程，它主要是将信息进行编解码，然后通过网络传输，因为网络传输中都是传输的二进制字节码文件，所以我们需要定义规则，将信息进行转换，消费者发送出去的信息生产者能明白其调用的内容，消费者也能明白生产者返回的信息。这一篇文章中也不去使用复杂的序列化方式，直接实现java中的`Serializable`接口。

<!--more-->

# 定义请求响应

消费者要将信息发送给生产者，发送过去的消息必须要被识别，所以需要定义请求消息类，而生产者调用实现完成后要将信息返回给消费者，所以也需要定义响应消息类。

在这里使用`lombok`来简化编程。

1. 请求消息类

  这个消息需要发送给生产者，生产者需要识别出消费者要调用的类，具体使用哪个类的实现，调用的哪个方法，并且传递的参数。所以我们先这样定义请求类

  ```java
  @Data
  public class RpcRequest implements Serializable {
  
  	private static final long serialVersionUID = -4129585144798112980L;
  
  	/**
  	 * 请求的类
  	 */
  	private Class<?> clazz;
  
  	/**
  	 * 实现类
  	 */
  	private Class<?> implClazz;
  
  	/**
  	 * 方法名称
  	 */
  	private String methodName;
  
  	/**
  	 * 参数类型
  	 */
  	private Class<?>[] parameterTypes;
  
  	/**
  	 * 参数列表
  	 */
  	private Object[] parameters;
  
  
  }
  ```

2. 请求响应类

	响应首要的任务是将生产者的响应信息返回到消费者，并且生产者可能有异常，需要让消费者明确是否请求成功，如果发生异常，错误原因的什么。所以先如下定义响应类。

	```JAVA
	@Data
	public class RpcResponse implements Serializable {
	
		private static final long serialVersionUID = 5837872617706737632L;
	
		public static int SUCCESS_CODE = 200;
		public static String SUCCESS_MESSAGE = "ok";
	
		private int code = SUCCESS_CODE;
	
		private String message = SUCCESS_MESSAGE;
	
		private Object data;
	
	}
	```

# 定义网络传输部分

这里先使用bio来进行简单实现。

## 服务端

这里的服务端就是在rpc请求流程中的生产者，它要做的东西就是启动，监听，处理，返回这几个过程。

```java
@Slf4j
public class BioServer {

	public void export(int port) {
		try {
			ServerSocket serverSocket = new ServerSocket(port);
			log.info("server started!");
			while (true) {
				//监听连接
				Socket client = serverSocket.accept();
				//转换信息
				ObjectInputStream objectInputStream = new ObjectInputStream(client.getInputStream());
				Object object = objectInputStream.readObject();
				if (object instanceof RpcRequest) {
					RpcRequest rpcRequest = (RpcRequest) object;
					log.info("bio server received client:{}", rpcRequest);
					//调用实现方法
					RpcResponse rpcResponse = handleRequest(rpcRequest);
					//将请求结果返回客户端
					ObjectOutputStream objectOutputStream = new ObjectOutputStream(client.getOutputStream());
					objectOutputStream.writeObject(rpcResponse);
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
}
```

在这里，使用`ServerSocket`来启动`socker`服务，然后监听客户端连接，然后将客户端发送的消息进行反序列化成对象，如果客户端发送的是我们定义的`RpcRequest`对象，我们就对它进行处理，然后再将处理结果返回到客户端。

看一下对请求实际处理的内部方法

```java
private RpcResponse handleRequest(RpcRequest request) {
  RpcResponse rpcResponse = new RpcResponse();
  try {
    //获取要请求的方法
    Method method = request.getClazz().getMethod(request.getMethodName(), request.getParameterTypes());

    Object res = method.invoke(request.getImplClazz().newInstance(), request.getParameters());
    rpcResponse.setData(res);
  } catch (Exception e) {
    log.error(e.getMessage());
    rpcResponse.setCode(-1);
    rpcResponse.setMessage(e.getClass().getName());
  }
  return rpcResponse;
}
```

这里通过请求的信息解析出请求信息，然后**通过反射`method.invoke()`来进行实际调用**，调用成功后将信息设置到返回信息的`data`属性，如果调用失败则设置错误原因，修改状态码。

## 客户端

客户端就是rpc请求中的消费者，它需要将它调用的信息发送给生产者，并且指定生产者的地址和端口。

```java
@Slf4j
public class BioClient {

	private String host;

	private int port;

	public BioClient(String host, int port) {
		this.host = host;
		this.port = port;
	}

	public RpcResponse send(RpcRequest rpcRequest) {
		try {
			Socket socket = new Socket(host, port);
			//发送rpc请求
			ObjectOutputStream objectOutputStream = new ObjectOutputStream(socket.getOutputStream());
			objectOutputStream.writeObject(rpcRequest);
			//接收响应
			ObjectInputStream objectInputStream = new ObjectInputStream(socket.getInputStream());
			Object object = objectInputStream.readObject();
			if (object instanceof RpcResponse) {
				return (RpcResponse) object;
			}
		} catch (Exception e) {
			log.error(e.getMessage());
		}
		return null;
	}

}
```

在网络请求的客户端对请求信息不做任何处理，将服务端返回的信息直接返回给调用者。

# 定义生产者和消费者的部分

## 生产者

这里生产者的作用就是启动网络传输的服务端，不存在服务注册等其他方法。

```java
public class RpcServer {

	public void start() {
		new BioServer().export(9090);
	}

}
```

## 消费者

由于要对调用者隐藏封装调用过程，所以使用了代理模式，并且代理对象不可知所以使用了动态代理。

在请求信息中需要明确实现类，所以又定义了一个成员变量来进行表示。

```java
public class RpcClient {

	private Class<?> implClazz;

	public void init(Class<?> implClazz) {
		this.implClazz = implClazz;
	}

	public <T> T getProxy(Class<T> clazz) {
		return (T) Proxy.newProxyInstance(getClass().getClassLoader(), new Class[]{clazz}, new RemoteInvoker(clazz, implClazz));
	}

}
```

动态代理类

```java
public class RemoteInvoker implements InvocationHandler {

	private Class<?> clazz;

	private Class<?> implClazz;

	public RemoteInvoker(Class<?> clazz, Class<?> implClazz) {
		this.clazz = clazz;
		this.implClazz = implClazz;
	}

	@Override
	public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
		RpcRequest rpcRequest = new RpcRequest();
		rpcRequest.setClazz(clazz);
		rpcRequest.setImplClazz(implClazz);
		rpcRequest.setMethodName(method.getName());
		rpcRequest.setParameterTypes(method.getParameterTypes());
		rpcRequest.setParameters(args);
		RpcResponse rpcResponse = new BioClient("127.0.0.1", 9090).send(rpcRequest);
    if (rpcResponse == null) {
			throw new Exception("network invoke error!");
		}
		return rpcResponse.getData();
	}
}
```

这动态代理类中进行请求信息的封装，网络请求的调用，判断返回结果，然后返回方法返回的实际内容。

# 测试一下

首先定义一个接口和实现类

```java
public interface HelloService {

	String sayHello(String name);

	String sayBye(String name);
}

public class HelloServiceImpl implements HelloService {

	@Override
	public String sayHello(String name) {
		return "hello," + name;
	}

	@Override
	public String sayBye(String name) {
		return "bye," + name;
	}
}
```

生产者的调用

```java
public class Server {

	public static void main(String[] args) {
		RpcServer rpcServer = new RpcServer();
		rpcServer.start();
	}

}
```

消费者的调用

```java
public class Client {

	public static void main(String[] args) {
		RpcClient rpcClient = new RpcClient();
		rpcClient.init(HelloServiceImpl.class);
		HelloService helloService = rpcClient.getProxy(HelloService.class);
		String sayHello = helloService.sayHello("rpc");
		System.out.println(sayHello);
		String sayBye = helloService.sayBye("rpc");
		System.out.println(sayBye);
	}

}
```

当看到控制台输出`hello,rpc  bye,rpc`字段时就表示我们这次的请求成功了。

# 后续

其实这个程序有一些问题，消费者的调用时其实并不请求它的实现类是什么，后续会针对这一问题进行改进。



