---
title: java线程池剖析
date: 2020-04-07 10:21:53
categories: "java"
toc: true
tags: 
	- java
---

# 为什么要使用线程池

要讨论为什么使用线程池的前提是我们已经使用了线程。由于存在以下问题，所以需要使用线程池来管理线程：

- 线程生命周期的开销非常高

	线程的创建，销毁这都是高开销的动作。有时候创建的时间甚至比我们的业务处理时间还要长，如果能提前创建好，直接提交业务请求，那么就可以减少请求时间。

- 资源消耗

	如果不加限制的创建线程，假如一个请求就会去创建一个线程，那么服务器上的资源肯定是不能够进行处理的。

# java提供的几种线程池

在java中提供了几种线程池的实现，让我们可以直接进行调用。有以下五种：

- `newFixedThreadPool`

	固定线程数量的线程池，传入要创建线程数量，那么在系统中就会创建这些数量的线程，并且数量固定，不会进行增加。

- `newCachedThreadPool`

	创建一个缓存线程，当请求到来时，先判断现在有没有空闲的线程，如果有则使用该线程。如果没有则创建一新的线程，处理完请求后不会立即销毁，而是等待60s，如果这段时间没有请求过来则进行销毁，如果有请求过来则使用这个线程进行处理。

- `newSingleThreadExecutor`

	只创建一个线程

- `newScheduledThreadPool`

- `newWorkStealingPool`

并且通过查看源码可以发现，`fix`,`cached`都是调用的`ThreadPoolExecutor`类来进行实现，`single`是通过其他类进行了转换，最终也是调用的`ThreadPoolExecutor`。而其他两个则是则是不同的实现，这一次先剖析一下上面的三个线程池，后面再对另外两个进行补充。

<!--more-->

# 区别

我们来分别看一下创建这三个线程池的代码：

```java
public static ExecutorService newFixedThreadPool(int nThreads) {
  return new ThreadPoolExecutor(nThreads, nThreads,0L, TimeUnit.MILLISECONDS,new LinkedBlockingQueue<Runnable>());
}

public static ExecutorService newSingleThreadExecutor() {
  return new FinalizableDelegatedExecutorService
    (new ThreadPoolExecutor(1, 1,0L, TimeUnit.MILLISECONDS,new LinkedBlockingQueue<Runnable>()));
}

public static ExecutorService newCachedThreadPool() {
  return new ThreadPoolExecutor(0, Integer.MAX_VALUE,60L, TimeUnit.SECONDS,new SynchronousQueue<Runnable>());
}
```

从这里可以看出，他们三个分别调用了`ThreadPoolExecutor`的构造方法，传入了不同的参数，从而实现了不同的功能。



