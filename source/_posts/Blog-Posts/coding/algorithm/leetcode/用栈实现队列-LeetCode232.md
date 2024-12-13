---
title: 用栈实现队列-LeetCode232
date: 2019-11-24
categories:
  - notes
tags:
  - LeetCode
related-project: "[[Blog-Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

> 使用栈实现队列的下列操作：
>
> push(x) -- 将一个元素放入队列的尾部。
> 		pop() -- 从队列首部移除元素。
> 		peek() -- 返回队列首部的元素。
> 		empty() -- 返回队列是否为空。
> 		示例:

> MyQueue queue = new MyQueue();
>
> queue.push(1);
> 		queue.push(2);  
> 		queue.peek();  // 返回 1
> 		queue.pop();   // 返回 1
> 		queue.empty(); // 返回 false
> 		说明:
>
> 你只能使用标准的栈操作 -- 也就是只有 push to top, peek/pop from top, size, 和 is empty 操作是合法的。
> 你所使用的语言也许不支持栈。你可以使用 list 或者 deque（双端队列）来模拟一个栈，只要是标准的栈操作即可。
> 假设所有操作都是有效的 （例如，一个空的队列不会调用 pop 或者 peek 操作）



<!-- more -->

# 解题思路

栈（先进后出）来实现队列（先进先出）。

可以用两个栈来实现，第一个栈存储，当进行 peek 或 pop 操作时，将第一个栈内元素按照先进后出的原则拿出来放到第二个栈里面。这时第二个栈里面在取就是我们总的第一个元素。

![用栈实现队列](https://raw.githubusercontent.com/liunaijie/images/master/用栈实现队列.png)

<!--more-->

# 代码实现

```java
class MyQueue {

    //初始化两个栈，用来实现队列
	Stack<Integer> input;
	Stack<Integer> output;

	/**
	 * 构造函数
	 */
	public MyQueue() {
		input = new Stack<Integer>();
        output = new Stack<Integer>();
	}

	/**
	 * 添加元素
	 * 向入栈中放
	 */
	public void push(int x) {
		input.push(x);
	}

	/**
	 * 获取并删除第一个元素
	 * 当出栈为空时，先将入栈中的元素添加到出栈中
	 * 然后返回出栈的第一个元素
	 */
	public int pop() {
		if (output.isEmpty()) {
			exchange();
		}
		return output.pop();
	}

	/**
	 * 查看第一个元素
	 */
	public int peek() {
		if (output.isEmpty()) {
			exchange();
		}
		return output.peek();
	}

    /**
	* 交换，将入栈的全部放到出栈中
	*/
	private void exchange() {
		while (!input.isEmpty()){
			output.push(input.pop());
		}
	}

	/**
	 * 判断两个栈全不为空时，队列才不为空
	 */
	public boolean empty() {
		return input.isEmpty() && output.isEmpty();
	}
}
```

我们用了两个栈，在插入数据时放到其中一个栈里面。当获取数据时，队列需要获取第一个放的元素，所以需要调转顺序，所以再将入栈的数据从尾开始拿，放到出栈里面，那么出栈里面的顺序就是我们要的顺序了。