---
title: 有效的括号—LeetCode20
date: 2019-08-07 20:17:30
categories: 
	- [code, leetcode]
toc: true
tags: 
	- leetcode
	- java
---

# 题目描述

> 给定一个只包括 `'('`，`')'`，`'{'`，`'}'`，`'['`，`']'` 的字符串，判断字符串是否有效。
>
> 有效字符串需满足：
>
> 1. 左括号必须用相同类型的右括号闭合。
> 2. 左括号必须以正确的顺序闭合。
>
> 注意空字符串可被认为是有效字符串。
>
> **示例 1:**
>
> ```
> 输入: "()"
> 输出: true
> ```
>
> **示例 2:**
>
> ```
> 输入: "()[]{}"
> 输出: true
> ```
>
> **示例 3:**
>
> ```
> 输入: "(]"
> 输出: false
> ```
>
> **示例 4:**
>
> ```
> 输入: "([)]"
> 输出: false
> ```
>
> **示例 5:**
>
> ```
> 输入: "{[]}"
> 输出: true
> ```

这个题目与我们编译器对括号的识别一样，当我们多了一个括号后编译器会报错提示。

<!--more-->

# 解题思路

如果给定的字符串不是偶数长度，则一定不是有效的括号，因为有效的括号一定是成对出现的，长度必然是偶数。

我们进行遍历时，如果首先出现结束符，即`) ] }`这三个字符，出现前并没有开始字符出现，那么肯定是无效的括号。

当出现开始字符`( [ {`时将它加入到栈中，遇到结束字符时去看栈中的第一个元素是不是对于的开始字符，如果不匹配则不是有效的括号。

```java
public boolean isValid(String s) {
  if (s.length() % 2 != 0) {
    // 如果不是偶数长度直接返回
    return false;
  }
  Stack<Character> stack = new Stack<Character>();
  Map<Character, Character> map = new HashMap<Character, Character>();
  map.put(')', '(');
  map.put(']', '[');
  map.put('}', '{');
  char[] chars = s.toCharArray();
  for (char c : chars) {
    if (map.containsKey(c)) {
      if (stack.isEmpty()) {
        return false;
      }
      char temp = stack.pop();
      if (temp != map.get(c)) {
        return false;
      }
    } else {
      stack.add(c);
    }
  }
  return stack.isEmpty();
}
```

