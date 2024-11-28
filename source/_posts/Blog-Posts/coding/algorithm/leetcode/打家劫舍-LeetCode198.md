---
title: 打家劫舍—LeetCode198
date: 2022-04-13 21:12:29
tags:
  - 算法与数据结构/动态规划
  - 算法与数据结构/Leetcode
related-project: "[[Blog Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

链接: https://leetcode-cn.com/problems/house-robber/

你是一个专业的小偷, 计划偷窃沿街的房屋, 每间房内都藏有一定的现金, 影响你偷窃的唯一限制因素是相邻的房屋装有相互连通的防盗系统. 如果两间相邻的房屋在同一晚上被小偷闯入, 系统会自动报警.

给定一个代表每个访问存放金额的非负整数数组, 计算你在不触发警报装置的情况下, 一夜之内能够偷窃到的最高金额.

> 示例1:
>
> 输入: \[1, 2, 3, 1]
>
> 输出: 4
>
> 偷窃1号和3号. 得到1+3 = 4.
>
> 示例2: 
>
> 输入: \[2, 7, 9, 3, 1]
>
> 输出: 12
>
> 偷窃1号, 3号和5号. 得到2+9+1 = 12.

<!--more-->

# 解题思路

由于不能偷窃两间相邻的房间, 所以在第N个房间时, 可能的情况为:

1. 由于N-1个房间已经偷窃过了, 所以不能偷窃
2. N-1个房间没偷, 所以当前房间可以偷.

那么在第N个房间时, 能偷到的最大金额就是这两种情况下的最大值.

转化为递推公式为: 

```java
f(n) = Max(f(n-1), f(n-2) + nums[n])
```

边界条件:

当n=0时, 表示只有一个房间, 那么最大值只能为`nums[0]`

当n=1时, 表示有两个房间, 我们只能偷一个, 那么f(1) = `Max(nums[0] , nums[1])`

## DP数组实现:

```java
	public int rob(int[] nums) {
		    if (nums == null) {
					    		    return 0;
				    }
				    if (nums.length == 1) {
		    		    			return nums[0];
		    		}
		    		int[] res = new int[nums.length];
				    res[0] = nums[0];
		    		res[1] = Math.max(nums[0], nums[1]);
		    		for (int i = 2; i < nums.length; i++) {
		    		    			res[i] = Math.max(nums[i] + res[i - 2], res[i - 1]);
		    		}
		    		return res[nums.length - 1];
	}
```

## 优化

动态规划的一个优化点, 我们可以不创建数组, 而是存储中间变量, 减少空间复杂度.

这里计算n时, 只需要n-1和n-2两个值, 所以我们可以定义两个变量来实现

```java
	public int rob2(int[] nums) {
    		if (nums == null || nums.length == 0) {
    		    					return 0;
		    		}
		    		if (nums.length == 1) {
			    		    		return nums[0];
    				}
    				int x = nums[0], y = Math.max(nums[0], nums[1]);
    				for (int i = 2; i < nums.length; i++) {
    		    					int temp = y;
    		    					y = Math.max(nums[i] + x, y);
    		    					x = temp;
    				}
    				return y;
	}
```

