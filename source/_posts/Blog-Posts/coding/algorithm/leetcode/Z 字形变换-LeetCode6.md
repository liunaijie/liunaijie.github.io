---
title: Z字形变换—LeetCode6
date: 2020-07-02 22:03:47
tags:
  - 算法与数据结构
  - 算法与数据结构/Leetcode
related-project: "[[Blog-Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

> 将一个给定字符串根据给定的行数，以从上往下、从左到右进行 Z 字形排列。
>
> 比如输入字符串为 "LEETCODEISHIRING" 行数为 3 时，排列如下：
>
> ```
> L   C   I   R
> E T O E S I I G
> E   D   H   N
> ```
>
> 之后，你的输出需要从左往右逐行读取，产生出一个新的字符串，比如："LCIRETOESIIGEDHN"。
>
> 请你实现这个将字符串进行指定行数变换的函数：
>
> string convert(string s, int numRows);
> 示例 1:
>
> 输入: s = "LEETCODEISHIRING", numRows = 3
> 输出: "LCIRETOESIIGEDHN"
> 示例 2:
>
> 输入: s = "LEETCODEISHIRING", numRows = 4
> 输出: "LDREOEIIECIHNTSG"
> 解释:
>
> ```
> L     D     R
> E   O E   I I
> E C   I H   N
> T     S     G
> ```

<!--more-->

# 解题思路

将给的字符串，先安装从上到下，从左到右的顺序，进行z字形的排列。这时候会出现`n`行字符串，然后我们再将这`n`行字符串按照从左到右，从上到下的顺序进行拼接起来，这就是我们最终要的结果。

这个题目的难点是怎么分配各个字符的位置。

我们拿最好一个实例为例，`numRows=4`，那么我们就会有4行内容，顺序是`(1,2,3,4,3,2,1,2,3,4)`这样的一个顺序。

每次到第一行和最后一行都需要进行变换，如果是第一行，那么后面每次分配到的行数都是加一，而如果是最后一行，那么每次分配的行数的减一。

而每次变动增加或减少的行数都是1，所以我们可以这样：

开始：从第0行开始放，每次放的位置加一。到达最后一行时，位置开始变成减一。当又到达第0行时，位置开始加一。

# 代码实例

```java
public String convert(String s, int numRows) {
  if (s == null || s.length() == 0 || numRows == 1) {
    return s;
  }
  // 会存在numRows行数据，所以初始化这些长度的数组
  StringBuilder[] lines = new StringBuilder[numRows];
  for (int i = 0; i < lines.length; i++) {
    lines[i] = new StringBuilder();
  }
  char[] chars = s.toCharArray();
  // 最开始从0开始放
  int index = 0;
  //每次增加或减少的间隔都是1
  int dir = 1;
  for (char c : chars) {
    lines[index].append(c);
    index += dir;
    //当遇到最开始或结束时，更改符号，后面就由加变成了减，或由减变成加
    if (index == 0 || index == numRows - 1) {
      dir = -dir;
    }
  }
  //将每一行的结果进行拼接返回
  StringBuilder stringBuilder = new StringBuilder();
  for (StringBuilder line : lines) {
    stringBuilder.append(line);
  }
  return stringBuilder.toString();
}
```

