---
title: Java中的锁
date: 2022-09-01 10:18:39
categories:
  - - coding
    - java
tags:
  - Java
  - Java/lock
related-project: "[[Blog Posts/coding/Java/Java|Java]]"
---
Java中的锁机制主要分为`Synchronized`和`Lock`

# Synchronized

Synchronized在JVM里的实现是基于Monitor来实现的, Monitor是依赖与底层的操作系统Mutex Lock(互斥锁)来实现的线程同步.

synchronized用的锁是存在Java对象头里的.

JVM基于进入和退出Monitor对象来实现方法同步和代码块同步. 代码块同步是使用monitorenter和monitorexit指令实现的, monitorenter指令是在编译后插入到同步代码块的开始位置, 而monitorexit是插入到方法结束处和异常处.

任何对象都有一个monitor与之关联, 当且一个monitor被持有后,它将处于锁定状态.

根据虚拟机规范的要求, 在执行monitorenter指令时, 首先要去尝试获取对象的锁, 如果这个对象没被锁定, 或者当前线程已经拥有了那个对象的锁, 把锁的计数器加1. 相应地, 在执行monitorexit指令时会将锁计数器减1, 当计数器被减到0时, 锁就释放了. 如果获取对象锁失败了, 那当前线程就要阻塞等待,直到对象锁被另一个线程释放为止.

1.  synchronized同步快对同一条线程来说是可重入的, 不会出现自己把自己锁死的问题
2.  同步块在已进入的线程执行完之前, 会阻塞后面其他线程的进入.
3.  可重入, 不可中断, 非公平锁

# Lock

Lock底层是基于AQS(AbstractQueuedSynchronizer)的, AQS是用来构建锁或者其他同步组件的基础框架, 它使用来一个int成员变量表示同步状态, 通过内置的FIFO队列来完成资源获取线程的排队工作.

使用时必须手动进行上锁, 解锁.

Lock接口有多种实现, 比如ReentrantLock和ReadWriteLock.

Lock可以通过tryLock来获取是否可以获取锁的状态.
1.  可重入, 可以选择是否公平锁
2.  可以响应在等待锁时的中断

# AQS
这个类中几个主要的变量:
- status (保存当前的状态)
- head/tail (保存队列)
主要的几个方法:
- acquire(int)
- release(int)
- acquireShared(int)
- releaseShared(int)
分别表示独占式的加锁与释放锁的方法
共享锁的加速与释放锁的方法



