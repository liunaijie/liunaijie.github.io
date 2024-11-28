---
title: 最长公共前缀-LeetCode14
date: 2018-12-12 20:50:52
tags:
  - 算法与数据结构
  - 算法与数据结构/Leetcode
related-project: "[[Blog Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

>编写一个函数来查找字符串数组中的最长公共前缀。
>
>如果不存在公共前缀，返回空字符串 `""`。
>
>**示例 1:**
>
>```
>输入: \["flower","flow","flight"]
>输出: "fl"
>```
>
>**示例 2:**
>
>```
>输入: \["dog","racecar","car"]
>输出: ""
>解释: 输入不存在公共前缀。
>```
>
>**说明:**
>
>所有输入只包含小写字母 `a-z` 。

<!--more-->

# 解题思路

首先判断入参数组的长度，如果数组为空则直接返回空字符串，如果长度为1，则返回第一个字符串即可。

当有多个字符串时，拿第一个字符串去与其他字符串对比。我们默认第一个字符串全部为公共前缀，于其他字符串每每比较，得到公共前缀，最终的结果就是全部字符串的公共前缀。有可能中间存在公共前缀为空的情况，这时不需要再向下遍历比较。

![](https://raw.githubusercontent.com/liunaijie/images/master/leetcode-14.png)

**代码实现：**

```java
public static String longestCommonPrefix(String[] strs) {
  if (strs.length == 0) {
    return "";
  } else if (strs.length == 1) {
    return strs[0];
  }
  String result = strs[0];
  for (int i = 1; i < strs.length; i++) {
    int end = 0;
    for (; end < result.length() && end < strs[i].length(); end++) {
      if (result.charAt(end) != strs[i].charAt(end)) {
        break;
      }
    }
    result = result.substring(0, end);
    if ("".equals(result)) {
      return result;
    }
  }
  return result;
}
```



