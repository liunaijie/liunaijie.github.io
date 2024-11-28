---
title: 自己动手实现一个RPC框架(六)
date: 2020-03-25 18:38:28
categories:
  - - coding
    - micro_service
tags:
  - Java
  - Java/rpc
---

# rpc-server

消费者的部分，这里使用配置类，将各种实现的部分在配置类中进行定义。

```java
public class ServerConfig {
	/**
	 * 监听端口
	 */
	private int port = 9090;
	/**
	 * 网络传输
	 */
	private Class<? extends TransportServer> transportClass = NettyServer.class;
	/**
	 * 注册中心
	 */
	private Class<? extends RpcRegister> rpcRegister = ZookeeperRegistry.class;
	/**
	 * 编码
	 */
	private Class<? extends Encoder> encoder = FastJsonEncoder.class;
	/**
	 * 解码
	 */
	private Class<? extends Decoder> decoder = FastJsonDecoder.class;

}
```

这这个配置中，定义了服务启动的端口，网络传输，注册中心，编解码的各种实现，当我们需要更换实现时只需要在这里修改即可。

<!--more-->

请求的实际处理类

```java
public class RpcRequestHandler implements RequestHandler {
   private final Decoder decoder;
   private final Encoder encoder;
   public RpcRequestHandler(Decoder decoder, Encoder encoder) {
      this.decoder = decoder;
      this.encoder = encoder;
   }

   @Override
   public Command handle(Command requestCommand) {
      Header header = requestCommand.getHeader();
      //反序列化RpcRequest
      RequestInfo requestInfo = decoder.decode(requestCommand.getBytes(), RequestInfo.class);
      try {
         //客户端在注册中心获取到实现类和地址
         ResponseServiceDescription responseServiceDescription = requestInfo.getResponseServiceDescription();
         //通过反射进行调用
         Class implClass = Class.forName(responseServiceDescription.getImplName());
         Object implInstance = implClass.newInstance();
         Method method = implClass.getMethod(requestInfo.getResponseServiceDescription().getMethod(), requestInfo.getResponseServiceDescription().getParameterTypes());
         Object result = method.invoke(implInstance, requestInfo.getParameters());
         //将结果封装成响应进行返回
         return new Command(new ResponseHeader(header.getRequestId(), header.getVersion(), ResponseHeader.SUCCESS_CODE, ResponseHeader.SUCCESS_MSG), encoder.encode(result));
      } catch (Throwable t) {
         //发生异常，返回错误信息
         log.warn("Exception:", t);
         return new Command(new ResponseHeader(header.getRequestId(), header.getVersion(), -1, t.getMessage()), new byte[0]);
      }
   }
}
```

这个类实现自`rpc-transport`中的`RequestHandler`接口

主类：

```java
public class RpcServer {
	/**
	 * 服务配置类
	 */
	private ServerConfig serverConfig;
	/**
	 * 网络传输服务端
	 */
	private TransportServer transportServer;
	/**
	 * 注册中心
	 */
	private RpcRegister rpcRegister;

	public RpcServer() {
		this(new ServerConfig());
	}

	public RpcServer(ServerConfig serverConfig) {
		this.serverConfig = serverConfig;
		this.transportServer = ReflectionUtils.newInstance(serverConfig.getTransportClass());
		Encoder encoder = ReflectionUtils.newInstance(serverConfig.getEncoder());
		Decoder decoder = ReflectionUtils.newInstance(serverConfig.getDecoder());
		this.transportServer.init(new RpcRequestHandler(decoder, encoder));
		this.rpcRegister = ReflectionUtils.newInstance(serverConfig.getRpcRegister());
	}

	/**
	 * 注册服务
	 * @param interfaceClass 接口类
	 * @param impl           实现类
	 * @param version        实现的版本号
	 * @param <T>            接口类型
	 */
	public <T> void register(Class<T> interfaceClass, Class<? extends T> impl, String version) {
		Method[] methods = ReflectionUtils.getPublicMethods(interfaceClass);
		for (Method method : methods) {
			ServiceDescriptor serviceDescriptor = ServiceDescriptor.from(interfaceClass, version, method);
			ResponseServiceDescription responseServiceDescription = formResponseServiceDescription(interfaceClass, method, version, impl);
			rpcRegister.register(serviceDescriptor, responseServiceDescription);
			log.info("register service:{}{} ", serviceDescriptor.getClazz(), serviceDescriptor.getMethod());
		}
	}

	/**
	 * 启动服务
	 */
	public void start() {
		try {
			this.transportServer.start(serverConfig.getPort());
		} catch (InterruptedException e) {
			e.printStackTrace();
			log.error("server start failed:{}", e.getMessage());
		}
	}

	public void stop() {
		this.transportServer.stop();
	}


	private <T> ResponseServiceDescription formResponseServiceDescription(Class<T> interfaceClass, Method method, String version, Class<? extends T> impl) {
		return ResponseServiceDescription.from(interfaceClass, version, method, impl, getURI());
	}

	/**
	 * 返回这个实例的地址和端口，由于本地调用所以就直接返回了localhost
	 * @return
	 */
	private URI getURI() {
		String host = "localhost";
		return URI.create("rpc://" + host + ":" + serverConfig.getPort());
	}
}
```

生产者调用流程：

1. 初始化`new RpcServer()`

2. 注册服务`register()`

3. 启动服务`start()`

# 其他部分链接

- [自己动手首先一个RPC框架（二）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（二）/)
- [自己动手首先一个RPC框架（三）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（三）/)
- [自己动手首先一个RPC框架（四）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（四）/)
- [自己动手首先一个RPC框架（五）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（五）/)
- [自己动手首先一个RPC框架（七）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（七）/)