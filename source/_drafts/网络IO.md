---
title: 网络IO
date: 2019-09-19 08:21:11
categories: "java"
toc: true
tags: 
	- java
	- io
---

这篇文章记录一下网络 io 中的多种模型，分别为 bio，nio，aio以及 netty。

# BIO (blocking I/O)

阻塞式 IO。这个 io 模型是java 最早的 io 模型。首先启动后台程序，对端口进行监听，每当有一个新客户端连接时启动一个线程对其进行响应。

为什么是阻塞式，因为我们对客户端连接进行监听时调用的`accept()`方法是阻塞方法，当没有客户端连接时会进入阻塞状态。

这个模型有什么问题呢？首先显而易见的是当有很多个客户端连接时我们要启动相应个数的线程进行响应，但是客户端并不一定每时每刻都在发消息，我们启动一个线程对这一个客户端进行服务，但是这个客户端有可能半天才发一个消息，那么这个线程就要闲置半天，占用系统资源。

![JAVA BIO](https://raw.githubusercontent.com/liunaijie/images/master/java_bio.png)

<!--more-->

## 代码实现

# NIO(new non-blocking I/O)

由于 bio 存在问题，所以在jdk1.4 发布了新的模型也就是 nio。

它主要是加了一个多路复用，也就是图中的`selector`，它会对客户端的状态进行监听，从而派发到不同的处理函数上，从而实现后台一个线程响应多个客户端。也可以进行优化让服务端启用线程池等来提高机器的使用性能。

![java nio](https://raw.githubusercontent.com/liunaijie/images/master/java_nio.png)

## 代码实现



# AIO（asynchronous I/O）

Todo

# netty

todo

基于 nio，对其中的类进行了修改增强，比如`ByteBuffer`修改为`ByteBuf`等。