---
title: Spring笔记
date: 2019-09-04 16:01:11
tags: 
	- spring
	- java
---

最近在阅读《Spring in action》这本书，也以此篇文章记录一下`spring`框架的相关内容。

那么既然聊`spring`了，一定会聊到的两个点就是`ioc`和`aop`。那就先来聊一下这两个东西。以下都是个人理解，如果有不对的地方，欢迎探讨指正。

ioc 和 aop 是编程思想，di 和 aspect 是他们的具体实现。

# IOC

IOC:控制反转，DI：依赖注入。

## 控制

在传统的 Java SE 程序中，我们在对象内部通过 new 的方法来创建对象实例，在这里是程序主动创建的依赖对象。而在 spring 中，它使用了专门的容器去控制对象。

控制的是对象的**创建、初始化、销毁**过程

在传统的 Java SE中，我们使用 new 进行创建。在构造器或者 setter 方法中给依赖对象赋值。给对象赋值 null 来销毁对象。

而在spring中一个bean的生命周期如下图所示：

![bean的生命周期](https://raw.githubusercontent.com/liunaijie/images/master/spring的bean生命周期.png)

<!--more-->

## 反转

控制反转。我们之前是主动方，主动去控制对象的生命周期。现在变成了由 spring 去进行控制。我们由对象的控制者变成了被动控制者。

## 依赖注入

ioc 思想落实到代码上的具体实现。

在spring中，我们一般使用注解`Component`，`Service`，`Repository`，`Controller`，`Autowired`或`Resource`来进行注入。这个实例化出来的bean生命周期交给了spring来进行管理。我们将他们放在不同的类上表达不同的含义。

如果不进行主动声明，则默认的bean的名称为类名首字母小写，比如我对一个`UserServiceImpl`上添加`@Service`注解，spring则将这个类声明为`userServiceImpl`的bean。也可以这样进行主动声明`@Service("beanName")`。

如果我们对一个接口进入注入，这个接口下有多个实现类，这是spring就不知道我们要使用哪个实现类了，启动时会报错。

![](https://raw.githubusercontent.com/liunaijie/images/master/20190919083201.png)

这时候有两种解决办法：

- 继续使用`@Autowired`注解

    这个注解下也有两种解决方式：

    - 对实现类进行修改，添加`@Primary`首选项注解

        我们对其中一个实现类添加这个注解，那么在注入时会首先注入这个实现类

    - 对引入类添加`@Qualifier`限定符注解

        我们在`@Autowired`下添加这个注解，注解里面的内容为我们要注入实现类bean的id。这时候如果实现类的类名修改了也就是bean的id修改了，就又有问题了。这种情况下可以自定义限定符来实现。

- 使用`@Resource`注解

    使用这个注解，即可在里面直接加参数，指定要注入实现类bean的id。

# AOP

面向切面编程：

> 在软件开发中，散布于应用中多处的功能被称为横切关注点。通常来讲，这些横切关注点从概念上是与应用的业务逻辑相分离的（但是往往会直接嵌入到应用的业务逻辑之中）。把这些横切关注点与业务逻辑相分离正是面向切面（AOP）所要解决的问题。

比如说我们现在有一个业务系统，有学生，教师，课程几个业务模块，我们现在需要一些功能，比如说日志，事务等功能，这些功能实际上并不是我们的业务模块，但是又需要在系统中添加，这就可以利用面向切面来解决这个问题。

![](https://raw.githubusercontent.com/liunaijie/images/master/a4.1.png)

> 在使用面向切面编程时，我们仍然在一个地方定义通用功能，但是可以通过声明的方式定义这个功能要以何种方式在何处应用，而无需修改受影响的类。横切关注点可以被模块化为特殊的类，这些类被称作切面（aspect）。这样做有两个好处：首先，现在每个关注点都集中于一个地方，而不是分散到多处代码中；其次，服务模块更简洁，因为它们只包含主要关注点（业务功能）的代码，而次要关注点的代码被转移到切面中了。

## AOP术语

描述切面的常用术语有通知(advice)，切点(pointcut)和连接点(joinpoint)。

### 通知（Advice）

通知定义了切面是什么以及何时使用。  

spring切面可以应用5种类型的通知

- 前置通知（Before）：在目标方法被调用之前调用通知功能；
- 后置通知（After）：在目标方法完成之后调用通知，此时不会关心方法的输出是什么；
- 返回通知（After-returning）：在目标方法成功执行之后调用通知；
- 异常通知（After-throwing）：在目标方法抛出异常后调用通知；
- 环绕通知（Around）：通知包裹了被通知的方法，在被通知的方法调用之前和调用之后执行自定义的行为。

### 连接点(JoinPoint)

连接点是在应用执行过程中能够插入切面的一个点。（被切入的地方）

### 切点(PointCut)

切点定义了"何处"。切点的定义会匹配通知所要织入的一个或多个连接点。我们通常使用明确的类和方法名称，或是利用正则表达式定义所匹配的类和方法名称来制定这些切点。有些AOP框架允许我们创建动态的切点，可以根据运行时的决策（比如方法的参数值）来决定是否应用通知。（定义的包，类，方法，注解等）

### 切面(Aspect)

切面是通知和切点的结合，通知和切点共同定义了切面的全部内容--它是什么，在何时和何处完成其功能。

### 引入

引入允许我们向现有的类添加新方法或属性。

### 织入

织入是把切面应用到目标对象并创建新的代理对象的过程。切面在指定的连接点被织入到目标对象中。在目标对象的生命周期里有多个点可以进行织入：

- 编译期：切面在目标类编译时被织入，这种方式需要特殊的编译器。AspectJ的织入编译器就是以这种方式织入切面的。
- 类加载期：切面在目标类加载到JVM时被织入。这种方式需要特殊的类加载器(ClassLoader)，它可以在目标被引入应用之前增强该目标类的字节码，AspectJ5的加载时织入就支持以这种方式织入切面。
- 运行期：切面在应用运行的某个时刻被织入。一般情况下，在织入切面时，AOP容器会为目标对象动态地创建一个代理对象。Spring AOP就是以这种方式织入切面的。

## 实现

#### 代码

```java
// 添加 @Aspect注解声明这是一个切面类
@Aspect
// 添加 @Component注解声明这是一个javabean，不然spring扫描不到这个类，我们在这里写的东西就没有用
@Component
public class TestAspect{
    
    // 使用@Pointcut注解定义可重用的切点，这样在下面就可以直接调用这个切点的方法名即可
    @Pointcut("execution(* com.test..*.*(..))")
    public void testPointcut() {
	}
    
    @Before("testPointcut()")
    public void doBefore(){
        System.out.println("method before...");
    }
    
    @After("testPointcut()")
    public void doAfter(){
        System.out.println("method after...");
    }
    
}	
```

我先声明了利用`@Pointcut`声明了一个切点，里面使用了`execution`关键字，这个关键字里面的内容就描述了我要对哪个地方进行切入。

![execution表达式解析](https://raw.githubusercontent.com/liunaijie/images/master/execution表达式解析.png)

在我刚才写的代码里面我是对`com.test`包下的所有的类，所有的方法，不管其参数类型，返回结果类型都进行切入，当`com.test`包下的方法被调用时，调用前会打印`doBefore()`方法中的内容，调用完成后会打印`doAfter()`方法中的内容。

我们只需要调整表达式里面的内容就可以自定义实现要切入的点。

然后再说一下对**注解**的切入  

如果我们自定义了一个注解，然后需要对这个注解实现切入。

```java
@Aspect
@Component
public class TestAspect{
    
    @Around("@annotation(testAnnotation)")
    public void around(ProceedingJoinPoint proceedingJoinPoint) {
       try{
            System.out.println("before method proceed...");
            proceedingJoinPoint.proceed();
            System.out.println("after method proceed...");
       }catch(Exception e){
           System.out.println("method error...");
       }
    }
}

```

对添加了`testAnnotation`注解的方法会执行这个切入，并且我使用了环绕通知。这里多了一个`ProceedingJoinPoint`参数，这个对象是必须要有的，需要调用`proceed()`方法才会实际调用被切入点执行的方法，而有意思的地方是**这个方法我们可以不调用(不会执行被切入点的逻辑)，也可调用一至多次**。

之前说的通知也有相应的注解

| 注解            | 通知                                     |
| --------------- | ---------------------------------------- |
| @Before         | 通知方法会在目标方法调用之前执行         |
| @After          | 通知方法会在目标方法返回或抛出异常后调用 |
| @AfterReturning | 通知方法会在目标方法返回后调用           |
| @AfterThrowing  | 通知方法会在目标方法抛出异常后调用       |
| @Around         | 通知方法会将目标方法封装起来             |

#### 进阶

1. 多个切面时执行顺序

    当一个类被多个切面切入时，如何控制多个切面的顺序呢？这时需要使用`@Order()`注解。

    ```java
    @Aspect
    @Component
    @Order(1)  //数值越小，优先级越高
    public class TestAspect{
    	...
    }
    ```

    

2. 设置在特定环境中使用 aop

    有一些通过 aop 实现的功能我们可能只想在开发、测试环境中进行使用。在生成环境中进行关闭。这时我们可以添加`@Profile`注解即可

    ```java
    @Aspect
    @Component
    @Profile({"dev","test"})  //添加这个注解即可在开发，测试环境中使用这个切面
    public class TestAspect{
    	...
    }
    ```

    添加这个注解后，需要在配置文件的`spring.profiles.active`属性设置为`dev`或`test`并添加相应的配置文件即可。

通过一张图来说明 aop 的执行顺序。

![aop流程](https://raw.githubusercontent.com/liunaijie/images/master/aop 流程.png)

#### 通过注解引入新功能

我们知道，切面只是实现了它们所包装的bean相同接口的代理。所以我们可以让接口暴露新的接口来实现添加新功能，比如现在我们需要对源码中的方法进行增强，需要添加一个方法，那么这个方式就很好的实现。

![](https://raw.githubusercontent.com/liunaijie/images/master/aop添加新功能.png)

```java
@Aspect
@Component
public class AddMethodAspect{
    
    @DeclareParents(value="com.test.ClassA+",defaultImpl=DefaultEncoreable.class)
    public static Encoreable encoreable;
    
}

// 新增加的接口，对切面新增加了一个方法
public interface Encoreable {
    void performEncore();
}

public class DefaultEncoreable implements Encoreable {
    
    @Override
    void performEncore(){
        System.out.println("this is a new method");
    }
}
```

这里也是定义了一个切面，但是这个切面有之前定义的有所不同，它并没有定义切点，通知方法。而是通过`@DeclareParents`注解，将`Encoreable`接口引入到`ClassA`**bean**中。

`@DeclareParents`注解主要由三部分组成

- value属性指定了哪种类型的bean要引入该接口，在本例中，也就是所有实现` ClassA`的类型。（标记符后面的加号表示所有子类型，而不是本身）
- defaultImpl属性指定了为引入功能提供实现的类，这里指定了`DefaultEncoreable`提供实现
- `@DeclareParents`注解所标记的静态属性指明了要引入的接口。

这样在调用所有实现`ClassA`类型的bean时，都可以进行调用`performEncore`方法。

**spring会创建一个代理，然后将调用委托给被代理的bean或被引入的实现，这取决于调用的方法属于被代理的bean还是属于被引入的接口。**

## AOP 使用场景

- 权限控制
- 日志存储
- 统一异常处理
- 缓存处理
- 事务处理
- ……

# 事务

## 事务隔离级别

在spring中，事务的隔离级别有五种，分别为

- DEFAULT(默认)

	使用数据库的隔离级别

- READ_UNCOMMITTED(读未提交)

- READ_COMMITTED(读已提交)

- SERIALIZABLE(串行化)

就是数据库的四种事务隔离级别再加上一个`default`，其他四种事务隔离级别在[MySQL知识整理这篇文章中进行了记录

## 事务传播级别

一共有7种

- Required

	当前方法必须运行在事务中，如果当前事务存在，方法就在该事务中运行，否则会启动一个新的事务

- Supports

	不需要事务，但是如果存在事务就在事务中运行

- Mandatory

	方法必须在事务中运行，如果不存在事务就抛出一个异常

- REQUIRES_NEW

	当前方法必须运行在自己的事务中，新启动一个事务，如果当时有事务则将当前事务挂起

- Not_Supported

	当前方法不运行在事务中，如果存在事务，则在方法运行期间将事务挂起

- Never

	当前方法不应该运行在事务中，如果有事务，就抛出异常

- Nested

	如果当前存在事务，则会嵌套事务运行，嵌套的事务可以独立的提交和回滚，不会对嵌套外部的事务有影响。如果当前不存在事务，则和Required一样



## Spring 中事务无效的情况（@Transactional）

1. 数据库是否支持事务

2. 注解添加在私有方法上`private`无效

3. 拦截的异常小于抛出的异常，注解里面的参数`rollbackFor`执行回滚的异常类型，如果这个异常类型比抛出的异常类型小就无法回滚。

4. 加入在未加入接口的public 方法，再通过普通接口方法调用，无效

    ```java
    @Service
    public class UserServiceImpl implements UserService {
        
        @Override
        public void implementsMethod(){
            // 实现的接口方法
            // 此时事务无效
            selfMethod();
        }
        
        @Transactional(propagation = Propagation.REQUIRED, rollbackFor = Exception.class)
        public void selfMethod(){
            //自己新增的方法
            //数据库操作
    		userDao.insert(new User());
    		// 我们知道 0 不能作为除数，所以会报错，然后通过异常拦截回滚
    		int a = 1 / 0;
        }
        
    }
    ```

    

5. 在没有事务的方法中调用有事务的方法，如果在有事务的方法中抛出异常事务也是无效的。

    ```java
    @Service
    public class UserServiceImpl implements UserService {
    	@Override
    	public void noTransactional() {
            // 此时事务无效
    		hasTransactional();
    	}
    
    	@Transactional(propagation = Propagation.REQUIRED, rollbackFor = Exception.class)
    	@Override
    	public void hasTransactional() {
    		//数据库操作
    		userDao.insert(new User());
    		// 我们知道 0 不能作为除数，所以会报错，然后通过异常拦截回滚
    		int a = 1 / 0;
    	}
    }
    ```

    如果要对这种情况进行改进，可以使用两种方式

    1. 对调用方法添加事务注解

    2. 调用时通过实例调用

        ```java
        @Service
        public class UserServiceImpl implements UserService {
        	
            @Autowired
        	private UserService userService;
            
            @Override
        	public void noTransactional() {
                // 此时事务有效
        		userService.hasTransactional();
        	}
        
        	@Transactional(propagation = Propagation.REQUIRED, rollbackFor = Exception.class)
        	@Override
        	public void hasTransactional() {
        		//数据库操作
        		userDao.insert(new User());
        		// 我们知道 0 不能作为除数，所以会报错，然后通过异常拦截回滚
        		int a = 1 / 0;
        	}
        }
        ```

        

# 配置文件加载顺序

几个常用的方式顺序，优先级高的会覆盖优先级低的。

1. 命令行参数
2. jar包同级的目录中的配置文件
3. 源码resources中的配置文件

我们用几个例子来说明，一个项目的结构如下：

1. > -- application.properties
   >
   > |-- demo.jar
   >
   > ​		|-- application.properties

那么这个在目录外的配置文件会比源码里面的配置文件优先级高

2. 当我们设置了`spring.profile.active`这个属性后，会根据不同环境选择不同的配置文件

>-- applitaion.properties
>
>​	|-- spring.profile.active=dev
>
>​	|-- server.port=8080
>
>-- applicaton-dev.properties
>
>​	|-- server.port=8081

当在主配置文件中设置`spring.profile.active`属性为`dev`时，`-dev`的配置文件就会生效，像上面的配置则会以8081端口启动，即带`{profile}`的配置文件优先级高

3. 在上面的情况下在进行扩展，当jar包外部也有一个`-dev`的配置文件时，在外部的优先级会更高。