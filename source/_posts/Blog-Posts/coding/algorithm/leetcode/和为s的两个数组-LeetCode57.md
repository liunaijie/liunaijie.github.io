---
title: 和为s的两个数组-LeetCode57
date: 2022-04-13 09:55:53
tags:
  - 算法与数据结构/Leetcode
related-project: "[[Blog-Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

链接: https://leetcode-cn.com/problems/he-wei-sde-liang-ge-shu-zi-lcof/

输入一个递增排序的数组和一个数字s, 在数组中查找两个数, 使得它们的和正好是s, 如果有多对数字的和都等于s, 则输出任意一对即可.
示例1:
输入：nums = \[2,7,11,15], target = 9
输出：\[2,7] 或者 \[7,2]

示例2: 
输入：nums = \[10,26,30,31,47,60], target = 40
输出：\[10,30] 或者 \[30,10]

<!--more-->

# 解题思路

这个题目是LeetCode第一题两数之和类型, 都是从数组中找到两个数, 相加之和为s. 

但是有区别的一点是, 这里的数组是已经升序排序好的. 所以我们可以利用升序的特性来进行优化.

## 双指针

我们将两个指针分别置为头尾, 然后判断这两个数之和与S的关系.

如果和大于S, 则尾指针向前移动一位

如果和小于S, 则头指针向后移动一位.

当和等于S时, 找到题解, 返回.

### 代码实现

```java
	public int[] twoSum(int[] nums, int target) {
    		int x = 0, y = nums.length - 1;
    		while (x < y) {
			        int temp = nums[x] + nums[y];
			        if (temp < target) {
            				x++;
        			} else if (temp > target) {
				            y--;
        			} else {
            				return new int[]{nums[x], nums[y]};
        			}
		    }
		    return null;
	}
```

# 相关题目

#算法与数据结构/Leetcode