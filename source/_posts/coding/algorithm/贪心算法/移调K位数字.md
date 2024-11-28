---
title: 移调K位数字
date: 2019-10-15 16:51:42
categories:
  - - coding
    - algorithm
tags:
  - 算法与数据结构/贪心
---

给定一个以字符串表示的非负整数num和一个整数k, 移除这个数中的k位数字, 使得剩下的数字最小.

# 题解

删除规则为

1.  当左侧数字大于当前数字时, 则将左侧数字删除
2.  如果全部数字是从小到达排列, 即全部左侧数字小于右侧数字. 则从尾部开始删除
```java
public static String removeKdigits(String num, int k) {
		Deque<Character> deque = new LinkedList<Character>();
		int length = num.length();
		for (int i = 0; i < length; ++i) {
			char digit = num.charAt(i);
			// 如果上一位数字比当前位数字大，则删除上一位数字
			// 并将需要删除的位数减1，当需要删除的位数为0时不再进行删除
			while (!deque.isEmpty() && k > 0 && deque.peekLast() > digit) {
				deque.pollLast();
				k--;
			}
			//将当前位放入栈中
			deque.offerLast(digit);
		}
		// 如果k仍然大于0，则从后向前删除k位
		for (int i = 0; i < k; ++i) {
			deque.pollLast();
		}
		// 将剩下的元素拼接成结果
		// 需要注意的一点是，可能存在0开头的数字，这时需要将0去掉，即结果为01时需要返回1
		StringBuilder ret = new StringBuilder();
		boolean leadingZero = true;
		while (!deque.isEmpty()) {
			char digit = deque.pollFirst();
			if (leadingZero && digit == '0') {
				continue;
			}
			leadingZero = false;
			ret.append(digit);
		}
		return ret.length() == 0 ? "0" : ret.toString();
	}
```