---
title: 三数之和—LeetCode15
date: 2019-10-25 21:36:20
tags:
  - 算法与数据结构/Leetcode
related-project: "[[Blog-Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

> 给你一个包含 n 个整数的数组 nums，判断 nums 中是否存在三个元素 a，b，c ，使得 a + b + c = 0 ？
>
> 请你找出所有满足条件且不重复的三元组。
>
> 注意：**答案中不可以包含重复的三元组**。
>
> 示例：
>
> 给定数组 nums = \[-1, 0, 1, 2, -1, -4]，
>
> 满足要求的三元组集合为：
> \[
>   \[-1, 0, 1],
>   \[-1, -1, 2]
> ]

这个题目中有一个条件，答案中不可以包含重复的三元组，即给定的数组中会有重复值，所以答案可能会存在重复答案，当答案存在时，不在添加到答案中

<!--more-->

# 解题思路

## 暴力

根据之前做过的[两数之和](https://www.liunaijie.top/2018/08/25/LeetCode/两数之和-LeetCode1)，这次的target变成了固定值0。

```java
public static List<List<Integer>> threeSum(int[] nums) {
  if (nums == null || nums.length <= 2) {
    return Collections.emptyList();
  }
  Set<List<Integer>> result = new LinkedHashSet<>();
  for (int i = 0; i < nums.length; i++) {
    for (int j = i + 1; j < nums.length; j++) {
      for (int k = j + 1; k < nums.length; k++) {
        if (nums[i] + nums[j] + nums[k] == 0) {
          List<Integer> value = Arrays.asList(nums[i], nums[j], nums[k]);
          value.sort(Comparator.naturalOrder());
          result.add(value);
        }
      }
    }
  }
  return new ArrayList<>(result);
}
```

在第11行中，在添加前先进行了排序，因为存在重复值，并且使用了set进行存储，就是为了去重，如果不排序直接添加，不同顺序相同内容在set中会被认为是不同内容，会添加进去，而我们不需要添加进去，所以先排序。并且这里只排序了长度为3的内容，比在开始对num数组排序的效率要高。

这个方法在LeetCode上面跑回超出时间限制。我们来分析一下它的复杂度

- 时间复杂度

	排序，快排的复杂度为O(nlogn)
	
	然后用到了三重循环，这个复杂度近似于O(n^3^)

- 空间复杂度

	由于这个问题本身就是要求返回集合类，所以肯定要占用额外的空间，使用了set来进行存储，所以空间复杂度为O(n)

## 哈希表

在两数相加中，我们还有一种解法，用到了哈希表，在这个题目中也可以用到

**代码实现：**

```java
public List<List<Integer>> threeSumHash(int[] nums) {
  if (nums == null || nums.length <= 2) {
    return Collections.emptyList();
  }
  Set<List<Integer>> result = new HashSet<>();
  for (int i = 0; i < nums.length; i++) {
    int target = -nums[i];
    Map<Integer, Integer> map = new HashMap<>();
    for (int j = i + 1; j < nums.length; j++) {
      int y = target - nums[j];
      if (map.containsKey(y)) {
        List<Integer> list = Arrays.asList(nums[i], nums[j], y);
        list.sort(Comparator.naturalOrder());
        result.add(list);
      } else {
        map.put(nums[j], j);
      }
    }
  }
  return new ArrayList<>(result);
}
```

复杂度分析：

- 时间复杂度：

	两次遍历，时间复杂度为O(n^2^)。在第二层循环中用到了排序，由于只有三个元素的排序，所以每次可以忽略

- 空间复杂度

	使用了map作为额外的存储，所以空间复杂度为O(1)

## 双指针法

这个方法首先需要排序，O(nlogn)

固定最小的数字指针`k`，双指针`i`,`j`分别设置在数组左边和右边，通过两个指针交替向中间移动，记录对于固定`k`是的所有满足条件的结果，然后再向右移动`k`。

1. 当`nums[k]>0`时不再需要向下查找，因为后面三个正数相加肯定不为0。
2. 当`nums[k]==nums[k-1]`时，跳过这个元素，因为在`nums[k-1]`中已经将结果添加到结果集中了
3. `i`,`j`分别在数组的两端，当`i<j`时，计算`s=nums[k]+nums[i]+nums[j]`
	- 当`s<0`时，结果小了，需要添加一个大数值，所以左边的`i`向右移动，`i++`，同时要跳过重复的值
	- 当`s>0`时，结果大了，需要添加一个小数值，所以右边的`j`向左移动,`j--`，同时跳过重复的值。
	- 当`s=0`时，找到结果，将`k.i,j`添加到结果中，然后继续操作`i,j`进行查找

**代码实现：**

```java
public List<List<Integer>> threeSumDouble(int[] nums) {
  Arrays.sort(nums);
  List<List<Integer>> result = new ArrayList<>();
  for (int k = 0; k < nums.length; k++) {
    if (nums[k] > 0) {
      break;
    }
    if (k > 0 && nums[k] == nums[k - 1]) {
      continue;
    }
    int i = k + 1, j = nums.length - 1;
    while (i < j) {
      int sum = nums[k] + nums[i] + nums[j];
      if (sum < 0) {
        while (i < j && nums[i] == nums[++i]) ;
      } else if (sum > 0) {
        while (i < j && nums[j] == nums[--j]) ;
      } else {
        result.add(new ArrayList<>(Arrays.asList(nums[k], nums[i], nums[j])));
        while (i < j && nums[i] == nums[++i]) ;
        while (i < j && nums[j] == nums[--j]) ;
      }
    }
  }
  return result;
}
```

复杂度分析：

- 时间复杂度

	排序：O(nlogn)
	
	双重循环：O(n^2^)

- 空间复杂度

	没有用到额外的空间，所以空间复杂度为O(1)

# 相关题目

- [两数之和]([https://www.liunaijie.top/2018/08/25/LeetCode/%E4%B8%A4%E6%95%B0%E4%B9%8B%E5%92%8C-LeetCode1/](https://www.liunaijie.top/2018/08/25/LeetCode/两数之和-LeetCode1/))