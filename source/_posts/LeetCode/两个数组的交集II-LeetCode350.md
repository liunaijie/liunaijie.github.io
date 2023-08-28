---
title: 两个数组的交集II-LeetCode350
date: 2019-08-07 20:17:30
categories: 
	- [code, leetcode]
toc: true
tags: 
	- leetcode
	- java
---

# 题目描述

> 给定两个数组，编写一个函数来计算它们的交集。
>
> **示例 1:**
>
> ```
> 输入: nums1 = [1,2,2,1], nums2 = [2,2]
> 输出: [2,2]
> ```
>
> **示例 2:**
>
> ```
> 输入: nums1 = [4,9,5], nums2 = [9,4,9,8,4]
> 输出: [4,9]
> ```
>
> **说明：**
>
> - 输出结果中每个元素出现的次数，应与元素在两个数组中出现的次数一致。
> - 我们可以不考虑输出结果的顺序。
>
> ***\*进阶:\****
>
> - 如果给定的数组已经排好序呢？你将如何优化你的算法？
> - 如果 *nums1* 的大小比 *nums2* 小很多，哪种方法更优？
> - 如果 *nums2* 的元素存储在磁盘上，磁盘内存是有限的，并且你不能一次加载所有的元素到内存中，你该怎么办？

这个题目的T349的进阶版。

<!--more-->

# 解题思路

这个题目有一个不同点是它的结果是交集并且包含重复元素的，在349题中，包含的重复元素在结果中出现一次即可。在这里需要将重复元素表示出来。

当遇到重复元素时，应该要进行计数，在对第二个数组进行遍历时，如果遇到重复元素并且计数大于0再进行添加。来看一下具体的代码

```java
public int[] intersect(int[] nums1, int[] nums2) {
  Map<Integer, Integer> map = new HashMap<Integer, Integer>();
  //遍历，如果遇到重复的数量加一
  for (int item : nums2) {
    if (map.containsKey(item)) {
      map.put(item, map.get(item) + 1);
    } else {
      map.put(item, 1);
    }
  }
  List<Integer> list = new ArrayList<Integer>();
  for (int item : nums1) {
    //当有交集时，数量减一，下次再遇到这个元素先判断数量是否大于0
    if (map.containsKey(item) && map.get(item) > 0) {
      list.add(item);
      map.put(item, map.get(item) - 1);
    }
  }
  //转换为数组
  int[] result = new int[list.size()];
  for (int i = 0; i < list.size(); i++) {
    result[i] = list.get(i);
  }
  return result;
}
```



# 相关题目

- [两个数组的交集](https://www.liunaijie.top)

