---
title: 删除最外层的括号—LeetCode1021
date: 2019-06-22 11:10:42
tags:
  - 算法与数据结构/Leetcode
related-project: "[[Blog-Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述：

>  有效括号字符串为空 ("")、"(" + A + ")" 或 A + B，其中 A 和 B 都是有效的括号字符串，+ 代表字符串的连接。
> 例如，""，"()"，"(())()" 和 "(()(()))" 都是有效的括号字符串。
> 如果有效字符串 S 非空，且不存在将其拆分为 S = A+B 的方法，我们称其为原语（primitive），其中 A 和 B 都是非空有效括号字符串。
> 给出一个非空有效字符串 S，考虑将其进行原语化分解，使得：S = P_1 + P_2 + ... + P_k，其中 P_i 是有效括号字符串原语。
> 对 S 进行原语化分解，删除分解中每个原语字符串的最外层括号，返回 S 。
> 示例 1：
> 输入："(()())(())"
> 输出："()()()"
> 解释：
> 输入字符串为 "(()())(())"，原语化分解得到 "(()())" + "(())"，
> 删除每个部分中的最外层括号后得到 "()()" + "()" = "()()()"。
> 示例 2：
> 输入："(()())(())(()(()))"
> 输出："()()()()(())"
> 解释：
> 输入字符串为 "(()())(())(()(()))"，原语化分解得到 "(()())" + "(())" + "(()(()))"，
> 删除每隔部分中的最外层括号后得到 "()()" + "()" + "()(())" = "()()()()(())"。
> 示例 3：
> 输入："()()"
> 输出：""
> 解释：
>  输入字符串为 "()()"，原语化分解得到 "()" + "()"，
> 删除每个部分中的最外层括号后得到 "" + "" = ""。
>  提示：
>  S.length <= 10000
>  S[i] 为 "(" 或 ")"
>  S 是一个有效括号字符串

# 解题思路：

字符串S是一个有效括号字符串，那么我们可以先进行原语化分解，然后再对每个原语进行去除最外层括号。  

进行原语分解的时候我们可以定义一个值和一个字符串，遇到左括号这个值加一并将左括号添加到这个字符串上，遇到右括号这个值减一并且将右括号添加到字符串上，当这个值变成0并且字符串的长度为2的倍数时就可以认为这个字符串是一个原语。  

<!--more-->

# 代码实现：

```java
public String removeOuterParentheses(String S) {
   int left = 0;
   List<String> list = new ArrayList<String>();
   StringBuilder item = new StringBuilder();
   for (int i = 0; i < S.length(); i++) {
      char c = S.charAt(i);
      if (c == '(') {
         item.append(c);
         left += 1;
      } else if (c == ')') {
         item.append(c);
         left -= 1;
      }
      if (left == 0 && item.length() % 2 == 0) {
         list.add(item.toString());
         item.setLength(0);
      }
   }
   StringBuilder result = new StringBuilder();
   for (String temp : list) {
      temp = temp.substring(1, temp.length() - 1);
      result.append(temp);
   }
   return result.toString();
}
```

