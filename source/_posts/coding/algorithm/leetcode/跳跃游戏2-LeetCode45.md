---
title: 跳跃游戏2-LeetCode45
date: 2022-04-14 07:51:29
tags:
- 算法与数据结构
- Leetcode
---

# 题目描述

链接: https://leetcode-cn.com/problems/jump-game-ii/

给定一个非负整数数组nums, 最初位于数组的第一个位置. 数组中的每个元素代表你在该位置上可以跳跃的最大长度.

你的目标是使用最少的跳跃次数到达数组的最后一个位置. 求最少需要跳跃几次, 假设总是可以到达数组的最后一个位置.

> 示例1:
>
> 输入: nums = \[2, 3, 1, 1, 4]
>
> 输出: 2
>
> 从下标0跳到下标1, 再从下标1跳3步到最后一个位置. 总共跳跃2次
>
> 示例2:
>
> 输入: nums = \[2, 3, 0, 1, 4]
>
> 输出: 2

<!--more-->

# 解题思路

这题与跳跃游戏1大致相同, 跳跃游戏1要求是否能够到达最后一个位置, 这里求到达最后一个位置最少需要几步.

与之前一样, 使用一个变量存储历史位置可达的最大下标. 然后再添加一个变量表示一次跳跃的结束下标.

每次更新历史最大可达下标

当当前位置的下标超过这一次跳跃的结束下标时, 跳跃次数加1, 将下一次跳跃的结束下标置为当前的历史最大可达下标.

## 代码实现

```java
		public int jump(int[] nums) {
		    int currentMaxAvailableIndex = 0, end = 0, steps = 0;
		    		for (int i = 0; i < nums.length - 1; i++) {
		    		    			currentMaxAvailableIndex = Math.max(currentMaxAvailableIndex, nums[i] + i);
		    		    			if (i == end) {
		    		    		    				end = currentMaxAvailableIndex;
		    		    		    				steps++;
		    		    			}
		    		}
		    		return steps;
	}
```

# 相关题目

