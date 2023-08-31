---
title: 自除数—LeetCode728
date: 2019-06-04 15:20:09
tags: 
- 算法与数据结构
- Leetcode
---

# 题目描述：

自除数 是指可以被它包含的每一位数除尽的数。
例如，128 是一个自除数，因为 128 % 1 == 0，128 % 2 == 0，128 % 8 == 0。
还有，自除数不允许包含 0 。
给定上边界和下边界数字，输出一个列表，列表的元素是边界（含边界）内所有的自除数。
示例 1：
输入：
上边界left = 1, 下边界right = 22
输出： \[1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 15, 22]
注意：
每个输入参数的边界满足 1 <= left <= right <= 10000。


# 解读：

判断一个数能不能被他的每一位除尽，那就要取出每一位数，进行计算，并且自除数不允许包含0，所以如果有0则直接判断不是自除数

<!--more-->

# 代码实现：

```java
/**
* 循环获取每一个边界内的数
* 判断这个数是否是自除数
*
* @param left 上边界
* @param right 下边界
* @return
*/
public List<Integer> selfDividingNumbers(int left, int right) {
   List<Integer> result = new ArrayList<>();
   for (int i = left; i <= right; i++) {
      if (isSelfDividing(i)) {
         result.add(i);
      }
   }
   return result;
}

/**
 * 用一个变量存储要计算的数字
 * <p>
 * 1.获取最后一位数
 * 2.当这位数字不为零并且能被要计算的数字整除时继续计算 否则返回false
 * 3.变量除以10 然后重复进行 1，2步操作
 *
 * @param num
 * @return
 */
public boolean isSelfDividing(int num) {
   int temp = num;
   while (temp != 0) {
      int digit = temp % 10;
      if (digit == 0 || num % digit != 0) {
         return false;
      }
      temp /= 10;
   }
   return true;
}
```