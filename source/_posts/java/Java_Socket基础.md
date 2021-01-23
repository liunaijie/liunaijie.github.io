---
title: Java Socket基础
date: 2019-05-09 11:55:18
toc: true
categories: "java"
tags: 
	- java
	- socket
---

# socket简介

https://blog.csdn.net/httpdrestart/article/details/80670388

# 简单socket连接

## 基于TCP的socket连接

### 服务端

服务端的实现主要分为以下几步：  

第一步：创建socket服务，指定端口  

第二步：调用accep()方法开始监听，等待客户端的连接  

第三步：获取客户端的输入流  

第四步：响应客户端信息，获取输出流  

第五步：关闭资源  

<!-- more -->

```java
import java.io.*;
import java.net.ServerSocket;
import java.net.Socket;

/**
 * tcp socket 服务端
 *
 * @author LiuNaiJie
 * on 2019-05-08
 */
public class TcpSocketServer {

	public static void main(String[] args) {
		try {
			// 1.连接socket连接，指定端口9090
			ServerSocket serverSocket = new ServerSocket(9090);
			System.out.println("服务端已启动，等待客户端连接");
			// 2.等待客户端连接，此时处于阻塞状态
			Socket socket = serverSocket.accept();

			// 3.获取客户端的信息
			// 字节流
			InputStream inputStream = socket.getInputStream();
			// 转换为字符流
			InputStreamReader inputStreamReader = new InputStreamReader(inputStream);
			// 建立缓存
			BufferedReader bufferedReader = new BufferedReader(inputStreamReader);
			String receiveLine;
			StringBuilder stringBuilder = new StringBuilder();
			while ((receiveLine = bufferedReader.readLine()) != null) {
				System.out.println("客户端的一行信息为：" + receiveLine);
				stringBuilder.append(receiveLine);
			}
			String receiveMsg = stringBuilder.toString();
			System.out.println("客户端的全部信息为：" + receiveMsg);

			// 4.返回信息
			String returnMsg = "你好，socket";
			OutputStream outputStream = socket.getOutputStream();
			OutputStreamWriter outputStreamWriter = new OutputStreamWriter(outputStream);
			BufferedWriter bufferedWriter = new BufferedWriter(outputStreamWriter);
			bufferedWriter.write(returnMsg);
			bufferedWriter.flush();

			// 5.关闭信息流
			bufferedWriter.close();
			outputStreamWriter.close();
			outputStream.close();

			bufferedReader.close();
			inputStreamReader.close();
			inputStream.close();

		} catch (IOException e) {
			System.out.println("服务端建立socket失败。。。。");
			e.printStackTrace();
		}
	}

}
```



### 客户端

客户端的实现主要为以下几步：  

第一步：建立与服务器端的连接，创建客户端socket，指定服务端的地址与端口  

第二步：获取输出流，向服务器发送消息  

第三步：获取输入流，得到服务器响应的信息  

第四步：释放资源    

其中有一个点需要我们注意的是在第23行的*`socket.shutdownOutput()`*。我现在服务端是接收完客户端的全部数据后才进行返回信息，如果不添加这句服务端就会认为客户端没有发送完毕消息就会一直进入堵塞状态，并不会执行响应客户端的语句，具体大家可以注释掉这一行来查看具体效果。并且为了更加方便的演示效果，我在客户端发送的消息添加了一个换行符号。

```java
import java.io.*;
import java.net.Socket;

/**
 * tcp socket 客户端
 *
 * @author LiuNaiJie
 * on 2019-05-08
 */
public class TcpSocketClient {

	public static void main(String[] args) {
		try {
			// 1.连接与服务器的连接
			Socket socket = new Socket("127.0.0.1", 9090);
			// 2.发送数据
			OutputStream outputStream = socket.getOutputStream();
			OutputStreamWriter outputStreamWriter = new OutputStreamWriter(outputStream);
			BufferedWriter bufferedWriter = new BufferedWriter(outputStreamWriter);
			bufferedWriter.write("你好，我是客户端\n这是第二行消息");
			bufferedWriter.flush();
			// 这一句必须添加
            socket.shutdownOutput();
			// 3.接收数据
			InputStream inputStream = socket.getInputStream();
			InputStreamReader inputStreamReader = new InputStreamReader(inputStream);
			BufferedReader bufferedReader = new BufferedReader(inputStreamReader);
			StringBuilder msg = new StringBuilder();
			String line;
			while ((line = bufferedReader.readLine()) != null) {
				System.out.println("返回信息的行：" + line);
				msg.append(line);
			}
			System.out.println("全部信息为：" + msg.toString());

			// 4.关闭连接
			bufferedReader.close();
			inputStreamReader.close();
			inputStream.close();

			bufferedWriter.close();
			outputStreamWriter.close();
			outputStream.close();

			socket.close();

		} catch (IOException e) {
			System.out.println("客户端建立连接失败。。。");
			e.printStackTrace();
		}
	}

}

```

