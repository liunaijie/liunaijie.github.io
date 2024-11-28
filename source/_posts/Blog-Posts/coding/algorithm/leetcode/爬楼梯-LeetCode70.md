---
title: 爬楼梯-LeetCode70
date: 2019-03-16 19:56:08
tags:
  - 算法与数据结构/动态规划
  - 算法与数据结构/Leetcode
related-project: "[[Blog Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

链接: https://leetcode-cn.com/problems/climbing-stairs/

假设你正在爬楼梯。需要 n 阶你才能到达楼顶。

每次你可以爬 1 或 2 个台阶。问你有多少种不同的方法可以爬到楼顶？

> 示例 1：
>
> 输入： 2
>		输出： 2
> 		有两种方法可以爬到楼顶。
>
> 第一种: 1 阶 + 1 阶
>
> 第二种: 2 阶
> 
> 示例 2：
> 
> 输入： 3
> 
>输出： 3
> 
> 有三种方法可以爬到楼顶。
> 
> 1.  1 阶 + 1 阶 + 1 阶
> 2.  1 阶 + 2 阶
> 3.  2 阶 + 1 阶
>

<!--more-->

# 解题思路

## 动态规划

每次可以爬1层或者2层, 所以我们在最后一层台阶时, 它上一次可以在第n-1层台阶上或n-2层台阶上.

递归方程为: f(x) = f(x-1) + f(x-2) (x>=2)

再看一下边界条件: 

f(0) : 由于我们是从开始爬, 要到达0可以看作只有一种方案, 也就是 f(0) = 1

f(1) : 从0到1也只有1种方案, 即f(1) = 1.

### 代码实现

#### DP数组:

```java
public int climbStairs(int n) {
  if (n == 1) {
    return 1;
  }else if (n == 2) {
    return 2;
  }else {
    int[] ans = new int[n];
    ans[0] = 1;
    ans[1] = 2;
    for(int i=2;i<n;i++) {
      ans[i]=ans[i-1]+ans[i-2];
    }
    return ans[n-1];
  }
}
```

#### 临时变量:

上面的代码, 我们创建了一个DP数组来存储每次的结果, 但是我们可以看出f(x)只与f(x-1)与f(x-2)有关. 所以我们可以定义两个变量表示f(x-1)和f(x-2)

```java
	public int climbStairs(int n) {
		    if (n <= 2) {
		    		    			return n;
		    		}
				    int x = 1, y = 2;
		    		int res = 0;
				    for (int i = 3; i <= n; i++) {
					    		    res = x + y;
					    		    x = y;
		    		    			y = res;
				    }
		    		return res;
	}
```

