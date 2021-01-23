---
title: Java注解
date: 2019-12-06 09:28:00
categories: "java"
toc: true
tags: 
	- java
---

注解，这个经常在开发中使用到的东西，它的使用语法是怎么样的？如何去自定义一个注解呢？

# 什么是注解

我们在日常开发中，比如 java 中的`@Override`，在 springboot 中用到的`@SpringBootApplication`等一系列标注在类或者方法上的注解。我们添加上注解后会有对应的事件处理，比如我们的`@Override`注解标明这个方法是重写了父类或者接口的方法，当参数不一致、返回类型不一致等不符合重写的要求时，编译器会报错。类似的`@SpringBootApplication`也是标明这个项目的一个 springboot 项目，默认会启动一个 tomcat 容器等。

注解是从 jdk5 开始引入的新特性。

# 注解的语法

```java
public @interface FirstAnnotation {}
```

通过`@interface`即可声明一个注解。

<!--more-->

## 内置的注解

Java 定义了一套注解，共有 7 个，3 个在 java.lang 中，剩下 4 个在 java.lang.annotation 中

### 作用在代码的注解是

- `@Override` - 检查该方法是否是重载方法。如果发现其父类，或者是引用的接口中并没有该方法时，会报编译错误。
- `@Deprecated` - 标记过时方法。如果使用该方法，会报编译警告。
- `@SuppressWarnings` - 指示编译器去忽略注解中声明的警告。

### 元注解

我们通过上面的语法定义了一个注解，但还需要其他的注解一同作用。在 jdk1.5中定义了 4 个标准注解，它们用来提供对其他 annotation 类型做说明。分别是：

- `@Retention` - 标识这个注解怎么保存，是只在代码中，还是编入class文件中，或者是在运行时可以通过反射访问。
- `@Documented` - 标记这些注解是否包含在用户文档中。
- `@Target` - 标记这个注解应该是哪种 Java 成员。
- `@Inherited` - 标记这个注解是继承于哪个注解类(默认 注解并没有继承于任何子类)

从 Java 7 开始，额外添加了 3 个注解:

- `@SafeVarargs` - Java 7 开始支持，忽略任何使用参数为泛型变量的方法或构造函数调用产生的警告。
- `@FunctionalInterface` - Java 8 开始支持，标识一个匿名函数或函数式接口。
- `@Repeatable` - Java 8 开始支持，标识某注解可以在同一个声明上使用多次。

#### @Retention

```java
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.ANNOTATION_TYPE)
public @interface Retention {
   
    RetentionPolicy value();
}


public enum RetentionPolicy {
    /* 注解被编译器丢弃，不会保留到 class 文件中 */
    SOURCE,
    /* 默认的类型。 注解在 class 文件中可用，但会被 jvm 丢弃 */
    CLASS,
    /*在运行期也保留，可以通过反射机制读取注解的信息*/
    RUNTIME
}
```

这个注解只有一个变量，类型是一个枚举。可以通过这个变量来表明这个注解是保存在源码中(source)，还是编入 class 文件中(class)，还是在运行时通过反射访问(runtime)。

#### @Target

```java
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.ANNOTATION_TYPE)
public @interface Target {
    
    ElementType[] value();
}


public enum ElementType {
    /* 表明该注解可以用于 类，接口（包括注解类型）或枚举声明*/
    TYPE,
    /* 表明该注解可以用于 字段声明（包括枚举常量） */
    FIELD,
    /* 表明该注解可以用于 方法声明 */
    METHOD,
    /* 表明该注解可以用于 参数声明 */
    PARAMETER,
    /* 表明该注解可以用于 构造函数声明 */
    CONSTRUCTOR,
    /* 表明该注解可以用于 局部变量声明 */
    LOCAL_VARIABLE,
    /* 表明该注解可以用于 注解声明（应用于另一个注解上） */
    ANNOTATION_TYPE,
    /* 表明该注解可以用于 包声明 */
    PACKAGE,
    /* 表明该注解可以用于 类型参数声明@since 1.8 */
    TYPE_PARAMETER,
    /* 类型使用声明 */
    TYPE_USE
}

```

#### @Documented

```java
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.ANNOTATION_TYPE)
public @interface Documented {
}
```

它没有任何变量，添加这个注解可以让我们执行 JavaDoc 文档打包时注解会被保存进 doc 文档，反之将在打包时丢弃。

#### @Inherited

```java
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.ANNOTATION_TYPE)
public @interface Inherited {
}
```

这个注解是什么意思呢？我们通过一个例子来说明一下：

```java
@Inherited
@Documented
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
public @interface DocumentFirst {
}

@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
public @interface DocumentSecond {
}

@DocumentFirst
class A{ }

class B extends A{ }

@DocumentSecond
class C{ }

class D extends C{ }


public class DocumentDemo {

    public static void main(String[] args){
        A instanceA=new B();
        System.out.println("实例 B 拥有的注解:"+Arrays.toString(instanceA.getClass().getAnnotations()));

        C instanceC = new D();

        System.out.println("实例 D 拥有的注解:"+Arrays.toString(instanceC.getClass().getAnnotations()));
    }

    /**
     * 运行结果:
     实例 B 拥有的注解:[@cn.lnj.annotationdemo.DocumentFirst()]
     实例 D 拥有的注解:[]
     */
}
```

可以看出来，添加了`@Inherited`元注解的注解，这个类被继承后的子类也可以拥有这个注解。也就是说这个注解的作用范围是父类和子类。而没有添加这个元注解的注解，作用范围只有被添加的类。

#### @Repeatable

添加这个注解后，注解可以在同一个声明上使用多次，来看一个例子：

```java
public @interface DocumentA {
    String[] names;
}

@Repeatable
public @interface DocumentB {
    String[] names;
}

//相同的注解，不能同时声明多次，因为没有添加@Repeatable注解
@DocumentA(names="AAA")
//@DocumentA(names="BBB")
class A { }

//相同的注解，可以同时被声明多次，不会报错
@DocumentB(names="AAA")
@DocumentB(names="BBB")
class B { }
```

#### @FunctionalInterface

在 jdk1.8中添加了 lambda 表达式，也就是函数式编程。虽然说添加了lambda，但也并不是所有的东西都可以无条件的去使用。需要在接口上添加`@FunctionalInterface`注解，并且这个接口里面只能有一个抽象方法。

# 通过 aop 来进行拦截

通过上面我们可以进行一个自定义的注解，但是我们即便把他声明在方法上，它其实还是没有作用的，如果需要这个注解起到我们想要的作用还需要进行自定义的处理。比如我们使用 aop 来进行这个处理

首先定义一个注解

```java
@Target({ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
public @interface HelloAnnotation {
    
}
```

然后在方法上添加这个注解

```java
@HelloAnnotation
public void sayHello(){
    System.out.println("i am working");
}
```

最后定义拦截器

```java
@Around("@annotation(HelloAnnotation)")
public Object around(ProceedingJoinPoint proceedingJoinPoint, HelloAnnotation helloAnnotation) {
	//方法执行前
    System.out.println("start");
    //调用方法
    proceedingJoinPoint.proceed();
    //方法执行后
    System.out.println("finish");
}
```

这样我们就可以在调用`sayHello()`这个方法后，执行这个拦截器逻辑。

# 参考

- [维基百科](https://zh.wikipedia.org/wiki/Java注解)
- https://blog.csdn.net/javazejian/article/details/71860633