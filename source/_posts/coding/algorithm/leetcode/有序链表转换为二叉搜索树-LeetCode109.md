---
title: 有序链表转换为二叉搜索树—LeetCode109
date: 2020-03-21 17:13:30
tags:
  - 算法与数据结构
  - 算法与数据结构/Leetcode
related-project: "[[Blog Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

>给定一个单链表，其中的元素按升序排序，将其转换为高度平衡的二叉搜索树。
>
>本题中，一个高度平衡二叉树是指一个二叉树每个节点 的左右两个子树的高度差的绝对值不超过 1。
>
>示例:
>
>给定的有序链表： \[-10, -3, 0, 5, 9],
>
>一个可能的答案是：\[0, -3, 9, -10, null, 5], 它可以表示下面这个高度平衡二叉搜索树：
>
>```
>		0
>	-3	9
> -10	 5
>```
>
>答案不唯一，只要满足平常二叉树的特性即可。

题目中给出的数组已经按升序排序，我们需要将其转换为平衡二叉树。

<!--more-->

# 解题思路

由于是二叉平衡树，所以根节点应该为中间值，这样树两边的元素高度在正负1范围内。

对于根节点两侧，也是一个平衡二叉树，可以递归调用来进行构建。

但是由于给出的是链表，不方便取值，所以可以先转换为数组。

**代码实现：**

```java
public TreeNode sortedListToBSTSelf(ListNode head) {
  //先将链表转化为数组，由于数组需要预先知道容量，所以使用了arraylist容器
  List<Integer> values = new ArrayList<Integer>();
  while (head != null) {
    values.add(head.val);
    head = head.next;
  }
  return help(values, 0, values.size() - 1);
}

private TreeNode help(List<Integer> list, int left, int right) {
  if (left > right) {
    return null;
  }
  //取中间值作为根节点
  int mid = left + (right - left) / 2;
  TreeNode node = new TreeNode(list.get(mid));
  //左侧节点，用数组的左边继续构建
  node.left = help(list, left, mid - 1);
  //右侧节点，用数组的右边继续构建
  node.right = help(list, mid + 1, right);
  return node;
}
```

