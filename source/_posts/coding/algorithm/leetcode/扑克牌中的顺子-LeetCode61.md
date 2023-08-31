---
title: 扑克牌中的顺子-剑指Offer LeetCode61
date: 2022-03-23 20:14:19
tags: 
- 算法与数据结构
- Leetcode
---

# 题目描述

链接: https://leetcode-cn.com/problems/bu-ke-pai-zhong-de-shun-zi-lcof/

从若干幅扑克牌中随机抽5张牌, 判断是不是一个顺子, 即这五张牌是不是连续的. 2~10为数字本身, A为1, J为11, Q为12, K为13. **大小王为0, 并且可以看出任意数字**

> 示例1:
>
> 输入: \[1,2,3,4,5]
>
> 输出:  true
>
> 示例2:
>
> 输入: \[0,0,1,2,5]
>
> 输出: true. 由于两个0可以代替为3和4, 所以可以构成顺子

<!--more-->

# 解题思路

给定5张牌, 判断这5张牌是不是顺子, 那么这里除了大小王(0)之外不能有重复. 并且去掉大小王之后max-min应该小于5. 这样才可以构成顺子

## 代码实现:

```java
		public boolean isStraight(int[] nums) {
			    // 首先对数组排序
			    Arrays.sort(nums);
			    		int index = 0;
					    for (int i = 0; i < nums.length - 1; i++) {
					    			    // 大小王则跳过
						    			    if (nums[i] == 0) {
			    			    			    				index++;
					    			    // 如果前后两个重复则可以直接判断不是顺子
			    						    } else if (nums[i] == nums[i + 1]) {
			    							    			    return false;
			    						    }
			    		}
				    // 由于已经排序, 所以最后一个值是最大值
			    		return nums[4] - nums[index] < 5;
	}
```



