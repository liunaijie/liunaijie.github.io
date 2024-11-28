---
title: 最大二叉树—LeetCode654
date: 2019-01-08 20:52:40
tags:
  - 算法与数据结构/二叉树
  - 算法与数据结构/Leetcode
related-project: "[[Blog Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

> 给定一个不含重复元素的整数数组。一个以此数组构建的最大二叉树定义如下：
>
> 二叉树的根是数组中的最大元素。
> 左子树是通过数组中最大值左边部分构造出的最大二叉树。
> 右子树是通过数组中最大值右边部分构造出的最大二叉树。
> 通过给定的数组构建最大二叉树，并且输出这个树的根节点。
>
> 示例 ：
>
> 输入：\[3,2,1,6,0,5]
> 输出：返回下面这棵树的根节点：
>
> ```
>   		6
>     /   \
>    3     5
>     \    / 
>      2  0   
>        \
>         1
> ```
>
>
> 提示：
>
> 给定的数组的大小在 \[1, 1000] 之间。
>

<!--more-->

# 解题思路

首先找到数组中的最大值，然后将它作为根节点

将数组左侧的数组再按照刚才构建树的方法进行递归构建，然后作为左节点

将数组右侧的数组按照刚才构建的方法进行递归构建，然后作为右节点

**代码实现：**

```java
public TreeNode constructMaximumBinaryTree(int[] nums) {
  return buildTree(nums, 0, nums.length - 1);
}

public TreeNode buildTree(int[] nums, int start, int end) {
  if (start > end) {
    return null;
  }
  int maxIndex = getMaxIndex(nums, start, end);
  TreeNode root = new TreeNode(nums[maxIndex]);
  root.left = buildTree(nums, start, maxIndex - 1);
  root.right = buildTree(nums, maxIndex + 1, end);
  return root;
}

//获取从 start到end之间最大值的下标
public int getMaxIndex(int[] array, int start, int end) {
  int maxIndex = start;
  for (int i = start; i <= end; i++) {
    if (array[i] > array[maxIndex]) {
      maxIndex = i;
    }
  }
  return maxIndex;
}
```

