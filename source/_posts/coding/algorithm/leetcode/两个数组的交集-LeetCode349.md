---
title: 有效的括号—LeetCode20
date: 2019-08-07 20:17:30
tags:
  - 算法与数据结构/Leetcode
related-project: "[[Blog Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

> 给定两个数组，编写一个函数来计算它们的交集。
>
> **示例 1:**
>
> ```
> 输入: nums1 = \[1,2,2,1], nums2 = \[2,2]
> 输出: \[2]
> ```
>
> **示例 2:**
>
> ```
> 输入: nums1 = \[4,9,5], nums2 = \[9,4,9,8,4]
> 输出: \[9,4]
> ```
>
> **说明:**
>
> - 输出结果中的每个元素一定是唯一的。
> - 我们可以不考虑输出结果的顺序。

<!--more-->

# 解题思路

求两个数组中的交集，我们先将`nums1`放到`set1`中，然后对`nums2`遍历，如果存在于`set1`中则将其添加到`set2`中，最后需要将`set`转换为数组返回。

```java
public int[] intersection(int[] nums1, int[] nums2) {
  Set<Integer> set1 = new HashSet<Integer>();
  for (int item : nums1) {
    set1.add(item);
  }
  Set<Integer> set2 = new HashSet<Integer>();
  for (int item : nums2) {
    if (set1.contains(item)) {
      set2.add(item);
    }
  }
  int[] result = new int[set2.size()];
  int index = 0;
  for (Integer integer : set2) {
    result[index++] = integer;
  }
  return result;
}
```

# 相关题目

- [两个数组的交集II](https://www.liunaijie.top/)