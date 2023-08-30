---
title: 按奇偶排序数组-LeetCode905
date: 2019-01-02 10:45:28
tags: 
	- leetcode
	- java
---

# 题目描述

> 给定一个非负整数数组 A，返回一个数组，在该数组中， A 的所有偶数元素之后跟着所有奇数元素。
>
> 你可以返回满足此条件的任何数组作为答案。
>
> 示例：
>
> 输入：[3,1,2,4]
> 输出：[2,4,3,1]
> 输出 [4,2,3,1]，[2,4,1,3] 和 [4,2,1,3] 也会被接受。
>
>
> 提示：
>
> 1 <= A.length <= 5000
> 0 <= A[i] <= 5000

<!--more-->

# 解题思路

## 两遍扫描

可以对数组遍历两遍，第一遍将偶数放到新创建的数组中，第二遍将奇数放到新创建的数组中

**代码实现:**

```java
public int[] sortArrayByParityArray(int[] A) {
  int[] result = new int[A.length];
  //先放偶数
  int index = 0;
  for (int i = 0; i < A.length; i++) {
    if ((A[i] & 1) == 0) {
      result[index++] = A[i];
    }
  }
  //再放奇数
  for (int i = 0; i < A.length; i++) {
    if ((A[i] & 1) == 1) {
      result[index++] = A[i];
    }
  }
  return result;
}
```

## 双指针法

它对于顺序没有要求，只要将所以偶数放到奇数前面就可以，我们利用两个指针分别从前后向中间移动。

`i`从左边向中间移动，时刻保持`i`左边的都是偶数，`i`行进过程中遇到偶数继续前进，遇到奇数先暂停。

`j`从右边向中间移动，遇到奇数继续前进，遇到偶数暂停。

当`i`遇到奇数，`j`遇到偶数时两者交换，再进行前进。

**代码实现**：

```java
public int[] sortArrayByParity(int[] A) {
  int i = 0, j = A.length - 1;
  while (i < j) {
    //i遇到偶数继续前进
    if (A[i] % 2 == 0) {
      i++;
    }
    //j遇到奇数继续前进
    if (A[j] % 2 == 1) {
      j--;
    }
    //当i遇到奇数 1 > j遇到偶数0 时交换
    if (A[i] % 2 > A[j] % 2) {
      int tmp = A[i];
      A[i] = A[j];
      A[j] = tmp;
    }
  }
  return A;
}
```

