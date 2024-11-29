---
title: 打家劫舍2-LeetCode213
date: 2022-04-13 22:10:48
tags:
  - 算法与数据结构/动态规划
  - 算法与数据结构/Leetcode
related-project: "[[Blog-Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

链接: https://leetcode-cn.com/problems/house-robber-ii/

你是一个专业的小偷, 计划偷窃沿街的房屋, 每间房内都藏有一定的现金. 这个地方所有的房屋都 围成一圈, 这意味着第一个房屋和最后一个房屋是紧挨着的. 同时, 相邻的房屋装有相互连通的防盗系统, 如果两间相邻的房屋在同一晚上被小偷闯入, 系统会自动报警 .

给定一个代表每个房屋存放金额的非负整数数组, 计算你在不触动警报装置的情况下,今晚能够偷窃到的最高金额.

> 示例1:
>
> 输入：nums = [2,3,2]
>
> 输出：3
>
> 你不能先偷窃 1 号房屋（金额 = 2），然后偷窃 3 号房屋（金额 = 2）, 因为他们是相邻的。
>
> 示例2:
>
>  输入：nums = [1,2,3,1]
>
> 输出：4
>
> 你可以先偷窃 1 号房屋（金额 = 1），然后偷窃 3 号房屋（金额 = 3）.    偷窃到的最高金额 = 1 + 3 = 4 .

<!--more-->

# 解题思路

这个题目与打家劫舍问题很相似, 唯一的区别是这里的房间是相连的.

当房间相连之和, 第一家和最后一家是不能一起偷的. 

我们可以计算[0, n-2]不偷最后一家 和[1, n-1]不偷第一家, 然后求两种情况能获取的最大金额.

而只偷[0, n-2]或[1, n-1]又转化成了打家劫舍问题1.

## 代码实现

```java
	public int rob(int[] nums) {
		    if (nums == null || nums.length == 0) {
							        return 0;
				    }
				    if (nums.length == 1) {
		    					    return nums[0];
				    }
		    		if (nums.length == 2) {
		    		    			return Math.max(nums[0], nums[1]);
				    }
		    		return Math.max(helper(nums, 0, nums.length - 1), helper(nums, 1, nums.length));
	}

	private int helper(int[] nums, int start, int end) {
				    int x = nums[start], y = Math.max(nums[start], nums[start + 1]);
		    		for (int i = start + 2; i < end; i++) {
		    		    			int temp = y;
		    		    			y = Math.max(nums[i] + x, y);
		    		    			x = temp;
		    		}
		    		return y;
	}
```

# 相关题目

