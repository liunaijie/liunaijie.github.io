---
title: SpringBoot启动过程
tags:
---

声明一个springboot的应用程序，在启动时只需执行`SpringApplication.run(xxx.class, args)`这样一行代码即可，那么它的启动流程到底是怎样的呢？从这个run方法开始深入看一下它的启动流程。

```java
public static ConfigurableApplicationContext run(Class<?> primarySource, String... args) {
    return run(new Class[]{primarySource}, args);
}
```

调用的方法传入了一个启动类，一个数组参数，在这个方法中将其启动类转换为数组调用另一个方法

```java
public static ConfigurableApplicationContext run(Class<?>[] primarySources, String[] args) {
    return (new SpringApplication(primarySources)).run(args);
}
```

首先调用了`SpringApplication`的构造函数，将启动类作为参数传递.

```java
public SpringApplication(Class<?>... primarySources) {
    this((ResourceLoader)null, primarySources);
}
```

在构造函数中，又调用了另一个构造函数，将ResourceLoader置为null。

```java
public SpringApplication(ResourceLoader resourceLoader, Class<?>... primarySources) {
    this.sources = new LinkedHashSet();
    this.bannerMode = Mode.CONSOLE;
    this.logStartupInfo = true;
    this.addCommandLineProperties = true;
    this.addConversionService = true;
    this.headless = true;
    this.registerShutdownHook = true;
    this.additionalProfiles = new HashSet();
    this.isCustomEnvironment = false;
    this.resourceLoader = resourceLoader;
    Assert.notNull(primarySources, "PrimarySources must not be null");
    this.primarySources = new LinkedHashSet(Arrays.asList(primarySources));
    this.webApplicationType = WebApplicationType.deduceFromClasspath();
    this.setInitializers(this.getSpringFactoriesInstances(ApplicationContextInitializer.class));
    this.setListeners(this.getSpringFactoriesInstances(ApplicationListener.class));
    this.mainApplicationClass = this.deduceMainApplicationClass();
}
```

在这里首先进行了一系列变量的赋值操作



```java
private static final String[] SERVLET_INDICATOR_CLASSES = new String[]{"javax.servlet.Servlet", "org.springframework.web.context.ConfigurableWebApplicationContext"};

static WebApplicationType deduceFromClasspath() {
    if (ClassUtils.isPresent("org.springframework.web.reactive.DispatcherHandler", (ClassLoader)null) && !ClassUtils.isPresent("org.springframework.web.servlet.DispatcherServlet", (ClassLoader)null) && !ClassUtils.isPresent("org.glassfish.jersey.servlet.ServletContainer", (ClassLoader)null)) {
        return REACTIVE;
    } else {
        String[] var0 = SERVLET_INDICATOR_CLASSES;
        int var1 = var0.length;

        for(int var2 = 0; var2 < var1; ++var2) {
            String className = var0[var2];
            if (!ClassUtils.isPresent(className, (ClassLoader)null)) {
                return NONE;
            }
        }

        return SERVLET;
    }
}
```

从类路径推断类型WebApplicationType，然后调用了ClassUtils.isPresent()方法判断类是否存在。

```java
public static boolean isPresent(String className, @Nullable ClassLoader classLoader) {
    try {
        forName(className, classLoader);
        return true;
    } catch (IllegalAccessError var3) {
        throw new IllegalStateException("Readability mismatch in inheritance hierarchy of class [" + className + "]: " + var3.getMessage(), var3);
    } catch (Throwable var4) {
        return false;
    }
}
```

```java
public static Class<?> forName(String name, @Nullable ClassLoader classLoader) throws ClassNotFoundException, LinkageError {
    Assert.notNull(name, "Name must not be null");
    Class<?> clazz = resolvePrimitiveClassName(name);
    //如果为空则进行赋值
  	if (clazz == null) {
        clazz = (Class)commonClassCache.get(name);
    }
		//不为空时返回
    if (clazz != null) {
        return clazz;
    } else {
        Class elementClass;
        String elementName;
        if (name.endsWith("[]")) {
            elementName = name.substring(0, name.length() - "[]".length());
            elementClass = forName(elementName, classLoader);
            return Array.newInstance(elementClass, 0).getClass();
        } else if (name.startsWith("[L") && name.endsWith(";")) {
            elementName = name.substring("[L".length(), name.length() - 1);
            elementClass = forName(elementName, classLoader);
            return Array.newInstance(elementClass, 0).getClass();
        } else if (name.startsWith("[")) {
            elementName = name.substring("[".length());
            elementClass = forName(elementName, classLoader);
            return Array.newInstance(elementClass, 0).getClass();
        } else {
            ClassLoader clToUse = classLoader;
            if (classLoader == null) {
                clToUse = getDefaultClassLoader();
            }

            try {
                return Class.forName(name, false, clToUse);
            } catch (ClassNotFoundException var9) {
                int lastDotIndex = name.lastIndexOf(46);
                if (lastDotIndex != -1) {
                    String innerClassName = name.substring(0, lastDotIndex) + '$' + name.substring(lastDotIndex + 1);

                    try {
                        return Class.forName(innerClassName, false, clToUse);
                    } catch (ClassNotFoundException var8) {
                    }
                }

                throw var9;
            }
        }
    }
}
```

这里判断类名称时，有几个不同寻常的判断，例如`[L`,`[]`等，这是判断数组的情况，例如`Double[].class.getName()`的结果是`[Ljava.lang.Double;`。而`int[].class.getName()`的结果是`[L`

```java
@Nullable
public static Class<?> resolvePrimitiveClassName(@Nullable String name) {
    Class<?> result = null;
    if (name != null && name.length() <= 8) {
        result = (Class)primitiveTypeNameMap.get(name);
    }

    return result;
}
```

​	在这个方法中，当类名不为空并且长度小于等于8位时从一个map中根据类名得到这个类。

如果为空则从缓存Map中再获取一次，当这两次能获取到值时就返回，如果仍获取不到值，则继续进行。

接下来调用了两个方法`setInitializers`和`setListeners`。先看一下`setInitializers`方法，这个里面传入了`this.getSpringFactoriesInstances(ApplicationContextInitializer.class))`。

在这里面又调用了其他方法，传入了一个接口类

```java
private <T> Collection<T> getSpringFactoriesInstances(Class<T> type) {
    return this.getSpringFactoriesInstances(type, new Class[0]);
}
//
private <T> Collection<T> getSpringFactoriesInstances(Class<T> type, Class<?>[] parameterTypes, Object... args) {
  ClassLoader classLoader = this.getClassLoader();
  Set<String> names = new LinkedHashSet(SpringFactoriesLoader.loadFactoryNames(type, classLoader));
  List<T> instances = this.createSpringFactoriesInstances(type, parameterTypes, classLoader, args, names);
  AnnotationAwareOrderComparator.sort(instances);
  return instances;
}

//获取类加载器，这里进行了判断如果传入类加载器则使用否则使用默认加载器
public ClassLoader getClassLoader() {
  return this.resourceLoader != null ? this.resourceLoader.getClassLoader() : ClassUtils.getDefaultClassLoader();
}
//首先根据类获取类的名称，然后通过类加载器进行加载类
public static List<String> loadFactoryNames(Class<?> factoryClass, @Nullable ClassLoader classLoader) {
  String factoryClassName = factoryClass.getName();
  return (List)loadSpringFactories(classLoader).getOrDefault(factoryClassName, Collections.emptyList());
}
```

