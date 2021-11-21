---
title: Java Class Loader
date: 2021-10-14 20:13:29
categories: "java"
toc: true
tags: 
	- java
    - jvm 
---

# Class Loader

站在Java虚拟机的角度来看，只存在两种不同的类加载器：

一种是启动类加载器(Bootstrap ClassLoader)，这个类加载器使用C++语言实现，是虚拟机自身的一部分；

另外一种就是其他所有的类加载器，这些类加载器都由Java语言实现，独立存在于虚拟机外部，并且全都继承自抽象类java.lang.ClassLoader。

站在Java开发人员的角度来看，类加载器就应当划分得更细致一些。自JDK 1.2以来，Java一直保
持着三层类加载器、双亲委派的类加载架构，尽管这套架构在Java模块化系统出现后有了一些调整变动，但依然未改变其主体结构。

## 启动类加载器(Bootstrap Class Loader)

这个类负责加载存放在`<JAVA_HOME>/lib` 目录下， 或者被参数`-Xbootclasspath`所指定的路径中存放的，并且是Java虚拟机能够识别的类库(按照文件名识别，名字不符合的类库即使放到lib目录下也不会被加载)加载到虚拟机内存中。

启动类加载器无法被Java程序直接引用，用户在编写自定义加载器时，如果需要把加载请求委派给引导类加载器去处理，那直接使用null代替即可。

## 扩展类加载器(Extension Class Loader)

这个类加载器是在类`sun.misc.Launcher$ExtClassLoader` 中以Java代码的形式实现的，它负责加载`<JAVA_HOME>/lib/ext`目录下，或者被`java.ext.dirs`系统变量所指定的路径中所有的类库。

这是一种Java系统类库的扩展机制，运行用户将具有通用性的类库放置到ext目录里以扩展Java SE的功能，在JDK9之后，这种扩展机制被模块化带来的天然扩展能力所取代。

由于扩展类加载器是由Java代码实现的，开发者可以直接在程序中使用扩展类加载器来加载Class文件。

## 应用程序类加载器(Application Class Loader)

这个类加载器由`sun.misc.Launcher$AppClassLoader`来实现。由于应用程序类加载器是ClassLoader类中的`getSystemClassLoader()`方法的返回值，所以有些场合中也称它为“系统类加载器”。它负责加载用户类路径(ClassPath)上所有的类库，开发者同样可以直接在代码中使用这个类加载器。如果应用程序中没有 自定义过自己的类加载器，一般情况下这个就是程序中默认的类加载器。

**三次类加载模型**

![](https://raw.githubusercontent.com/liunaijie/images/master/20211121101921.png)

### 双亲委派模型

双亲委派模型要求除了顶层的启动类加载器外，其他的类加载器都应有自己的父类加载器。它并不是一个具有强制性约束力的模型，而是推荐的一种最佳实践。

**工作流程：**

当一个类加载器收到了类加载的请求，它首先不会自己去尝试加载这个类，而是把这个请求委派给父类加载器去完成，每一层的类加载器都是如此，因此所有的加载请求最终都会传送到最顶层的启动类加载器中，只有当父加载器反馈自己无法完成这个加载请求时(它的搜索范围中没有找到所需的类)，子加载器才会尝试自己去完成加载。

使用双亲委派模型来组织类加载器之间的关系，一个显而易见的好处是Java中的类随着它的类加载器一起具备类一种带有优先级的层次关系。对于保证Java程序的稳定运行极为重要。

```java
protected synchronized Class<?> loadClass(String name, boolean resolve) throws ClassNotFoundException {
    // 首先，检查请求的类是否已经被加载过了 
    Class c = findLoadedClass(name); 
    if (c == null) {
        try {
            if (parent != null) {
                c = parent.loadClass(name, false);
            } else {
                c = findBootstrapClassOrNull(name); 
            }
        } catch (ClassNotFoundException e) {
            // 如果父类加载器抛出ClassNotFoundException // 说明父类加载器无法完成加载请求
        }
        if (c == null) {
            // 在父类加载器无法加载时
            // 再调用本身的findClass方法来进行类加载 c = findClass(name);
        } 
    }
    if (resolve) { 
        resolveClass(c);
    }
    return c; 
}
```