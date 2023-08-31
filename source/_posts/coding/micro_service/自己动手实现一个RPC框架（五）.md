---
title: 自己动手实现一个RPC框架(五)
date: 2020-03-25 17:30:17
tags:
- java/rpc
---

# rpc-transport

这个模块是有在观看[消息队列高手课](https://time.geekbang.org/column/intro/100032301)中的rpc示例完成的。

网络传输模块，这里使用`netty`来进行实现。

生产者调用来指定端口启动服务。

```java
public interface TransportServer {
	void start(int port) throws InterruptedException;
	void stop();
}
```

<!--more-->

消费者调用来创建一个连接

```java
public interface TransportClient extends Closeable {
	Transport createTransport(SocketAddress address, long timeout) throws TimeoutException, InterruptedException;
	@Override
	void close();
}

public interface Transport {
	/**
	 * 发送请求命令
	 *
	 * @param request 请求命令
	 * @return 一个future
	 */
	CompletableFuture<Command> sendRequest(Command request);

}
```

发送一个`Command`然后使用`future`来实现异步。

`future`的定义如下：

```java
public class ResponseFuture {
	private final long requestId;
	private final CompletableFuture<Command> future;
	private final long timestamp;
	public ResponseFuture(long requestId, CompletableFuture<Command> future) {
		this.requestId = requestId;
		this.future = future;
    //创建时间初始化时自动指定
		this.timestamp = System.nanoTime();
	}
}
```

同时我们使用信号量来实现对客户端请求的限流。同时将`future`使用容器存储起来。

```java
public class InFlightRequests implements Closeable {

	/**
	 * 超时时间，当超过20秒仍未收到响应则删除这个请求
	 */
	private final static long TIMEOUT_SEC = 20L;
	/**
	 * 容器，以请求编号为key，future作为value
	 */
	private final Map<Long, ResponseFuture> futureMap = new ConcurrentHashMap<>();

	/**
	 * 定义一个信号量，发送10个请求，每当归还一个信号后才能继续发送
	 * 不然客户端会一直想服务端发送消息，服务端如果处理不过来而客户端一直在发送就让服务端更糟糕
	 */
	private final Semaphore semaphore = new Semaphore(10);

	/**
	 * 启动一个线程，以固定频率TIMEOUT_SEC（即超时时间）启动，每次将超时的任务删除，同时释放一个信号量
	 */
	private final ScheduledExecutorService scheduledExecutorService = Executors.newSingleThreadScheduledExecutor();
	private final ScheduledFuture scheduledFuture;

	public InFlightRequests() {
		//初始化，线程以固定频率执行清除任务
		scheduledFuture = scheduledExecutorService.scheduleAtFixedRate(this::removeTimeoutFutures, TIMEOUT_SEC, TIMEOUT_SEC, TimeUnit.SECONDS);
	}


	public void put(ResponseFuture responseFuture) throws InterruptedException, TimeoutException {
		//在指定时间内获取一个许可，获取不到则超时抛出异常
		if (semaphore.tryAcquire(TIMEOUT_SEC, TimeUnit.SECONDS)) {
			futureMap.put(responseFuture.getRequestId(), responseFuture);
		} else {
			throw new TimeoutException();
		}
	}

	/**
	 * 对超过时间的请求进行移除
	 */
	private void removeTimeoutFutures() {
		futureMap.entrySet().removeIf(entry -> {
			if (System.nanoTime() - entry.getValue().getTimestamp() > TIMEOUT_SEC * 1000000000L) {
				semaphore.release();
				return true;
			} else {
				return false;
			}
		});
	}

	public ResponseFuture remove(long requestId) {
		ResponseFuture future = futureMap.remove(requestId);
		if (null != future) {
			semaphore.release();
		}
		return future;
	}
	@Override
	public void close() {
		//关闭时将定时线程关闭
		scheduledFuture.cancel(true);
		scheduledExecutorService.shutdown();
	}
}
```

## netty实现

### 编解码

由于`netty`使用了自己定义的`ByteBuf`,所以我们需要进行编解码。

我们按照请求流程来理一下

1. 消费者将`Command`命令编码后发送到生产者
2. 生产者需要解析消息。
3. 然后生产者进行调用，返回时需要将响应消息编码。
4. 消费者接收到生产者的响应，需要将响应信息解码。

我们来看一下对应每一步的代码实现：

1. 定义请求的编码类

```java
public class CommandEncoder extends MessageToByteEncoder<Command> {
	@Override
	protected void encode(ChannelHandlerContext channelHandlerContext, Command command, ByteBuf byteBuf) throws Exception {
    //定义信息长度，头信息长度+实际信息长度+再加一个int的字节长度
		byteBuf.writeInt(Integer.BYTES + command.getHeader().length() + command.getBytes().length);
		//对头部信息进行编码
    encodeHeader(channelHandlerContext, command.getHeader(), byteBuf);
		byteBuf.writeBytes(command.getBytes());
	}

	protected void encodeHeader(ChannelHandlerContext channelHandlerContext, Header header, ByteBuf byteBuf) throws Exception {
		byteBuf.writeLong(header.getRequestId());
		byteBuf.writeInt(header.getVersion());
	}

}
```

这时信息到达生产者，就需要进行解析了。

```java
public abstract class CommandDecoder extends ByteToMessageDecoder {

	private static final int LENGTH_FIELD_LENGTH = Integer.BYTES;

	@Override
	protected void decode(ChannelHandlerContext channelHandlerContext, ByteBuf byteBuf, List<Object> list) throws Exception {
		if (!byteBuf.isReadable(LENGTH_FIELD_LENGTH)) {
			return;
		}
		byteBuf.markReaderIndex();
		int length = byteBuf.readInt() - LENGTH_FIELD_LENGTH;
		if (byteBuf.readableBytes() < length) {
			byteBuf.resetReaderIndex();
			return;
		}
		Header header = decodeHeader(channelHandlerContext, byteBuf);
		int bytesLength = length - header.length();
		byte[] bytes = new byte[bytesLength];
		byteBuf.readBytes(bytes);
		list.add(new Command(header, bytes));
	}


	protected abstract Header decodeHeader(ChannelHandlerContext channelHandlerContext, ByteBuf byteBuf);

}
```

这个与上面不同的地方是，上面的编码信息是对请求的编码，只会在消费者发送到生产者时用到。而这个解码是对`Command`的解码，在生产者接收消费者的请求，消费者接收生产者的响应时都会用到。这两个请求有一个不同的地方是头部信息是不一样的，所以这里定义为抽象类。

这里定义了一个成员变量`LENGTH_FIELD_LENGTH`就是我们在上面多加了一个`Inter.BYTES`。

头部解码的不同实现：

```java
public class RequestDecoder extends CommandDecoder {
	@Override
	protected Header decodeHeader(ChannelHandlerContext channelHandlerContext, ByteBuf byteBuf) {
		return new Header(byteBuf.readLong(),byteBuf.readInt());
	}
}

public class ResponseDecoder extends CommandDecoder {
	@Override
	protected Header decodeHeader(ChannelHandlerContext channelHandlerContext, ByteBuf byteBuf) {
		long requestId = byteBuf.readLong();
		int version = byteBuf.readInt();
		int code = byteBuf.readInt();
		int msgLength = byteBuf.readInt();
		byte[] msgBytes = new byte[msgLength];
		byteBuf.readBytes(msgBytes);
		String msg = new String(msgBytes, StandardCharsets.UTF_8);
		return new ResponseHeader(requestId, version, code, msg);
	}
}
```

**这里的读取顺序必须与写入时的顺序一致！**

请求信息的编码在上面可以看到是先写请求编号，再写协议版本，所以在这里也是先解析请求编号，再解析协议版本。

响应信息的编码在后面。

3. 生产者调用完成，需要向消费者响应

	```java
	public class ResponseEncoder extends CommandEncoder {
	
		@Override
		protected void encodeHeader(ChannelHandlerContext channelHandlerContext, Header header, ByteBuf byteBuf) throws Exception {
			super.encodeHeader(channelHandlerContext, header, byteBuf);
			if (header instanceof ResponseHeader) {
				ResponseHeader responseHeader = (ResponseHeader) header;
				byteBuf.writeInt(responseHeader.getCode());
				byteBuf.writeInt(responseHeader.getMsg().length());
				byteBuf.writeBytes(responseHeader.getMsg() == null ? new byte[0] : responseHeader.getMsg().getBytes(StandardCharsets.UTF_8));
			}
		}
	}
	```

	这个类是继承自`CommandEncoder`也就是第一步中的类。在他的基础上又多了响应信息头部的编码。

	这里的写入顺序与上面解析的顺序都要保持一致。

	4. 消费者收到响应，解析响应信息

	这里就是第二步中的响应信息的解析。

### 具体实现

这一部分还未弄请求各部分的流程，也就是对`netty`执行过程还不是特别了解，挖坑，后续更新。

- `NettyServer`
- `NettyClient`
- `ResponseInvocation`
- `RequestInvocation`
- `NettyTransport`

对于实际反射的调用我将它放到了服务端来进行实现。

# 其他部分链接

- [自己动手首先一个RPC框架（二）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（二）/)
- [自己动手首先一个RPC框架（三）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（三）/)
- [自己动手首先一个RPC框架（四）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（四）/)
- [自己动手首先一个RPC框架（六）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（六）/)
- [自己动手首先一个RPC框架（七）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（七）/)