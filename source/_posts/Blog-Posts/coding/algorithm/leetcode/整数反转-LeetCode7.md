---
title: 整数反转—LeetCode7
date: 2019-11-15
categories:
  - notes
tags:
  - LeetCode
related-project: "[[Blog-Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

>给出一个 32 位的有符号整数，你需要将这个整数中每位上的数字进行反转。
>
>示例 1:
>
>输入: 123
>输出: 321
> 示例 2:
>
>输入: -123
>输出: -321
>示例 3:
>
>输入: 120
>输出: 21
>注意:
>
>假设我们的环境只能存储得下 32 位的有符号整数，则其数值范围为 \[−231,  231 − 1]。请根据这个假设，如果反转后整数溢出那么就返回 0。
>

题目中给出了条件，我们只能存储32位有符号整数，如果溢出后则返回0，避免出现溢出错误

<!--more-->

# 解题思路

根据实例可以看出，反转后不会改变符号，我们按照数学方法，将入参`x`,每次对10取余得结果`m`，然后预设结果y,`y=y*10+m`，每次添加时都要判断是否有可能会溢出。

我们以示例1为例，参数`x=123`，预设`y=0`。`x%10=3`，`y<INTMAX/10`，`y=0*10+3`。

这一步结束后得到`x=12`,`y=3`，然后继续执行，直到结束。

我们在对y溢出情况的判断是要先进行判断，因为`y~n~=y~n-1~*10+m>INTMAX`时，`y~n-1~>INTMAX/10`，我们不要在溢出后再进行判断，提前判断预防溢出发生错误。

**代码实现：**

```java
public int reverse(int x) {
  int result = 0;
  while (x != 0) {
    int last = x % 10;
    x /= 10;
    if (result > Integer.MAX_VALUE / 10) {
      return 0;
    }
    if (result < Integer.MIN_VALUE / 10) {
      return 0;
    }
    result = result * 10 + last;
  }
  return result;
}
```

