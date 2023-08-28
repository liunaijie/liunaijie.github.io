---
title: ArrayList源码学习
date: 2019-08-20 19:28:12
categories: 
	- [code, java]
toc: true
tags: 
	- java
---

# 变量

```java
private static final int DEFAULT_CAPACITY = 10;
private static final Object[] EMPTY_ELEMENTDATA = {};
private static final Object[] DEFAULTCAPACITY_EMPTY_ELEMENTDATA = {};
transient Object[] elementData; 
private int size;
```

-   `DEFAULT_CAPACITY`：默认的容量，当我们不指定容量时默认容量是10
-   `EMPTY_ELEMENTDATA`：空的数据集
-   `DEFAULTCAPACITY_EMPTY_ELEMENTDATA`：同上面的一样，都是空的数据集
-   `elementData`：保存的元素
-   `size`：元素长度，实际存储的元素数量

# 构造方法：

-   无参的构造方法

```java
public ArrayList() {
        this.elementData = DEFAULTCAPACITY_EMPTY_ELEMENTDATA;
}
```

很简单的一句话，将保存元素的变量进行初始化。

<!--more-->

-   指定容量的构造方法

```java
public ArrayList(int initialCapacity) {
    if (initialCapacity > 0) {
        this.elementData = new Object[initialCapacity];
    } else if (initialCapacity == 0) {
        this.elementData = EMPTY_ELEMENTDATA;
    } else {
        throw new IllegalArgumentException("Illegal Capacity: "+ initialCapacity);
    }
}
```

当我们指定了容量大小，先判断容量是否大于0，毕竟容量不可能是负数，然后将保存元素的变量初始化为一个指定大小的数组。

-   Collection对象的构造方法

```java
public ArrayList(Collection<? extends E> c) {
    elementData = c.toArray();
    if ((size = elementData.length) != 0) {
        // c.toArray might (incorrectly) not return Object[] (see 6260652)
        if (elementData.getClass() != Object[].class)
            elementData = Arrays.copyOf(elementData, size, Object[].class);
    } else {
        // replace with empty array.
        this.elementData = EMPTY_ELEMENTDATA;
    }
}
```

传入一个容器对象，如果这个容器是空的，初始化为空数组。如果不为空，则将容器转换为Object类型的数组。

# 常用方法：

## add

-   **add(E e)**

```java
public boolean add(E e) {
    // 检测容量
    ensureCapacityInternal(size + 1);  // Increments modCount!!
    // 添加保存元素
    elementData[size++] = e;
    return true;
}
```

首先确保容量是否可以继续添加新元素，然后进行添加元素。

```java
/**
 * The maximum size of array to allocate.
 * Some VMs reserve some header words in an array.
 * Attempts to allocate larger arrays may result in
 * OutOfMemoryError: Requested array size exceeds VM limit
 */
// 为什么是-8 搜了一些其实这个8并没有什么特别的含义，只是有些虚拟机可能会在头部带有一些信息，所以尽量减少出错的几率
private static final int MAX_ARRAY_SIZE = Integer.MAX_VALUE - 8;

private void ensureCapacityInternal(int minCapacity) {
	ensureExplicitCapacity(calculateCapacity(elementData, minCapacity));
}

private void ensureExplicitCapacity(int minCapacity) {
    // 这个变量是为了 Iterable
	modCount++;
    // 如果我们现在需要的容量比数组的长度大 那么就需要扩容了
    if (minCapacity - elementData.length > 0)
    	grow(minCapacity);
}

private void grow(int minCapacity) {
    int oldCapacity = elementData.length;
    // 新容量=原来数组容量的1.5倍
    int newCapacity = oldCapacity + (oldCapacity >> 1);
    // 如果1.5倍仍然不满足我们要扩容的容量，那么就使用我们传入的容量
    // 比如传入16 原来是10 1.5倍后是15 15<16 所以就使用16
    if (newCapacity - minCapacity < 0)
        newCapacity = minCapacity;
    if (newCapacity - MAX_ARRAY_SIZE > 0)
        newCapacity = hugeCapacity(minCapacity);
    // minCapacity is usually close to size, so this is a win:
    // 创建一个容量为新容量的新数组，将旧数组的内容拷贝给新数组。
    elementData = Arrays.copyOf(elementData, newCapacity);
}

private static int hugeCapacity(int minCapacity) {
    if (minCapacity < 0) // overflow
        throw new OutOfMemoryError();
    // 通过这里可以知道最大容量是 Integer.MAX_VALUE 
    return (minCapacity > MAX_ARRAY_SIZE) ?
        Integer.MAX_VALUE :
    MAX_ARRAY_SIZE;
}
```

