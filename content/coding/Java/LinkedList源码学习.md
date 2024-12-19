---
title: LinkedList源码学习
date: 2019-08-21
categories:
  - notes
tags:
  - Java
related-project: "[[Blog Posts/coding/Java/Java|Java]]"
---

`LinkedList`使用了链表实现，相比`ArrayList`来说，插入更快，查看较慢。   

首先看一下使用的链表结构

```java
private static class Node<E> {
	E item;
	Node<E> next;
	Node<E> prev;

	Node(Node<E> prev, E element, Node<E> next) {
		this.item = element;
		this.next = next;
		this.prev = prev;
	}
}
```

每个`Node`节点存储一个元素，`item`表示这个元素的值，`prev`表示上一个元素，如果已经的第一个了那么为`null`。同理，`next`表示的是下一个元素，当插入新元素时会改变上一个元素的`next`值指向自己，这样就把这个链表串起来了。  

# 变量

```java
// 元素的数量
transient int size = 0;
// 指向第一个元素
transient Node<E> first;
// 指向最后一个元素
transient Node<E> last;
```



<!--more-->

# 构造方法

```java
public LinkedList() {
}

public LinkedList(Collection<? extends E> c) {
    this();
    addAll(c);
}
```

-   无参的构造方法

    这个方法什么事情也没做

-   传入集合的构造方法

    调用了`addAll`方法将集合中的元素添加进来。

# 增加

## add(E e)

```java
public boolean add(E e) {
    linkLast(e);
    return true;
}

void linkLast(E e) {
    final Node<E> l = last;
    final Node<E> newNode = new Node<>(l, e, null);
    last = newNode;
    if (l == null)
        first = newNode;
    else
        l.next = newNode;
    size++;
    modCount++;
}
```

先获取到最后一个元素节点，然后创建一个新节点，并且将这个节点的上一个节点指向当前链表的最后一个元素节点，然后再把最后的元素节点替换成这个新建的节点。  

然后判断这个之前获取的最后一个元素节点是不是空，如果是空那表示我们整个链表都是空的，将第一个元素节点也替换成这个新创建的节点。  

如果不是空，则将之前的最后一个节点的下一个元素指向我们新创建的节点上。  

然后是常规的将容量数量增加，修改的次数增加。

## add(int index,E element)

```java
public void add(int index, E element) {
    checkPositionIndex(index);

    if (index == size)
        linkLast(element);
    else
        linkBefore(element, node(index));
}


private void checkPositionIndex(int index) {
    if (!isPositionIndex(index))
        throw new IndexOutOfBoundsException(outOfBoundsMsg(index));
}
private boolean isPositionIndex(int index) {
    return index >= 0 && index <= size;
}

Node<E> node(int index) {
    // assert isElementIndex(index);

    if (index < (size >> 1)) {
        Node<E> x = first;
        for (int i = 0; i < index; i++)
            x = x.next;
        return x;
    } else {
        Node<E> x = last;
        for (int i = size - 1; i > index; i--)
            x = x.prev;
        return x;
    }
}

void linkBefore(E e, Node<E> succ) {
    // assert succ != null;
    final Node<E> pred = succ.prev;
    final Node<E> newNode = new Node<>(pred, e, succ);
    succ.prev = newNode;
    if (pred == null)
        first = newNode;
    else
        pred.next = newNode;
    size++;
    modCount++;
}
```

指定位置插入元素，首先进行判断这个位置是否符合要求。  

如果这个下标的位置等于元素的长度，就表示他是向最后一个进入插入，那就和`add(E e)`一样，调用的方法也是一样的。如果不是则表示向链表中间进行插入。这里用到了`node()`方法获取指定位置的元素。  

`node(int index)`方法获取元素：判断要查找的位置与（当前元素长度除以2）的关系，判断后决定是从前向后循环还是从后向前循环，从而尽量减少循环的次数。从这里也能看出**链表在查找元素时耗时的原因**    

`linkBefore()`方法：传入了原来的节点，要更改的元素值。获取原来节点的执行的上一个节点`pred`，创建一个新节点这个新节点的上一个节点指向刚刚获取的`pred`，下一个节点指向原来的`succ`节点。  

