---
title: 环形链表—LeetCode141
date: 2019-12-21 13:13:30
tags:
  - 算法与数据结构/链表
  - 算法与数据结构/Leetcode
related-project: "[[Blog Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

> 给定一个链表，判断链表中是否有环。
>
> 为了表示给定链表中的环，我们使用整数 `pos` 来表示链表尾连接到链表中的位置（索引从 0 开始）。 如果 `pos` 是 `-1`，则在该链表中没有环。
>
>  
>
> **示例 1：**
>
> ```
> 输入：head = \[3,2,0,-4], pos = 1
> 输出：true
> 解释：链表中有一个环，其尾部连接到第二个节点。
> ```
>
> ![img](https://assets.leetcode-cn.com/aliyun-lc-upload/uploads/2018/12/07/circularlinkedlist.png)
>
> **示例 2：**
>
> ```
> 输入：head = \[1,2], pos = 0
> 输出：true
> 解释：链表中有一个环，其尾部连接到第一个节点。
> ```
>
> ![img](https://assets.leetcode-cn.com/aliyun-lc-upload/uploads/2018/12/07/circularlinkedlist_test2.png)
>
> **示例 3：**
>
> ```
> 输入：head = \[1], pos = -1
> 输出：false
> 解释：链表中没有环。
> ```
>
> ![img](https://assets.leetcode-cn.com/aliyun-lc-upload/uploads/2018/12/07/circularlinkedlist_test3.png)
>
>  
>
> **进阶：**
>
> 你能用 *O(1)*（即，常量）内存解决此问题吗？

<!--more-->

# 解题思路

如果一个链表中出现了环，我们在进行遍历时就会有重复的元素出现，那么可以使用哈希表来实现。

## 哈希表

```java
public static boolean hasCycle1(ListNode head) {
  if (head == null) {
    //入参检查，如果链表为空则不可能存在环
    return false;
  }
  Set set = new HashSet();
  while (head != null) {
    //如果当前节点在 set 中存储过，则表示有环
    if (set.contains(head)) {
      return true;
    }
    //不然将当前节点添加到 set 中，并将当前节点改为下一个节点
    set.add(head);
    head = head.next;
  }
  return false;
}
```

使用哈希表的空间复杂度为O(n)

## 双指针

使用双指针可以实现O(1)的空间复杂度，因为如果链表有环，我们使用两个速度不同的指针，那么它两个最终都会相遇，如果没有环，那快指针会先到达终点。

```java
public static boolean hasCycle2(ListNode head) {
  if (head == null || head.next == null) {
    return false;
  }
  ListNode slow = head;
  ListNode fast = head.next;
  while (slow != fast) {
    if (fast == null || fast.next == null) {
      return false;
    }
    slow = slow.next;
    fast = fast.next.next;
  }
  return true;
}
```