-   **add(int index,E element)**

```java
public void add(int index, E element) {
    rangeCheckForAdd(index);
	// 容量扩容检测，同上面的方法
    ensureCapacityInternal(size + 1);  // Increments modCount!!
    // 这个是主要的实现方法。非常麻烦和耗时，这就是为什么ArrayList最好不要从中间插入
    System.arraycopy(elementData, index, elementData, index + 1,
                     size - index);
    elementData[index] = element;
    size++;
}
```

在指定位置添加一个元素，首先检查这个插入位置是否符合要求，然后确保容量够用，再在指定位置添加元素。

```java
// 检查位置是否符合要求
private void rangeCheckForAdd(int index) {
    if (index > size || index < 0)
    	throw new IndexOutOfBoundsException(outOfBoundsMsg(index));
}

/**
* src 从哪里复制
* srcPos 从哪个位置开始
* dest 复制到哪里去
* destPos 从哪里开始放
* length 复制多少个元素
*/ 
public static native void arraycopy(Object src,  int  srcPos,
                                        Object dest, int destPos,
                                        int length);
```

我们再来看`arraycopy(elementData, index, elementData, index + 1, size - index)`这句，他就是将原来数组中从`index`开始`size-index`个元素，再复制到原来的数组中，不过是从`index+1`开始放，这样就使从`index`开始的元素都向后挪动了一位，就空出来了`index`位置存放我们要存放的数据。

-   **添加集合**

```java
public boolean addAll(Collection<? extends E> c) {
    Object[] a = c.toArray();
    int numNew = a.length;
    ensureCapacityInternal(size + numNew);  // Increments modCount
    System.arraycopy(a, 0, elementData, size, numNew);
    size += numNew;
    return numNew != 0;
}
```

经过上面几个方法我们已经明白了这个过程，首先转换成`Object`数组，然后进行容量检测，再将要添加的集合复制到我们已有的数组中，元素数量增加。

-   **从指定位置添加集合**

```java
public boolean addAll(int index, Collection<? extends E> c) {
    // 检测要插入的位置是否符合要求
    rangeCheckForAdd(index);

    Object[] a = c.toArray();
    int numNew = a.length;
    // 扩容检测
    ensureCapacityInternal(size + numNew);  // Increments modCount
	// 计算需要移动的元素数量
    int numMoved = size - index;
    if (numMoved > 0)
        // 从index位置的元素向后移动要插入的集合长度个单位
    	System.arraycopy(elementData, index, elementData, index + numNew,
    numMoved);
	// 将要插入的集合复制到原有的数组中
    System.arraycopy(a, 0, elementData, index, numNew);
    size += numNew;
    return numNew != 0;
}
```

## set

```java
public E set(int index, E element) {
    rangeCheck(index);

    E oldValue = elementData(index);
    elementData[index] = element;
    return oldValue;
}
```

`set`就是对指定位置的元素进行替换，首先检查这个位置是否符合要求，然后获取原来位置的元素，再用新的元素进行替换，返回旧的元素值。

```java
// 对元素位置进行检查，如果位置大于当前元素数组的实际长度则会报错
private void rangeCheck(int index) {
	if (index >= size)
		throw new IndexOutOfBoundsException(outOfBoundsMsg(index));
}
// 获取指定位置的元素
E elementData(int index) {
	return (E) elementData[index];
}
```

## get

```java
public E get(int index) {
	rangeCheck(index);

	return elementData(index);
}
```

先检查位置是否正确，然后返回指定位置的元素。

## remove

