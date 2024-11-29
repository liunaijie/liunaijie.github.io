---
title: 二叉树的最大深度-LeetCode104
date: 2020-02-20 20:53:30
tags:
  - 算法与数据结构/二叉树
  - 算法与数据结构/Leetcode
related-project: "[[Blog Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

> 给定一个二叉树，找出其最大深度。
>
> 二叉树的深度为根节点到最远叶子节点的最长路径上的节点数。
>
> 说明: 叶子节点是指没有子节点的节点。
>
> 示例：
> 给定二叉树 \[3,9,20,null,null,15,7]，
>
>     3
>    / \
>   9  20
>     /  \
>    15   7
> 返回它的最大深度 3 。

<!--more-->

# 解题思路

求树的最大深度，一个节点的深度为子节点的深度加一，而最大深度为两个子节点深度的最大值。

```java
public int maxDepth(TreeNode root) {
  if (root == null) {
    return 0;
  }
  return 1 + Math.max(maxDepth(root.left), maxDepth(root.right));
}
```

