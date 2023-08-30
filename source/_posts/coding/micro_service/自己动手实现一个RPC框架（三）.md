---
title: 自己动手实现一个RPC框架（三）
date: 2020-03-25 11:18:09
tags:
	- rpc
---

# rpc-commons

这个模块主要是定义一些通信协议类，工具类。

<!--more-->

1. 请求编号类

对请求过程添加请求编号，所以设置一个`IDUtil`，里面的实现使用`AtomicLong`来进行递增取值。

2. 反射工具类

	在生产者接收到请求信息进行实际调用时需要用到反射来进行实际调用。所有在这里先将反射的一些方法写成工具类。

	需要通过反射来获取对象实例，进行实际调用，并且注册时需要将所有公共方法都进行注册，所有还需要一个获取类中所有公共方法的方法。

	```java
	public class ReflectionUtils {
		/**
		 * 根据class创建对象实例
		 *
		 * @param clazz 待创建的对象
		 * @param <T>   对象类型
		 * @return 创建好的对象
		 */
		public static <T> T newInstance(Class<T> clazz) {
			try {
				return clazz.newInstance();
			} catch (Exception e) {
				e.printStackTrace();
				throw new IllegalStateException(e);
			}
		}
		/**
		 * 获取一个类中所有的公共方法
		 *
		 * @param clazz 目标类
		 * @return 公共方法的数组
		 */
		public static Method[] getPublicMethods(Class clazz) {
			Method[] methods = clazz.getDeclaredMethods();
			List<Method> list = new ArrayList<>();
			for (Method method : methods) {
				if (Modifier.isPublic(method.getModifiers())) {
					list.add(method);
				}
			}
			return list.toArray(new Method[0]);
		}
		/**
		 * 调用指定对象的指定方法
		 *
		 * @param obj    被调用的对象
		 * @param method 被调用的参数
		 * @param args   参数
		 * @return 方法返回结果
		 */
		public static Object invoke(Object obj, Method method, Object... args) {
			try {
				return method.invoke(obj, args);
			} catch (Exception e) {
				e.printStackTrace();
				throw new IllegalStateException(e);
			}
		}
	}
	```

3. 网络传输发送的信息

	我们将实际发送的业务请求信息与一些其它项目分别开。

	```java
	public class Command {
		/**
		 * 头信息
		 */
		private Header header;
		private byte[] bytes;
	}
	```

	在这里，`bytes`是业务请求信息，而`header`中是我们对请求的一些信息。

	```java
	public class Header {
		/**
		 * 请求编号
		 */
		private long requestId;
		/**
		 * 请求协议的版本号
		 */
		private int version;
		/**
		 * 计算长度信息，后面请求解析时用到
		 * @return
		 */
		public int length() {
			return Long.BYTES + Integer.BYTES;
	  }
	}
	
	public class ResponseHeader extends Header {
		public static final int SUCCESS_CODE = 0;
		public static final String SUCCESS_MSG = "ok";
		/**
		 * 响应码
		 */
		private int code = SUCCESS_CODE;
		/**
		 * 响应信息，错误信息
		 */
		private String msg = SUCCESS_MSG;
		@Override
		public int length() {
			return Long.BYTES + Integer.BYTES +
					Integer.BYTES + Integer.BYTES +
					(msg == null ? 0 : msg.getBytes(StandardCharsets.UTF_8).length);
		}
		public ResponseHeader(long requestId, int version, int code, String msg) {
			super(requestId, version);
			this.code = code;
			this.msg = msg;
		}
	}
	```

	`Header`也分为请求头部和返回信息的头部，在请求信息中，我们需要给出这次请求的编号，这次请求的协议版本号，版本号是为了后续可能升级协议后导致的不兼容问题。

	`ResponseHeader`是返回信息的头部，它是`Header`的子类，除了父类中的请求编号，协议版本号之外，还增加了状态码，状态信息字段。

	

	**重要的地方：length()**

	**length()**方法，这个方法是返回头部信息的长度。由于`Header`中只有两个字段分别为`long`,`int`。所以长度即为它们两个的字节长度之和。

	而在返回信息中，它多了`msg`这个字符串类型的字段，它在遇到异常时返回异常信息，所以它的长度是不固定的，我们在响应编码时需要先写入`msg`的长度，再写入`msg`的具体信息。所以这里求长度，除了几个字段的长度为还多了一个`Integet.BYTES`，这就是因为在编码时多了一个长度。

	可以结合`rpc-transport/netty/codec/ResponseEncoder`和`rpc-transport/netty/codec/ResponseDecoder` 两个类分别为对响应信息的编解码操作来理解。

4. 业务请求内容

```java
public class RequestInfo {
	/**
	 * 服务描述，类，方法，参数类型，返回类型等
	 */
	private ResponseServiceDescription responseServiceDescription;
	/**
	 * 参数
	 */
	private Object[] parameters;
}
```

这个类就是在`Command`类中的`bytes`对应的内容。

而这里有使用了一个类`ResponseServiceDescription`，这个类是对服务的描述信息。它首先继承自``ServiceDescription`。

来看一下它们两个类的代码：

```java
public class ServiceDescriptor {

	private static final String DEFAULT_VERSION = "1.0";
	/**
	 * 接口名称
	 */
	private String clazz;
	/**
	 * 方法
	 */
	private String method;
	/**
	 * 版本号
	 */
	private String version;
	/**
	 * 返回值类型
	 */
	private String returnType;
	/**
	 * 参数类型
	 */
	private Class[] parameterTypes;
	public static ServiceDescriptor from(Class clazz, String version, Method method) {
		...
	}
}


public class ResponseServiceDescription extends ServiceDescriptor {
	/**
	 * 实现类
	 */
	private String implName;
	/**
	 * 实例的地址
	 */
	private URI uri;
  public static ResponseServiceDescription from(Class clazz, String version, Method method, Class implClass, URI uri) {
    ...
  }
}
```

它们两个主要的区别是`ResponseServiceDescription`中多了`implName`和`uri`两个字段。

我这里采用的是消费者构造`ServiceDescription`去注册中心进查询，注册中心返回`ResponseServiceDescription`，即给出了要调用接口的实现类，这个实现类所在实例的请求地址。

返回实现类是为了请求到达生产者后，生产者能直接构建实例进行调用，请求地址则是为了网络通信。

# 结语

对于通用模块或者协议的定义中，需要提前想到升级后的处理，比如这里的`version`字段。

对于同一个实现类，可能存在不同版本的实现，在`ServiceDescription`中的`version`字段来表示。

我这里其实将实现类的信息返回给了消费者，也可以在消费者端维护一个容器，存储接口和实现类，注册中心只返回`uri`。这样消费者发送给生产者的信息就可以是`ServiceDescription`。



# 其他部分链接

- [自己动手首先一个RPC框架（二）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（二）/)
- [自己动手首先一个RPC框架（四）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（四）/)
- [自己动手首先一个RPC框架（五）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（五）/)
- [自己动手首先一个RPC框架（六）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（六）/)
- [自己动手首先一个RPC框架（七）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（七）/)