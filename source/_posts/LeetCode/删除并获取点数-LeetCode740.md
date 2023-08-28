---
title: 删除并获取点数-LeetCode740
categories: 
	- [code, leetcode]
toc: true
date: 2022-04-13 22:30:48
tags:
	- leetcode
	- java
	- 动态规划
---

# 题目描述

链接: https://leetcode-cn.com/problems/delete-and-earn/

给你一个整数数组nums, 可以对他进行一些操作. 每次操作中, 选择任意一个nums[i], 删除它然后获取nums[i]的点数. 同时还需要删除所有 等于nums[i]-1和nums[i]+1的元素. 例如删除3, 那么得到3个点数, 同时需要在数组中删除所有的2和4.

开始时拥有0个点数, 求你能通过这些操作获取的最大点数.

> 示例1:
>
> 输入: nums = [3, 4, 2]
>
> 输出: 6
>
> 删除4和2.得到6点.
>
> 删除4获取4个点数, 同时3也被删除.
>
> 还剩下2, 然后删除2再得到2个点数.
>
> 示例2:
>
> 输入: nums = [2, 2, 3, 3, 3, 4]
>
> 输出: 9
>
> 删除3, 总共可以得到9个点数(3*3). 同时删除2和4.
>
> 最终得到9个点数.

<!--more-->

# 解题思路

删除nums[i]时, 需要将num[i]-1和nums[i]+1一起删除掉. 并且如果nums[i]在数组中有多个值, 我们可以得到nums[i]多个值的和.

我们先将题目进行一次转化, 输入[2, 2, 3, 3, 3, 4]

将nums[i]放到newArray[nums[i]]的位置并进行累积. 这里只有2, 3, 4三个元素. 则分别放到相应的文件然后进行累加. 转化为 [0, 0 ,4, 9, 4]. 

然后我们再来看一下这个问题, 我们在newArray中, 得到newArray[i]时, 就无法得到newArray[i-1]和newArray[i+1].

这个问题与打家劫舍问题类型.

## 代码实现

```java
	public int deleteAndEarn(int[] nums) {
    		int max = Integer.MIN_VALUE;
		    		for (int num : nums) {
    		    					if (num > max) {
        				    						max = num;
    					    		}
    				}
    				int[] sum = new int[max + 1];
    				for (int num : nums) {
    		    					sum[num] = sum[num] + num;
    				}
    				int x = sum[0], y = Math.max(sum[0], sum[1]);
    				for (int i = 2; i < sum.length; i++) {
    		    					int temp = y;
    		    					y = Math.max(x + sum[i], y);
    		    					x = temp;
    				}
    				return y;
	}
```

# 相关题目

