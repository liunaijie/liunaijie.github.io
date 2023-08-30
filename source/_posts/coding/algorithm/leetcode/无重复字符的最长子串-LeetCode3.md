---
title: 无重复字符的最长子串-LeetCode3
date: 2019-03-12 18:50:08
tags: 
	- leetcode
	- java
---

# 题目描述

>给定一个字符串，请你找出其中不含有重复字符的 最长子串 的长度。
>
>示例 1:
>
>输入: "abcabcbb"
>输出: 3 
>解释: 因为无重复字符的最长子串是 "abc"，所以其长度为 3。
>示例 2:
>
>输入: "bbbbb"
>输出: 1
>解释: 因为无重复字符的最长子串是 "b"，所以其长度为 1。
>示例 3:
>
>输入: "pwwkew"
>输出: 3
>解释: 因为无重复字符的最长子串是 "wke"，所以其长度为 3。
>     请注意，你的答案必须是 子串 的长度，"pwke" 是一个子序列，不是子串。

要注意这个题目最后要求返回的是长度，并不是最长的子串内容是什么

<!--more-->

# 解题思路

先来分析一下我的做法，我将字符串遍历，然后添加到一个新字符串中。如果字符没有出现在字符串中就添加，当字符串已经出现在字符串中后，从出现位置开始截取，然后与后面的内容再进行拼接，最后比较字符串的长度与预设值，取最大值作为新的长度。

**代码实现：**

```java
public int lengthOfLongestSubstring(String s) {
  int length = 0;
  StringBuilder str = new StringBuilder();
  for (int i = 0; i < s.length(); i++) {
    int index = str.indexOf(String.valueOf(s.charAt(i)));
    if (index < 0) {
      str.append(s.charAt(i));
    } else {
      String rest = str.substring(index + 1);
      str.setLength(0);
      str.append(rest);
      str.append(s.charAt(i));
    }
    length = Math.max(length, str.length());
  }
  return length;
}
```

## 滑动窗口

利用两个变量`i,j`来表示窗口的两侧，`j`向右移动，遇到未出现的字符时，比较长度。遇到已经添加的字符时`i`向右移动直到出现的字符串后面，此时窗口内的内容是无重复的，然后继续向右移动，直至末尾。

![](https://raw.githubusercontent.com/liunaijie/images/master/leetcode-3.png)

**代码实现：**

```java
public int lengthOfLongestSubstringWindow(String s) {
  int n = s.length();
  Set<Character> set = new HashSet<>();
  int result = 0, i = 0, j = 0;
  while (i < n && j < n) {
    if (!set.contains(s.charAt(j))) {
      set.add(s.charAt(j++));
      result = Math.max(result, j - i);
    } else {
      //一直向右删除，一直到不再包含此字符
      set.remove(s.charAt(i++));
    }
  }
  return result;
}
```

# 进阶

这个题目中只要求返回最大的长度，如果要求返回具体的子串是什么则要怎么做呢？

**代码实现：**

```java
public static String lengthOfLongestSubstringWindowString(String s) {
  int n = s.length();
  Set<Character> set = new HashSet<>();
  int result = 0, i = 0, j = 0;
  String word = "";
  StringBuilder stringBuilder = new StringBuilder();
  while (i < n && j < n) {
    if (!set.contains(s.charAt(j))) {
      stringBuilder.append(s.charAt(j));
      set.add(s.charAt(j++));
      result = Math.max(result, j - i);
    } else {
      //一直向右删除，一直到不再包含此字符
      set.remove(s.charAt(i++));
      stringBuilder.setLength(0);
    }
    if (stringBuilder.length() > word.length()) {
      word = stringBuilder.toString();
    }
  }
  return word;
}
```

