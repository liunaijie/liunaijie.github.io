---
title: 链表中的倒数第K个节点-LeetCodeM22
date: 2020-02-08 11:42:28
categories: 
	- [code, leetcode]
toc: true
tags: 
	- leetcode
	- java
---

#  题目描述

输入一个链表，输出该链表中倒数第k个节点。为了符合大多数人的习惯，本题从1开始计数，即链表的尾节点是倒数第1个节点。例如，一个链表有6个节点，从头节点开始，它们的值依次是1、2、3、4、5、6。这个链表的倒数第3个节点是值为4的节点。 

> 示例：
>
> 给定一个链表: 1->2->3->4->5, 和 k = 2.
>
> 返回链表 4->5.
>

<!--more-->

# 解题思路

要求链表的倒数第k个节点，可以利用两个变量，第一个变量从头记录，第二个变量为第一个元素后的第k个元素，然后两个变量一起先后走，当第二个变量到达尾部时，第一个变量就是要求的元素。

**代码实现：**

```java
public ListNode getKthFromEnd(ListNode head, int k) {
  if (head == null) {
    return null;
  }
  ListNode fast = head;
  ListNode slow = head;
  for (int i = 0; i <k  && fast !=null; i++) {
    fast = fast.next;
  }
  while (fast != null){
    fast = fast.next;
    slow = slow.next;
  }
  return slow;
}
```

