---
title: 旋转数组—LeetCode189
date: 2018-08-29 20:28:32
tags:
  - 算法与数据结构/Leetcode
related-project: "[[Blog-Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

>给定一个数组，将数组中的元素向右移动 k 个位置，其中 k 是非负数。
>
>示例 1:
>
>输入: \[1,2,3,4,5,6,7] 和 k = 3
>输出: \[5,6,7,1,2,3,4]
>解释:
>向右旋转 1 步: \[7,1,2,3,4,5,6]
>向右旋转 2 步: \[6,7,1,2,3,4,5]
>向右旋转 3 步: \[5,6,7,1,2,3,4]
>	示例 2:
>
>输入: \[-1,-100,3,99] 和 k = 2
>输出: \[3,99,-1,-100]
>解释: 
>向右旋转 1 步: \[99,-1,-100,3]
>向右旋转 2 步: \[3,99,-1,-100]
>说明:
>
>尽可能想出更多的解决方案，至少有三种不同的方法可以解决这个问题。
>要求使用空间复杂度为 O(1) 的 原地 算法。

首先我们要明确一个问题，当k超过数组长度时，我们要将k对数组长度取余。 当k等于数组长度时，不用进行操作直接返回。



<!-- more -->

# 解题思路

## 暴力

从上面的步骤可以看到我们可以移动k次，每一次向右移动一次。

```java
public void rotate(int[] nums, int k) {
  int length = nums.length;
  //对k的处理
  if(k==length){
    return;
  }else if(k>length){
    k %= length;
  }
  //移动k次，
  for (int i = 0; i <k ; i++) {
    //将最后一个元素暂时存储，然后将数组从头开始向后挪动一位，移动元素长度-1个。然后再将第一个置为临时元素。
    int temp = nums[length-1];
    System.arraycopy(nums,0,nums,1,nums.length-1);
    nums[0]=temp;
  }
}
```

复杂度分析：

时间复杂度：我们移动了k次，每次移动都需要移动n个元素，所以时间复杂度为O(k*n)。

空间复杂度：没有使用到额外的空间，所以空间复杂度为O(1)

## 反转

我们来看一个例子：数组\[1,2,3,4,5,6,7],k=3。

1. 我们首先将全部元素反转\[7,6,5,4,3,2,1]
2. 然后将前k个元素反转 \[5,6,7,4,3,2,1]
3. 将后面的n-k个元素反转 \[5,6,7,1,2,3,4]

**代码实现：**

```java
public void rotateThree(int[] nums, int k) {
  if (k == nums.length) {
    return;
  } else {
    k %= nums.length;
  }
  reverseThreeHelp(nums, 0, nums.length - 1);
  reverseThreeHelp(nums, 0, k - 1);
  reverseThreeHelp(nums, k, nums.length - 1);
}

public void reverseThreeHelp(int[] nums, int start, int end) {
  while (start < end) {
    int temp = nums[start];
    nums[start] = nums[end];
    nums[end] = temp;
    start++;
    end--;
  }
}
```

复杂度分析：

空间复杂度：没有用到额外的空间，所以空间复杂度为O(1)

时间复杂度：经过了3次反转，每次反转时间复杂度为O(n)，所以时间复杂度为O(3*n)。

## 使用额外的数组

我们可以先将后k个元素存储到数组中，然后将前面的元素移动，再将刚才保存的元素复制到数组开头。

**代码实现：**

```java
public void rotateArray(int[] nums, int k) {
  if (k == nums.length) {
    return;
  } else {
    k %= nums.length;
  }
  int[] array = new int[k];
  System.arraycopy(nums, nums.length - k, array, 0, k);
  System.arraycopy(nums, 0, nums, k, nums.length - k);
  System.arraycopy(array, 0, nums, 0, k);
}
```

但是这个思路的空间复杂度为O(k)，并不是O(1)，所以不符合要求，但是是这个问题的一种解决思路。