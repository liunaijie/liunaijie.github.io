---
title: StringBuilder为什么线程不安全?
date: 2019-11-17 16:55:30
tags: 
- java
---

在脉脉上看到一篇文章，StringBulider 为什么线程不安全，然后想了一下，确实不知道。

之前问string 相关问题，只了解了 string 不可变，stringbuffer 线程安全，stringbuilder 线程不安全。但却没有搞清楚为什么是不安全的，今天就去看了一下 stringbuilder 的源码，来了解一下原因。

首先来测试一下多线程下的不安全问题：

```java
public static void main(String[] args) {
    StringBuilder stringBuilder = new StringBuilder();

    for (int i = 0; i < 100000; i++) {
        new Thread(() -> stringBuilder.append("a")).start();
    }

    System.out.println(stringBuilder.length());

}
```

这个方法最终的理想结果应该是 100000，但是当我们多运行几次，发现他的结果出错了！结果变成了99999或者更小的数值。有时候甚至还抛出了数组越界异常（概率极小）。

<!--more-->

# 代码分析

```javascript
@Override
public StringBuilder append(String str) {
    super.append(str);
    return this;
}

public int length() {
    return count;
}
```

查看 stringbuilder 的 append 方法发现是调用了父类`AbstractStringBuilder`的 append 方法，那么继续进入父类的方法中进行查看

```java
char[] value;

public AbstractStringBuilder append(String str) {
    if (str == null)
        return appendNull();
    int len = str.length();
    ensureCapacityInternal(count + len);
    str.getChars(0, len, value, count);
    count += len;
    return this;
}
```

我们跟着代码的逻辑来分析一下：

1. 入参检查

2. 获取 append 的字符串长度并确保数组容量足够( ensureCapacityInternal(count + len) )

    ```java
    private void ensureCapacityInternal(int minimumCapacity) {
        // 如果 原来字符串长度 加上 新添加字符串长度 比 原来char数组长度 大，则需要进行扩容
        if (minimumCapacity - value.length > 0) {
            value = Arrays.copyOf(value,
                                  newCapacity(minimumCapacity));
        }
    }
    //扩容的容量大小，默认是原来字符串长度 2 倍+2
    private int newCapacity(int minCapacity) {
        // overflow-conscious code
        int newCapacity = (value.length << 1) + 2;
        if (newCapacity - minCapacity < 0) {
            newCapacity = minCapacity;
        }
        return (newCapacity <= 0 || MAX_ARRAY_SIZE - newCapacity < 0)
            ? hugeCapacity(minCapacity)
            : newCapacity;
    }
    
    public static char[] copyOf(char[] original, int newLength) {
        char[] copy = new char[newLength];
        System.arraycopy(original, 0, copy, 0,
                         Math.min(original.length, newLength));
        return copy;
    }
    ```

3. 复制字符串( str.getChars(0, len, value, count) )

    ```java
    public void getChars(int srcBegin, int srcEnd, char dst[], int dstBegin) {
        if (srcBegin < 0) {
            throw new StringIndexOutOfBoundsException(srcBegin);
        }
        if (srcEnd > value.length) {
            throw new StringIndexOutOfBoundsException(srcEnd);
        }
        if (srcBegin > srcEnd) {
            throw new StringIndexOutOfBoundsException(srcEnd - srcBegin);
        }
        System.arraycopy(value, srcBegin, dst, dstBegin, srcEnd - srcBegin);
    }
    
    public static native void arraycopy(Object src,  int  srcPos,
                                            Object dest, int destPos,
                                            int length);
    ```

    最终调用`arraycopy`方法，将appen 参数字符串，从 0 开始，到 len 长度，也就是全部内容，复制到strinbuilder 的 char[]中，从 count位置开始放。

这样就完成了一次 stringbuilder 的 append 过程。

# 错误分析

为什么长度会不对呢？

有点经验的朋友们可能发现了在 append 方法中有一行代码是`count+=len`。而 count 和 len 都是 int 类型，他们在多线程下是不具备原子性的。而长度就是返回的 count 值，所以问题就出现在这里。

那为什么会出现数组越界错误呢？

首先我们要知道，不管是 string，stringbuilder，stringbuffer 都是使用的 char数组来保存字符串的。而 string 的 char数组变量被加了 final 修饰符进行修饰，所以它是不可变的。而stringbuilder，stringbuffer 集成的AbstractStringBuilder使用的 char数组没有加 final 修饰符。

经过上面的分析，数组越界错误可能会出现在两个地方：

- Array.copy

    这个方法是当添加元素时，对原数组进行扩容，保证数组能盛下新数据。**将旧数据复制到新长度的数组中**。

- System.arraycopy

    将要添加的字符串复制到已经扩容完成的 stringbuilder中的char[]中。

出现错误的地方：

线程 1 进行扩容，完毕后切换到线程 2，线程 2 发现添加数据不需要进行扩容。然后切换到线程 1 进行添加数据，线程 1 操作完成。再次切换到线程 2，这时由于线程 1 已经添加数据了，再次添加数据时长度不够了，所以会报错。所以这个**数组越界错误肯定是由`system.arraycopy`方法抛出的**，在 array.copy 方法中不会抛出异常。

# 为什么 StringBuffer 是线程安全的

看一下 stringbuffer 中的代码：

```java
public synchronized StringBuffer append(String str) {
    toStringCache = null;
    super.append(str);
    return this;
}
```

从这里就可以看出为什么是线程安全的了，因为他加了锁，同一时间只能有一个线程进行访问。而它后面的代码也跟 stringbuilder 一样。只不过在入口添加了锁。