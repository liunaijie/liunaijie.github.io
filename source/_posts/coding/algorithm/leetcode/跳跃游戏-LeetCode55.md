---
title: 跳跃游戏-LeetCode55
date: 2022-04-14 07:35:38
tags:
- 算法与数据结构
- Leetcode
---

# 题目描述

链接: https://leetcode-cn.com/problems/jump-game/

给定一个非负整数数组nums, 你最初位于数组的第一个下标, 数组中的每个元素代表你在该位置可以跳跃的最大长度.

判断你是否能够到达最后一个下标

> 示例1:
>
> 输入: nums=\[2, 3, 1, 1, 4]
>
> 输出: true
>
> 可以先从下标0走1步到下标1,  然后从下标1走3步到最后一个下标
>
> 示例2:
>
> 输入: nums = \[3, 2, 1, 0, 4]
>
> 输出: false
>
> 无论怎么走, 都会走到下标3的位置, 到了这里无法在继续往前走. 所以不可能到达最后一个坐标

<!--more-->

# 解题思路

## 使用额外数组

使用一个额外的数组来存储每个位置是否可达, 遍历完成后判断最后一个位置是否可达.

遍历数组, 首先判断当前位置是否可达, 如果不可达, 直接返回false.

如果可达, 将后nums[i]为标记为可达. 如果超过数组长度则直接返回true, 提前终止.

### 代码实现

```java
	public static boolean canJump(int[] nums) {
		    if (nums == null || nums.length == 0) {
		    		    			return false;
				    }
				    if (nums.length == 1) {
		    		    			return true;
		    		}
				    int[] res = new int[nums.length];
				    res[0] = 1;
				    for (int i = 0; i < nums.length - 1; i++) {
							        if (res[i] == 0) {
		    		    		    				return false;
		    		    			}
							        int jumpSize = nums[i];
							        for (int j = 1; j <= jumpSize; j++) {
								        		    if ((i + j) < nums.length) {
									        		    		    res[i + j] = 1;
				        		    				} else {
				        		    		    					return true;
								        		    }
		    					    }
				    }
				    return res[nums.length - 1] == 1;
	}

```

## 标记历史位置可达的最大位置

遍历数组, 使用变量存储当前位置可以到达的最大下标

如果当前位置的下标比历史最大下标小, 所以当前位置不可达.

否则比较历史最大下标与 (i+nums[i])的值, 取最大值作为最大可达下标

如果最大可达下标超过数组长度, 提前返回true

### 代码实现

```java
	public boolean canJump(int[] nums) {
		    int n = nums.length;
				    int currentMaxAvailableIndex = 0;
				    for (int i = 0; i < n; i++) {
					    		    if (i <= currentMaxAvailableIndex) {
						    		    		    currentMaxAvailableIndex = Math.max(currentMaxAvailableIndex, i + nums[i]);
		    		    		    				if (currentMaxAvailableIndex >= n - 1) {
							    		    		    		    return true;
		    		    		    				}
		    		    			}
		    		}
		    		return false;
	}
```

# 相关题目

