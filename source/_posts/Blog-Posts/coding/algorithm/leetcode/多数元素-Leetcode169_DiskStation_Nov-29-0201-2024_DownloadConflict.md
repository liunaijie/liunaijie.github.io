---
title: 多数元素-LeetCode169
date: 2020-03-29 14:03:52
tags:
  - 算法与数据结构/Leetcode
related-project: "[[Blog Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

> 给定一个大小为 n 的数组，找到其中的多数元素。多数元素是指在数组中出现次数大于 ⌊ n/2 ⌋ 的元素。
>
> 你可以假设数组是非空的，并且给定的数组总是存在多数元素。
>
> 示例 1:
>
> 输入: \[3,2,3]
> 输出: 3
> 示例 2:
>
> 输入: \[2,2,1,1,1,2,2]
> 输出: 2

<!--more-->

# 解题思路

这个题目要求我们找这个数组里面数量最多的元素，并且这个元素出现的次数大于 `n/2`。

1. map

	遍历数组，key相同的数量加一，然后判断数量如果大于`n/2`则找到答案

2. 排序

	将数组排序后，由于多数元素出现次数大于`n/2`，所以在`n/2`上的元素就是我们要找的元素

# 代码实现

```java
public int majorityElement(int[] nums) {
  int n = nums.length;
  Map<Integer, Integer> map = new HashMap<>(n);
  for (int num : nums) {
    if (map.containsKey(num)) {
      int count = map.get(num);
      if ((count + 1) > n / 2) {
        return num;
      }
      map.put(num, count + 1);
    } else {
      map.put(num, 1);
    }
  }
  return nums[0];
}

/**
	 * 排序后 在n/2位的肯定是多数元素
	 * @param nums
	 * @return
	 */
public int majorityElementSort(int[] nums) {
  Arrays.sort(nums);
  return nums[nums.length / 2];
}
```

