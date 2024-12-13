---
title: 重复N次的元素-LeetCode961
date: 2019-08-08
categories:
  - notes
tags:
  - LeetCode
related-project: "[[Blog-Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

> 在大小为 2N 的数组 A 中有 N+1 个不同的元素，其中有一个元素重复了 N 次。
>
> 返回重复了 N 次的那个元素。
>
>  示例 1：
>
> 输入：\[1,2,3,3]
> 输出：3
> 示例 2：
>
> 输入：\[2,1,2,5,3,2]
> 输出：2
> 示例 3：
>
> 输入：\[5,1,5,2,5,3,5,4]
> 输出：5
>
>
> 提示：
>
> 4 <= A.length <= 10000
> 0 <= A\[i] < 10000
> A.length 为偶数

大小为2N的数字中有个N+1个元素，其中有个元素重复了N次，这也说明了除了这个元素其他元素都没有重复，也可以理解成查找重复的元素

<!--more-->

# 解题思路

## 排序后遍历

因为只有一个重复的元素，那么排序后肯定是相邻的。

排好序后，只要有两个相邻的元素是一样的，那么就是答案

**代码实现：**

```java
public int repeatedNTimes(int[] A) {
  Arrays.sort(A);
  for (int i = 0; i < A.length - 1; i++) {
    if (A[i] == A[i + 1]) {
      return A[i];
    }
  }
  return 0;
}
```

## 哈希表

这个题也相当于查找重复元素，这个时候肯定可以利用哈希表来实现

**代码实现：**

```java
public int repeatedNTimesHash(int[] A) {
  Set<Integer> set = new HashSet<>(A.length);
  for (int i : A) {
    if (set.contains(i)) {
      return i;
    }
    set.add(i);
  }
  return -1;
}
```

