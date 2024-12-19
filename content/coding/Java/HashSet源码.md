---
title: HashSet源码
date: 2019-08-26
categories:
  - notes
tags:
  - Java
related-project: "[[Blog Posts/coding/Java/Java|Java]]"
---

# 变量

```java
private transient HashMap<E,Object> map;
// 传入到HashMap中作为value
private static final Object PRESENT = new Object();
```



# 构造函数

```java
public HashSet() {
    map = new HashMap<>();
}

public HashSet(int initialCapacity) {
    map = new HashMap<>(initialCapacity);
}

public HashSet(int initialCapacity, float loadFactor) {
    map = new HashMap<>(initialCapacity, loadFactor);
}

public HashSet(Collection<? extends E> c) {
    map = new HashMap<>(Math.max((int) (c.size()/.75f) + 1, 16));
    addAll(c);
}
```

我们可以看到他的构造函数都是再次调用了`HashMap`的构造函数。将`map`变量初始化为相应的`HashMap`。

# 添加

```java
public boolean add(E e) {
    return map.put(e, PRESENT)==null;
}
```

将传入的`key`，一个空的`value`。通过map的put操作放值到map中。通过map的key不能重复原理。如果key重复，则不会添加到map中。  

# 迭代器

````java
public Iterator<E> iterator() {
    return map.keySet().iterator();
}
````

通过这里我们可以看出来`HashSet`的原理就是在`HashMap`的基础上实现的。  

我们只需要他的`key`集合就是我们所需的`HashSet`。

