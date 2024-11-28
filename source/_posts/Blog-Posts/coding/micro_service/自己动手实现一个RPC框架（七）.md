---
title: 自己动手实现一个RPC框架(七)
date: 2020-03-25 18:52:10
categories:
  - - coding
    - micro_service
tags:
  - Java
  - Java/rpc
---

# rpc-client

消费者端，通过代理来进行调用。

与生产者端类型，首先定义配置类：

```java
public class ClientConfig {

	private Class<? extends Encoder> encoder = FastJsonEncoder.class;

	private Class<? extends Decoder> decoder = FastJsonDecoder.class;

	private Class<? extends TransportClient> transportClient = NettyClient.class;

	private Class<? extends RpcRegister> rpcRegister = ZookeeperRegistry.class;
}
```

<!--more-->

代理类：

```java
public class RemoteInvoker implements InvocationHandler {

	/**
	 * 请求的对象
	 */
	private Class clazz;
	/**
	 * 编码
	 */
	private Encoder encoder;
	/**
	 * 解码
	 */
	private Decoder decoder;
	/**
	 * 网络传输
	 */
	private TransportClient transportClient;
	/**
	 * 注册中心
	 */
	private RpcRegister rpcRegister;

	private String version;


	@Override
	public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
		//首先从注册中心查询
		ResponseServiceDescription responseServiceDescription = lookup(clazz, version, method);
    //创建连接
		Transport transport = transportClient.createTransport(new InetSocketAddress(responseServiceDescription.getUri().getHost(), responseServiceDescription.getUri().getPort()), 30000L);
		//构建请求信息
    Header header = new Header();
		header.setRequestId(IDUtil.nextId());
		header.setVersion(1);
		RequestInfo requestInfo = new RequestInfo(responseServiceDescription, args);
		Command requestCommand = new Command(header, encoder.encode(requestInfo));
		//发送请求
    CompletableFuture<Command> future = transport.sendRequest(requestCommand);
    //获取响应
		Command responseCommand = future.get();
		Header respHeader = responseCommand.getHeader();
		if (respHeader instanceof ResponseHeader) {
   		//对响应信息做判断
			ResponseHeader responseHeader = (ResponseHeader) respHeader;
			if (responseHeader.getCode() != ResponseHeader.SUCCESS_CODE) {
				throw new IllegalStateException(responseHeader.getMsg());
			}
		}
    //返回响应结果
		return decoder.decode(responseCommand.getBytes(), method.getReturnType());
	}

	/**
	 * 向注册中心查询
	 */
	private ResponseServiceDescription lookup(Class clazz, String version, Method method) {
		ServiceDescriptor serviceDescriptor = ServiceDescriptor.from(clazz, version, method);
		ResponseServiceDescription responseServiceDescription = rpcRegister.lookup(serviceDescriptor);
		if (responseServiceDescription == null) {
			throw new IllegalStateException("provider not exist!");
		}
		return responseServiceDescription;
	}
}
```

# 其他部分链接

- [自己动手首先一个RPC框架（二）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（二）/)

- [自己动手首先一个RPC框架（三）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（三）/)

- [自己动手首先一个RPC框架（四）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（四）/)

- [自己动手首先一个RPC框架（五）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（五）/)

- [自己动手首先一个RPC框架（六）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（六）/)

	