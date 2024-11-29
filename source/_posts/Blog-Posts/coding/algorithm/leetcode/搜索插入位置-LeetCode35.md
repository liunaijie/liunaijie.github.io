---
title: 搜索插入位置-LeetCode35
date: 2019-03-06 19:59:48
tags:
  - 算法与数据结构/Leetcode
related-project: "[[Blog-Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

> 给定一个排序数组和一个目标值，在数组中找到目标值，并返回其索引。如果目标值不存在于数组中，返回它将会被按顺序插入的位置。
>
> 你可以假设数组中无重复元素。
>
> 示例 1:
>
> 输入: \[1,3,5,6], 5
> 输出: 2
> 示例 2:
>
> 输入: \[1,3,5,6], 2
> 输出: 1
> 示例 3:
>
> 输入: \[1,3,5,6], 7
> 输出: 4
> 示例 4:
>
> 输入: \[1,3,5,6], 0
> 输出: 0

<!--more-->

# 解题思路

## 遍历

由于数组已经排序，可以从头开始向后查找，当target与数组内某个元素相等时，返回下标，当target比某个元素大时，返回下标。

```java
public int searchInsertSearch(int[] nums, int target) {
  int result = nums.length;
  for (int i = 0; i < nums.length; i++) {
    if (nums[i] == target) {
      return i;
    }
    if (target < nums[i]) {
      return i;
    }
  }
  return result;
}
```



## 二分查找

由于已经排序了，先将中间值与目标值对比，然后再分区间对比

```java
public int searchInsertBinarySearch(int[] nums, int target) {
  int low = 0;
  int high = nums.length - 1;
  while (low <= high) {
    int mid = low + ((high - low) >> 1);
    if (nums[mid] >= target) {
      //当中间值大于等于目标值时
      //如果已经到头了，就不再向前查找。或者前一个元素比目标值小也直接返回
      if ((mid == 0) || (nums[mid - 1] < target)) {
        return mid;
      } else {
        //否则再向前一位
        high = mid - 1;
      }
    } else {
      low = mid + 1;
    }
  }
  return nums.length;
}
```

