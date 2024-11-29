---
title: 只出现一次的数字—LeetCode136
date: 2019-04-11 13:52:40
tags:
  - 算法与数据结构
  - 算法与数据结构/Leetcode
related-project: "[[Blog-Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述：

给定一个**非空**整数数组，除了某个元素只出现一次以外，其余每个元素均出现两次。找出那个只出现了一次的元素。

示例1：

```
输入：[2,2,1]
输出：1
```

示例2：

```
输入：[4,1,2,1,2]
输出：4
```

<!-- more -->

# 解题思路：

刚开始是这样想的，先进行排序，然后我们两个一组，如果这两个数字一样，则开始下一组。如果不一样，那么第一个就是我们要找的元素。我们这组元素是奇数个，所以如果前面的都是相同的，那最后剩下的这个元素就是我们要找的元素。

# 代码：

```java
public int singleNumber(int[] nums) {
       //排序
		Arrays.sort(nums);
    	// 默认第一个元素
		int result = nums[0];
		int count = nums.length;
    	// 两个一组
		for (int i = 0; i < count; i += 2) {
			int first = nums[i];
            //如果是最后一个，那么直接返回
			if (i == count - 1) {
				return first;
			}
			int second = nums[i + 1];
            // 如果两个数字不一样，返回第一个数字
			if (first != second) {
				return first;
			}
		}
		return result;
	}
```

提交后发现我这个代码运行需要9ms，然后看了前面的代码，发现了一个很好的点：利用异或操作。(两个数字异或，相同得0，不同得1)。

代码如下：

```java
public int singleNumber(int[] nums) {
        //使用异或运算似的出现偶数次数的数组元素消除。
        int result=nums[0];
        for(int i=0;i<nums.length;i++){
            result=result^nums[i];
        }
        return result;
    }
```

是不是很简洁，而且速度也比我的快(1ms)~~~