-   **删除指定位置的元素**

```java
public E remove(int index) {
    rangeCheck(index);

    modCount++;
    E oldValue = elementData(index);

    int numMoved = size - index - 1;
    if (numMoved > 0)
    	System.arraycopy(elementData, index+1, elementData, index,numMoved);
    elementData[--size] = null; // clear to let GC do its work

    return oldValue;
}
```

先检查这个位置是否正确，然后获取指定位置的元素，将这个位置之后的元素复制向前移动。并将最后一个元素置为`null`。这里也要对`modCount`进行加1。

-   **删除指定的对象**

```java
public boolean remove(Object o) {
    if (o == null) {
    	for (int index = 0; index < size; index++)
    		if (elementData[index] == null) {
    			fastRemove(index);
    			return true;
    		}
    } else {
        for (int index = 0; index < size; index++)
            if (o.equals(elementData[index])) {
                fastRemove(index);
                return true;
            }
    return false;
}
```

删除第一个符合条件的对象，具体删除的方法与上面的一致，少了检查位置。

```JAVA
private void fastRemove(int index) {
    modCount++;
    int numMoved = size - index - 1;
    if (numMoved > 0)
    	System.arraycopy(elementData, index+1, elementData, index,numMoved);
    elementData[--size] = null; // clear to let GC do its work
}
```

-   删除集合

```java
public boolean removeAll(Collection<?> c) {
    // 判断传入的集合不能为空
    Objects.requireNonNull(c);
    return batchRemove(c, false);
}
```

对传入集合里面的元素进行删除

```java
private boolean batchRemove(Collection<?> c, boolean complement) {
    final Object[] elementData = this.elementData;
    int r = 0, w = 0;
    boolean modified = false;
    try {
        for (; r < size; r++)
            // 当条件为真时，将符合条件的元素从0开始存储
            /*
            * complement=false（删除元素）时：
            * 要删除的元素集合中不包含当前元素 条件成立，存储 （移除了要删除的元素）
            * complement=true（保留元素）时：
            * 保留的元素集合中包含当前元素 条件成立，存储（保留了要保留的元素）
        	*/
        	if (c.contains(elementData[r]) == complement)
        		elementData[w++] = elementData[r];
    } finally {
        // Preserve behavioral compatibility with AbstractCollection,
        // even if c.contains() throws.
        if (r != size) {
            // 一般情况下是不会走的
            // 当遇到异常后将还没有操作的元素复制到要保存的元素之后
        	System.arraycopy(elementData, r,elementData, w,size - r);
            w += size - r;
        }
        if (w != size) {
            // clear to let GC do its work
            // 如果修改了 则将后面的元素置为空
            for (int i = w; i < size; i++)
            	elementData[i] = null;
            modCount += size - w;
            size = w;
            modified = true;
        }
    }
    return modified;
}
```

-   保留集合，删除其他元素

```java
public boolean retainAll(Collection<?> c) {
    Objects.requireNonNull(c);
    return batchRemove(c, true);
}
```

这个与上面的一样，都调用了`batchRemove`方法

## indexOf

-   **indexOf()**

```java
public int indexOf(Object o) {
    if (o == null) {
        for (int i = 0; i < size; i++)
        	if (elementData[i]==null)
        return i;
    } else {
    	for (int i = 0; i < size; i++)
    		if (o.equals(elementData[i]))
    	return i;
    }
    return -1;
}
```

从开始寻找第一个符合的值的下标。

-   **lastIndexOf()**

具体方法与`indexOf`类似，循环的时候倒序循环。

## contains

```java
public boolean contains(Object o) {
    return indexOf(o) >= 0;
}
```

通过调用元素位置来判断的是否包含该元素  

可以看到`modCount`这个变量在新增，删除操作时，即长度有变化时都需要操作。现在还没弄明白这个变量的作用，好像是与`iterator`迭代器、线程有关。后面看到相关内容后会再来补充。

# 参考文章：

https://stackoverflow.com/questions/35582809/java-8-arraylist-hugecapacityint-implementation  

https://wiki.jikexueyuan.com/project/java-enhancement/java-twentyone.html