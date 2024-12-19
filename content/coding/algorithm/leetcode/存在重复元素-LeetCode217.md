---
title: 存在重复元素-LeetCode217
date: 2019-03-10
categories:
  - notes
tags:
  - LeetCode
related-project: "[[Blog-Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

> 给定一个整数数组，判断是否存在重复元素。
>
> 如果任何值在数组中出现至少两次，函数返回 true。如果数组中每个元素都不相同，则返回 false。
>
> 示例 1:
>
> 输入: \[1,2,3,1]
> 输出: true
> 示例 2:
>
> 输入: \[1,2,3,4]
> 输出: false
> 示例 3:
>
> 输入: \[1,1,1,3,3,4,3,2,4,2]
> 输出: true

判断数组中是否有元素存在重复值。

<!--more-->

# 解题思路

## 遍历查找

我们可以直接使用最粗暴的双重循环进行查找。拿一个值与后面所有的元素比较，如果都不相等则拿第二个值与后面的所有元素比较。

**代码实现如下：**

```java
public boolean containsDuplicate(int[] nums) {
  for (int i = 0; i < nums.length - 1; i++) {
    for (int j = i+1; j < nums.length; j++) {
      if (nums[i] == nums[j]) {
        return true;
      }
    }
  }
  return false;
}
```

我们来分析一下这个实现的时间和空间复杂度：

- 空间复杂度

	由于没有用到额外的空间，所以空间复杂度为O(1)

- 时间复杂度

由于用到了双重for循环，它的运行次数约为n^2^。所以它的时间复杂度也约为O(n^2^)。

如果将此答案放到LeetCode上跑，则会超出时间。

## 排序后查找

我们如果先进行排序，则相同的元素应该前后相邻。

而排序我们可以使用快速排序达到O(nlogn)的复杂度，然后再进行数组查找，这个的复杂度为O(n)。

**代码实现如下：**

```java
public boolean containsDuplicateSort(int[] nums) {
  Arrays.sort(nums);
  for (int i = 0; i < nums.length - 1; i++) {
    if (nums[i] == nums[i + 1]) {
      return true;
    }
  }
  return false;
}
```

这里直接调用了java的api来进行排序，后面就是对数组的查找，我们只需要遍历一次，比较前后两个位置元素是否相同即可。

复杂度分析：

- 空间复杂度

	没有用到额外的空间，所以空间复杂度为O(1)

- 时间复杂度

	时间复杂度为排序的复杂度O(nlogn)+O(n)。

## 哈希表

我们将元素做哈希运算，然后进行存储，对新元素与存储的哈希值做对比，如果哈希值不存在则继续存储进行下一个查找。当存在时比较具体值是否相同，如果相同则返回结果。

**代码实现:**

```java
public boolean containsDuplicateHash(int[] nums) {
  Set<Integer> set = new HashSet<>(nums.length);
  for (int num : nums) {
    if (set.contains(num)) {
      return true;
    } else {
      set.add(num);
    }
  }
  return false;
}
```

这里使用了java中的HashSet。

复杂度分析：

- 空间复杂度：

	由于使用了set来存储数组，所以空间复杂度为O(n)

- 时间复杂度：

	 从上面代码可以看出，我们只对数组遍历了一次，时间复杂度也就是O(n)