---
title: 转换为小写字母—LeetCode709
date: 2019-01-03 13:52:40
categories: 
	- [code, leetcode]
toc: true
tags: 
	- leetcode
	- java
---

# 题目描述

> 实现函数 ToLowerCase()，该函数接收一个字符串参数 str，并将该字符串中的大写字母转换成小写字母，之后返回新的字符串。
>
> 示例 1：
>
> 输入: "Hello"
> 输出: "hello"
> 示例 2：
>
> 输入: "here"
> 输出: "here"
> 示例 3：
>
> 输入: "LOVELY"
> 输出: "lovely"

<!--more-->

# 解题思路

实现一个转换成小写的功能，对字符串进行遍历，如果是大写，将其转换成小写，然后再进行拼接

**代码实现：**

```java
public String toLowerCase(String str) {
  StringBuilder stringBuilder = new StringBuilder();
  for (int i = 0; i < str.length(); i++) {
    char c = str.charAt(i);
    if (c >= 'A' && c <= 'Z') {
      c += 32;
    }
    stringBuilder.append(c);
  }
  return stringBuilder.toString();
}
```

