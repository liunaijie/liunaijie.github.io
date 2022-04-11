---
title: 机器人的运动路径- 剑指Offer LeetCode13
date: 2022-03-24 23:10:46
categories: "leetcode"
toc: true
tags: 
	- leetcode
	- java
---

# 题目描述

链接: https://leetcode-cn.com/problems/ji-qi-ren-de-yun-dong-fan-wei-lcof/

地上有一个m行n列的二维矩阵, 从坐标[0, 0]到[m-1, n-1]. 一个机器人从坐标[0, 0]的格子开始移动, 每次可以向左, 右, 上, 下移动一格.

不能移动到方格外, 也不能移动到行坐标和列坐标的数位之和大于K的格子. 例如当K=18时, 机器人可以进入方格[35, 37], 因为3+5+3+7=18. 但是不能进入[35, 38], 因为3+5+3+8=19. 求机器人能够到达多少个格子.

<!--more-->

# 解题思路

求能够到达多少个格子, 那么就要使用额外的数组来存储当前格子是否被访问过, 否则就会造成重复计数的情况.

并且每个格子都可以往上下左右四个方向移动, 我们从左上角[0, 0]移动, 所以每次只需要判断向右和向下的可达数量, 不需要再向左, 向上移动

DFS遍历

## 代码实现

```java
	private int m, n, k;
	private boolean[][] visited;

	public int movingCount(int m, int n, int k) {
    		if (m <= 0 || n <= 0 || k < 0) {
	        		return 0;
    	}
		    	this.m = m;
		    	this.n = n;
		    	this.k = k;
    			this.visited = new boolean[m][n];
    			return dfs(0, 0, 0, 0);
	}
// sumI表示 坐标i的数位之和
// sumJ表示 坐标j的数位之和
	private int dfs(int i, int j, int sumI, int sumJ) {
	    	// 判断当前是否会造成数组越界
		    	// 判断当前是否满足小于K的情况
    	// 判断当前节点是否访问过
    			if (i >= m || j >= n || k < sumI + sumJ || visited[i][j]) {
			        		return 0;
    			}
    	// 将当前节点标记为已访问
	    	visited[i][j] = true;
	    	// 结果为当前节点的1 再加上 向右, 向下的结果
	    		return 1 
	    	    	    + dfs(i + 1, j, sums(i + 1), sumJ) 
	    	    	    + dfs(i, j + 1, sumI, sums(j + 1));
	}


	private int sums(int x) {
			    int s = 0;
	    		while (x != 0) {
	 	       			s += x % 10;
					        x = x / 10;
			    }
			    return s;
	}
```



