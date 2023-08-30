---
title: 山脉数组的峰顶索引-LeetCode852
date: 2019-07-18 23:01:56
tags: 
	- leetcode
	- java
---

# 题目描述

> 我们把符合下列属性的数组 A 称作山脉：
>
> A.length >= 3
> 存在 0 < i < A.length - 1 使得A\[0] < A\[1] < ... A\[i-1] < A\[i] > A\[i+1] > ... > A\[A.length - 1]
> 给定一个确定为山脉的数组，返回任何满足 A\[0] < A\[1] < ... A\[i-1] < A\[i] > A\[i+1] > ... > A\[A.length - 1] 的 i 的值。 
>
> 示例 1：
>
> 输入：\[0,1,0]
> 输出：1
> 示例 2：
>
> 输入：\[0,2,1,0]
> 输出：1
>
>
> 提示：
>
> 3 <= A.length <= 10000
> 0 <= A\[i] <= 10^6
> A 是如上定义的山脉

其实这就是一个寻找数组最大值的问题

<!--more-->

# 解题思路

## 扫描

查找数组的最大值，可以从前向后遍历查找即可

代码实现：

```java
public int peakIndexInMountainArray(int[] A) {
  int i = 0;
  while (A[i] < A[i + 1]) {
    i++;
  }
  return i;
}
```



## 二分查找

从左向右查找，顺序为递增

从右向左查找，顺序为递增

当两边相遇时就遇到了最大值。

```java
public int peakIndexInMountainArrayDouble(int[] A) {
  int left = 0, right = A.length - 1;
  while (left < right) {
    int mid = left + (right - left) / 2;
    if (A[mid] < A[mid + 1]) {
      left = mid + 1;
    } else {
      right = mid - 1;
    }
  }
  return left;
}
```

