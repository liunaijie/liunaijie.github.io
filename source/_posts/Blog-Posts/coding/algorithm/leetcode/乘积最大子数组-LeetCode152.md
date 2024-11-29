---
title: 乘积最大子数组-LeetCode152
date: 2022-04-15 20:31:27
tags:
  - 算法与数据结构/动态规划
  - 算法与数据结构/Leetcode
related-project: "[[Blog-Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

链接: https://leetcode-cn.com/problems/maximum-product-subarray/

给你一个整数数组nums, 请你找出数组中成绩最大的非空连续子数组(该子数组中至少包含一个数字), 并返回该子数组所对应的乘积.

> 示例1:
>
> 输入: \[2, 3, -2, 4]
>
> 输出: 6
>
> 子数组 \[2, 3]得到最大乘积6
>
> 输入 \[-2, 0 -,1]
>
> 输出: 0

<!--more-->

# 解题思路

求子数组乘积的最大值, 由于数组中存在负数, 当最大值遇到负数之后结果就变成了最小值. 所以我们需要保存最大值和最小值. 

如果遇到正数, 则最大值依然是最大值, 如果遇到负数则将最大值和最小值交换, 然后仍然使用最大值(交换之后的最小值)与负数相乘得到最大值.

## 代码实现

```java
public int maxProduct(int[] nums) {
		int res = Integer.MIN_VALUE;
		int max = 1, min = 1;
		for (int num : nums) {
			if (num < 0) {
				int temp = min;
				min = max;
				max = temp;
			}
			min = Math.min(min * num, num);
			max = Math.max(max * num, num);
			res = Math.max(max, res);
		}
		return res;
	}
```

# 相关题目

