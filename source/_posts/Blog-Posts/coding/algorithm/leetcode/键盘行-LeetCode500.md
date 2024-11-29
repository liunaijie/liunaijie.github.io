---
title: 键盘行-LeetCode500
date: 2019-07-15 20:06:56
tags:
  - 算法与数据结构/Leetcode
related-project: "[[Blog-Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

> 给定一个单词列表，只返回可以使用在键盘同一行的字母打印出来的单词。键盘如下图所示。
>
> ![](https://assets.leetcode-cn.com/aliyun-lc-upload/uploads/2018/10/12/keyboard.png)
>
> 示例：
>
> 输入: \["Hello", "Alaska", "Dad", "Peace"]
> 输出: \["Alaska", "Dad"]
>
>
> 注意：
>
> 你可以重复使用键盘上同一字符。
> 你可以假设输入的字符串将只包含字母。

判断给出的字符是否全部在一行中

<!--more-->

# 解题思路

由于键盘行的内容是固定的，所以可以先将信息固定，然后将字符串与它对比，当有不匹配的就返回，完全匹配就添加到结果集中。

**代码实现：**

```java
public String[] findWords(String[] words) {
  String[] lines = {"qwertyuiop", "asdfghjkl", "zxcvbnm"};
  List<String> result = new ArrayList<>();
  for (String word : words) {
    char[] chars = word.toLowerCase().toCharArray();
    for (String line : lines) {
      if (line.contains(String.valueOf(chars[0]))) {
        boolean check = checkWord(line, chars);
        if (check) {
          result.add(word);
        }
      }
    }
  }
  return result.toArray(new String[result.size()]);
}
```

