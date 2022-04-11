---
title: 把数组排成最小的数-剑指Offer LeetCode45
date: 2022-03-23 19:55:48
categories: "leetcode"
toc: true
tags: 
	- leetcode
	- java
---

# 题目描述

链接: https://leetcode-cn.com/problems/ba-shu-zu-pai-cheng-zui-xiao-de-shu-lcof/

输入一个非负整数数组, 把数组里所有数字拼接起来排出一个数, 打印能拼接出的数字中最小的一个.

> 示例1:
>
> 输入: [10, 2]
>
> 输出: "102". 两个数字的排列可能为102, 210. 由于102小, 所以结果为102.
>
> 示例2:
>
> 输入: [3, 30, 34, 5, 9]
>
> 输出: ”3033459“

<!--more-->

# 解题思路

我们以两个数字转化为的字符串(x, y)为例

- 当 x + y > y + x 时, x应该大于y, 即x应该在y的后面
- 当 x  + y < y + x时,  y应该大于x, 即y应该在x的后面

可以看出, 这个问题可以转化为自定义排序的问题.  再来验证一下是否对多个值通用:

输入数组: [3, 30, 34, 5 ,9]. 

首先判断3, 30, 由于 330 > 303, 所以30在前面, 结果为[30, 3, 34, 5 ,9]

然后判断3, 34, 由于334< 343, 所以3在前面, 结果为[30, 3, 34, 5 ,9]

判断34, 5, 由于345< 534, 所以34在前面, 结果为[30, 3, 34, 5 ,9]

最后判断5, 9. 由于59< 95, 所以5在前面, 结果为[30, 3, 34, 5 ,9]. 与答案一致.

## 代码实现:

```java
	public String minNumber(int[] nums) {
	    				String[] strs = new String[nums.length];
	    				for (int i = 0; i < nums.length; i++) {
	    						    		strs[i] = String.valueOf(nums[i]);
			    		}
			    		quickSort(strs, 0, strs.length - 1);
			    		StringBuilder res = new StringBuilder();
			    		for (String s : strs) {
				    			    		res.append(s);
	    		}
			    		return res.toString();
	}

// 使用快排
	private void quickSort(String[] strs, int left, int right) {
	    		if (left >= right) return;
			    		int i = left, j = right;
			    		String tmp = strs[i];
			    		while (i < j) {
				    		// 如果 j + left > left + j, 那么left就应该做左侧, j在右侧。所以j--, 比较下一个值
				    		while ((strs[j] + strs[left]).compareTo(strs[left] + strs[j]) >= 0 && i < j) {
	    							    		j--;
	    					}
				    		// 如果 i + left < left + i, 那么i应该在左侧, left在右侧。所以i++, 比较下一个值
				    		while ((strs[i] + strs[left]).compareTo(strs[left] + strs[i]) <= 0 && i < j) {
					    			    		i++;
	    					}
				    		// 找到两个要交换的值，将其交换
				    		tmp = strs[i];
				    		strs[i] = strs[j];
				    		strs[j] = tmp;
	    				}
			    		strs[i] = strs[left];
			    		strs[left] = tmp;
	    				quickSort(strs, left, i - 1);
	    				quickSort(strs, i + 1, right);
	}
```



