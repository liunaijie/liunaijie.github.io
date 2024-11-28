---
title: 罗马数字转整数-LeetCode13
date: 2018-12-10 19:59:29
tags:
  - 算法与数据结构/Leetcode
related-project: "[[Blog Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

> 罗马数字包含以下七种字符: I， V， X， L，C，D 和 M。
>
> 字符          数值
> I             1
> V             5
> X             10
> L             50
> C             100
> D             500
> M             1000
> 例如， 罗马数字 2 写做 II ，即为两个并列的 1。12 写做 XII ，即为 X + II 。 27 写做  XXVII, 即为 XX + V + II 。
>
> 通常情况下，罗马数字中小的数字在大的数字的右边。但也存在特例，例如 4 不写做 IIII，而是 IV。数字 1 在数字 5 的左边，所表示的数等于大数 5 减小数 1 得到的数值 4 。同样地，数字 9 表示为 IX。这个特殊的规则只适用于以下六种情况：
>
> I 可以放在 V (5) 和 X (10) 的左边，来表示 4 和 9。
> X 可以放在 L (50) 和 C (100) 的左边，来表示 40 和 90。 
> C 可以放在 D (500) 和 M (1000) 的左边，来表示 400 和 900。
> 给定一个罗马数字，将其转换成整数。输入确保在 1 到 3999 的范围内。
>
> 示例 1:
>
> 输入: "III"
> 输出: 3
> 示例 2:
>
> 输入: "IV"
> 输出: 4
> 示例 3:
>
> 输入: "IX"
> 输出: 9
> 示例 4:
>
> 输入: "LVIII"
> 输出: 58
> 解释: L = 50, V= 5, III = 3.
> 示例 5:
>
> 输入: "MCMXCIV"
> 输出: 1994
> 解释: M = 1000, CM = 900, XC = 90, IV = 4.

<!--more-->

# 解题思路

罗马数字与平常看到的十进制不同，它没有进制。它只要把这个符号代表的数值累加起来。

有一个注意的地方是当`I,X,C`三个字符出现时要先判断后面出现的字符，拿`I`来说，如果它的后面出现的是`V,X`，它的意思就不是加一了，而是减一了，即`IV= -1+5 =4`。

```java
public static int romanToInt(String s) {
  int result = 0;
  for (int i = 0; i < s.length(); i++) {
    char c = s.charAt(i);
    switch (c) {
      case 'I':
        if (i + 1 < s.length() && s.charAt(i + 1) == 'V') {
          result += 4;
          i++;
          continue;
        }
        if (i + 1 < s.length() && s.charAt(i + 1) == 'X') {
          result += 9;
          i++;
          continue;
        }
      case 'X':
        if (i + 1 < s.length() && s.charAt(i + 1) == 'L') {
          result += 40;
          i++;
          continue;
        }
        if (i + 1 < s.length() && s.charAt(i + 1) == 'C') {
          result += 90;
          i++;
          continue;
        }
      case 'C':
        if (i + 1 < s.length() && s.charAt(i + 1) == 'D') {
          result += 400;
          i++;
          continue;
        }
        if (i + 1 < s.length() && s.charAt(i + 1) == 'M') {
          result += 900;
          i++;
          continue;
        }
      default:
    }
    result += help(c);
  }
  return result;
}

private static int help(char c) {
  switch (c) {
    case 'I':
      return 1;
    case 'V':
      return 5;
    case 'X':
      return 10;
    case 'L':
      return 50;
    case 'C':
      return 100;
    case 'D':
      return 500;
    case 'M':
      return 1000;
    default:
      return 0;
  }
  return 0;
}
```

### 优化

针对上面的思路我们进行了优化，不再使用额外的函数来进行转换，而是使用hashmap来存储，并且可以看出，如果前面的数字比后面的数字小，那么就应该是做减法

用代码来实现一下能更好理解：

```java
public int romanToIntMap(String s) {
  Map<Character, Integer> map = new HashMap<>(7);
  map.put('I', 1);
  map.put('V', 5);
  map.put('X', 10);
  map.put('L', 50);
  map.put('C', 100);
  map.put('D', 500);
  map.put('M', 1000);
  int result = 0;
  int pre = map.get(s.charAt(0));
  for (int i = 1; i < s.length(); i++) {
    int now = map.get(s.charAt(i));
    if (pre < now) {
      //比如，1<5。此时应该做减法 即 -1+5
      result -= pre;
    } else {
      result += pre;
    }
    //将当前数字置为下一个的前一个数字
    pre = now;
  }
  //由于最后一个还没有添加所以再将其累加上
  result += pre;
  return result;
}
```



