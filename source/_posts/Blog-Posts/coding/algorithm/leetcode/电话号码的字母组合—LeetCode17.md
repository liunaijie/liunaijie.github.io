---
title: 电话号码的字母组合—LeetCode17
date: 2019-06-15 20:48:52
tags:
  - 算法与数据结构/Leetcode
related-project: "[[Blog-Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述：  

> 给定一个仅包含数字 2-9 的字符串，返回所有它能表示的字母组合。
> 给出数字到字母的映射如下（与电话按键相同）。注意 1 不对应任何字母。
> 示例:
> 输入："23"
> 输出：\["ad", "ae", "af", "bd", "be", "bf", "cd", "ce", "cf"].
>  说明:
>  尽管上面的答案是按字典序排列的，但是你可以任意选择答案输出的顺序。

# 题目解读：

这个问题的场景就是我们的手机9宫格按键，当我们按下按键时计算出所有的字母组合，当我们按下第一个按键时，现在的组合次数为该按键对应的字母个数(m)。当我们再一次按下一个按键时，现在的次数变成了这一次按键对应的字母个数与上一次的次数相乘(m*n)

<!--more-->

# 题目解答：

```java
public List<String> letterCombinations(String digits) {
   char[] chars = digits.toCharArray();
   Map<String, List<String>> keys = new HashMap<String, List<String>>();
   keys.put("2", Arrays.asList("a", "b", "c"));
   keys.put("3", Arrays.asList("d", "e", "f"));
   keys.put("4", Arrays.asList("g", "h", "i"));
   keys.put("5", Arrays.asList("j", "k", "l"));
   keys.put("6", Arrays.asList("m", "n", "o"));
   keys.put("7", Arrays.asList("p", "q", "r", "s"));
   keys.put("8", Arrays.asList("t", "u", "v"));
   keys.put("9", Arrays.asList("w", "x", "y", "z"));
   List<String> result = new ArrayList<String>();
   for (char c : chars) {
      // 拿到输入的字符对应的字母集合
      List values = keys.get(String.valueOf(c));
      result = add(result, values);
   }
   return result;
}

/**
 * @param old 已经有的组合
 * @param now 又要添加的字符
 * @return
 */
private List<String> add(List<String> old, List<String> now) {
   if (old == null || old.size() == 0) {
      // 如果之前没有组合，那新的字母就是所有的组合
      old = now;
      return old;
   }
   List<String> result = new ArrayList<String>();
   for (String oldWord : old) {
      for (String newWord : now) {
         result.add(oldWord + newWord);
      }
   }
   return result;
}
```