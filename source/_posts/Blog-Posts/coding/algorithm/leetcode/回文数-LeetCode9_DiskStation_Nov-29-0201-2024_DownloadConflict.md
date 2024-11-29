---
title: 回文数—LeetCode9
date: 2019-11-07 19:58:29
tags:
  - 算法与数据结构/Leetcode
related-project: "[[Blog Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

>判断一个整数是否是回文数。回文数是指正序（从左向右）和倒序（从右向左）读都是一样的整数。
>
>示例 1:
>
>输入: 121
>输出: true
>示例 2:
>
>输入: -121
>输出: false
>解释: 从左向右读, 为 -121 。 从右向左读, 为 121- 。因此它不是一个回文数。
>示例 3:
>
>输入: 10
>输出: false
>解释: 从右向左读, 为 01 。因此它不是一个回文数。
>进阶:
>
>你能不将整数转为字符串来解决这个问题吗？
>

从示例2中可以看出，负数不是回文数，可以先对此进行判断。

而提示中有一个提示，能否不使用字符串来解决这个问题，那么使用字符串肯定是可以解决这个问题的。

<!--more-->

# 解题思路

## 转换字符串

我们可以直接将数字转换为字符串，然后两个字符串进行匹配，看反转后的字符串是否与入参相同

代码如下：

```java
public boolean isPalindromeString(int x) {
  if(x<0){
    return false;
  }
  String reverseStr = new StringBuilder(x).reverse().toString();
  return reverseStr.equals(x + "");
}
```

## 数学解法

对比一个数是不是回文数，可以前面和后面各取一位，然后对比，如果不相同则返回`false`。如果相同，则继续前后各取一位继续进行比较。

举一个例子：`10201`：

第一步，拿到开始和结尾是`1`和`1`，相同则继续对比第二位`0`和`0`然后只剩一位，所以是回文数。

再来一个反例：`12345`：

第一步，拿到开始和结尾分别是`1`和`5`。不一致直接返回`false`

**代码实现：**

```java
public boolean isPalindrome1(int x) {
  if (x < 0) {
    return false;
  }
  //先计算它的位数
  int count = 1;
  while (x / count >= 10) {
    count *= 10;
  }
  while (x > 0) {
    //头部的值
    int left = x / count;
    //尾部的值
    int right = x % 10;
    //判断是否相等
    if (left != right) {
      return false;
    }
    //将比较过的前后位置去掉
    // 10201为例， 先对1000取余，得到201，然后除以10，得到20
    //以这个20为例，再次计算是 20/100=0 20%100=0 相等，不会有影响
    x = (x % count) / 10;
    //因为这里每次都去掉了前后两位，所以是除以100
    count /= 100;
  }
  return true;
}
```

## 进阶解法

一个回文数，我们只需要比较前一半的数字是否与后一半的数字相等即可。

参数`x`，每次先对10取余，得到余数`y`。

定义一个数值m表示从后向前的数字，得到余数后进行添加`m=m*10+y`。

对`x`要自除10`x/=10`

当x<m时，就说明已经计算了一半或者超过一半了。

当x是偶数的时候，计算到一半时`m=x`。当x是奇数时，最中间的数字在m的最低位上，可以比较`m/10`是否与x相等

**代码实现：**

```java
public boolean isPalindrome(int x) {
  if (x < 0) {
    return false;
  }
  //当x不为0时，余数出现了0，比如 10，这种情况肯定不是回文数
  if (x % 10 == 0 && x != 0) {
    return false;
  }
  int m = 0;
  while (x > m) {
    m = m * 10 + x % 10;
    x /= 10;
  }
  //有两种情况，偶数时m=x,奇数时m/10=x
  return x == m || x == m / 10;
}
```

