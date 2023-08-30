---
title: 有序数组的平方—LeetCode977
date: 2019-01-09 13:52:40
tags: 
	- leetcode
	- java

---

# 题目描述

>给定一个按非递减顺序排序的整数数组 A，返回每个数字的平方组成的新数组，要求也按非递减顺序排序。 
>
>示例 1：
>
>输入：[-4,-1,0,3,10]
>输出：[0,1,9,16,100]
>示例 2：
>
>输入：[-7,-3,2,3,11]
>输出：[4,9,9,49,121]
>
>
>提示：
>
>1 <= A.length <= 10000
>-10000 <= A[i] <= 10000
>A 已按非递减顺序排序。

<!--more-->

# 解题思路

## 排序

我们先将每个元素平方后放到原来的位置，然后再对数组进行排序

```java
public int[] sortedSquares(int[] A) {
  for (int i : A) {
    A[i] *= A[i];
  }
  Arrays.sort(A);
  return A;
}
```

## 双指针

平方后对于正负数就没有区别了，所以我们先找到正负数的边间，然后向两边走。

**代码实现：**

```java
public int[] sortedSquaresDouble(int[] A) {
  //先找到正数负数的分解
  int length = A.length;
  int j = 0;
  while (j < length && A[j] < 0) {
    j++;
  }
  //负数最后的下标
  int i = j - 1;
  int[] res = new int[length];
  int index = 0;
  while (i >= 0 && j < length) {
    if (A[i] * A[i] < A[j] * A[j]) {
      res[index++] = A[i] * A[i];
      i--;
    } else {
      res[index++] = A[j] * A[j];
      j++;
    }
  }
  //再将两边剩余的部分添加到数组中
  while (i >= 0) {
    res[index++] = A[i] * A[i];
    i--;
  }
  while (j < length) {
    res[index++] = A[j] * A[j];
    j++;
  }
  return res;
}
```

