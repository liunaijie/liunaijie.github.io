---
title: 两数相加-LeetCode2
date: 2019-08-20 16:17:51
categories: "leetcode"
toc: true
tags: 
	- leetcode
	- java
---

# 题目描述

>给出两个 非空 的链表用来表示两个非负的整数。其中，它们各自的位数是按照 逆序 的方式存储的，并且它们的每个节点只能存储 一位 数字。
>
>如果，我们将这两个数相加起来，则会返回一个新的链表来表示它们的和。
>
>您可以假设除了数字 0 之外，这两个数都不会以 0 开头。
>
>示例：
>
>输入：(2 -> 4 -> 3) + (5 -> 6 -> 4)
>输出：7 -> 0 -> 8
>原因：342 + 465 = 807

<!--more-->

# 题目解析

给了两个链表，每个链表中的节点是数字中的一位数，将这两个链表的数相加后再返回一个链表。  

刚开始的思路是： 将第一个链表转换成数字1，第二个链表转换成数字2，两者相加得到数字3。最后将数字3转换为链表进行返回。  

写了一下运行的时候发现超时了，那这个方法就不行了。  

那就继续想优化的思路吧。  

他现在给出的是每一位上的数值，我们可以利用小学的竖式来计算，个位加个位，十位加十位的这种方式。这种情况下还要考虑进位的问题。

<!--more-->

# 代码解答

我看了解答区有一种解答思路是先创建一个节点，然后返回值执行该节点的下一个节点。也就是说会多创建一个节点。先来看这种代码：

```java
public ListNode addTwoNumbers2(ListNode l1, ListNode l2) {
   	// 定义一个节点，初始化值为0
    ListNode node = new ListNode(0);
    ListNode curr = node;
    // 进位存储的值
    int carry = 0;
    while (l1 != null || l2 != null) {
        // 获取两个链表当前位的元素，如果为空则用0代替。
        int val1 = l1 == null ? 0 : l1.val;
        int val2 = l2 == null ? 0 : l2.val;
        // 计算的时候还要加上之前的进位值
        int sum = val1 + val2 + carry;
        // 计算进位的值，不需进位时为0，需要时为1
        carry = sum / 10;
        // 得到这个位的数值
        sum = sum % 10;
        // 直接创建新节点并且将第一个节点的下一个节点指向新节点
        curr.next = new ListNode(sum);
        curr = curr.next;
        if (l1 != null) {
            l1 = l1.next;
        }
        if (l2 != null) {
            l2 = l2.next;
        }
    }
    // 如果还需要进位 （53+61=104）
    if (carry == 1) {
        curr.next = new ListNode(carry);
    }
	// 返回的时候要返回初始化节点的下一个节点开始
    return node.next;
}
```

这样其实最终得到的链表结构最开始会有一个值为`0`的节点，然后由于返回的是从第二个节点开始，所以对整体运行结果没关系。   

我写的代码主要是在中间放值的时候进行了修改，将计算出来的当前位的值给当前的节点而不是给下一个节点。只有没计算完成时再去关联下一个节点。ps：如果没有这个判断，我们也会多一个节点，不过是在最后的时候多一个，而且在结果中也会有展示。（7->0->8）会变成(7->0->8->0)。返回结果的时候也不用返回初始化节点的下一个节点，直接返回初始化节点即可。

```java
public ListNode addTwoNumbers(ListNode l1, ListNode l2) {
    
    ListNode node = new ListNode(0);
    ListNode curr = node;
    
    int carry = 0;
    while (l1 != null || l2 != null) { 
        int val1 = l1 == null ? 0 : l1.val;
        int val2 = l2 == null ? 0 : l2.val;
        int sum = val1 + val2 + carry;
        carry = sum / 10;
        sum = sum % 10;
		// 将当前节点的值更改为 计算得到的值
        curr.val = sum;
        if ((l1 != null && l1.next != null) || (l2 != null && l2.next != null)) {
            // 如果都已经计算完了就不再创建下一个节点
            // 如果还需要计算就再新建一个节点 初始化值为0 将这个节点的下个节点执行这个新节点，再将当前操作的节点替换为新建的节点
            curr.next = new ListNode(0);
            curr = curr.next;
        }
        if (l1 != null) {
            l1 = l1.next;
        }
        if (l2 != null) {
            l2 = l2.next;
        }
    }
    
    if (carry == 1) {
        curr.next = new ListNode(carry);
    }
    return node;
}
```

这两个程序都跑了一下：第一个程序耗时：10ms，内存消耗：47.9MB。第二个程序耗时：5ms，内存消耗43.8MB。