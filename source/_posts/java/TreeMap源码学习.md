---
title: TreeMap源码学习
date: 2019-11-12 15:59:25
categories: "java"
toc: true
tags: 
	- java
---

之前看过了`HashMap`,`LinkedHashMap`的源码，这次来看一下`TreeMap`的源码。

从这个名字就能看出，`TreeMap`底层使用的是树来进行存储的。

# 变量

```java
//比较器，用于左右子树的判断。
//正常情况下，左子树为 1，父节点为 2，右子树为 3。如果比较器设置 3<1<2。则左子树为3，父节点为 1，右子树为 2。
private final Comparator<? super K> comparator;
//根节点
private transient Entry<K,V> root;
//容量
private transient int size = 0;
//修改的次数，在迭代和序列化时用到
private transient int modCount = 0;
```

看一下 root 节点的数据结构:

```java
static final class Entry<K,V> implements Map.Entry<K,V> {
        K key;
        V value;
        Entry<K,V> left;
        Entry<K,V> right;
        Entry<K,V> parent;
        boolean color = BLACK;

	...
}
```

由于有一个`color=BLACK`属性，所以底层数据结构应该是**红黑树**

<!--more-->

# 构造器

```java
// 无参构造器
public TreeMap() {
    comparator = null;
}
//传入比较器
public TreeMap(Comparator<? super K> comparator) {
    this.comparator = comparator;
}
//传入 map
public TreeMap(Map<? extends K, ? extends V> m) {
    comparator = null;
    putAll(m);
}
//传入一个排序的 map
public TreeMap(SortedMap<K, ? extends V> m) {
    comparator = m.comparator();
    try {
        buildFromSorted(m.size(), m.entrySet().iterator(), null, null);
    } catch (java.io.IOException cannotHappen) {
    } catch (ClassNotFoundException cannotHappen) {
    }
}
```

# get

```java
public V get(Object key) {
    Entry<K,V> p = getEntry(key);
    return (p==null ? null : p.value);
}

final Entry<K,V> getEntry(Object key) {
    // Offload comparator-based version for sake of performance
    if (comparator != null)
        return getEntryUsingComparator(key);
    if (key == null)
        throw new NullPointerException();
    @SuppressWarnings("unchecked")
    Comparable<? super K> k = (Comparable<? super K>) key;
    Entry<K,V> p = root;
    while (p != null) {
        int cmp = k.compareTo(p.key);
        if (cmp < 0)
            p = p.left;
        else if (cmp > 0)
            p = p.right;
        else
            return p;
    }
    return null;
}

final Entry<K,V> getEntryUsingComparator(Object key) {
    @SuppressWarnings("unchecked")
    K k = (K) key;
    Comparator<? super K> cpr = comparator;
    if (cpr != null) {
        Entry<K,V> p = root;
        while (p != null) {
            int cmp = cpr.compare(k, p.key);
            if (cmp < 0)
                p = p.left;
            else if (cmp > 0)
                p = p.right;
            else
                return p;
        }
    }
    return null;
}
```

在上面代码中的第八行进行了判断`comparator`也就是自定义的比较器是否为空，这两种情况下查找的比较器和 key 有所不同。然后再进行二分查找。

# put

```java
public V put(K key, V value) {
    Entry<K,V> t = root;
    if (t == null) {
        //当 map 为空时
        compare(key, key); // type (and possibly null) check
        root = new Entry<>(key, value, null);
        size = 1;
        modCount++;
        return null;
    }
    int cmp;
    Entry<K,V> parent;
    // split comparator and comparable paths
    Comparator<? super K> cpr = comparator;
    if (cpr != null) {
        //自定义比较器
        do {
            //对树进行插入，如果key 重复则更新 value
            parent = t;
            cmp = cpr.compare(key, t.key);
            if (cmp < 0)
                t = t.left;
            else if (cmp > 0)
                t = t.right;
            else
                return t.setValue(value);
        } while (t != null);
    }
    else {
        //无自定义比较器
        if (key == null)
            throw new NullPointerException();
        @SuppressWarnings("unchecked")
        Comparable<? super K> k = (Comparable<? super K>) key;
        do {
            parent = t;
            cmp = k.compareTo(t.key);
            if (cmp < 0)
                t = t.left;
            else if (cmp > 0)
                t = t.right;
            else
                return t.setValue(value);
        } while (t != null);
    }
    Entry<K,V> e = new Entry<>(key, value, parent);
    if (cmp < 0)
        parent.left = e;
    else
        parent.right = e;
    //这个方法里面是对红黑树的重排
    fixAfterInsertion(e);
    size++;
    modCount++;
    return null;
}
```

首先进行了 map 为空时的判断。然后对比较器为空和非空时的逻辑。最后调用了对红黑树重排的方法。