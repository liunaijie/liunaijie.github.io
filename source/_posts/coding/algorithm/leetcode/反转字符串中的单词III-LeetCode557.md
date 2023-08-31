---
title: 反转字符串中的单词III-LeetCode557
date: 2019-07-12 20:01:56
tags: 
- 算法与数据结构
- Leetcode
---

# 题目描述

> 给定一个字符串，你需要反转字符串中每个单词的字符顺序，同时仍保留空格和单词的初始顺序。
>
> 示例 1:
>
> 输入: "Let's take LeetCode contest"
> 输出: "s'teL ekat edoCteeL tsetnoc" 
> 注意：在字符串中，每个单词由单个空格分隔，并且字符串中不会有任何额外的空格。

根据示例可以看出，需要将每个单词反转后再根据原有顺序拼接起来

<!--more-->

# 解题思路

首先要分解出单词，然后将单词进行反转。将反转后的单词再进行拼接。

在这里不借助java自带的方法

**代码实现：**

```java
public static String reverseWords2(String s) {
  StringBuilder stringBuilder = new StringBuilder();
  int start = 0;
  for (int end = 0; end < s.length(); end++) {
    //分隔单词
    if (s.charAt(end) == ' ') {
      //将空格前的一个单词进行反转
      append(stringBuilder, s, start, end - 1);
      //反转后还需要添加上空格
      stringBuilder.append(' ');
      //记录下一个单词的开始位置
      start = end + 1;
    }
    //判断是否达到最后
    if (end == s.length() - 1) {
      append(stringBuilder, s, start, end);
    }
  }
  return stringBuilder.toString();
}

private static void append(StringBuilder stringBuilder, String s, int start, int end) {
  for (int i = end; i >= start; i--) {
    stringBuilder.append(s.charAt(i));
  }
}
```

