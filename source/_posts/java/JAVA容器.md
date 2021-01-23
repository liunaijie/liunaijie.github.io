---
title: JAVA容器
date: 2019-08-31 19:12:23
categories: "java"
toc: true
tags: 
	- java
---

# 概述

容器主要包括`Collection`和`Map`两种，`Collection`存储对象的集合，而`Map`存储着键值对。  而`Collection`下又分为`List`，`Set`，和`Queue`三种。

![JAVA容器](https://raw.githubusercontent.com/liunaijie/images/master/JAVA容器分类.png)

# 源码分析

- Map
  - [x] [HashMap](https://www.liunaijie.top/2019/08/22/java/HashMap源码学习/)
  - [x] [LinkedHashMap](https://www.liunaijie.top/2019/08/22/java/LinkedHashMap源码/)
  - [x] [TreeMap](https://www.liunaijie.top/2019/11/12/java/TreeMap源码学习/)
  - [x] [Hashtable](https://www.liunaijie.top/2019/12/20/java/Java古老的集合类之Hashtable/)

HashMap 采用数组+链表+红黑树的数据结构(1.8)，查找的效率由哈希O(1)+链表O(n)，改为了哈希O(1)+O(logN)。当链表长度到达8时转换为红黑树，当红黑树上节点的数量降为6时再转换为链表。遍历时的顺序与插入顺序不一致。它的查找效率高。

LinkedHashMap 它是 hashmap 的子类，在 hashmap 的基础上添加了双向链表。通过链表的方式保证了遍历时顺序与插入时顺序一致。可以在构造函数中设置访问顺序，实现 lru 算法。

TreeMap 采用红黑树的数据结构。所以在遍历时内部是排好序的。但效率最低。

Hashtable 采用数组+链表的数据结构。它在可能多线程访问的方法上添加了`synchronized`关键字，保证了线程的安全性。与HashMap的思路大体相同。

- List
  - [x] [ArrayList](https://www.liunaijie.top/2019/08/20/java/ArrayList源码学习/)
  - [x] [LinkedList](https://www.liunaijie.top/2019/08/21/java/LinkedList源码学习/)
  - [x] [Vector](https://www.liunaijie.top/2019/12/23/java/Java古老的集合类之Vector/)

ArrayList 通过数组实现，所以在访问时直接通过下标即可获取，速度快。但插入需要复制数组，速度慢。

LinkedList 通过链表实现，所以在插入时速度快，但访问时需要通过链表逐个访问，速度慢。

Vector 通过数组实现，大体与ArrayList相同。但它是线程安全的，通过在方法上添加`synchronized`关键字来实现。并且它可以设置一个扩容的长度，每次扩容时数组增加我们设置的长度，当没设置是为双倍扩容。ArrayList是1.5倍扩容并且没有设置扩容长度的变量。

- Set
  - [x] [HashSet](https://www.liunaijie.top/2019/08/26/java/HashSet源码/)
  - [ ] LinkedHashSet
  - [ ] TreeSet

set 是 map 的子集，当 map 只存储 key，value 为空时就是 set。

- Queue
  - [x] [LinkedList](https://www.liunaijie.top/2019/08/21/java/LinkedList源码学习/)
  - [ ] PriorityQueue

队列，先进先出原则。通过链表很容易实现，获取头部节点，新增时插入到尾部。而PriorityQueue通过数组进行的实现，并可以实现优先级。

- [迭代器](https://www.liunaijie.top/2019/08/28/java/迭代器/)

