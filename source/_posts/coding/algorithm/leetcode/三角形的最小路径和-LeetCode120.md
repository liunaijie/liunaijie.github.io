---
title: 三角形最小路径和—LeetCode120
date: 2019-06-16 22:18:23
tags: 
- 算法与数据结构
- Leetcode
---

# 题目描述

> 给定一个三角形，找出自顶向下的最小路径和。每一步只能移动到下一行中相邻的结点上。
>
> 例如，给定三角形：
>
> \[
>      \[2],
>     \[3,4],
>    \[6,5,7],
>   \[4,1,8,3]
> ]
> 自顶向下的最小路径和为 11（即，2 + 3 + 5 + 1 = 11）。
>
> 说明：
>
> 如果你可以只使用 O(n) 的额外空间（n 为三角形的总行数）来解决这个问题，那么你的算法会很加分。
>

题目中有一句话，每一步只能移动到下一行中相邻的结点中，所以在m行n列时，下一步的落地只能在m+1行n列或者m+1行n+1列中。

<!--more-->

# 解题思路

## 二维数组，从上向下

利用二维数组，将每一步到开始的步骤记录下来。

以上面的例子为例：我们如果将每一个位置到顶点的最小步数记录下来，那么就是：

```java
[
  [2],
  [5,6],
  [11,10,13],
  [15,11,18,16]
]
```

可以看出，第一层不变，每一行的最开始和结束两个位置的计算方法为当前元素加上上一行中的第一个或最后一个元素。即`sum[i][0]=a[i][0]+sum[i-1][0]`，`sum[i][last]=a[i][last]+sum[i-1][last]`

代码实现：

```java
public static int minimumTotalTwo(List<List<Integer>> triangle) {
  if (triangle.size() == 0) {
    return 0;
  }
  int[][] paths = new int[triangle.size()][triangle.size()];
  //对第一层进行初始化
  paths[0][0] = triangle.get(0).get(0);
  //从第二层开始
  for (int i = 1; i < triangle.size(); i++) {
    List<Integer> single = triangle.get(i);
    for (int j = 0; j < single.size(); j++) {
      if (j == 0) {
        // 当前行第一个数字 是上一行的和与当前值累加 
        //因为第一个元素的上一步只能是第一个过来，m(i,j)的上一步为m(i-1,j-1)和m(i-1,j)由于j已经为0，所以j-1不存在，后面同理在当前行中的最后一个元素，在上一行中是没有的
        paths[i][j] = paths[i - 1][0] + single.get(0);
      } else if (j == single.size() - 1) {
        // 当前行最后一个数字
        paths[i][j] = paths[i - 1][j - 1] + single.get(j);
      } else {
        paths[i][j] = Math.min(paths[i - 1][j - 1], paths[i - 1][j]) + single.get(j);
      }
    }
  }
  int[] nums = paths[triangle.size() - 1];
  int min = nums[0];
  for (int temp : nums) {
    if (temp < min) {
      min = temp;
    }
  }
  return min;
}
```

## 自下向上，一维数组

刚才我们是从开始向结束看，我们如果从结束向开始看呢？

那么`sum[i,j]=Math.min(sum[i+1,j],sum[i+1,j+1])+a[i,j]`。我们可以临时构建一个一维数组，**存储每一行到结束的最小路径**，那么最后`sum[0]`就是最小路径

代码实现：

```java
public static int minimumTotal(List<List<Integer>> triangle) {
  //入参判断
  if (triangle.size() == 0) {
    return 0;
  }
  //由于j+1可能会造成越界，所以长度多加一位
  int[] dp = new int[triangle.size() + 1];
  // 从后向前进行计算
  for (int i = triangle.size() - 1; i >= 0; i--) {
    //从后得到每一行
    List<Integer> content = triangle.get(i);
    //这一行中这一列到终点的最小路径为上一行中能到达位置的最小值加上自身值
    for (int j = 0; j < content.size(); j++) {
      dp[j] = Math.min(dp[j], dp[j + 1]) + content.get(j);
    }
  }
  return dp[0];
}
```

