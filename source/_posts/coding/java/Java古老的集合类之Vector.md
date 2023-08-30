---
title: Java古老的集合类之Vector
date: 2019-12-23 11:51:46
tags: 
	- java
---

今天继续来看一下Java中古老的集合类-Vector

# 变量

```java
//容器存储实体的底层数据结构，Vector也是使用数组来进行存储的
protected Object[] elementData;
//实体的数量
protected int elementCount;
//每次扩容时增加的长度，当为0是扩容原数组长度的两倍
protected int capacityIncrement;
```

从上面的变量可以得知，Vector也是使用数组来进行底层的数据存储，并且还设置了扩容容量。

<!--more-->

# 构造函数

```java
public Vector() {
  this(10);
}

public Vector(int initialCapacity) {
  this(initialCapacity, 0);
}

public Vector(int initialCapacity, int capacityIncrement) {
  super();
  if (initialCapacity < 0)
    throw new IllegalArgumentException("Illegal Capacity: "+
                                       initialCapacity);
  this.elementData = new Object[initialCapacity];
  this.capacityIncrement = capacityIncrement;
}

public Vector(Collection<? extends E> c) {
        elementData = c.toArray();
        elementCount = elementData.length;
        // c.toArray might (incorrectly) not return Object[] (see 6260652)
        if (elementData.getClass() != Object[].class)
            elementData = Arrays.copyOf(elementData, elementCount, Object[].class);
    }
```

构造函数主要分为两类，一类指定初始容量和扩容容量，一类则是将Collection转换为Vector。

默认的初始容量为10，扩容容量为0也就是双倍扩容。

# add()

```java
public synchronized boolean add(E e) {
    modCount++;
    ensureCapacityHelper(elementCount + 1);
    elementData[elementCount++] = e;
    return true;
}
```

首先在方法上添加了`synchronized`关键字。保证了多线程情况下的安全性。

由于继承自`AbstactList`，所以在添加元素中对`modCount`数量进行了加一。然后调用函数`ensureCapacityHelper()`，查看是否需要扩容。完成后在数组中将元素设置进去。最后返回true。 

来看一下它的扩容机制

```java
private void ensureCapacityHelper(int minCapacity) {
  // overflow-conscious code
  if (minCapacity - elementData.length > 0)
    grow(minCapacity);
}

private void grow(int minCapacity) {
  // overflow-conscious code
  int oldCapacity = elementData.length;
  int newCapacity = oldCapacity + ((capacityIncrement > 0) ?
                                   capacityIncrement : oldCapacity);
  if (newCapacity - minCapacity < 0)
    newCapacity = minCapacity;
  if (newCapacity - MAX_ARRAY_SIZE > 0)
    newCapacity = hugeCapacity(minCapacity);
  elementData = Arrays.copyOf(elementData, newCapacity);
}

private static int hugeCapacity(int minCapacity) {
  if (minCapacity < 0) // overflow
    throw new OutOfMemoryError();
  return (minCapacity > MAX_ARRAY_SIZE) ?
    Integer.MAX_VALUE :
  MAX_ARRAY_SIZE;
}
```

判断数组现在容量添加一个实体后会不会超过定义数组的长度，如果超过了长度则需要进行扩容。

在扩容的时候它进行了一个判断，判断我们设置的`capacityIncrement`这个变量是否大于0，如果大于零则按照设置的数量进行扩容，即新数组长度=旧数组长度+`capacityIncrement`。否则每次增加为旧数组长度的两倍。

下面就是对长度的一个校验，如果我们经过上面的扩容后依然不够我们所需的长度则使用我们所需的长度。还有一个判断是进行双倍扩容后是否会超过int正数的最大值，当超过后就会变成负数，这时肯定不能作为数组的长度单位。还有从上面的代码也能看出，Vector容器的最大长度为int的最大值。但是这个时候在不同的jvm下可能会有问题，所以还有一个`MAX_ARRAY_SIZE`变量，从其他的容器源码中也可以看到这个变量，它保证了在不同的jvm平台下尽量能不出问题。

# get()

```java
public synchronized E get(int index) {
  if (index >= elementCount)
    throw new ArrayIndexOutOfBoundsException(index);

  return elementData(index);
}

E elementData(int index) {
  return (E) elementData[index];
}
```

在方法上添加`synchronized`关键字，保证多线程情况下的安全性。

然后有一个下标的校验。调用了内部的方法，返回数组中下标的元素并通过泛型进行了由Object向下E的转型

# set()

```java
public synchronized E set(int index, E element) {
  if (index >= elementCount)
    throw new ArrayIndexOutOfBoundsException(index);

  E oldValue = elementData(index);
  elementData[index] = element;
  return oldValue;
}
```

在方法上添加`synchronized`关键字，保证多线程情况下的安全性。

然后对入参进行了判断。将原来的值暂存后设置新值，将旧值返回。

# copyInfo()

```java
public synchronized void copyInto(Object[] anArray) {
        System.arraycopy(elementData, 0, anArray, 0, elementCount);
    }
```

这个方法添加了`synchronized`关键字，保证了线程的安全性。然后调用了`System.arraycopy()`方法将Vector中的数据复制到了参数的数组中。

# 与ArrayList异同

## 区别：

1. 线程安全的。

   它在多线程访问的方法上添加了`synchronized`关键字，保证了多线程下只有一个线程进行访问，但是由于全部添加了方法上会造成效率低下。

2. 扩容机制不同

   Vector有一个变量可以设置每次扩容时数组长度增加多少，未设置的情况下会是双倍原数组长度的扩容。

   ArrayList没有设置扩容长度的变量，并且它的扩容机制是原数组长度的1.5倍扩容。

## 相同点

1. 都是采用的数组作为底层的存储结构
2. 大部分方法的思路都是一致的

