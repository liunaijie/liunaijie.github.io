---
title: LinkedHashMap源码
date: 2019-08-22 20:12:23
tags:
  - java
categories: 
	- [code, java]
toc: true
---


![LinkedHashMap结构图](https://raw.githubusercontent.com/liunaijie/images/master/LinkedHashMap.jpg)

`LinkedHashMap`继承了`HashMap`类，实现了`Map`接口。  

他与`HashMap`的主要区别就是使用链表存储了每个节点的顺序。这样就能保证有序。  

来看一下他的节点情况：

```java
static class Entry<K,V> extends HashMap.Node<K,V> {
    Entry<K,V> before, after;
    Entry(int hash, K key, V value, Node<K,V> next) {
        super(hash, key, value, next);
    }
}
```

从这里可以看出他使用了两个变量，`before`，`after`存储这个节点的前后顺序。

<!--more-->

# 构造方法

```java
public LinkedHashMap() {
    super();
    accessOrder = false;
}

public LinkedHashMap(int initialCapacity) {
    super(initialCapacity);
    accessOrder = false;
}

public LinkedHashMap(int initialCapacity, float loadFactor) {
    super(initialCapacity, loadFactor);
    accessOrder = false;
}

public LinkedHashMap(int initialCapacity,
                     float loadFactor,
                     boolean accessOrder) {
    super(initialCapacity, loadFactor);
    this.accessOrder = accessOrder;
}

public LinkedHashMap(Map<? extends K, ? extends V> m) {
    super();
    accessOrder = false;
    putMapEntries(m, false);
}
```

`LinkedHashMap`一共有5个构造方法，仔细看一下主要是三个参数：`initialCapacity`，`loadFactor`，`accessOrder`这三个变量。并且他们都调用了父类也就是`HashMap`的构造方法。  

`initialCapacity`，`loadFactor`这两个在看`HashMap`的时候就了解到这是初始容量值与扩容阈值，就不仔细说了，如果想仔细了解这两个字段可以看这一篇[HashMap源码学习](https://www.liunaijie.top/2019/08/22/java/HashMap源码学习/)。  

那就主要看一下`accessOrder`。

```java
/**
 * The iteration ordering method for this linked hash map: <tt>true</tt>
 * for access-order, <tt>false</tt> for insertion-order.
 *
 * @serial
 */
final boolean accessOrder;
```

这个字段也给出了注释，如果为`true`则表示基于访问顺序，如果为`false`则基于插入顺序。所以我们想要的按照访问顺序取就要设置为`false`。如果为`true`则按照访问顺序排序，将访问过的元素放到链表后面。我们用代码看一下实际效果。

```java
public static void main(String[] args) {
    LinkedHashMap<String, Integer> first = new LinkedHashMap<String, Integer>(16, 0.75f, false);
    first.put("1", 1);
    first.put("2", 2);
    first.put("3", 3);
    first.put("4", 4);
    first.get("1");
    first.get("3");
    System.out.println(first);
    LinkedHashMap<String, Integer> second = new LinkedHashMap<String, Integer>(16, 0.75f, true);
    second.put("1", 1);
    second.put("2", 2);
    second.put("3", 3);
    second.put("4", 4);
    second.get("1");
    second.get("3");
    System.out.println(second);
}

/**输出**/
{1=1, 2=2, 3=3, 4=4}
{2=2, 4=4, 1=1, 3=3}
```

初始化了两个容量，负载系数都一样的`LinkedHashMap`，第一个设置`accessOrder`属性为`false`，第二个设置为`true`。  

然后都执行了相同的代码。先放入元素，然后中间对其中几个元素进行读取。最后在输出查看。  

我们可以看到第一个也就是`accessOrder`属性设置成`false`的虽然中间获取了元素，但是他的打印顺序还是按照放入顺序的。而第二个中间对两个元素进行了获取，所以他将这两个元素放在了后面，打印顺序是我们放入的顺序再加上访问顺序后最终得到的顺序。

# 添加元素

调用了父类`HashMap`的方法。

```java
public V put(K key, V value) {	
    return putVal(hash(key), key, value, false, true);
}

final V putVal(int hash, K key, V value, boolean onlyIfAbsent,
               boolean evict) {
    Node<K,V>[] tab; Node<K,V> p; int n, i;
    if ((tab = table) == null || (n = tab.length) == 0)
        n = (tab = resize()).length;
    if ((p = tab[i = (n - 1) & hash]) == null)
        tab[i] = newNode(hash, key, value, null);
    else {
        Node<K,V> e; K k;
        if (p.hash == hash &&
            ((k = p.key) == key || (key != null && key.equals(k))))
            e = p;
        else if (p instanceof TreeNode)
            e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
        else {
            for (int binCount = 0; ; ++binCount) {
                if ((e = p.next) == null) {
                    p.next = newNode(hash, key, value, null);
                    if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
                        treeifyBin(tab, hash);
                    break;
                }
                if (e.hash == hash &&
                    ((k = e.key) == key || (key != null && key.equals(k))))
                    break;
                p = e;
            }
        }
        if (e != null) { // existing mapping for key
            V oldValue = e.value;
            if (!onlyIfAbsent || oldValue == null)
                e.value = value;
            afterNodeAccess(e); // 这一句
            return oldValue;
        }
    }
    ++modCount;
    if (++size > threshold)
        resize();
    afterNodeInsertion(evict); // 这一句
    return null;
}
```

先来看`afterNodeInsertion`方法

```java
void afterNodeInsertion(boolean evict) { // possibly remove eldest
    LinkedHashMap.Entry<K,V> first;
    if (evict && (first = head) != null && removeEldestEntry(first)) {
        K key = first.key;
        removeNode(hash(key), key, null, false, true);
    }
}

protected boolean removeEldestEntry(Map.Entry<K,V> eldest) {
    return false;
}
```

**这个方法我就没看明白了，他判断条件三个同时成立才会走，然后第三个条件直接返回了`false`。这不就永远不执行了，还是说实际调用的是其他实现方法？欢迎大家指教。**

# 获取元素

```java
public V get(Object key) {
    Node<K,V> e;
    if ((e = getNode(hash(key), key)) == null)
        return null;
    if (accessOrder)
        afterNodeAccess(e); // 这一句
    return e.value;
}
```

现在来看一下之前没说的方法`afterNodeAccess`

```java
void afterNodeAccess(Node<K,V> e) { // move node to last
    LinkedHashMap.Entry<K,V> last;
    if (accessOrder && (last = tail) != e) {
        LinkedHashMap.Entry<K,V> p =
            (LinkedHashMap.Entry<K,V>)e, b = p.before, a = p.after;
        p.after = null;
        if (b == null)
            head = a;
        else
            b.after = a;
        if (a != null)
            a.before = b;
        else
            last = b;
        if (last == null)
            head = p;
        else {
            p.before = last;
            last.after = p;
        }
        tail = p;
        ++modCount;
    }
}
```

这里有`accessOrder`属性的判断，当其为`true`时才会执行下面的代码，所以只有在构造函数中将这个属性设置成`true`时这个方法才会走。  

这个方法的作用就是将这个节点放到整个链表的最后。如果这个节点有下一个节点，则将上一个节点连接到下一个节点。然后将这个节点设置成最后一个节点。像我们刚才执行的演示代码：顺序放置了`1,2,3,4`。然后中间获取`1`。这是就走了这个方法，将`1`放置到了链表最后，变成了`2,3,4,1`。

# 参考文档

https://stackoverflow.com/questions/38974417/what-is-purpose-of-accessorder-field-in-linkedhashmap