---
title: 自己动手实现一个RPC框架（二）
date: 2020-03-25 10:20:48
categories:
  - - coding
    - micro_service
tags:
  - Java
  - Java/rpc
---

**自己动手实现一个RPC框架**  
使用fastjson，netty，反射，动态代理，zookeeper实现一个RPC框架。  

代码链接：https://github.com/liunaijie/self-rpc-framwork`

# 各模块说明：

- `rpc-commons`
   通用设置模块，包括网络传输的数据格式，请求编号工具类，反射工具类等一些底层协议，工具相关的内容

- `rpc-register`  
   服务注册模块，主要包括服务的注册与发现功能。这里使用`zookeeper`来进行实现。  
    在这里，服务端注册时，使用通用模块中的`ServiceDescriptor`,`ResponseServiceDescription`类来进行注册
   `ResponseServiceDescription`类是`ServiceDescription`的子类，添加了`实现类，实例地址`等属性。
    消费者查找服务时，发送`ServiceDescription`得到`ResponseServiceDescription`，一个类可能有多个实现类，多个实例，在返回时进行随机返回。
    对于同一个实现的不同版本实现，或多个服务实例这种情况随机返回没有问题。对于不同实现类，采用随机返回可能有些问题，但是在`spring`中对于多实现类也需要指定实现类，所以后面再考虑更改。 

   <!--more--> 
   
- `rpc-codec`  
  

信息的编解码，这里使用`fastjson`来进行实现。  

- rpc-transport

   网络传输模块，生产者调用启动监听服务，消费者调用发送请求。

   这里使用netty来进行实现。

- `rpc-server`  
   生产者调用的模块，注册服务实现，包括实现的接口，实现类，版本等。  
   启动服务，监听连接，对请求的解析，然后通过反射来进行处理，最后将处理结果进行返回。  

- `rpc-client`  
   消费者调用的模块，通过代理来进行实际调用。  
   通过信号量`Semaphore`来控制同时发送的请求数量，防止多请求发送后压垮服务端。  
   使用`future`来实现异步操作，使用map容器存储，并且启动固定频率线程，清除超时超时的`future`。

- `simple-example`  
   一个简单的客户端，定义了一个接口，包含有返回值和无返回值的两个方法  

```java
public interface HelloService {
    String hello(String name);
    void bye(String name);       
}
```

然后定义了两个不同的实现类`Chinese`,`English`两种实现分别以不同语言进行返回或打印。  

```java
public class ChineseHelloImpl implements HelloService {
   @Override
   public String hello(String name) {
      return "你好，" + name;
   }
   @Override
   public void bye(String name) {
      System.out.println("再见," + name);
   }
}

public class EnglishHelloImpl implements HelloService {
   @Override
   public String hello(String name) {
      return "hello," + name;
   }
   @Override
   public void bye(String name) {
      System.out.println("bye,"+name);
   }
}
```

 并且定义了同一个实现类的不同版本，在返回信息中做了区别。  

```java
public class V2Chinese implements HelloService {
   @Override
   public String hello(String name) {
      return "v2 你好," + name;
   }
   @Override
   public void bye(String name) {
      System.out.println("v2 再见," + name);
   }
}
```

然后先后启动`SimpleProvide`和`SimpleConsumer`两个类。  

可以在`SimpleConsumer`控制台中看到有返回值的调用内容，在`SimpleProvider`控制台中看到无返回值的调用。即表示服务调用成功。

# 其他部分链接

- [自己动手首先一个RPC框架（三）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（三）/)
- [自己动手首先一个RPC框架（四）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（四）/)
- [自己动手首先一个RPC框架（五）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（五）/)
- [自己动手首先一个RPC框架（六）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（六）/)
- [自己动手首先一个RPC框架（七）](https://www.liunaijie.top/2020/03/25/微服务/自己动手实现一个RPC框架（七）/)