再将原来节点的上一个节点改为这个新节点。然后判断上一个节点是不是空，如果是空表示我们向第一位进行了插入，这时候将第一个的元素节点替换成这个新节点。不为空则将上一个元素的下一个节点指向这个新节点。  

然后是元素数量加一，修改数量加一。

## addAll(Collection<? extends E> c)

```java
public boolean addAll(Collection<? extends E> c) {
    return addAll(size, c);
}

public boolean addAll(int index, Collection<? extends E> c) {
    checkPositionIndex(index);
	// 将集合c转换为数组
    Object[] a = c.toArray();
    int numNew = a.length;
    if (numNew == 0)
        // 如果集合为空
        return false;
	// 定义节点，分别表示 pred上一个 succ下一个
    Node<E> pred, succ;
    if (index == size) {
        // 如果向链表尾部进行添加
        succ = null;
        pred = last;
    } else {
        succ = node(index);
        pred = succ.prev;
    }
	// 循环添加
    for (Object o : a) {
        @SuppressWarnings("unchecked") E e = (E) o;
        // 定义新节点
        Node<E> newNode = new Node<>(pred, e, null);
        if (pred == null)
            // pred=last == null 表示当前链表为空 让第一个节点为当前节点 
            first = newNode;
        else
            // 否则让上一个节点的 下一个元素节点 指向当前节点
            pred.next = newNode;
        // 将pred再置为当前节点，那么对应下一个节点来说 上一个节点就是这个节点了
        pred = newNode;
    }
	// 完成了将集合中的元素添加到链表中，还需要对 原来链表插入点之后的元素进行修改
    if (succ == null) {
        // 如果原来的下个节点为空，说明我们是向尾部插入的，让last等于最后插入的一个节点就行了
        last = pred;
    } else {
        // 不为空时还需要将插入的最后一个节点和之前的下一个节点进行关联
        pred.next = succ;
        succ.prev = pred;
    }

    size += numNew;
    modCount++;
    return true;
}
```

添加一个集合类，先获取当前`LinkedList`的元素长度`size`，具体操作在`addAll(int index, Collection<? extends E> c)`方法中进行。  

先判断下标是否符合要求，

# 更新

## set(int index,E element)

```java
public E set(int index, E element) {
    checkElementIndex(index);
    Node<E> x = node(index);
    E oldVal = x.item;
    x.item = element;
    return oldVal;
}
```

首先执行了判断下标是否符合要求，然后获取这个位置的元素节点。  

将这个节点的值替换为新的值，将原来的值返回。

# 查找

## get(int index)

```java
public E get(int index) {
    checkElementIndex(index);
    return node(index).item;
}
```

这里用到的方法上面也有使用过。先检查位置是否符合要求，然后根据下标查找节点，再返回节点的值。  

定义了两个变量`first`和`last`，我们只能根据这两个头和尾来找到中间的值，所以先进行了判断，要找的角标更靠近那个一些，如果靠近尾就从尾开始找，所以说他是把沿着链表一个一个的找的，如果现在链表中有100个元素，我们要找第80个。80>(100/2)，所以从后向前找，`99->98->97->......->80`这样一个一个的找出来。耗时比较长。

# 删除

## remove(int index)

```java
public E remove(int index) {
    checkElementIndex(index);
    return unlink(node(index));
}

E unlink(Node<E> x) {
    // assert x != null;
    // 获取这个节点的值 指向的上一个节点 指向的下一个节点
    final E element = x.item;
    final Node<E> next = x.next;
    final Node<E> prev = x.prev;

    if (prev == null) {
        // 上一个节点为空，表示这是第一个元素，让fist等于下一个元素
        first = next;
    } else {
        // 让上一个节点的 下一个元素节点 指向下一个节点
        prev.next = next;
        // 将本身的上一个节点指向置空
        x.prev = null;
    }

    if (next == null) {
        // 下一个节点为空，表示这是最后一个元素，让last等于上一个元素
        last = prev;
    } else {
        // 让下一个节点的 上一个元素节点 指向上一个节点
        next.prev = prev;
        // 将本身的下一个节点置空
        x.next = null;
    }
	// 将本身的值置空 这三个置空可能是为了垃圾回收
    x.item = null;
    size--;
    modCount++;
    return element;
}
```

