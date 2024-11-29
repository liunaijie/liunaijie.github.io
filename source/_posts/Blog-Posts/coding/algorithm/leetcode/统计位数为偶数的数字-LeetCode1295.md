---
title: 统计位数为偶数的数字—LeetCode1295
date: 2020-02-21 21:13:30
tags:
  - 算法与数据结构/Leetcode
related-project: "[[Blog-Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

> 给你一个整数数组 nums，请你返回其中位数为 偶数 的数字的个数。
>
>  示例 1：
>
> 输入：nums = \[12,345,2,6,7896]
> 输出：2
> 解释：
> 12 是 2 位数字（位数为偶数） 
> 345 是 3 位数字（位数为奇数）  
> 2 是 1 位数字（位数为奇数） 
> 6 是 1 位数字 位数为奇数） 
> 7896 是 4 位数字（位数为偶数）  
> 因此只有 12 和 7896 是位数为偶数的数字
> 示例 2：
>
> 输入：nums = \[555,901,482,1771]
> 输出：1 
> 解释： 
> 只有 1771 是位数为偶数的数字。
>
>
> 提示：
>
> 1 <= nums.length <= 500
> 1 <= nums\[i] <= 10^5

<!--more-->

# 解题思路

这里使用了一个取巧的办法，将它转换为字符串，然后判断长度是否为偶数

代码实现：

```java
public int findNumbers(int[] nums) {
  int count = 0;
  for (int num : nums) {
    if ((String.valueOf(num).length() & 1) == 0) {
      count++;
    }
  }
  return count;
}
```

