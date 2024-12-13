---
title: 最大子数组和-LeetCode53
date: 2022-04-14
categories:
  - notes
tags:
  - 动态规划
  - LeetCode
related-project: "[[Blog-Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

链接: https://leetcode-cn.com/problems/maximum-subarray/

给你一个整数数组nums, 请你找出一个具有最大和的连续子数组(子数组最少包含一个元素), 返回其最大和

子数组是数组中的一个连续部分

> 示例1:
>
> 输入: nums =\[-2, 1, -3, 4, -1, 2, 1, -5, 4]
>
> 输出: 6
>
> 连续子数组 \[4, -1, 2, 1]的和最大, 为6.
>
> 示例2:
>
> 输入: nums = \[1]
>
> 输出: 1
>
> 示例3:
>
> 输入: nums = \[5, 4, -1, 7, 8]
>
> 输出: 23

<!--more-->

# 解题思路

求一个连续子数组的最大和, 先来看在每个位置上如何求连续子数组的最大和.

在下标n时的连续子数组最大和应该为 上一个位置的最大和加上当前位置的值与当前位置的值的最大值.

公式为: f(n) = `Max( f(n-1)+nums[n], nums[n] )`

然后我们需要的结果为全局的最大值即 res = Max(f(n))

## 代码实现

```java
	public int maxSubArray(int[] nums) {
		    int res = nums[0], temp = 0;
				    for (int x : nums) {
					    		    temp = Math.max(temp + x, x);
					    		    res = Math.max(res, temp);
				    }
		    		return res;
	}
```

# 相关题目

