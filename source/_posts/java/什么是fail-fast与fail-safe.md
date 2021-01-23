---
title: 什么是fail-fast与fail-safe
date: 2020-04-01 10:23:53
categories: "java"
toc: true
tags: 
	- java
---

# fail-fast与fail-safe

在Collection集合的各个类中，有线程安全和线程不安全这2大类的版本。

对于线程不安全的类，并发情况下可能会出现fail-fast情况；而线程安全的类，可能出现fail-safe的情况。

**快速失败（fail—fast）**是java集合中的一种机制， 在用迭代器遍历一个集合对象时，如果遍历过程中对集合对象的内容进行了修改（增加、删除、修改），则会抛出Concurrent Modification Exception。

**安全失败（fail-sage）**保存了该集合对象的一个快照副本。你可以并发读取，不会抛出异常，但是不保证你遍历读取的值和当前集合对象的状态是一致的！

# fail-fast

来看一下线程不安全的类`ArrayList`，它实现`fail-fast`主要靠一个字段`modCount`。来从头认识一下它。

首先找到引用它的地方：

```java
public boolean add(E e) {
  ensureCapacityInternal(size + 1);  // Increments modCount!!
  elementData[size++] = e;
  return true;
}

private void ensureCapacityInternal(int minCapacity) {
  ensureExplicitCapacity(calculateCapacity(elementData, minCapacity));
}

private void ensureExplicitCapacity(int minCapacity) {
  modCount++;

  // overflow-conscious code
  if (minCapacity - elementData.length > 0)
    grow(minCapacity);
}

public E remove(int index) {
  rangeCheck(index);

  modCount++;
  E oldValue = elementData(index);

  int numMoved = size - index - 1;
  if (numMoved > 0)
    System.arraycopy(elementData, index+1, elementData, index,
                     numMoved);
  elementData[--size] = null; // clear to let GC do its work

  return oldValue;
}
```

可以看出，在增加元素，删除元素时都会对`modCount`值加一。当我们查看更新，查找的代码时并没有找到对`modCount`的修改。

`modCount`字段翻译过来就是`修改次数`，再结合上面的代码可以了解到只有在结构发生变化，数量增减的时候才会修改。查找不会对结构发生变化也不用修改，至于更新操作，虽然它修改了值，但是在结构上总体的数量没有改变，结构上指的是：是谁不重要，有就行。

<!--more-->

我们继续查找用到`modCount`字段的地方：

```java
final void checkForComodification() {
  if (modCount != expectedModCount)
    throw new ConcurrentModificationException();
}
```

找到这样的一段代码，判断`modCount`与另一个值是否相同，如果不相同就抛出异常！再来找到`expectedModCount`定义的地方。

```java
private class Itr implements Iterator<E> {
  int cursor;       // index of next element to return
  int lastRet = -1; // index of last element returned; -1 if no such
  int expectedModCount = modCount;

  Itr() {}
  ...
}
```

从这里看到`expectedModCount=modCount`。小朋友你是否有很多疑惑？为什么这里将`modCount`赋值给`expectedModCount`，后面又需要判断它们是否相等呢？

其实我们将这两个字段翻译过来，一个是`修改数量`，一个是`期望的修改数量`。当我们看到这两个词时脑子里应该有了一些猜想。

这个`expectedModCount`是迭代器在子类实现中定义的一个成员变量。当我们使用迭代器后就将这个变量值初始化完成了，如果我们在使用迭代器期间结构发生了变化，那么就会遇到两者不一样的情况。

我们来看这样的一段代码，演示一下这种错误情况：

```java
public static void main(String[] args) {
  List list = new ArrayList();
  list.add("a");
  list.add("b");
  list.add("c");
  list.add("d");
  Iterator<String> iterator = list.iterator();
  while (iterator.hasNext()) {
    String s = iterator.next();
    System.out.println(s);
    // 修改集合结构
    if ("b".equals(s)) {
      list.remove(s);
    }
  }
}
```

这段代码中，我先添加了4条数据，添加完成后`list`的`modCount=4`。这时我调用了迭代器方法，此时`iterator`中的`expectedModCount=4`。  