运行结果：

需要注意的是我们需要先启动服务端，然后再启动客户端。

服务端：![](https://raw.githubusercontent.com/liunaijie/images/master/20190509131951.png)

客户端：![](https://raw.githubusercontent.com/liunaijie/images/master/20190509132056.png)

## 基于UDP的socket连接

udp的连接主要使用`DatagramPacket`进行信息传输

### 服务器

服务端的实现主要是以下步骤：

第一步：创建服务器端DatagramSocket,指定端口  

第二步：创建数据包，用于接收客户端发送的数据  

第三步：接收客户端发来的信息  

第四步：创建数据包，用于响应客户端  

第五步：响应客户端  

第六步：关闭资源  

```java
import java.io.IOException;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.SocketException;

/**
 * udp socket 服务端
 *
 * @author LiuNaiJie
 * on 2019-05-09
 */
public class UdpSocketServer {

	public static void main(String[] args) {
		try {

			/*
			 接收客户端的数据
			 */

			// 1.创建服务器端DatagramSocket，指定端口
			DatagramSocket datagramSocket = new DatagramSocket(8888);
			System.out.println("服务器已启动，等待客户端连接");
			// 2.创建数据报，用于接收客户端发送的数据
			byte[] data = new byte[1024];
			DatagramPacket datagramPacket = new DatagramPacket(data, data.length);
			// 3.接收客户端发送的数据。 此方法在接收到数据报之前会一直阻塞
			datagramSocket.receive(datagramPacket);
			// 4.读取数据
			String info = new String(data, 0, datagramPacket.getLength());
			System.out.println("服务器接收到数据为：" + info);

			/*
			向客户端响应数据
			 */
			// 1.定义客户端的地址，端口号，数据
			InetAddress inetAddress = datagramPacket.getAddress();
			int port = datagramPacket.getPort();
			byte[] returnMsg = ("我是服务器返回信息，你发送给我的信息为：" + info).getBytes();
			// 2.创建数据报，包含响应的数据信息
			DatagramPacket returnPacket = new DatagramPacket(returnMsg, returnMsg.length, inetAddress, port);
			// 3.响应客户端
			datagramSocket.send(returnPacket);
			// 4.关闭资源
			datagramSocket.close();
		} catch (SocketException e) {
			System.out.println("服务端启动socket失败。。。");
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

}
```

### 客户端

客户端的实现主要是以下步骤：  

第一步：定义服务器的地址、端口号、数据  

第二步：创建数据报，包含发送的数据信息  

第三步：创建数据报，用于接收服务器响应的数据  

第四步：接收服务器响应的数据  

第五步：读取数据  

第六步：关闭资源  

```java
import java.io.IOException;
import java.net.*;

/**
 * @author LiuNaiJie
 * on 2019-05-09
 */
public class UdpSocketClient {

	public static void main(String[] args) {
		try {

			/*
			向服务器发送数据
			 */

			// 1.定义服务器的地址，端口号，数据
			InetAddress inetAddress = InetAddress.getByName("localhost");
			int port = 8888;
			byte[] data = "这是客户端发送的信息".getBytes();
			// 2.创建数据报，包含发送的数据信息
			DatagramPacket datagramPacket = new DatagramPacket(data, data.length, inetAddress, port);
			// 3.创建DatagramSocket对象
			DatagramSocket datagramSocket = new DatagramSocket();
			// 4.向服务端发送数据报
			datagramSocket.send(datagramPacket);

			/*
			接收服务器响应的数据
			 */
			// 1.创建数据报，接收服务器响应的数据
			byte[] returnMsg = new byte[1024];
			DatagramPacket returnPacket = new DatagramPacket(returnMsg, returnMsg.length);
			// 2.接收服务器响应的数据
			datagramSocket.receive(returnPacket);
			// 3.读取数据
			String reply = new String(returnMsg, 0, returnPacket.getLength());
			System.out.println("服务器返回信息为：" + reply);
			// 4.关闭资源
			datagramSocket.close();

		} catch (IOException e) {
			e.printStackTrace();
		}
	}

}
```



参考：

https://blog.csdn.net/httpdrestart/article/details/80670388

[https://shirukai.github.io/2018/09/30/Java Socket 基础以及NIO Socket/#2-5-基于UDP的Sokcet客户端](https://shirukai.github.io/2018/09/30/Java Socket 基础以及NIO Socket/#2-5-基于UDP的Sokcet客户端)

