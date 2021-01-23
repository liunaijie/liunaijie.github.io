---
title: Netty源码剖析与实战笔记
tags:
  - java
  - netty
categories: code
date: 2020-02-09 09:08:39
---

## Netty怎么切换三种I/O模式

- 什么是经典的三种I/O模式

  - BIO（阻塞I/O）

    jdk1.4之前

  - NIO（非阻塞I/O）

    jdk1.4后在java.nio包下

  - AIO（异步I/O）

    jdk1.7

- Netty对三种I/O模式的支持

- 为什么Netty仅支持NIO

- 为什么Netty有多种NIO实现

- NIO一定优于BIO么

- 源码解读Netty怎么切换I/O模式