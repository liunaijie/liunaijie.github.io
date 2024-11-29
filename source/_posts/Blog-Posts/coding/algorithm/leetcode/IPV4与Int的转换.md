---
title: IPV4与Int的转换
date: 2021-01-05 21:13:30
tags:
  - 算法与数据结构
  - 算法与数据结构/Leetcode
related-project: "[[Blog-Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

> 将IPV4的地址转换成int值，然后再将其转换回来

<!--more-->

# 解题思路

IPV4的格式为 \[a,b,c,d]，并且值的范围是0~255.

255是2^8^-1，int的长度为32位，正好可以将4位ip拼接成一个int值。前8位是第一个ip地址，第二个8位是第二个ip地址，第三个8位存放第三个ip地址，第四个8位存放第四个ip地址。

![](https://raw.githubusercontent.com/liunaijie/images/master/20210825180934.png)

这里就需要使用位移操作符来进行操作，第一个ip地址向左移24位，第二个ip地址左移16位，第三个ip地址左移8位，第四个ip地址不需要移位，然后将其相加起来就得到最终的int值。

将int值转换位ip地址时需要注意，由于int的第一位表示正负，所以这里需要使用无符号右移`>>>`

第一个ip地址转换回来时，直接无符号右移24位即可

第二个ip地址转换回来时，需要先左移8位后去除掉第一个ip地址，然后再无符号右移24位

第三个ip地址转换回来时，需要先左移16位后去掉第一个和第二个ip地址，然后再无符号右移24位

![](https://raw.githubusercontent.com/liunaijie/images/master/20210825181159.png)

**代码实现:**

```java
	public static void main(String[] args) {
		int[] ips = {255, 2, 120, 250};
		int one = ips[0] << 24;
		int two = ips[1] << 16;
		int three = ips[2] << 8;
		int four = ips[3];
		int res = one + two + three + four;
		System.out.println(Integer.toBinaryString(res));
		int convertOne = res >>> 24;
		int convertTwo = res << 8 >>> 24;
		int convertThree = res << 16 >>> 24;
		int convertFour = res << 24 >>> 24;
		System.out.println(convertOne);
		System.out.println(convertTwo);
		System.out.println(convertThree);
		System.out.println(convertFour);
	}
```

