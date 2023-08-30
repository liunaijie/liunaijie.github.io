---
title: 反转一个单链表-LeetCode206
date: 2019-11-24 11:18:35
tags: 
	- leetcode
	- java
---

# 题目描述

> 反转一个单链表。
>
> **示例:**
>
> ```
> 输入: 1->2->3->4->5->NULL
> 输出: 5->4->3->2->1->NULL
> ```
>
> **进阶:**
> 你可以迭代或递归地反转链表。你能否用两种方法解决这道题？

<!--more-->

# 解题思路

## 迭代

使用迭代法，存储两个节点，上一个节点和当前节点，然后进行反转

代码实现：

```java
public ListNode reverseList(ListNode head) {
  ListNode prev = null;
  ListNode cur = head;
  while (cur != null) {
    ListNode temp = cur.next;
    cur.next = prev;
    prev = cur;
    cur = temp;
  }
  return prev;
}
```

## 递归

```java
public ListNode reverseList2(ListNode head) {
  ListNode prev = null;
  ListNode cur = head;
  return reverseHelp(prev, cur);
}

public ListNode reverseHelp(ListNode prev, ListNode cur) {
  if (cur == null) {
    return prev;
  }
  ListNode temp = cur.next;
  cur.next = prev;
  prev = cur;
  cur = temp;
  return reverseHelp(prev, cur);
}
```

# 相关题目

- [K个一组反转链表](https://www.liunaijie.top/2019/11/27/LeetCode/K个一组翻转链表-LeetCode25/)