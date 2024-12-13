---
title: 矩阵中的路径-剑指Offer LeetCode12
date: 2022-03-25
categories:
  - notes
tags:
  - LeetCode
related-project: "[[Blog-Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

链接: https://leetcode-cn.com/problems/ju-zhen-zhong-de-lu-jing-lcof/

给定一个存储字母的m*n二维数组和一个字符串单词word. 如果word存在与二维数组中, 返回true, 否则返回flase

单词必须按照字母顺序, 通过相邻的单元格内的字母构成, 其他"相邻"单元格是那些水平相邻或垂直相邻的单元格. 同一个单元格内的字母不允许被重复使用.

> 例如, 在下面的3*4的矩阵中包含单词"ABCCED"
>
> ![img](https://assets.leetcode.com/uploads/2020/11/04/word2.jpg)
>
> 示例1:
>
> 输入: borad = \[ \["A", "B", "C", "E"], \["S", "F", "C", "S"], \["A", "D", "E", "E"], \["A", "D", "E", "E"]], word = "ABCCED"
>
> 输出: true
>
> 示例2:
>
> 输入：board = \[\["a","b"],\["c","d"]], word = "abcd"
> 		输出：false

<!--more-->

# 解题思路

由于单词必须按照字母顺序, 所以我们首先需要在二维数组中找到字符串开头的字母.

然后从这个位置开始上下左右判断与字符串第二个字母是否一致, 如果一致则继续判断与字符串下一个字母进行匹配.

如果当前字母已经是字符串最后一个字母, 则返回true.

题目中要求, 同一个单元格内的字母不允许被重复使用, 所以我们在判断当前单元格内字母与字符串中某个字母匹配之后, 需要将当前单元格内字符替换为一个不相关的元素, 在退出当前节点判断后再将当前节点字符还原.

## 代码实现

```java
	public boolean exist(char[][] board, String word) {
    		char[] chars = word.toCharArray();
		    		for (int i = 0; i < board.length; i++) {
    					    		for (int j = 0; j < board[0].length; j++) {
    		    						    		if (dfs(board, i, j, chars, 0)) {
    		    		    							    		return true;
    		    						    		}
			    		    		}
		    		}
    				return false;
	}

	private boolean dfs(char[][] board, int i, int j, char[] chars, int k) {
		    		// 如果下标越界，两个值不相等，返回false
    				if (i < 0 || j < 0 || i >= board.length || j >= board[0].length || board[i][j] != chars[k]) {
			    		    		return false;
    				}
    				// 如果两个值匹配，并且该值是字符串最后一个元素，那么可以直接返回true，因为已经判断完了
    				if (k == chars.length - 1) {
    		    					return true;
    				}
		    		// 将该位置的元素修改为无关变量，避免重复字符问题
    				board[i][j] = '\0';
		    		// 向上， 下，左，右进行匹配，匹配下一个字符
    				boolean res = 
    		dfs(board, i - 1, j, chars, k + 1) 
    		|| dfs(board, i + 1, j, chars, k + 1) 
    		|| dfs(board, i, j - 1, chars, k + 1) 
    		|| dfs(board, i, j + 1, chars, k + 1);
    				// 再将刚刚替换成无关变量的元素替换回来
		    		board[i][j] = chars[k];
    				return res;
	}
```

