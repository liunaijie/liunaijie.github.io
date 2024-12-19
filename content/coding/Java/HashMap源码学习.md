---
title: HashMap源码学习
date: 2019-08-22
categories:
  - notes
tags:
  - Java
related-project: "[[Blog Posts/coding/Java/Java|Java]]"
---

![HashMap结构](https://raw.githubusercontent.com/liunaijie/images/master/HashMap.jpg)

画了一张结构图，欢迎指正。  

# 变量

```java
/**
* The default initial capacity - MUST be a power of two.
* 默认的容量，容量必须是2的幂
*/
static final int DEFAULT_INITIAL_CAPACITY = 1 << 4; // aka 16

/**
* The maximum capacity, used if a higher value is implicitly specified
* by either of the constructors with arguments.
* MUST be a power of two <= 1<<30.
* 最大的容量值 2的30次幂
*/
static final int MAXIMUM_CAPACITY = 1 << 30;

/**
* The load factor used when none specified in constructor.
* 默认的负载系数
*/
static final float DEFAULT_LOAD_FACTOR = 0.75f;

/**
* The bin count threshold for using a tree rather than list for a
* bin.  Bins are converted to trees when adding an element to a
* bin with at least this many nodes. The value must be greater
* than 2 and should be at least 8 to mesh with assumptions in
* tree removal about conversion back to plain bins upon
* shrinkage.
* 链表的长度到达8之后转换为红黑树
*/
static final int TREEIFY_THRESHOLD = 8;

/**
* The bin count threshold for untreeifying a (split) bin during a
* resize operation. Should be less than TREEIFY_THRESHOLD, and at
* most 6 to mesh with shrinkage detection under removal.
*/
static final int UNTREEIFY_THRESHOLD = 6;

/**
* The smallest table capacity for which bins may be treeified.
* (Otherwise the table is resized if too many nodes in a bin.)
* Should be at least 4 * TREEIFY_THRESHOLD to avoid conflicts
* between resizing and treeification thresholds.
* 
*/
static final int MIN_TREEIFY_CAPACITY = 64;

// 存储的容器
transient Node<K,V>[] table;

/**
* Holds cached entrySet(). Note that AbstractMap fields are used
* for keySet() and values().
*/
transient Set<Map.Entry<K,V>> entrySet;

/**
* The number of key-value mappings contained in this map.
*/
transient int size;

/**
* The number of times this HashMap has been structurally modified
* Structural modifications are those that change the number of mappings in
* the HashMap or otherwise modify its internal structure (e.g.,
* rehash).  This field is used to make iterators on Collection-views of
* the HashMap fail-fast.  (See ConcurrentModificationException).
* 结构修改的次数，每次增加和删除都修改这个数值
*/
transient int modCount;

/**
* The next size value at which to resize (capacity * load factor).
*
* @serial
*/
// (The javadoc description is true upon serialization.
// Additionally, if the table array has not been allocated, this
// field holds the initial array capacity, or zero signifying
// DEFAULT_INITIAL_CAPACITY.)
// 扩容的阈值，当键值对的数量超过这个值就会扩容
int threshold;

/**
* The load factor for the hash table.
* 负载系数
*/
final float loadFactor;
```

<!--more-->

# 构造方法

```java
/**
* 构造方法1，无参的构造方法
*/
public HashMap() {
	this.loadFactor = DEFAULT_LOAD_FACTOR; // all other fields defaulted
}
/**
* 声明容量的构造方法
*/
public HashMap(int initialCapacity) {
	this(initialCapacity, DEFAULT_LOAD_FACTOR);
}
/**
* 声明容量和负载系数的构造方法
*/
public HashMap(int initialCapacity, float loadFactor) {
    if (initialCapacity < 0)
        throw new IllegalArgumentException("Illegal initial capacity: " + initialCapacity);
    if (initialCapacity > MAXIMUM_CAPACITY)
        initialCapacity = MAXIMUM_CAPACITY;
    if (loadFactor <= 0 || Float.isNaN(loadFactor))
        throw new IllegalArgumentException("Illegal load factor: " + loadFactor);
    this.loadFactor = loadFactor;
    this.threshold = tableSizeFor(initialCapacity);
}
/**
* 参数为map的构造方法
*/
public HashMap(Map<? extends K, ? extends V> m) {
    this.loadFactor = DEFAULT_LOAD_FACTOR;
    putMapEntries(m, false);
}
```

-   **无参的构造方法**

    这个应该就是我们最常用的构造方法，将负载系数初始化为默认的系数。

-   **声明容量的构造方法**

    调用了声明容量和负载系数的构造方法

-   **声明容量和负载系数的构造方法**

    首先会判断这个容量是否符合要求，并且最大值是`MAXIMUM_CAPACITY=1<<30`，从这里可以看出map的最大容量值。然后再计算`threshold`值，这个值表示扩容的阈值，当键值对的数量超过这个值就会扩容。下面会介绍一下`tableSizeFor()`方法。

    ```java
    static final int tableSizeFor(int cap) {
        int n = cap - 1;
        n |= n >>> 1;
        n |= n >>> 2;
        n |= n >>> 4;
        n |= n >>> 8;
        n |= n >>> 16;
        return (n < 0) ? 1 : (n >= MAXIMUM_CAPACITY) ? MAXIMUM_CAPACITY : n + 1;
    }
    ```

    这个方法的主要作用是找到等于或大于cap的，最小的2的幂。比如我们传入`6`，他返回`8`，传入`8`，返回`8`。利用了位运算。

-   **参数为map的构造方法**

    负载系数使用默认的系数，然后将传入的map参数放到新的map中。这个`putMapEntries()`方法在下面的putAll方法中进行解读。

从这里可以看出，在构造函数里面并没有对存储键值对的变量进行初始化，这个初始化过程是放在第一次放的过程中。

#  插入  put(K key,V value)

```java
public V put(K key, V value) {
	return putVal(hash(key), key, value, false, true);
}

/**
* Implements Map.put and related methods
*
* @param hash hash for key
* @param key the key
* @param value the value to put
* @param onlyIfAbsent if true, don't change existing value
* @param evict if false, the table is in creation mode.
* @return previous value, or null if none
*/
final V putVal(int hash, K key, V value, boolean onlyIfAbsent, boolean evict) {
	Node<K,V>[] tab; Node<K,V> p; int n, i;
    // 如果table为空进行了初始化，
	if ((tab = table) == null || (n = tab.length) == 0)
        	// n=16
        	n = (tab = resize()).length;
	if ((p = tab[i = (n - 1) & hash]) == null)
        // 存放新的键值对，根据 n和hash找到这个key对应在桶中的下标，然后赋予p，如果不为空则说明这个key的hash没有重复，直接放入
		tab[i] = newNode(hash, key, value, null);
	else {
        // 如果不为空，则可能是key重复，或者key的hash重复
        // key 重复，覆盖原来的值
        // key的hash重复，先使用链表，如果这个链表的长度大于等于7，则转换为红黑树存储。方便后面的查找。
    	Node<K,V> e; K k;
    	if (p.hash == hash &&  ((k = p.key) == key || (key != null && key.equals(k))))
    		// key重复的情况
            e = p;
    	else if (p instanceof TreeNode)
            // 当这个hash已经是红黑树了
    		e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
    	else {
    		for (int binCount = 0; ; ++binCount) {
                // 这里是个死循环，当遇到下面两种情况跳出循环
                //1.找到最后一个节点并存储值
            	if ((e = p.next) == null) {
                    // 将下个节点设置成新的键值对，链表长度加1
            		p.next = newNode(hash, key, value, null);
                    if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
                        // 这里判断如果这个链表的长度大于等于7，就将链表转换为红黑树
                        // 从这里可以看出不会存在7个长度的链表，当7的时候就转换成红黑树了
                    	treeifyBin(tab, hash);
                    break;
        		}
                // 2.这个key重复了。不知道为什么这里还有一个判断。
                if (e.hash == hash && ((k = e.key) == key || (key != null && key.equals(k))))
                	break;
                p = e;
        	}
    	}
    	if (e != null) { // existing mapping for key
    		// 在上面的代码中，用e来存储之前的键值对，如果e不为空说明这个key重复。
            V oldValue = e.value;
    		if (!onlyIfAbsent || oldValue == null)
    			e.value = value;
            // todo 做一些操作，然后返回旧的值
    		afterNodeAccess(e);
    		return oldValue;
    	}
    }
    // 如果key不重复则到这里，将modCount增加
    ++modCount;
    // 如果 容量+1 比要扩容的阈值还大，那么进行扩容
    // 他的扩容机制是放在本次结束后的，并不是放到下一次的开始。
    if (++size > threshold)
    	resize();
    // todo 
    afterNodeInsertion(evict);
    return null;
}
```

## 计算hash

在放的时候用到了`hash()`方法对键做哈希运算，并且没有直接运用`Object`的`hashCode()`方法，在这个的基础上又进行了一些运算。这个16位也是有原因的，具体后面再过来讲。

```java
static final int hash(Object key) {
	int h;
	return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
}
```

## 扩容

还用到了扩容的方法

```java
final Node<K,V>[] resize() {
    Node<K,V>[] oldTab = table;
    // 获取原来桶数组的元素长度和扩容阈值，当没初始化时即oldTab=null时，长度为0 阈值=12（16*0.75）
    int oldCap = (oldTab == null) ? 0 : oldTab.length;
    int oldThr = threshold;
    // 新桶数组的元素长度
    int newCap, newThr = 0;
    if (oldCap > 0) {
        if (oldCap >= MAXIMUM_CAPACITY) {
            // 原来的桶数组里面有元素，并且容量为最大容量了，将阈值设置为int的最大值，并直接返回原来的桶数组
            threshold = Integer.MAX_VALUE;
            return oldTab;
        }
        else if ((newCap = oldCap << 1) < MAXIMUM_CAPACITY && oldCap >= DEFAULT_INITIAL_CAPACITY)
            // 如果旧桶数组的长度乘2后小于最大容量并且旧桶数组的长度大于默认的容量，新桶的容量等于原来容量的两倍，所以扩容是2倍扩容
            newThr = oldThr << 1; // double threshold
    }
    else if (oldThr > 0) // initial capacity was placed in threshold
        // 当原来的容量为小于等于0 并且阈值大于0时，让新容量等于旧的阈值
        newCap = oldThr;
    else {               // zero initial threshold signifies using defaults
        // 如果这两个都小于等于0 使用默认值，初始化
        newCap = DEFAULT_INITIAL_CAPACITY;
        newThr = (int)(DEFAULT_LOAD_FACTOR * DEFAULT_INITIAL_CAPACITY);
    }
    if (newThr == 0) {
        float ft = (float)newCap * loadFactor;
        // 新的负载系数= ft 或者 int的最大值
        // 当新容量小于最大容量并且 ft<MAXIMUM_CAPACITY 时 负载系数=ft
        newThr = (newCap < MAXIMUM_CAPACITY && ft < (float)MAXIMUM_CAPACITY ? (int)ft : Integer.MAX_VALUE);
    }
    // 负载系数=newThr
    threshold = newThr;
    @SuppressWarnings({"rawtypes","unchecked"})
    // 将桶数组进行初始化
    Node<K,V>[] newTab = (Node<K,V>[])new Node[newCap];
    table = newTab;
    if (oldTab != null) {
        // 当之前有元素时走这里，否则直接返回newTab，这里进行扩容。
        // 还没仔细看，应该是扩容后根据hash计算桶的下标会改变（长度为10时，hash计算出来的角标为5，但是长度为20后角标可能改成10了，所以需要将原来5的放到10的位置。）应该是这样没有仔细看，后面再过来看。
        for (int j = 0; j < oldCap; ++j) {
            Node<K,V> e;
            if ((e = oldTab[j]) != null) {
                oldTab[j] = null;
                if (e.next == null)
                    newTab[e.hash & (newCap - 1)] = e;
                else if (e instanceof TreeNode)
                    ((TreeNode<K,V>)e).split(this, newTab, j, oldCap);
                else { // preserve order
                    Node<K,V> loHead = null, loTail = null;
                    Node<K,V> hiHead = null, hiTail = null;
                    Node<K,V> next;
                    do {
                        next = e.next;
                        if ((e.hash & oldCap) == 0) {
                            if (loTail == null)
                                loHead = e;
                            else
                                loTail.next = e;
                            loTail = e;
                        }
                        else {
                            if (hiTail == null)
                                hiHead = e;
                            else
                                hiTail.next = e;
                            hiTail = e;
                        }
                    } while ((e = next) != null);
                    if (loTail != null) {
                        loTail.next = null;
                        newTab[j] = loHead;
                    }
                    if (hiTail != null) {
                        hiTail.next = null;
                        newTab[j + oldCap] = hiHead;
                    }
                }
            }
        }
    }
    return newTab;
}
```

# putAll

```java
public void putAll(Map<? extends K, ? extends V> m) {
    putMapEntries(m, true);
}

final void putMapEntries(Map<? extends K, ? extends V> m, boolean evict) {
    int s = m.size();
    if (s > 0) {
        if (table == null) { // pre-size
            // table为初始化的时候
            float ft = ((float)s / loadFactor) + 1.0F;
            int t = ((ft < (float)MAXIMUM_CAPACITY) ?
                     (int)ft : MAXIMUM_CAPACITY);
            if (t > threshold)
                threshold = tableSizeFor(t);
        }
        else if (s > threshold)
            // 如果s的容量比扩容的阈值大则进行扩容
            resize();
        for (Map.Entry<? extends K, ? extends V> e : m.entrySet()) {
            K key = e.getKey();
            V value = e.getValue();
            // for循环调用putVal方法
            putVal(hash(key), key, value, false, evict);
        }
    }
}
```

# get

给出key，获取value。

```java
public V get(Object key) {
	Node<K,V> e;
	return (e = getNode(hash(key), key)) == null ? null : e.value;
}

final Node<K,V> getNode(int hash, Object key) {
	Node<K,V>[] tab; Node<K,V> first, e; int n; K k;
	if ((tab = table) != null && (n = tab.length) > 0 && (first = tab[(n - 1) & hash]) != null) {
    //如果桶数组不为空、长度大于0，并且根据 hash，长度计算出角标的位置的第一个元素也不为空，不然这个key就不存在。
		if (first.hash == hash && ((k = first.key) == key || (key != null && key.equals(k))))
			// always check first node 总从第一个链表开始验证
            return first;
		if ((e = first.next) != null) {
			if (first instanceof TreeNode)
                // 如果是红黑树，则走红黑树的查找方法
				return ((TreeNode<K,V>)first).getTreeNode(hash, key);
			do {
                // 否则一直沿着链表进行查找
				if (e.hash == hash && ((k = e.key) == key || (key != null && key.equals(k))))
					return e;
			} while ((e = e.next) != null);
		}
	}
	return null;
}
```

# remove()

根据key删除值。

```java
public V remove(Object key) {
	Node<K,V> e;
	return (e = removeNode(hash(key), key, null, false, true)) == null ? null : e.value;
}

final Node<K,V> removeNode(int hash, Object key, Object value, boolean matchValue, boolean movable) {
	Node<K,V>[] tab; Node<K,V> p; int n, index;
	if ((tab = table) != null && (n = tab.length) > 0 && (p = tab[index = (n - 1) & hash]) != null) {
		Node<K,V> node = null, e; K k; V v;
        if (p.hash == hash && ((k = p.key) == key || (key != null && key.equals(k))))
        	// 直接命中
            node = p;
        else if ((e = p.next) != null) {
        	if (p instanceof TreeNode)
                // 如果是红黑树
            	node = ((TreeNode<K,V>)p).getTreeNode(hash, key);
            else {
                // 链表结构
            	do {
                	if (e.hash == hash &&  ((k = e.key) == key || (key != null && key.equals(k)))) {
                    	node = e;
                    	break;
                    }
                    p = e;
                } while ((e = e.next) != null);
            }
        }
        // 经过上面的代码，node是key对应的节点，如果不为空则进行删除节点
        if (node != null && (!matchValue || (v = node.value) == value || (value != null && value.equals(v)))) {
            if (node instanceof TreeNode)
                ((TreeNode<K,V>)node).removeTreeNode(this, tab, movable);
            else if (node == p)
                tab[index] = node.next;
            else
                p.next = node.next;
            ++modCount;
            --size;
            afterNodeRemoval(node);
            return node;
        }
    }
    return null;
}
```



# containsKey(Object key)

判断map中是否包含这个key

```java
public boolean containsKey(Object key) {
    return getNode(hash(key), key) != null;
}
```

从代码可以看出，他其实先调用了根据key查询的方法，然后判断这个key对应的键值对是否存在，`getNode`方法也在上面有用到。

# containsValue（Object value）

根据value判断是否存在这个map中。

```java
public boolean containsValue(Object value) {
	Node<K,V>[] tab; V v;
	if ((tab = table) != null && size > 0) {
        for (int i = 0; i < tab.length; ++i) {
            for (Node<K,V> e = tab[i]; e != null; e = e.next) {
                if ((v = e.value) == value || (value != null && value.equals(v)))
                    return true;
            }
        }
    }
    return false;
}
```

# keySet()

```java
public Set<K> keySet() {
    Set<K> ks = keySet;
    if (ks == null) {
        ks = new KeySet();
        keySet = ks;
    }
    return ks;
}
```

# values

```java
public Collection<V> values() {
    Collection<V> vs = values;
    if (vs == null) {
        vs = new Values();
        values = vs;
    }
    return vs;
}
```

# entrySet

```java
public Set<Map.Entry<K,V>> entrySet() {
    Set<Map.Entry<K,V>> es;
    return (es = entrySet) == null ? (entrySet = new EntrySet()) : es;
}
```

# treeifyBin



```java
final void treeifyBin(Node<K,V>[] tab, int hash) {
    int n, index; Node<K,V> e;
    if (tab == null || (n = tab.length) < MIN_TREEIFY_CAPACITY)
        resize();
    else if ((e = tab[index = (n - 1) & hash]) != null) {
        TreeNode<K,V> hd = null, tl = null;
        do {
            TreeNode<K,V> p = replacementTreeNode(e, null);
            if (tl == null)
                hd = p;
            else {
                p.prev = tl;
                tl.next = p;
            }
            tl = p;
        } while ((e = e.next) != null);
        if ((tab[index] = hd) != null)
            hd.treeify(tab);
    }
}
```



# 总结

-   扩容机制为2倍扩容，最大容量为2的30次幂，并且扩容是放到这一次的结束进行判断下一次是否需要扩容，而不是放到下一次的开始。
-   实现为数组+链表+红黑树（jdk1.8之后）
-   `HashMap`是无序的，因为放值的时候下标是`(n - 1) & hash`计算出来的，如果`hash`值相同则为同一个下标，然后使用链表或树结构。比如我现在顺序放三个key，（a,b,c）。如果a和c的hash值是一样的，b跟他俩不一样，那么最终得到的结果就是a和c是一起拿出来的。他们中间不会有b。如果希望有序需要使用`LinkedHashMap`。

# 参考文章：

https://segmentfault.com/a/1190000012926722#articleHeader3

https://zhuanlan.zhihu.com/p/34280652