---
title: 打印从1到最大的n位数—LeetCodeM17
date: 2019-02-21 13:45:16
tags: 
- 算法与数据结构
- Leetcode
---

# 题目描述

> 输入数字 `n`，按顺序打印出从 1 到最大的 n 位十进制数。比如输入 3，则打印出 1、2、3 一直到最大的 3 位数 999。
>
> **示例 1:**
>
> ```
> 输入: n = 1
> 输出: \[1,2,3,4,5,6,7,8,9] 
> ```
>
> 说明：
>
> - 用返回一个整数列表来代替打印
> - n 为正整数

首先要获取最大值，然后遍历添加到数组中，而通过位数获取最大值可以通过`10^n^`来获取。

<!--more-->

# 代码实现

```java
public int[] printNumbers(int n) {
  int max = (int)Math.pow(10,n);
  int[] result = new int[max-1];
  for(int i=0;i<max-1;i++){
    result[i]=i+1;
  }
  return result;
}
```

