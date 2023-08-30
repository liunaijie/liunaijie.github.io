---
title: 用队列实现栈-LeetCode225
date: 2019-11-24 10:07:41
categories: 
	- [code, leetcode]
toc: true
tags: 
	- leetcode
	- java
---

# 题目描述

>使用队列实现栈的下列操作：
>push(x) -- 元素 x 入栈
>pop() -- 移除栈顶元素
>top() -- 获取栈顶元素
>empty() -- 返回栈是否为空
>注意:
>
>你只能使用队列的基本操作-- 也就是 push to back, peek/pop from front, size, 和 is empty 这些操作是合法的。
>你所使用的语言也许不支持队列。 你可以使用 list 或者 deque（双端队列）来模拟一个队列 , 只要是标准的队列操作即可。
>你可以假设所有操作都是有效的（例如, 对一个空的栈不会调用 pop 或者 top 操作）。

<!-- more -->

# 解题思路

1. 使用两个队列

    将元素添加到第一个队列中。

    在获取元素时，将第一个队列中除了最后一个元素都添加到第二个队列中，剩下的这个就是要返回的元素。

    将两个队列进行交换，这样在添加元素时都能放到第一个队列中。

    使用一个变量来存储最后一个元素，这样在调用 top 方法时直接返回这个变量即可。

    ![用双队列实现栈](https://raw.githubusercontent.com/liunaijie/images/master/用双队列实现栈.png)

2. 使用一个队列

    添加元素时添加到队列中，然后将队列中的元素除了最后一个再重新放入一遍

    在获取元素和查看元素时都拿第一个即可

    ![用一个队列实现栈](https://raw.githubusercontent.com/liunaijie/images/master/用一个队列实现栈.png)

    <!--more-->

# 代码实现

1. 双队列实现

```java
class MyStack {

	Queue<Integer> input;
	Queue<Integer> output;
	int top;

	/**
	 * 构造函数
	 */
	public MyStack() {
		input = new LinkedList<Integer>();
		output = new LinkedList<Integer>();
	}

	/**
	 * 添加元素，在第一个队列里面添加，并使用变量存储第一个元素
	 */
	public void push(int x) {
		input.add(x);
		top = x;
	}

	/**
	 * 查看并移除第一个元素
	 */
	public int pop() {
        //将第一个队列里面的元素只留一个，其他都放到第二个队列中，并将 top 变量保存的值进行修改
		while (input.size() > 1) {
			top =  input.poll();
			output.add(top);
		}
        //然后将第一个和第二个队列进行交换
		Queue temp = input;
		input = output;
		output = temp;
        //返回刚刚剩下的一个元素，那就就是最后一个元素
		return output.poll();
	}

	/**
	 * 查看最后一个元素，直接返回变量即可
	 */
	public int top() {
		return top;
	}

	/**
	 * 判断两个队列都不为空
	 */
	public boolean empty() {
		return input.isEmpty() && output.isEmpty();
	}
}
```

2. 单队列实现

```java
class MyStack2 {

	Queue<Integer> queue;

	/**
	 * Initialize your data structure here.
	 */
	public MyStack2() {
		queue = new LinkedList<Integer>();
	}

	/**
	 * Push element x onto stack.
	 */
	public void push(int x) {
		queue.add(x);
		int size = queue.size();
		while (size > 1) {
			queue.add(queue.poll());
			size--;
		}
	}

	/**
	 * Removes the element on top of the stack and returns that element.
	 */
	public int pop() {
		return queue.poll();
	}

	/**
	 * Get the top element.
	 */
	public int top() {
		return queue.peek();
	}

	/**
	 * Returns whether the stack is empty.
	 */
	public boolean empty() {
		return queue.isEmpty();
	}


}
```

