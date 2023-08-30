---
title: dubbo笔记
date: 2019-06-23 17:58:16
categories: "java"
toc: true
tags: 
	- dubbo
	- rpc
	- java
---

## 建立基础项目

建立一个`maven`项目，然后建立一个`api`模块，作为这个项目的总的调用接口

```
learn-dubbo-demo/
├── simple-api
```

https://github.com/liunaijie/learn-demo/tree/master/learn-dubbo-demo  

https://github.com/liunaijie/learn-demo/tree/master/learn-dubbo-demo/sample-api

然后在api项目中创建接口，提供给生产者和消费者调用。  

我这里定义一个了`sayhello()`方法

<!--more-->

## 使用zookeeper作为服务注册中心

```
learn-dubbo-demo/
├── simple-api
├── zookeeper-register
	└──zookeeper-consumer-sample
    └──zookeeper-provider-sample
```

这里使用`zookeeper`作为`dubbo`的服务注册中心，简单实现rpc的调用

新建两个子项目，一个作为生产者（`spring-boot-starter`），一个作为消费者  （`spring-boot-starter-web`）

在这两个module中都需要引入api的module

### 生产者：

```java
package cn.lnj.project.demo.dubbo.zookeeper.provider.service;

import cn.lnj.project.demo.dubbo.api.IUserService;
import org.springframework.beans.factory.annotation.Value;
import org.apache.dubbo.config.annotation.Service; //service的导包要导入dubbo的包，而不是spring的包

//这个版本从配置文件读取，生产者调用的时候只要版本一致就可以调用到这个实现类中
//也就是说我们可以有多个版本的生产者 消费者调用时写不同的版本就可以调用不同的后台内容
@Service(version = "${service.api.version}")
public class UserServiceImpl implements IUserService {
	
	//从配置文件中读取我们这个项目的名称，其实就是我随便定义的返回信息
	@Value("${dubbo.application.name}")
	private String serviceName;

	@Override
	public String sayHello(String name) {
		System.out.println("zookeeper provider works");
		return String.format("[%s] : Hello,i am work, %s", serviceName, name);
	}

}
```

然后写生产者的配置文件：

```yml
spring:
  application:
    name: zookeeper-provider-sample

dubbo:
  application:
    name: zookeeper-provider-sample
  registry:
    address: zookeeper://****:2181 #zk的注册地址
    file: ${user.home}/dubbo-cache/${spring.application.name}/dubbo.cache
  scan:
    base-packages: cn.lnj.project.demo.dubbo.zookeeper.provider.service #实现类的包，dubbo会扫描这个包下，我们如果把实现类放在这个包外就注册不了

service:
  api:
    version: 0.0.1 #定义我们api的版本号
```

然后启动生产者会出现如下就表示我们生产者启动成功了。

![zookeeper-provider](https://raw.githubusercontent.com/liunaijie/images/master/1562133824449.jpg)

我又进入zk里面查看了这个生产者的信息：

![zk-provider-info](https://raw.githubusercontent.com/liunaijie/images/master/1562134014446.jpg)

从这里我们可以看到存储了生产者信息的ip地址为`192.168.0.18`。所以这也就要求了消费者与生产者在一个网段，否则不会调用成功。如果我将生产者与zk放到同一台机器上，那么这个ip地址就会变成`127.0.0.1`，这样就要求消费者也要在同一台机器上。当然我们也可以修改本机的hosts来修改注册到zk上的地址，最终保证消费者能ping同生产者的ip才能调用成功。这个我认为是`rpc`调用与`http`调用的区别之一。

### 2.2消费者

首先是配置文件

```yml
spring:
  application:
    name: zookeeper-consumer-sample

dubbo:
  application:
    name: zookeeper-consumer-sample
  registry:
    address: zookeeper://****:2181
    file: ${user.home}/dubbo-cache/${spring.application.name}/dubbo.cache

server:
  port: 8080
  servlet:
    context-path: /zookeeper-consumer #因为我用了web页面来进行调用，所以写了一个上下文

service:
  api:
    version: 0.0.1  #要与生产者里面的版本对应
```

然后又写了一个controller来提供页面调用

```java
package cn.lnj.project.demo.dubbo.zookeeper.consumer.controller;

import cn.lnj.project.demo.dubbo.api.IUserService;
import org.apache.dubbo.config.annotation.Reference;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class UserController {
	
    // dubbo中使用 refernce 来实现注入并指明调用的版本
	@Reference(interfaceClass = IUserService.class,version = "${service.api.version}")
	private IUserService iUserService;

	@RequestMapping(value = "/hello")
	public Object sayHello(@RequestParam(value = "name") String name) {
		return iUserService.sayHello(name);
	}

}
```

然后进行web页面调用：我传入了一个zookeeper的参数。出现了如下的结果就表示我们这个调用成功了

![zk-consumer-web](https://raw.githubusercontent.com/liunaijie/images/master/1562134832228.jpg)

