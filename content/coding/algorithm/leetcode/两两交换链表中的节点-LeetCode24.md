---
title: 两两交换链表中的节点—LeetCode24
date: 2019-11-21
categories:
  - notes
tags:
  - LeetCode
related-project: "[[Blog-Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

> 给定一个链表，两两交换其中相邻的节点，并返回交换后的链表。
>
> **你不能只是单纯的改变节点内部的值**，而是需要实际的进行节点交换。
>
> **示例:**
>
> ```
> 给定 1->2->3->4, 你应该返回 2->1->4->3.
> ```

可以看出，链表每两个一组交换了前后位置，然后再跟其他元素按照原有顺序连接。

<!--more-->

# 解题思路

## 迭代

两个为一组，那么就根据这一组前面的节点和后面的节点等分为了这样的结构：`pre,first,second,next`。

每对一组进行修改，要将`pre.next=second`，`first.next=next`，`second.next=first`

然后下一组的`pre = first,fist=next`

在开始的时候，头结点没有前面的节点，所以需要临时构建一个节点。

代码实现：

```java
public ListNode swapPairs(ListNode head) {
  ListNode fakeHead = new ListNode(-1);
  fakeHead.next = head;
  ListNode pre = fakeHead;
  ListNode curr = pre.next;
  while (curr != null && curr.next != null) {
    ListNode temp = curr.next;
    ListNode next = temp.next;
    pre.next = temp;
    temp.next = curr;

    pre = curr;
    curr = next;
  }
  pre.next = curr;
  return fakeHead.next;
}
```

## 递归

这个问题当然也可以使用递归来实现，递归时如果当前节点和下一个节点不为空则进行处理，即终止条件为两个节点都为空。

然后递归调用第二个节点的下一个元素。向上返回的结果是反转后的头元素，也就是两个元素中的第二个元素。

代码实现：

```java
public ListNode swapPairs2(ListNode head) {
  if ((head == null) || (head.next == null)) {
    return head;
  }
  ListNode firstNode = head;
  ListNode secondNode = head.next;
  firstNode.next  = swapPairs2(secondNode.next);
  secondNode.next = firstNode;
  return secondNode;
}
```

