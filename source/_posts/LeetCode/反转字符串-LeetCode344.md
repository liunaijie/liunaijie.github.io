---
title: 反转字符串-LeetCode344
date: 2019-07-10 21:12:56
categories: 
	- [code, leetcode]
toc: true
tags: 
	- leetcode
	- java
---

# 题目描述

> 编写一个函数，其作用是将输入的字符串反转过来。输入字符串以字符数组 char[] 的形式给出。
>
> 不要给另外的数组分配额外的空间，你必须原地修改输入数组、使用 O(1) 的额外空间解决这一问题。
>
> 你可以假设数组中的所有字符都是 ASCII 码表中的可打印字符。
>
>  示例 1：
>
> 输入：["h","e","l","l","o"]
> 输出：["o","l","l","e","h"]
> 示例 2：
>
> 输入：["H","a","n","n","a","h"]
> 输出：["h","a","n","n","a","H"]

这个题目的要求是在O(1)的空间复杂度下完成反转

# 解题思路

不能使用额外的空间，又需要将数组反转，我们可以将第一个与最后一个进行反转，然后第二个与倒数第二个进行反转

**代码实现：**

```java
public void reverseString(char[] s) {
  int time = s.length / 2;
  for (int i = 0; i < time; i++) {
    char temp = s[i];
    s[i] = s[s.length - 1 - i];
    s[s.length - 1 - i] = temp;
  }
}
```

