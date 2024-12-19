---
title: 盛水最多的容器—LeetCode11
date: 2020-03-26
categories:
  - notes
tags:
  - LeetCode
related-project: "[[Blog-Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

> 给你 n 个非负整数 a1，a2，...，an，每个数代表坐标中的一个点 (i, ai) 。在坐标内画 n 条垂直线，垂直线 i 的两个端点分别为 (i, ai) 和 (i, 0)。找出其中的两条线，使得它们与 x 轴共同构成的容器可以容纳最多的水。
>
> 说明：你不能倾斜容器，且 n 的值至少为 2。
>
> ![](https://aliyun-lc-upload.oss-cn-hangzhou.aliyuncs.com/aliyun-lc-upload/uploads/2018/07/25/question_11.jpg)
>
> 图中垂直线代表输入数组 \[1,8,6,2,5,4,8,3,7]。在此情况下，容器能够容纳水（表示为蓝色部分）的最大值为 49。
>
> 示例：
>
> 输入：\[1,8,6,2,5,4,8,3,7]
> 输出：49

<!--more-->

# 解题思路

水的容量怎么算呢？两个边界的最小值，与边界之间的距离相乘，结果就是所能盛水的容量。

最开始拿两边的边界来进行计算，得到一个水的容量。这个时候，下一步如何移动呢？我们开始是从最左侧和最右侧找的两个值，然后比较这两个值，当哪边的值小，哪边的指针就向另一侧移动，补短板。

比较每次的容量与最大值，如果比最大值还大则替换，直到找完。

# 代码实现

```java
public int maxArea(int[] height) {
  int max = 0;
  int left = 0, right = height.length - 1;
  while (left < right) {
    int temp = Math.min(height[left], height[right]) * (right - left);
    max = Math.max(temp, max);
    if (height[left] < height[right]) {
      left++;
    } else {
      right--;
    }
  }
  return max;
}
```



