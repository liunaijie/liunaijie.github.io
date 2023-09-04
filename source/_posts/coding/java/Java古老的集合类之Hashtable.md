---
title: Java古老的集合类之Hashtable
date: 2019-12-20 10:12:23
categories:
- [coding, java]
tags: 
- java
- collection
---

Hashtable虽然现在不经常被用到，但是它作为Java最早的集合类，今天来看一下它的源码。

首先说明一个问题，在Java中大部分都是驼峰式写法，但是Hasbtable并没有采用这种写法。

# 继承与实现关系

```java
public class Hashtable<K,V> 
  	extends Dictionary<K,V>
    implements Map<K,V>, Cloneable, java.io.Serializable {}
```

可以看出它继承的是`Dictionary`与`HashMap`并不是同一个父类。但是它也实现了`Map`，`Cloneable`，`Serializable`接口。说明它可以被克隆，可以执行序列化。

# 变量

```java
private transient Entry<?,?>[] table;

private transient int count;

private int threshold;

private float loadFactor;

private transient int modCount = 0;
```

来一个一个的解释每一个变量的意义：

- table

与HashMap一样，利用数组作为底层的存储容器，并且添加了关键字`transient`。这个关键字的意思是在进行序列化的时候不会被序列化。这个关键字具体可以看一下[这篇文章](https://www.liunaijie.top/2019/12/22/java/Java关键字-transient)。

- count

表示容器中存储的数量

- threshold

扩容阈值，当容器中的数量到达这个值后会进行扩容机制。这个值默认情况下为 （capacity* loadFactor）

- loadFactor

扩容系数，默认为0.75f。

- modCount

修改次数，当增加或删除时，这个值会进行加一。表示这个容器结构修改的次数。这个变量在迭代，序列化等操作、多线程的操作下都尽量保证了安全性。

<!--more-->

# 构造函数

```java
public Hashtable() {
  this(11, 0.75f);
}

public Hashtable(int initialCapacity) {
  this(initialCapacity, 0.75f);
}

public Hashtable(int initialCapacity, float loadFactor) {
  if (initialCapacity < 0)
    throw new IllegalArgumentException("Illegal Capacity: "+
                                       initialCapacity);
  if (loadFactor <= 0 || Float.isNaN(loadFactor))
    throw new IllegalArgumentException("Illegal Load: "+loadFactor);

  if (initialCapacity==0)
    initialCapacity = 1;
  this.loadFactor = loadFactor;
  table = new Entry<?,?>[initialCapacity];
  threshold = (int)Math.min(initialCapacity * loadFactor, MAX_ARRAY_SIZE + 1);
}

public Hashtable(Map<? extends K, ? extends V> t) {
  this(Math.max(2*t.size(), 11), 0.75f);
  putAll(t);
}
```

从上面的构造函数可以看出几个点：

1. Hashtable的默认容量为 11
2. Hashtable的默认扩容系数为 0.75。

在这几个构造函数中都调用了全参数的构造函数`public Hashtable(int initialCapacity, float loadFactor)`。我们就来具体看一下这个构造函数的执行过程。

1. 首先做了一个入参检查，这一步很值得我们去学习，对方法中的参数先进行检查校验。

   在这里调用了一个函数`Float.isNan(float f)`，这个方法会校验我们传入的值是不是一个正确的浮点数。因为在float与double中有一个值为`NaN`，`public static final float NaN = 0.0f / 0.0f;`。

2. 后面将传入的扩容系数进行赋值，然后构造了一个传入容量大小的数组。再就是扩容阈值的赋值。

这里使用了一个变量`MAX_ARRAY_SIZE`。这个变量的值是`private static final int MAX_ARRAY_SIZE = Integer.MAX_VALUE - 8`。这个值是int的最大值然后减去8。为什么要减去8，在字段注释上也给出了说明：在不同的虚拟机下会有不同的情况，有的会在数组中添加头信息。这是就会占用几个长度。如果使用int最大值就会产生错误。所以使用了int最大值-8。

# put()方法

```java
public synchronized V put(K key, V value) {
  // Make sure the value is not null
  if (value == null) {
    throw new NullPointerException();
  }

  // Makes sure the key is not already in the hashtable.
  Entry<?,?> tab[] = table;
  int hash = key.hashCode();
  int index = (hash & 0x7FFFFFFF) % tab.length;
  @SuppressWarnings("unchecked")
  Entry<K,V> entry = (Entry<K,V>)tab[index];
  for(; entry != null ; entry = entry.next) {
    if ((entry.hash == hash) && entry.key.equals(key)) {
      V old = entry.value;
      entry.value = value;
      return old;
    }
  }

  addEntry(hash, key, value, index);
  return null;
}
```

1. 首先我们可以看出，它在方法上添加了`synchronized`关键字，那么这个方法在同一时间只能有一个线程访问。下面其他方法也是采用的同种方法，保证的线程安全性。

2. 从上面的代码中很容易看出进行了value不能为空的校验。其实key也不能为空。key不能为空的原因是在计算hash值时，在这里调用了`key.hashCode()`这个方法，但是如果我们的key是null，在调用这个方法时会报一个空指针错误。所以Hashtable存储的key，value都不能为null。

   再对比一个HashMap，它计算hash值时是这样的：

```java
static final int hash(Object key) {
  int h;
  return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
}
```

​	它会先进行key为null的判断，如果为null，则返回一个0的哈希值。它也没有对value进行校验，所以HashMap能存储null作为key，value。而Hashtable在存储null时都会报错。

3. 然后它又进行了key相同的判断，先根据key计算hash，然后再计算出这个hash在数组中的下标位置。然后循环判断是否是相同的key，如果key相同则进行替换value、退出方法。所以Hashtable采用的是数组+链表的实现方式。
4. 当没有找到相同的key时会调用`addEntry()`方法

```java
private void addEntry(int hash, K key, V value, int index) {
  modCount++;

  Entry<?,?> tab[] = table;
  if (count >= threshold) {
    // Rehash the table if the threshold is exceeded
    rehash();

    tab = table;
    hash = key.hashCode();
    index = (hash & 0x7FFFFFFF) % tab.length;
  }

  // Creates the new entry.
  @SuppressWarnings("unchecked")
  Entry<K,V> e = (Entry<K,V>) tab[index];
  tab[index] = new Entry<>(hash, key, value, e);
  count++;
}
```

因为填了一个新值，所以数据结构长度增加了1，需要对modCount继续加1。

然后判断是否需要扩容，当容器内实体的数量大于扩容阈值时就要进行扩容`rehash()`。

```java
protected void rehash() {
  int oldCapacity = table.length;
  Entry<?,?>[] oldMap = table;

  // overflow-conscious code
  int newCapacity = (oldCapacity << 1) + 1;
  if (newCapacity - MAX_ARRAY_SIZE > 0) {
    if (oldCapacity == MAX_ARRAY_SIZE)
      // Keep running with MAX_ARRAY_SIZE buckets
      return;
    newCapacity = MAX_ARRAY_SIZE;
        }
  Entry<?,?>[] newMap = new Entry<?,?>[newCapacity];

  modCount++;
  threshold = (int)Math.min(newCapacity * loadFactor, MAX_ARRAY_SIZE + 1);
  table = newMap;

  for (int i = oldCapacity ; i-- > 0 ;) {
    for (Entry<K,V> old = (Entry<K,V>)oldMap[i] ; old != null ; ) {
      Entry<K,V> e = old;
      old = old.next;

      int index = (e.hash & 0x7FFFFFFF) % newCapacity;
      e.next = (Entry<K,V>)newMap[index];
      newMap[index] = e;
    }
  }
}
```

hashtable的扩容机制是将新数组的长度变为 原来数组长度的两倍+1。但是也还不会超过之前定义的`MAX_ARRAY_SIZE`也就是int的最大值-8。然后又将`modCount`值加了1。将扩容阈值进行修改，

然后将原来数组中的值复制到新数组中。

当扩容完成后由于我们这个容器的数组发生了变化，所以又进行了重新取值`tab=table`。并且重新计算了在数组中的下标。

将新值添加到数组中的方法也与`hashmap`有不同。在`addEntry()`方法中，先获取到原来下标中的元素e，然后新建了一个值，并将这个新值的next元素指向刚刚得到的元素e，然后将这个新值放到数组下标位置。也就是新的元素是放到了链表中的头部，而在hashmap的实现中它是遍历链表然后将元素放到链表的尾部，遍历的原因应该是需要判断是否需要转换红黑树。不然还是hashtable的实现方法更加方便一些。

# get()

```java
public synchronized V get(Object key) {
  Entry<?,?> tab[] = table;
  int hash = key.hashCode();
  int index = (hash & 0x7FFFFFFF) % tab.length;
  for (Entry<?,?> e = tab[index] ; e != null ; e = e.next) {
    if ((e.hash == hash) && e.key.equals(key)) {
      return (V)e.value;
    }
  }
  return null;
}
```

首先在方法上添加了`synchronized`关键字，保证了同一时间只能有一个线程访问。

然后根据key计算出在数组中的下标，对链表进行循环，判断如果哈希值和key都一样则返回。

# contains

## containsKey()

```java
public synchronized boolean containsKey(Object key) {
  Entry<?,?> tab[] = table;
  int hash = key.hashCode();
  int index = (hash & 0x7FFFFFFF) % tab.length;
  for (Entry<?,?> e = tab[index] ; e != null ; e = e.next) {
    if ((e.hash == hash) && e.key.equals(key)) {
      return true;
    }
  }
  return false;
}
```

判断容器内是否包含key，首先根据key计算出这个哈希值，然后计算出在数组中的下标。对这个下标内的链表进行循环，如果key相同、哈希值相同则返回true，否则返回false。

## containsValue()

```java
public boolean containsValue(Object value) {
  return contains(value);
}

public synchronized boolean contains(Object value) {
  if (value == null) {
    throw new NullPointerException();
  }

  Entry<?,?> tab[] = table;
  for (int i = tab.length ; i-- > 0 ;) {
    for (Entry<?,?> e = tab[i] ; e != null ; e = e.next) {
      if (e.value.equals(value)) {
        return true;
      }
    }
  }
  return false;
}
```

判断容器内是否包含value，对数组进行循环，然后对数组中的链表进行循环，只有值相同就返回true。当全部遍历完成后如果还未找到则返回false。

# remove()

```java
public synchronized V remove(Object key) {
  Entry<?,?> tab[] = table;
  int hash = key.hashCode();
  int index = (hash & 0x7FFFFFFF) % tab.length;
  @SuppressWarnings("unchecked")
  Entry<K,V> e = (Entry<K,V>)tab[index];
  for(Entry<K,V> prev = null ; e != null ; prev = e, e = e.next) {
    if ((e.hash == hash) && e.key.equals(key)) {
      modCount++;
      if (prev != null) {
        prev.next = e.next;
      } else {
        tab[index] = e.next;
      }
      count--;
      V oldValue = e.value;
      e.value = null;
      return oldValue;
    }
  }
  return null;
}
```

根据key删除，先根据key计算出数组下标，然后遍历判断是否相同。如果相同则进行删除，并修改链表的结构。

进行删除的操作后需要修改`modCount`值，并且数量变少也需要修改`count`值。

```java
@Override
public synchronized boolean remove(Object key, Object value) {
  Objects.requireNonNull(value);

  Entry<?,?> tab[] = table;
  int hash = key.hashCode();
  int index = (hash & 0x7FFFFFFF) % tab.length;
  @SuppressWarnings("unchecked")
      Entry<K,V> e = (Entry<K,V>)tab[index];
      for (Entry<K,V> prev = null; e != null; prev = e, e = e.next) {
        if ((e.hash == hash) && e.key.equals(key) && e.value.equals(value)) {
          modCount++;
          if (prev != null) {
            prev.next = e.next;
          } else {
            tab[index] = e.next;
          }
          count--;
          e.value = null;
          return true;
        }
      }
      return false;
    }
```

还有一个方法，接受key，value两个参数，当这两个条件同时满足后会进行删除，但是这个是返回布尔值，当成功删除后会返回true，当未找到会返回false

# putAll()

```java
public synchronized void putAll(Map<? extends K, ? extends V> t) {
  for (Map.Entry<? extends K, ? extends V> e : t.entrySet())
    put(e.getKey(), e.getValue());
}
```

构造函数中也调用了这个方法，对参数中的map进行循环调用，然后执行put()操作。

# clear()

```java
public synchronized void clear() {
  Entry<?,?> tab[] = table;
  modCount++;
  for (int index = tab.length; --index >= 0; )
    tab[index] = null;
  count = 0;
}
```

清空操作，对map数组进行循环，将每一项设置为null。

# 总结

Hashtable作为一个线程安全的集合类，是利用了`synchronized`关键字，在进入方法时就加了悲观锁，所以在效率方面不是很好。

Hashtable存储的key和value都不能是null。

Hashtable采用的是数组加链表的存储方式