## remove(Object o)

```java
public boolean remove(Object o) {
    if (o == null) {
        for (Node<E> x = first; x != null; x = x.next) {
            if (x.item == null) {
                unlink(x);
                return true;
            }
        }
    } else {
        for (Node<E> x = first; x != null; x = x.next) {
            if (o.equals(x.item)) {
                unlink(x);
                return true;
            }
        }
    }
    return false;
}
```

给定一个对象，从链表中删除，从链表的头开始循环对比，如果节点的值与给定的值一样则执行删除操作。这个的删除与`ArrayList`的逻辑是一样的。

# 判断元素下标位置

```java
public int indexOf(Object o) {
    int index = 0;
    if (o == null) {
        for (Node<E> x = first; x != null; x = x.next) {
            if (x.item == null)
                return index;
            index++;
        }
    } else {
        for (Node<E> x = first; x != null; x = x.next) {
            if (o.equals(x.item))
                return index;
            index++;
        }
    }
    return -1;
}
```



给出一个对象，找出这个对象在链表中的位置，从第一个节点开始找，找到第一个匹配的后返回下标，没有找到返回`-1`。  

**lastIndexOf(Object o)**是从`last`最后一个节点向前匹配。

# 清空链表

```java
public void clear() {
    // Clearing all of the links between nodes is "unnecessary", but:
    // - helps a generational GC if the discarded nodes inhabit
    //   more than one generation
    // - is sure to free memory even if there is a reachable Iterator
    for (Node<E> x = first; x != null; ) {
        Node<E> next = x.next;
        x.item = null;
        x.next = null;
        x.prev = null;
        x = next;
    }
    first = last = null;
    size = 0;
    modCount++;
}
```

从`first`第一个节点开始，将每个节点的 值、上一个节点指向的元素、下一个节点指向的元素都置空。通过注释可以看出这个置空操作也是为了垃圾回收机制，所以上面的删除方法中置空应该也是这个原因。

# 队列 Queue

`LinkedList`不仅实现了`List`的接口，也实现了`Queue`的接口。  

其实我们先明白队列`Queue`是什么：

> ​	**队列**，又称为**伫列**（queue），是[先进先出](https://zh.wikipedia.org/wiki/先進先出)（FIFO, First-In-First-Out）的[线性表](https://zh.wikipedia.org/wiki/线性表)。在具体应用中通常用[链表](https://zh.wikipedia.org/wiki/链表)或者[数组](https://zh.wikipedia.org/wiki/数组)来实现。队列只允许在后端（称为*rear*）进行插入操作，在前端（称为*front*）进行删除操作。

我们从他的定义中可以得知，遵循先进先出的规则，第一个放入的元素，也要第一个拿出来。向这里面插入元素只能从队列最后面插入。从前面进行删除操作。  

其实不用从上面的代码就能大体知道他是怎么实现的了，`LinkedList`有`first`和`last`两个变量存储第一个和最后一个元素。在队列中只要改变这两个变量就可以实现了。

```java
public boolean offer(E e) {
					    return add(e);
}

public E element() {
    return getFirst();
}

public E poll() {
			    //					获取第一个元素，并将第一个删除
	    final Node<E> f = first;
    return (f == null) ? null : unlinkFirst(f);
}

private E unlinkFirst(Node<E> f) {
    // assert f == first && f != null;
    final E element = f.item;
    final Node<E> next = f.next;
    f.item = null;
    f.next = null; // help GC
    first = next;
    if (next == null)
        	last = null;
    else
        next.prev = null;
    size--;
    modCount++;
    return element;
}

public E peek() {
	    // 只获取不删除
		    final Node<E> f = first;
    return (f == null) ? null : f.item;
}

public E remove() {
			    return removeFirst();
}
```

