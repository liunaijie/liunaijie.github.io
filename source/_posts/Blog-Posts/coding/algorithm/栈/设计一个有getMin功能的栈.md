---
title: 设计一个有getMin功能的栈
date: 2019-10-15 16:51:42
categories:
  - - coding
    - algorithm
tags:
  - 算法与数据结构/栈
related-project: "[[Blog-Posts/coding/algorithm/算法与数据结构|算法与数据结构]]"
---
# 题目：

实现一个特殊的栈，在实现栈的基本功能的基础上，再实现返回栈内最小元素的操作

# 要求：

1.  pop, push, getMin操作的时间复杂度都是O(1)
2.  设计的栈类型可以使用现成的栈结构

# 解答：

## 使用辅助栈

使用两个栈，一个栈完成基础的操作，这样pop，push的时间复杂度都是O(1)。然后使用辅助栈完成getMin的功能。

辅助栈内的存储也有两种方式：

1.  辅助栈内元素的数量与基础栈内元素数量一致，对应位置上存储当前时刻的最小值。
2.  辅助栈内的元素数量少于基础栈内元素数量，如果对应位置上的最小值已存在则不进行存储。

实现1：

```java
public class GetMin1 {

	private Stack<Integer> stackData;
	private Stack<Integer> stackMin;

	private GetMin1() {
		stackData = new Stack<Integer>();
		stackMin = new Stack<Integer>();
	}

	public void push(int num) {
		if (this.stackMin.isEmpty()) {
			// 如果最小栈为空，直接放
			this.stackMin.push(num);
		} else if (num < this.getMin()) {
			// 如果值小于现在的最小值，那么插入值就是当前位置的最小值，将插入值写入到最小栈中
			this.stackMin.push(num);
		} else {
			// 否则当前位置的最小值就是最小栈的第一个元素，重新写入一次
			int min = this.stackMin.peek();
			this.stackMin.push(min);
		}
		this.stackData.push(num);
	}

	public int pop() {
		if (this.stackData.isEmpty()) {
			throw new RuntimeException("empty stack!");
		}
		this.stackMin.pop();
		return this.stackData.pop();
	}

	public int getMin() {
		if (this.stackMin.isEmpty()) {
			throw new RuntimeException("empty stack!");
		}
		return this.stackMin.peek();
	}

}
```

实现2: