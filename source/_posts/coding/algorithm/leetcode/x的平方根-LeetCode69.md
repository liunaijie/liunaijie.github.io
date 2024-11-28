---
title: x的平方根—LeetCode69
date: 2019-01-05 21:13:30
tags:
  - 算法与数据结构
  - 算法与数据结构/Leetcode
related-project: "[[Blog Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

> 实现 int sqrt(int x) 函数。
>
> 计算并返回 x 的平方根，其中 x 是非负整数。
>
> 由于返回类型是整数，结果只保留整数的部分，小数部分将被舍去。
>
> 示例 1:
>
> 输入: 4
> 输出: 2
> 示例 2:
>
> 输入: 8
> 输出: 2
> 说明: 8 的平方根是 2.82842..., 
>      由于返回类型是整数，小数部分将被舍去。

<!--more-->

# 解题思路

## 二分查找

这个题目可以用二分查找来做，给定`x`,求平方根，当`x>=2`时，`x`的平方根一定小于`x/2`且大于0。我们可以不断的逼近x，取中间值然后进行平方，与`x`比较，如果平方值比`x`小，则向中间值后面进行查找，否则在前面进行查找。

**代码实现：**

```java
public int mySqrt(int x) {
  if (x < 2) {
    return x;
  }
  int left = 2, right = x / 2;
  while (left <= right) {
    int mid = left + (right - left) / 2;
    //为了避免溢出，要转换为long类型，不然结果会有问题
    long num = (long) mid * mid;
    if (num > x) {
      right = mid - 1;
    } else if (num < x) {
      left = mid + 1;
    } else {
      return mid;
    }
  }
  return right;
}
```

