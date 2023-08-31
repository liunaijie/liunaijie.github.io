---
title: 两数之和—LeetCode1
date: 2018-08-25 20:52:40
tags: 
- 算法与数据结构
- Leetcode
---

# 题目描述

> 给定一个整数数组 nums 和一个目标值 target，请你在该数组中找出和为目标值的那 两个 整数，并返回他们的数组下标。
>
> 你可以假设每种输入只会对应一个答案。但是，你不能重复利用这个数组中同样的元素。
>
> 示例:
>
> 给定 nums = \[2, 7, 11, 15], target = 9
>
> 因为 nums\[0] + nums\[1] = 2 + 7 = 9
> 所以返回 \[0, 1]

<!--more-->

# 解题思路

## 暴力破解

这个题是第一个题，我刚开始的时候什么都没想，直接上来就用了暴力破解。

遍历每个元素`x`，然后查找是否存在一个值能和`x`相加得到`target`。

**代码实现：**

```java
public int[] twoSum(int[] nums, int target) {
  for(int i=0;i<nums.length;i++){
    for(int j=i+1;j<nums.length;j++){
      if(nums[i]+nums[j]==target){
        return new int[]{i,j};
      }
    }
  }
  return new int[]{-1,-1};
}
```

空间复杂度为：O(1)，时间复杂度为O(n^2^)。

## 哈希表

为了降低时间复杂度，我们可以使用哈希表来实现，利用哈希表来存储元素，由于哈希查找的效率为O(1)，所以能降低时间复杂度。

代码实现：

```java
public int[] twoSumHash(int[] nums, int target) {
  Map<Integer, Integer> map = new HashMap<>(nums.length);
  for (int i = 0; i < nums.length; i++) {
    int y = target - nums[i];
    if (map.containsKey(y)) {
      return new int[]{i, map.get(y)};
    }
    map.put(nums[i], i);
  }
  return new int[]{-1, -1};
}
```

使用了java中的hashmap。key存储数组的元素，value存储下标。

时间复杂度为O(n)，空间复杂度为O(n)

# 相关题目

- [三数之和](https://www.liunaijie.top/2019/10/25/LeetCode/三数之和-LeetCode15/)