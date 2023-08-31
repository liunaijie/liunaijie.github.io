---
title: 对称二叉树—LeetCode101
date: 2019-02-25 11:21:16
tags: 
- 算法与数据结构/二叉树
- Leetcode
---

# 题目描述

> 给定一个二叉树，检查它是否是镜像对称的。
>
> 例如，二叉树 `[1,2,2,3,4,4,3]` 是对称的。
>
> ```
>     1
>    / \
>   2   2
>  / \ / \
> 3  4 4  3
> ```
>
> 但是下面这个 `[1,2,2,null,3,null,3]` 则不是镜像对称的:
>
> ```
>     1
>    / \
>   2   2
>    \   \
>    3    3
> ```
>
> **说明:**
>
> 如果你可以运用递归和迭代两种方法解决这个问题，会很加分。

<!--more-->

# 解题思路

当一棵树的两个子节点有相同的值，并且每个树的右子树与另一个树的左子树镜像对称。

## 递归实现

```java
public boolean isSymmetric(TreeNode root) {
	return isMirror(root, root);
}

public boolean isMirror(TreeNode t1, TreeNode t2) {
  if (t1 == null && t2 == null) {
    return true;
  }
  if (t1 == null || t2 == null) {
    return false;
  }
  return (t1.val == t2.val) && isMirror(t1.left, t2.right) && isMirror(t1.right, t2.left);
}
```

## 迭代实现

迭代实现需要借助队列来进行实现。

```java
public boolean isSymmetricQueue(TreeNode root) {
  Queue<TreeNode> q = new LinkedList<>();
  q.add(root);
  q.add(root);
  while (!q.isEmpty()) {
    TreeNode t1 = q.poll();
    TreeNode t2 = q.poll();
    if (t1 == null && t2 == null) {
      continue;
    }
    if (t1 == null || t2 == null) {
      return false;
    }
    if (t1.val != t2.val) {
      return false;
    }
    q.add(t1.left);
    q.add(t2.right);
    q.add(t1.right);
    q.add(t2.left);
  }
  return true;
}
```

这样每次都对比左节点和另外一棵树的右节点。

