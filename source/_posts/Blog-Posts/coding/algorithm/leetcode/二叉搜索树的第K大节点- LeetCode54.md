---
title: 二叉搜索树的第K大节点-剑指Offer LeetCode54
date: 2022-03-23 20:14:19
tags:
  - 算法与数据结构/二叉树
  - 算法与数据结构/Leetcode
related-project: "[[Blog Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

链接: https://leetcode-cn.com/problems/er-cha-sou-suo-shu-de-di-kda-jie-dian-lcof/

给定一颗二叉搜索树, 请找出其中第K大节点的值

> 示例1:
>
> 输入:  层序遍历 = \[3, 1, 4, null ,2] , k = 1
>
> ​			  3
>
> ​		/			\
>
> ​	1				4
>
> ​		\	
>
> ​			2		
>
> 输出: 4, 最大的节点为4
>
> 示例2:
>
> 输入: 层序遍历 =  \[ 5, 3, 6, 2, 4, null, null ,1], k = 3
>
> ​						5
>
> ​				/					\
>
> ​			   3						6
>
> ​			/	\
>
> ​		2		4	
>
> ​	/
>
> 1
>
> 输出: 4. 倒数第3个最大节点为4.



<!--more-->

# 解题思路

## 中序遍历

我们可以利用二叉搜索树中序遍历有序的特性, 先遍历一次有序的数组, 然后取倒数第K个元素

### 代码实现:

```java
	public int kthLargest(TreeNode root, int k) {
		    List<Integer> list = new LinkedList<>();
		    		Stack<TreeNode> stack = new Stack<>();
				    while (root != null || !stack.isEmpty()) {
		    		    			while (root != null) {
		    		    		    				stack.push(root);
		    		    		    				root = root.left;
		    		    			}
					    		    root = stack.pop();
					    		    list.add(root.val);
		    		    			root = root.right;
		    		}
				    return list.get(list.size() - 1 - (k - 1));
	}
```



## 倒序的中序遍历

中序遍历的顺序为: 左节点, 根节点, 右节点. 所以可以得到升序的数组

如果我们将顺序修改为: 右节点, 根节点, 左节点. 那么就可以得到降序的数组, 同时我们只需要得到倒数第K个节点, 所以可以在遍历中判断当前是否满足条件, 如果满足条件可以提前返回不需要遍历整颗树

### 代码实现

```java
	int res, k;

	public int kthLargest2(TreeNode root, int k) {
		    this.k = k;
		    		dfs(root);
				    return res;
	}

	private void dfs(TreeNode root) {
		    		if (root == null) {
					    		    return;
		    		}
		    // 先遍历右节点
				    dfs(root.right);
		    		if (k == 0) {
		    		    			return;
		    		}
		    		k = k - 1;
		    // 当k等于0时, 返回当前节点
		    		if (k == 0) {
		    		    			res = root.val;
		    		}
			    // 最后遍历左节点
		    		dfs(root.left);
	}
```



