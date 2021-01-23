---
title: K个一组翻转链表-LeetCode25
date: 2019-11-27 18:50:08
categories: "leetcode"
toc: true
tags: 
	- leetcode
	- java
---

# 题目描述

> 给你一个链表，每 k 个节点一组进行翻转，请你返回翻转后的链表。
> k 是一个正整数，它的值小于或等于链表的长度。
> 如果节点总数不是 k 的整数倍，那么请将最后剩余的节点保持原有顺序。
> 示例 :
> 给定这个链表：1->2->3->4->5
> 当 k = 2 时，应当返回: 2->1->4->3->5
> 当 k = 3 时，应当返回: 3->2->1->4->5
> 说明 :
> 你的算法只能使用常数的额外空间。
> 你不能只是单纯的改变节点内部的值，而是需要实际的进行节点交换

# 解题思路

首先根据 k，分隔每一组。将这一组反转，将下面的一组递归调用函数，然后将这一组的最后一个节点（就是参数中的头结点）与下一组反转后的头结点相连接。

<!--more-->

# 代码

```java
public ListNode reverseKGroup(ListNode head, int k) {
    ListNode lastNode = head;
    //根据 k ，分割每一组。最终 temp 为一组的最后一个节点
    for (int i = 1; i < k; i++) {
        if (lastNode != null) {
            lastNode = lastNode.next;
        }
    }
    //如果为空则表示不足一组，不用反转，返回头指针
    if (lastNode == null) {
        return head;
    }
    //开始每一组的反转，首先将下一组的开始存为一个变量
    ListNode nextGroupHead = lastNode.next;
    //然后将这一组与下一组分隔，不然无法反转这一组，后面再将两者连接
    lastNode.next = null;
    //将这一组反转
    ListNode newHead = reverseGroupHelp(head);
    //将后面的继续递归反转，得到的结果是下面一组反转后的头结点
    ListNode reverseNextHead = reverseKGroup(nextGroupHead, k);
    //当这一组进行反转后，传入的 head 变成了这一组最后一个节点，最后一个节点连接下一组的头结点。如果不够一组，在上面已经 return 掉了
    head.next = reverseNextHead;
    return newHead;
}

/**
 * 反转链表函数
 */
private ListNode reverseGroupHelp(ListNode head) {
    if (head == null || head.next == null) {
        return head;
    }
    ListNode result = reverseGroupHelp(head.next);
    head.next.next = head;
    head.next = null;
    return result;
}
```

参数中传入了头结点，根据 k 找到这一组的最后一个节点。然后将这个节点与下一组节点分隔。

将头结点进行反转，返回反转后的头结点。

将下一组递归调用这个函数，得到返回的头结点。

将这一组的最后一个节点与后面的头结点相连接。一组反转后的最后一个节点也就是传入参数中的头结点

# 变形-从后开始反转

在上面这道题，是从头开始计算反转，这次要从尾部开始反转。拿上面的例子来说：

> 给定一个链表：1->2->3->4->5
> 当 k = 2 时，应当返回: 1->3->2->5->4
> 当 k = 3 时，应当返回: 1->2->5->4->3

这道题需要先转换一下思路：如果给定的是这样：

> 给定一个链表：5->4->3->2->1
> 当 k = 2 时，应当返回: 4->5->2->3->1
> 当 k = 3 时，应当返回: 3->4->5->2->1

是不是就和我们刚刚做的题目一样了。所以我们要做的是先将链表反转，然后进行 k 个一组反转，最后再将链表反转回来。最终的代码如下：

```java
public ListNode reverseKGroupFromTail(ListNode head, int k) {
    //首先将链表反转
    ListNode tail = reverseGroupHelp(head);
    //然后将链表分组反转
    ListNode reverse = reverseKGroup(tail, k);
    //再将链表反转回来
    return reverseGroupHelp(reverse);
}
```

