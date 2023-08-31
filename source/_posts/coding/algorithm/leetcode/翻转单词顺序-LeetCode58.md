---
title: 翻转单词顺序-LeetCode58
date: 2022-04-13 09:20:49
tags:
- 算法与数据结构
- Leetcode
---

# 题目描述

链接: https://leetcode-cn.com/problems/fan-zhuan-dan-ci-shun-xu-lcof/

输入一个英文句子, 翻转句子中单词的顺序, 但单词内字符的顺序不变. 标点符号和普通字母一样处理. 例如输入字符串"I am a student.", 输出应该为"student. a am I"

> 示例1:
>
> 输入 :  "the sky is blue"
>
> 输出 : "blue is sky the"
>
> 示例2:
>
> 输入 : "    hello world!   "
>
> 输出 :  "world! hello"
>
> 忽略字符串前后的空格
>
> 示例3: 
>
> 输入: "a good   example"
>
> 输出: "example good a"
>
> 如果两个单词间有多余的空格，将反转后单词间的空格减少到只含一个。

<!--more-->

# 解题思路

来理一下几个要求:

1. 忽略字符串前后的空格
2. 两个单词之间只需要一个空格
3. 只翻转单词顺序, 而不翻转单词内容

## 双指针

使用两个指针x, y来表示一个单词. 并且由于需要翻转, 所以我们从后向前开始遍历.

由于要求1, 我们可以先将头尾两端的空格去除掉再进行处理.

1. 将指针x, y置于已经处理的字符串尾部. 

2. x向前走, 直到遇到空格. 这时截取x,y之间的内容.

3. 由于要求2, 中间可能会出现多个空格. 所以如果前面还是空格, 则x继续走.
4. 令y=x.

重复步骤2, 3, 4. 终止条件为x>=0

### 代码实现

```java
	public String reverseWords(String s) {
		    s = s.trim();
		    		int x = s.length() - 1, y = x;
		    		StringBuilder sb = new StringBuilder();
		    		while (x >= 0) {
					    		    while (x >= 0 && s.charAt(x) != ' ') {
		    		    		    				x--;
		    		    			}
					 		       sb.append(s, x + 1, y + 1);
		    		    			sb.append(" ");
					    		    while (x >= 0 && s.charAt(x) == ' ') {
		    		    		    				x--;
		    		    			}
		    		    			y = x;
		    		}
		    		return sb.toString().trim();
	}
```

## 按照空格切分

由于我们知道, 单词是按照空格进行划分的, 那么我们将字符串按照空格划分为数组. 

然后从尾部开始遍历, 将单词添加到结果中. 要注意一点是, 由于字符串中间可能会出现多个空格, 从而出现空单词的情况, 需要在遍历时进行判断.

```java
    public String reverseWords(String s) {
        String[] strs = s.trim().split(" "); 
        StringBuilder res = new StringBuilder();
        for(int i = strs.length - 1; i >= 0; i--) { 
            if(strs[i].equals("")) continue;
            res.append(strs[i] + " "); 
        }
        return res.toString().trim();
    }
```

# 相关题目