然后我利用迭代器的方法进行取值，删除了其中一个数据，这时`list`的`modCount=3`，当我们下一次使用迭代器循环时，检测到`expectedModCount=4 != modCount`，这时就会抛出异常。

# fail-safe

上面的代码是线程不安全的`ArrayList`的源码，接下来看一下线程安全的类`ConcurrentHashMap`是怎样实现的。

```java
public Set<Map.Entry<K,V>> entrySet() {
  EntrySetView<K,V> es;
  return (es = entrySet) != null ? es : (entrySet = new EntrySetView<K,V>(this));
}
```

调用map的迭代时选择了`entrySet`方法，这里会先进行判断一个变量`es`是否为空，不为空则返回，为空则进行了一个实例化，并且传入了当前对象，即传入了当前的`ConcurrentHashMap`对象，找一下调用的这个方法。

```java
static final class EntrySetView<K,V> extends CollectionView<K,V,Map.Entry<K,V>>
  implements Set<Map.Entry<K,V>>, java.io.Serializable {
  
  EntrySetView(ConcurrentHashMap<K,V> map) { super(map); }
  ...
}
```

在这个构造函数中又调用了父类的构造函数，我们还需要继续向上找

```java
abstract static class CollectionView<K,V,E>
  implements Collection<E>, java.io.Serializable {
  private static final long serialVersionUID = 7249069246763182397L;
  final ConcurrentHashMap<K,V> map;
  CollectionView(ConcurrentHashMap<K,V> map)  { this.map = map; }

  public abstract Iterator<E> iterator();

  ...
}
```

找到了这个父类，它在这里将我们上面穿入的`ConcurrentHashMap`对象实例赋值到成员变量`map`上。

并且有一个抽象方法`iterator()`，并且这个方法有3个实现，分别是`EntrySetView`,`KeySetView`,`ValueSetView`，这也是分别对应`entrySet()`,`keySet()`，`valueSet()`的实现。进入到`EntrySetView`中看一下：

```java
static final class EntrySetView<K,V> extends CollectionView<K,V,Map.Entry<K,V>>
  implements Set<Map.Entry<K,V>>, java.io.Serializable {
  private static final long serialVersionUID = 2249069246763182397L;
  EntrySetView(ConcurrentHashMap<K,V> map) { super(map); }

  public Iterator<Map.Entry<K,V>> iterator() {
    ConcurrentHashMap<K,V> m = map;
    Node<K,V>[] t;
    int f = (t = m.table) == null ? 0 : t.length;
    return new EntryIterator<K,V>(t, f, 0, f, m);
  }
}

static final class EntryIterator<K,V> extends BaseIterator<K,V>
  implements Iterator<Map.Entry<K,V>> {
  EntryIterator(Node<K,V>[] tab, int index, int size, int limit,
                ConcurrentHashMap<K,V> map) {
    super(tab, index, size, limit, map);
  }

  public final Map.Entry<K,V> next() {
    Node<K,V> p;
    if ((p = next) == null)
      throw new NoSuchElementException();
    K k = p.key;
    V v = p.val;
    lastReturned = p;
    advance();
    return new MapEntry<K,V>(k, v, map);
  }
}
```

经过上面的代码，可以看出在这里它将当前实例赋值到一个新的map中，相当于在调用`entrySet`时做了一个镜像，然后操作时是在镜像上进行操作，在操作时如果对数据有修改，也不会影响到镜像里面的内容。但是同样的，在镜像里面做迭代也不会有创建镜像后新增的数据。

# 总结

在线程不安全的类中使用使用`fail-fast`来尽最大努力抛出ConcurrentModificationException异常，因为在更新时虽然数据发生了变化，但是在结构上并没变化，只能在增加，删除时保证了安全。

在线程安全的类中，比如`java.util.concurrent`包下的容器都是`fail-safe`。它内部实现是保存了创建一个快照副本，读取这个快照副本的数据。它的缺点是不能保证返回集合更新后的数据，另外创建新的快照也需要一些相应的时间空间开销。