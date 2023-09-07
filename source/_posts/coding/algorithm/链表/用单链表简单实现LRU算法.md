---
title: 用单链表简单实现LRU算法
date: 2020-02-26 13:51:33
categories:
- [coding, algorithm]
tags:	
- 算法与数据结构
- 链表
---

# 什么是LRU算法

Least Recently Used，最近最少使用，当数据超过容量时，淘汰最近最少使用的一个然后再进行添加。

用单链表来进行实现：

维护一个链表，从头插入数据。当新数据插入时将新数据作为头部，指向旧的头结点。

向一个单链表插入数据，首先遍历这个链表，查看数据是否已经存在于链表中。如果存在，则删除原有数据，将新数据插入到头结点。

如果不存在，先看是否已经到达容量，如果没有到达容量则插入到头结点。如果到达容量则删除尾部节点，再进行插入。

在这个过程中，将最近使用过的又重新插入到了头部，在链表尾部的就是最近最少使用的一项，所以从尾部删除。

<!--more-->

# 数据结构

 首先我们需要定义一下节点的数据结构：

```java
class Node {
	Node next;
	int val;
	public Node(int val) {
		this.val = val;
	}
}
```

为了方便直接使用int作为存储的数据结构

# 定义实现

lru需要一个容量，以及链表的长度，还有头结点

我们添加节点，定义一个添加方法

为了方便查看数据，我们再定义一个打印数据方法

```java
class LruList {
  Node head;
  int length;
  int maxLength;
  
  public LruList(int maxLength){
    this.maxLength = maxLength;
  }
  void add(int val){
    ...
  }
  void print(){
    Node temp = head; 
		while (temp != null) {
			System.out.print(temp.val + " ,");
			temp = temp.next;
		}
		System.out.println();
  }
}
```

我们在插入的时候，需要向头部插入，如果重复则删除当前节点，或者删除最后一个节点，我们将其抽离为单独的方法。最终的代码如下：

```java
class LruList {
	Node head;
	int length;
	int maxLength;

	public LruList() {
	}

	public LruList(int maxLength) {
		this.maxLength = maxLength;
	}

	void add(int val) {
		Node node = new Node(val);
		//当链表为空的情况
    if (head == null) {
			head = node;
			length++;
			return;
		}
		if (head.val == val) {
			//如果是跟头部一样，则直接返回，因为需要先删除这个头部旧节点再添加，所以直接返回不做操作
			return;
		}
    //进行遍历，查找是否已经存在，由于已经比较过头结点，所以从第二个节点开始
    //同时，保存两个节点，便于删除
		Node e = head;
		Node next = e.next;
		while (e != null && next != null) {
			if (next.val == val) {
				e.next = next.next;
        next = null;
				addHead(node);
				return;
			}
			e = e.next;
			next = next.next;
		}
		//新插入节点不存在，判断是否超过容量
		if (length < maxLength) {
			addHead(node);
			length++;
		} else {
			//删除尾部节点，然后再从头插入
			deleteLast();
			addHead(node);
		}

	}

  /**
  * 删除尾部节点
  */
	private void deleteLast() {
		Node t = head;
		while (t.next != null && t.next.next != null) {
			t = t.next;
		}
		t.next = null;
	}
	
  /**
  * 从头部插入节点
  */
	private void addHead(Node e) {
		e.next = head;
		head = e;
	}

	/**
	 * 将链表打印
	 */
	void print() {
		Node temp = head;
		while (temp != null) {
			System.out.print(temp.val + " ,");
			temp = temp.next;
		}
		System.out.println();
	}

}

class Node {
	Node next;
	int val;

	public Node(int val) {
		this.val = val;
	}

}
```

# 测试一下

```java
public static void main(String[] args) {
		LruList lruList = new LruList(5);
		lruList.add(1);
		lruList.add(2);
		lruList.add(3);
		lruList.add(4);
		lruList.add(5);
		lruList.add(1);
		lruList.add(1);
		lruList.add(3);
		lruList.add(4);
		lruList.add(5);
		lruList.print();
	}
```

最终打印结果为5,4,3,1,2。跟我们预期的结果一致。

