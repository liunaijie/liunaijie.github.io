---
title: 增减字符串匹配—LeetCode942
date: 2019-06-20 20:36:23
categories: 
	- [code, leetcode]
toc: true
tags: 
	- leetcode
	- java
---

# 题目描述：

> 给定只含 "I"（增大）或 "D"（减小）的字符串 S ，令 N = S.length。
>
> 返回 [0, 1, ..., N] 的任意排列 A 使得对于所有 i = 0, ..., N-1，都有：
>
> 如果 S[i] == "I"，那么 A[i] < A[i+1]
>
> 如果 S[i] == "D"，那么 A[i] > A[i+1]
>
> 示例 1：
>
> 输出："IDID"
>
> 输出：[0,4,1,3,2]
>
> 示例 2：
>
> 输出："III"
>
> 输出：[0,1,2,3]
>
> 示例 3：
>
> 输出："DDI"
>
> 输出：[3,2,0,1]
>
> 提示：
>
> 1 <= S.length <= 1000
>
> S 只包含字符 "I" 或 "D"。
> 

<!-- more -->

# 解题思路：

给定只包含`I`和`D`的字符串，让我们求符合规则的数组。首先确认的是数组内的数值为0到字符串的长度，如果字符串长度为2，那数组内的数值就是0，1，2。  

然后遇到`I`表示增大，遇到`D`表示减少，那么可以利用双指针，如果遇到`I`则从最小值`0`开始放然后加一，遇到`D`则从最大值开始放然后减一。

**代码实现：**

```java
public int[] diStringMatch(String S) {
  int length = S.length();
  int[] result = new int[length+1];
  char[] chars = S.toCharArray();
  int max = length;
  int min = 0;
  for (int i = 0; i < chars.length; i++) {
    char c = chars[i];
    switch (c) {
      case 'I':
        result[i] = min;
        min++;
        break;
      case 'D':
        result[i] = max;
        max--;
        break;
      default:
        break;
    }
  }
  result[length]=max;
  return result;
}
```

