---
title: 乘积为正数的最长子数组长度-LeetCode1567
categories: leetcode
toc: true
date: 2022-04-15 20:58:16
tags:
	- leetcode
	- java
	- 动态规划
---

# 题目描述

链接: https://leetcode-cn.com/problems/maximum-length-of-subarray-with-positive-product/

给定一个整数数组nums, 求乘积为正数的最长子数组的长度

> 示例1:
>
> 输入: [1, -2, -3, 4]
>
> 输出: 4
>
> 数组本身乘积就是正数
>
> 示例2:
>
> 输入: [0, 1, -2, -3, -4]
>
> 输出: 3
>
> 最长乘积为整数的子数组为[1, -2, -3]

<!--more-->

# 解题思路

使用动态规划来计算乘积为正数的最长子数组长度.

使用两个数组positive和negative, 表示在第i个位置时, 乘积为正数的最长子数组长度 和 乘积为负数的最长子数组长度.

由于数组中可能存在0, 所以对于值为0时还需要特殊处理.

对于位置i, 

1. 如果nums[i]>0即为正数

	那么nums[i]与前面的数组相乘时不会改变符号. 即使前面乘积为0, 那么nums[i]也可以单独作为子数组, 长度为1.

	所以 

	```
	positive[i] = positive[i-1] + 1
	```

	对于乘积为负数的最长子数组长度, 如果前面的乘积为0, 那么这时仍然是0. 如果前面不为0, 这时就等于前面的长度加1.

	所以

	```
	negative[i] = negative[i-1] + 1  (negative[i-1]>0)
	negative[i] = 0	  (negative[i-1]=0)
	```

2. 如果nums[i]为负数

	那么nums[i]与前面的数组相乘就会改变符号. 所以当前位置的正数长度应该为上一次的负数长度加1, 同时需要判断上次的负数长度是否为0.

	```
	positive[i] = negative[i-1]+1 (negative[i-1]>0)
	positive[i] = 0  (negative[i-1]=0)
	```

	当前位置的负数长度应该为上一次正数长度加1

	```
	negative[i] = positive[i-1]+1
	```

3. 如果nums[i]=0

	这时乘积为0, 所以

	```
	negative[i] = positive[i] = 0
	```

最后求positive数组中的最大值

## 代码实现

```java
    public int getMaxLen(int[] nums) {
        int length = nums.length;
        int[] positive = new int[length];
        int[] negative = new int[length];
        if (nums[0] > 0) {
            positive[0] = 1;
        } else if (nums[0] < 0) {
            negative[0] = 1;
        }
        int maxLength = positive[0];
        for (int i = 1; i < length; i++) {
            if (nums[i] > 0) {
                positive[i] = positive[i - 1] + 1;
                negative[i] = negative[i - 1] > 0 ? negative[i - 1] + 1 : 0;
            } else if (nums[i] < 0) {
                positive[i] = negative[i - 1] > 0 ? negative[i - 1] + 1 : 0;
                negative[i] = positive[i - 1] + 1;
            } else {
                positive[i] = 0;
                negative[i] = 0;
            }
            maxLength = Math.max(maxLength, positive[i]);
        }
        return maxLength;
    }

```

## 优化

动态规划的一个常规优化, 递推方程只与上一次的状态有关, 所以我们只需要临时变量保存上一次的状态

 ```java
	public int getMaxLen(int[] nums) {
		int length = nums.length;
		int positive = nums[0] > 0 ? 1 : 0;
		int negative = nums[0] < 0 ? 1 : 0;
		int maxLength = positive;
		for (int i = 1; i < length; i++) {
			if (nums[i] > 0) {
				positive++;
				negative = negative > 0 ? negative + 1 : 0;
			} else if (nums[i] < 0) {
				int newPositive = negative > 0 ? negative + 1 : 0;
				negative = positive + 1;
				positive = newPositive;
			} else {
				positive = 0;
				negative = 0;
			}
			maxLength = Math.max(maxLength, positive);
		}
		return maxLength;
	}
 ```

# 相关题目

