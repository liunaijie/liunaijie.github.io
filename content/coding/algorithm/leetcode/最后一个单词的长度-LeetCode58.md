---
title: 最后一个单词的长度-LeetCode58
date: 2018-12-20
categories:
  - notes
tags:
  - LeetCode
related-project: "[[Blog-Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

> 给定一个仅包含大小写字母和空格 ' ' 的字符串 s，返回其最后一个单词的长度。如果字符串从左向右滚动显示，那么最后一个单词就是最后出现的单词。
>
> 如果不存在最后一个单词，请返回 0 。
>
> 说明：一个单词是指仅由字母组成、不包含任何空格字符的 最大子字符串。
>
>  
>
> 示例:
>
> 输入: "Hello World"
> 输出: 5

<!--more-->

# 解题思路

题目要求最后一个单词的长度，我们从字符串最后面开始向前查找，当遇到空格时就表示我们找到了最后一个单词。

这还有一些其他情况，单词最后还有空格，字符串只有一个单词，都需要进行一些判断。

**代码实现：**

```java
public int lengthOfLastWord(String s) {
  int index = s.length() - 1;
  //先将字符串后面的空格去掉
  while (index >= 0 && s.charAt(index) == ' ') {
    index--;
  }
  //如果不存在最后一个单词，返回0
  if (index < 0) {
    return 0;
  }
  //查找最后一个单词
  int start = index;
  while (start >= 0 && s.charAt(start) != ' ') {
    start--;
  }
  //返回长度
  return index - start;
}
```

