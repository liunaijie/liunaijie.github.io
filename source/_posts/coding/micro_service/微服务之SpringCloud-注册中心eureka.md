---
title: 微服务之SpringCloud-注册中心eureka
date: 2019-12-18 11:33:18
categories:
- [coding, micro_service]
tags: 
- java
- micro_service
- eureka
---

# 简单项目

首先我们建立一个项目，它作为我们的全部项目的容器，并负责公共依赖的版本管理等。

项目结构是这样的：

![](https://raw.githubusercontent.com/liunaijie/images/master/20191218114357.png)

然后我们在`pom.xml`中导入我们所需要的依赖，我们全部使用 springboot 来启动项目，并且需要修改`packaging`的方式为`pom`。最终的文件如下所示：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>
	<groupId>learn.spring.cloud.eureka.demo</groupId>
	<artifactId>learn-spring-cloud-eureka</artifactId>
	<version>1.0-SNAPSHOT</version>
	<packaging>pom</packaging>
	<name>simple-parent</name>
	<description>学习eureka</description>
	<parent>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-parent</artifactId>
		<version>2.0.3.RELEASE</version>
		<relativePath/>
	</parent>
	<properties>
		<project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
		<project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
		<java.version>1.8</java.version>
		<spring-cloud.version>Finchley.RELEASE</spring-cloud.version>
	</properties>
	<dependencies>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-test</artifactId>
			<scope>test</scope>
		</dependency>
	</dependencies>
	<dependencyManagement>
		<dependencies>
			<dependency>
				<groupId>org.springframework.cloud</groupId>
				<artifactId>spring-cloud-dependencies</artifactId>
				<version>${spring-cloud.version}</version>
				<type>pom</type>
				<scope>import</scope>
			</dependency>
		</dependencies>
	</dependencyManagement>
	<build>
		<plugins>
			<plugin>
				<groupId>org.springframework.boot</groupId>
				<artifactId>spring-boot-maven-plugin</artifactId>
			</plugin>
		</plugins>
	</build>

</project>
```

<!--more-->

## 单机版

1. 首先我们需要建立一个服务注册中心`eureka-server`，pom 文件如下：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>
	<groupId>learn.spring.cloud.eureka.demo</groupId>
	<artifactId>eureka-server</artifactId>
	<packaging>jar</packaging>
	<version>1.0-SNAPSHOT</version>
	<name>eureka server</name>
	<description>服务注册中心 eureka 第一个服务实例</description>
	<parent>
		<artifactId>learn-spring-cloud-eureka</artifactId>
		<groupId>learn.spring.cloud.eureka.demo</groupId>
		<version>1.0-SNAPSHOT</version>
	</parent>
	<dependencies>
		<dependency>
			<groupId>org.springframework.cloud</groupId>
			<artifactId>spring-cloud-starter-netflix-eureka-server</artifactId>
		</dependency>
	</dependencies>
</project>
```

然后仅需在 springboot 的启动项上添加`@EnableEurekaServer`注解即可。其实只要我们在 pom 文件中引入了`eureka-server`的 jar 包，springboot 就会自动将它作为`eureka server`，但是为了更加友好，还是在启动项上添加注解来启动。

然后我们要修改配置文件：

```yaml
spring:
  application:
    name: eurka-server # 定义项目名称，方便从控制面板查看项目注册情况
    
eureka:
  client:
    # registerWithEureka 此实例是否应将其信息注册到eureka服务器以供其他服务发现
    # 我们可以先将下面两项设置为 true 可以更加直观的从网页上看到服务端注册的信息。
    registerWithEureka: false
    fetchRegistry: false
    serviceUrl:
      defaultZone: http://127.0.0.1:8761/eureka/ #eureka 默认的端口为8761
```

然后我们就可以启动项目，并且打开`http://localhost:8761`来查看项目的配置情况

![](https://raw.githubusercontent.com/liunaijie/images/master/20191218120848.png)

可以看到，我们建立的 eureka-server 已经注册到我们的注册中心(只是为了演示，单机情况下注册中心不会再注册到注册中心上)。

2. 然后我们再建立生产者`eureka-provider`

    首先创建我们的 pom文件，我们需要将这个服务注册到 eureka 的服务端，所以我们这次需要导入`eureka client`包，并且我们需要对外提供 rest 服务，所以我们又导入了`web`相关。最终如下：

    ```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <project xmlns="http://maven.apache.org/POM/4.0.0"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    
    	<groupId>learn.spring.cloud.eureka.demo</groupId>
    	<artifactId>eureka-provider</artifactId>
    	<version>1.0-SNAPSHOT</version>
    	<packaging>jar</packaging>
    
    	<parent>
    		<artifactId>learn-spring-cloud-eureka</artifactId>
    		<groupId>learn.spring.cloud.eureka.demo</groupId>
    		<version>1.0-SNAPSHOT</version>
    	</parent>
    
    	<name>eureka provider</name>
    	<description>一个服务提供者，注册到 eureka 中供消费者调用</description>
    
    	<modelVersion>4.0.0</modelVersion>
    
    
    	<dependencies>
    		<dependency>
    			<groupId>org.springframework.cloud</groupId>
    			<artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
    		</dependency>
    		<dependency>
    			<groupId>org.springframework.boot</groupId>
    			<artifactId>spring-boot-starter-web</artifactId>
    		</dependency>
    	</dependencies>
    
    </project>
    ```

    接下来是我们的配置文件

    ```yaml
    spring:
      application:
        name: eureka-provider # 创建这个服务的名称
        
    server:
      # 这个业务实例的端口
      port: 8080
    
    eureka:
      instance:
        prefer-ip-address: true # 用 ip 而不是 host 的方式
      client:
        serviceUrl:
          # 注册中心的地址
          defaultZone: http://localhost:8761/eureka/
          
    ```

    然后我们要在这个项目的启动类上添加`@EuableEurekaClient`注册，从而将这个服务注册到服务中心。并且我们这个服务是需要对外提供 rest 的，所以我有定义了一个方法来供外部调用，最终启动类如下：

    ```java
    @SpringBootApplication
    @EnableEurekaClient
    @RestController
    public class EurekaProviderApplication {
    
    	public static void main(String[] args) {
    		SpringApplication.run(EurekaProviderApplication.class, args);
    	}
    
    	@Value("${server.port}")
    	String port;
    
    	@GetMapping(value = "/provider")
    	public String sayHello(@RequestParam(value = "name", defaultValue = "consumer") String name) {
    		return "hello," + name + "。 i am the provider from port :" + port;
    	}
    
    }
    ```

    然后我们启动项目，启动项目后我们去 eureka-server 的网页上查看注册信息：

    ![](https://raw.githubusercontent.com/liunaijie/images/master/20191218122211.png)

    我们可以看到我们刚刚启动的这个生产者项目已经注册到注册中心了，并且他的端口是我们设置的8080。

    然后我们验证一下我们对外提供的接口

    ![](https://raw.githubusercontent.com/liunaijie/images/master/20191218122341.png)

    全部成功后我们就需要进行下一步，创建消费者

    3. 创建消费者

        消费者与生产者的 pom 文件是一样的，这样就不再贴上了。

        然后是我们的配置文件

        ```yaml
        server:
          port: 8083 # 服务启动的端口
        
        spring:
          application:
            name: eureka-consumer # 服务名称
        
        eureka:
          instance:
            prefer-ip-address: true
          client:
            serviceUrl:
              # eureka server 的地址
              defaultZone: http://localhost:8762/eureka/
        ```

        最后就是我们的启动类：

        ​	消费者是要去调用生产者的具体实现。也就是我们要访问消费者的接口，但实际返回信息是从生产者那里过了一遍的。我们在这里使用 springboot 提供的`RestTemplate`作为http 请求的工具类。我们需要从注册中心里拿到我们所需要服务实例的访问地址和端口，然后通过`RestTemplate`去请求。具体代码如下：

        ```java
        @SpringBootApplication
        @EnableDiscoveryClient
        @RestController
        public class EurekaConsumerApplication {
        
        	@Autowired
        	private EurekaClient eurekaClient;
        	@Autowired
        	private RestTemplate restTemplate;
        
        	public static void main(String[] args) {
        		SpringApplication.run(EurekaConsumerApplication.class, args);
        	}
        
        	@Bean
        	public RestTemplate restTemplate(RestTemplateBuilder builder) {
        		return builder.build();
        	}
        
        	@GetMapping(value = "/consumer")
        	public Object getFromProvider() {
        		//通过 eureka 查找服务名为eureka-provider的实例返回一个访问地址，会先经过负载均衡（轮询）然后再返回
        		InstanceInfo instance = eurekaClient.getNextServerFromEureka("eureka-provider", false);
        		String homePageUrl = instance.getHomePageUrl();
        		//然后调用接口，获取数据
        		return restTemplate.getForObject(homePageUrl + "provider?name=world", String.class);
        	}
        
        }
        ```

        ​	我们首先用`eurekaClient`去获取我们所需服务的可访问地址，然后拿到访问链接，最终通过拼接的方式拼接出我们需要访问的链接。在这里我直接将生产者返回的信息返回出去。

        ​	我们启动项目后，首先去eureka-server 的页面上查看我们是否将消费者注册到注册中心上了：

        ![](https://raw.githubusercontent.com/liunaijie/images/master/20191218124110.png)

        然后我们就需要去验证，我们是否可以通过访问消费者来得到生产者返回的信息：从上面的代码中可以看到，我在消费者去请求时传递了参数为`world`,如果请求成功，它的返回信息将为`hello world`。

        ![](https://raw.githubusercontent.com/liunaijie/images/master/20191218124334.png)

        出现这样的返回信息就表示我们成功搭建了一个单机版本的eureka 并完成了消费者与生产者直接的调用。

## 集群版

在实际生产中，我们的实例可以部署多份，这时需要将eureka-server 也部署多份，并且实现注册节点的互通。我们根据上面的项目来进行改进

1. 首先是 eureka-server

    我定义了多个配置文件，在启动时分别启动不同的配置文件即可。

    ![](https://raw.githubusercontent.com/liunaijie/images/master/20191218125623.png)

    在 8762 的配置文件中是这样的：

    ```yaml
    # 集群eureka配置
    server:
      port: 8762
    eureka:
      instance:
        hostname: localhost
      client:
        serviceUrl:
          defaultZone: http://localhost:8763/eureka/,http://localhost:8764/eureka/ # 集群配置，将注册到本机的节点也发送到其他节点
    ```

    在不同的配置文件中修改端口，然后修改注册地址，将本身的信息注册到其他节点上，实现信息互通

    在 idea 中可以这样来启动不同配置文件的实例项目

    ![](https://raw.githubusercontent.com/liunaijie/images/master/20191218125724.png)

2. 接下来是 eureka-provider

    我也将这个服务通过配置文件的方式在本机启动多份。

    ![](https://raw.githubusercontent.com/liunaijie/images/master/20191218131314.png)

    启动方式同上面的一样。

3. 启动

    消费者我就没有启动多个实例了，我们将所以的项目实例进行启动

    ![](https://raw.githubusercontent.com/liunaijie/images/master/20191218131440.png)

然后打开网页查看注册信息

![](https://raw.githubusercontent.com/liunaijie/images/master/20191218131811.png)

由于我在生产者和消费者写的地址8762，所以启动完后在 8762 会有信息，而其他的两个节点需要等待一段时间后由 8762 节点发送过去。

然后我们访问消费者节点，看一下他是不是会访问多个生产者节点。

![](https://raw.githubusercontent.com/liunaijie/images/master/20191218132430.png)

![](https://raw.githubusercontent.com/liunaijie/images/master/20191218132443.png)

可以看出，返回信息不同，说明是访问了不同的服务实例，并且多请求几次后会发现这个是轮询负载均衡策略。

我将完整的代码放到了 github，地址为https://github.com/liunaijie/learn-demo/tree/master/SpringCloud/Eureka/learn-spring-cloud-eureka

