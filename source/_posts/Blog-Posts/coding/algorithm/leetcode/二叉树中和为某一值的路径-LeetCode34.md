---
title: 二叉树中和为某一值的路径- 剑指Offer LeetCode34
date: 2022-03-24 22:21:46
tags:
  - 算法与数据结构/二叉树
  - 算法与数据结构/Leetcode
related-project: "[[Blog-Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

链接: https://leetcode-cn.com/problems/er-cha-shu-zhong-he-wei-mou-yi-zhi-de-lu-jing-lcof/

给定二叉树的根节点root和一个整数目标targetSum, 找出所有**从根节点到叶子节点**路径总和等于给定目标和的路径

叶子节点是指没有子节点的节点

> 示例1: 
>
> ![](https://assets.leetcode.com/uploads/2021/01/18/pathsumii1.jpg)
>
> 输入：root = \[5,4,8,11,null,13,4,7,2,null,null,5,1], targetSum = 22
> 		输出：\[\[5,4,11,2], \[5,8,4,5]]
>
> 有两条路径加起来之和等于22
>
> 示例2:
>
> ![img](https://assets.leetcode.com/uploads/2021/01/18/pathsum2.jpg)
>
> 输入：root = \[1,2,3], targetSum = 5
> 		输出：\[] 
>
> 没有符合条件的路径

<!--more-->

# 解题思路

DFS

每次遍历时, 将当前节点加入到路径中, 并将总和减去当前节点的值

判断当前节点是否是叶子节点, 如果是则判断和是否已经等于0, 如果等于0, 则表示当前路径符合要求. 否则回到上一层

回到上一层时, 将路径中减去当前节点, 并将总和再加上当前节点.

## 代码实现

```java
	List<List<Integer>> res = new LinkedList<>();
	LinkedList<Integer> path = new LinkedList<>();

public List<List<Integer>> pathSum(TreeNode root, int target) {
    		dfs(root, target);
		    return res;
	}

	private void dfs(TreeNode node, int target) {
		    if (node == null) {
        			return;
    		}
		    // 保存当前路径
    		path.addLast(node.val);
		    // 将目标值减去当前节点的值
    		target -= node.val;
		    // 如果是叶子节点，并且目标值为0也就是满足条件后，将当前路径放到结果集合中
    		if (node.left == null && node.right == null && target == 0) {
			        res.add(new LinkedList<>(path));
		    }
    		// 遍历左节点
    		dfs(node.left, target);
		    // 遍历右节点
    		dfs(node.right, target);
    		// 将当前节点的值从路径中移除
		    path.removeLast();
	}
```



