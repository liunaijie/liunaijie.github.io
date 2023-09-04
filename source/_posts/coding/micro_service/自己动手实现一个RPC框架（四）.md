---
title: 自己动手实现一个RPC框架(四)
date: 2020-03-25 17:13:51
categories:
- [coding, micro_service]
tags:
- java
- rpc
---

# rpc-register

注册中心，这里使用`zookeeper`来实现。

生产者在启动服务时，将自己实现的服务注册到注册中心。

消费者调用服务时，来注册中心查找，返回调用服务实例的地址信息。

并且为了适应不同的注册实现，我们将功能定义为接口，在替换实现时在配置文件中进行替换即可。

```java
public interface RpcRegister {
	/**
	 * 注册服务
	 * @param serviceDescriptor
	 * @param responseServiceDescription
	 */
	void register(ServiceDescriptor serviceDescriptor, ResponseServiceDescription responseServiceDescription);
	/**
	 * 根据服务名称查询实例地址
	 * @param serviceDescriptor
	 * @return
	 */
	ResponseServiceDescription lookup(ServiceDescriptor serviceDescriptor);
}
```

<!--more-->

## zookeeper实现

```java
public class ZookeeperRegistry implements RpcRegister {

	/**
	 * 注册的名称
	 */
	private static final String NAME_SPACE = "zk-rpc";
	/**
	 * 节点信息
	 */
	private static final String RPC_PROVIDER_NODE = "/provider";
	/**
	 * 保存多个生产者信息,作为缓存容器
	 */
	private final Map<ServiceDescriptor, List<ResponseServiceDescription>> remoteProviders = new ConcurrentHashMap<>();
	/**
	 * 客户端
	 */
	private CuratorFramework zkClient;
	/**
	* 编解码，将节点信息编码后存到节点中
	*/
  private Encoder encoder;
	private Decoder decoder;

	public ZookeeperRegistry() {
		this("localhost:2181");
	}

	public ZookeeperRegistry(String zkConnectString) {
		// 设置重试次数和两次重试间隔时间
		RetryPolicy retryPolicy = new RetryNTimes(3, 5000);
		//获取客户端
		this.zkClient = CuratorFrameworkFactory.builder()
				.connectString(zkConnectString)
				.sessionTimeoutMs(10000)
				.retryPolicy(retryPolicy)
				.namespace(NAME_SPACE)
				.build();
		this.encoder = new FastJsonEncoder();
		this.decoder = new FastJsonDecoder();
		this.zkClient.start();
	}

	/**
	 * 注册服务
	 * @param serviceDescriptor 请求服务信息
	 * @param responseServiceDescription 响应信息，包括实现类和实例地址
	 */
	@Override
	public void register(ServiceDescriptor serviceDescriptor, ResponseServiceDescription responseServiceDescription) {
		String nodePath = RPC_PROVIDER_NODE + "/" + serviceDescriptor.toString();
		try {
			// 判断节点是否存在，如果不存在则创建
			Stat stat = zkClient.checkExists().forPath(nodePath);
			if (stat == null) {
				zkClient.create()
						.creatingParentsIfNeeded()
						.withMode(CreateMode.EPHEMERAL_SEQUENTIAL)
						.withACL(ZooDefs.Ids.OPEN_ACL_UNSAFE)
					//创建节点，并且将信息写入节点中	
          .forPath(nodePath, encoder.encode(responseServiceDescription));
			} else {
        //这里对于多个实例的情况没有处理
				System.out.println("the provider already exist," + serviceDescriptor.toString());
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

  /**
	 * 订阅服务
	 */
	public void subscribe(ServiceDescriptor serviceDescriptor) {
		try {
			List<String> providerIds = zkClient.getChildren().forPath(RPC_PROVIDER_NODE);
			for (String providerId : providerIds) {
				//如果与订阅服务相同，则获取节点信息
				if (providerId.contains(serviceDescriptor.toString())) {
					String nodePath = RPC_PROVIDER_NODE + "/" + providerId;
					byte[] data = zkClient.getData().forPath(nodePath);
					ResponseServiceDescription providerInfo = decoder.decode(data, ResponseServiceDescription.class);
          //获取到服务信息后，将它放到缓存中
					if (remoteProviders.containsKey(serviceDescriptor)) {
						remoteProviders.get(serviceDescriptor).add(providerInfo);
					} else {
						List<ResponseServiceDescription> list = new ArrayList<>();
						list.add(providerInfo);
						remoteProviders.put(serviceDescriptor, list);
					}
				}
			}
			//添加监听事件
			addProviderWatch(serviceDescriptor);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	public void addProviderWatch(ServiceDescriptor serviceDescriptor) {
		try {
			//创建子节点缓存
			final PathChildrenCache childrenCache = new PathChildrenCache(this.zkClient, RPC_PROVIDER_NODE, true);
			childrenCache.start(PathChildrenCache.StartMode.BUILD_INITIAL_CACHE);
			//添加子节点监听事件
			childrenCache.getListenable().addListener((client, event) -> {
				String nodePath = event.getData().getPath();
				if (nodePath.contains(serviceDescriptor.toString())) {
					if (event.getType().equals(PathChildrenCacheEvent.Type.CHILD_REMOVED)) {
						//节点移除
						this.remoteProviders.remove(nodePath);
					} else if (event.getType().equals(PathChildrenCacheEvent.Type.CHILD_ADDED)) {
						byte[] data = event.getData().getData();
						ResponseServiceDescription providerInfo = decoder.decode(data, ResponseServiceDescription.class);
						//添加节点
						if (remoteProviders.containsKey(serviceDescriptor)) {
							remoteProviders.get(serviceDescriptor).add(providerInfo);
						} else {
							List<ResponseServiceDescription> list = new ArrayList<>();
							list.add(providerInfo);
							remoteProviders.put(serviceDescriptor, list);
						}
					}
				}
			});
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

  /**
	 * 查找服务，先去缓存容器中查询，如果没有调用订阅的方法，
	 * 订阅后会将信息放到容器中。最后都从容器中返回。
	 */
	@Override
	public ResponseServiceDescription lookup(ServiceDescriptor serviceDescriptor) {
		if (!remoteProviders.containsKey(serviceDescriptor)) {
			subscribe(serviceDescriptor);
		}
		List<ResponseServiceDescription> list = remoteProviders.get(serviceDescriptor);
		return list.get(new Random().nextInt(list.size()));
	}
}
```

这里有一个问题是如果有多个实现类，我这里只是随机返回一个，这种请求在spring中也需要进行手动声明，

所以暂时没有想到什么好的解决方法。

在注册中心维护了一个容器作为客户端调用的缓存。并且对节点进行监听，如果有变动会更改容器的内容。

# rpc-codec

编解码模块，将对象转换成字节码从而进行网络传输。

将字节码进行解析成对象，从而进行业务处理。

这里使用了阿里的`Fastjson`来进行实现。

```java
public interface Decoder {
	/**
	 * 将字节数组转换为对象
	 *
	 * @param bytes 字节数组
	 * @param clazz 被转换成的类型
	 * @param <T>   类型
	 * @return 转换成的对象
	 */
	<T> T decode(byte[] bytes, Class<T> clazz);
}

public interface Encoder {
	/**
	 * 将对象转换为字节数组
	 *
	 * @param obj 要转换的对象
	 * @return
	 */
	byte[] encode(Object obj);
}
```

而实现对象也直接调用fastjson的方法即可。

```java
public class FastJsonDecoder implements Decoder {
	@Override
	public <T> T decode(byte[] bytes, Class<T> calzz) {
		return JSON.parseObject(bytes, calzz);
	}
}

public class FastJsonEncoder implements Encoder {
	@Override
	public byte[] encode(Object obj) {
		return JSON.toJSONBytes(obj);
	}
}
```

# 其他部分链接

- [自己动手首先一个RPC框架（二）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（二）/)
- [自己动手首先一个RPC框架（三）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（三）/)
- [自己动手首先一个RPC框架（五）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（五）/)
- [自己动手首先一个RPC框架（六）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（六）/)
- [自己动手首先一个RPC框架（七）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（七）/)