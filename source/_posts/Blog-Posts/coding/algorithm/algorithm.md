---
title: 算法与数据结构
date: 2019-10-15 10:01:10
categories:
  - - coding
    - algorithm
tags:
  - 算法与数据结构
---

最近在看极客时间覃超的[《算法面试通关 40 讲》](https://time.geekbang.org/course/intro/100019701)，也一起看了一些数据结构，正好在这里进行一下整理。

主要分为数据结构和算法两大章节，每个章节里面都会先结合自己的理解对它的定义进行一下解释，然后会拿出例题来进行实战。

# 数据结构

## [数组](https://www.liunaijie.top/2019/10/15/算法与数据结构/数组/)

## [链表](https://www.liunaijie.top/2019/10/15/算法与数据结构/链表/)

## 队列

先入先出（first in first out FIFO）

习题：[用栈实现队列](https://www.liunaijie.top/2019/11/24/LeetCode/用栈实现队列-LeetCode232/)

### 普通队列

### 优先队列

## 堆栈

后入先出(last in first out LIFO)

习题：[用队列实现栈](https://www.liunaijie.top/2019/11/24/LeetCode/用队列实现栈-LeetCode225/)

## 树

链表是一种特殊的树，当每个链表节点的链表变成多个时就变成了树



### 二叉搜索树（binary search tree BST）

性质：

- 左子树上所有节点的值均小于它的根节点的值
- 右子树上所有节点的值均大于它的根节点的值；
- 左，右子树也分别满足以上性质

[AVL,红黑树学习](https://www.liunaijie.top/2019/12/09/算法与数据结构/AVL，红黑树学习)

### 红黑树

[手写红黑树的简单实现](https://www.liunaijie.top/2019/12/24/算法与数据结构/手写红黑树的简单实现)

### B 树

![B树](https://raw.githubusercontent.com/liunaijie/images/master/B树.png)

### B+树

![B+树](https://raw.githubusercontent.com/liunaijie/images/master/B%2B树.png)

MySQL 的 Innodb 中使用的索引就是采用的 B+树的数据结构进行存储的。

<!--more-->

### 字典树

### 图

由于没有用到，暂时也不去做深入的了解。

附图：来自[https://www.bigocheatsheet.com/](https://www.bigocheatsheet.com/)的一张不同数据结构在不同情况下的查找，新增等操作的时间复杂度

![不同数据结构的时间复杂度](https://raw.githubusercontent.com/liunaijie/images/master/big-o-cheat-sheet-poster.png)

# 算法

## 排序

### 冒泡排序

```java
/**
*冒泡排序
*比较相邻的两个元素，如果第一个比第二个大则将两个交换顺序
*i<numbers.length 控制排序轮数 一般为数组长度减1次，因为最后一次循环只剩下一个数组元素，不需要对比，同时数组已经完成排序了
*j<numbers.length-i  因为经过一个排序后，最大（或最小）的元素都已经放到了数组的最后一位，下次不用再进行比较。所以长度改变
*/
public void bubbleSort(int[] numbers){
    for(int i=1;i<numbers.length;i++){
        for(int j=0;j<numbers.length-i;j++){
            if(numbers[j]>numbers[j+1]){
                int temp=numbers[j];
                numbers[j]=numbers[j+1];
                numbers[j+1]=temp;
            }
        }
    }
}
```

### 快速排序

### 选择排序

首先找到数组中最小的元素，其次，将它与数组第一个元素交换位置

然后，在剩下的元素中找到最小的元素，将它与数组第二个元素交换位置

```java
public void selectSort(int[] array){
    int N = array.length;
    for(int i=1;i<N;i++){
       int minIndex =i;
        for(int j=i+1;j<N;j++){
            if(array[j]<array[minIndex]){
                minIndex=j;
            }
        }
        int temp=array[minIndex];
        array[minIndex]=array[i];
        array[i]=temp;
    }
}
```

不会访问索引左侧的元素（j++）

需要 N 次交换，(n-1)+(n-2)+...+2+1 ≈ (N^2^)/2 次比较

数组有序或者混乱时的速度完全一致。

### 直接插入排序

将数组中的元素依次与前面已经排好序的元素相比较，如果选择的元素比已排序的元素小，则交换。

```java
public void sore(int[] nums){
    int N=nums.length;
	for(int i=1;i<N;i++){
        for(int j=i;j>0;j--){
            if(nums[j]<nums[j-1]){
                int temp = nums[j];
                nums[j] = nums[j-1];
                nums[j-1]=nums[j];
            }
        }
    }
}
```

不会访问索引右侧的元素（j--）

当数组有序时比混乱时速度快。

## 查找

### 二分查找

### 广度优先遍历（BFS)

打个比方，给出父节点后对树进行遍历，使用 bfs 先去遍历完所有的子节点，再去遍历所有的孙子节点，然后这样一层一层的进行遍历。

[树的几种遍历方式](https://www.liunaijie.top/2020/03/03/算法与数据结构/树的几种遍历方式/#广度优先遍历)

### 深度优先遍历（DFS）

  [树的几种遍历方式](https://www.liunaijie.top/2020/03/03/算法与数据结构/树的几种遍历方式/#深度优先遍历)

## LRU 算法

最近最少使用（least recently used）

[用单链表简单实现LRU算法](https://www.liunaijie.top/2020/02/26/算法与数据结构/用单链表简单实现LRU算法/)

## 递归

## 分治

将一个大问题，分隔成许多小问题，然后小问题的答案组合成大问题最终的答案。

## 位运算

| 符号 | 描述 | 运算规则                                   |
| ---- | ---- | ------------------------------------------ |
| &    | 与   | 两个位都为 1 时，结果为 1                  |
| \|   | 或   | 两个位都为 0 时，结果为 0                  |
| ^    | 异或 | 两个位相同位为 0，相异为 1                 |
| ~    | 取反 | 0 变 1，1 变 0                             |
| <<   | 左移 | 将二进位全部左移若干位，高位丢弃，低位补 0 |
| >>   | 右移 | 二进位全部右移若干位，对无符号数，高位补 0 |

再记录一些高级的位运行：

- x&1 == 1 or ==0 判断奇偶性
- x=x&(x-1) 清零最低位的 1
- x&-x 得到最低位的 1
- 将 x 最右边的 n 位清零 `x&(~0<<n)`
- 获取 x 的第 n 位值 `(x>>n)&1`
- 获取 x 的第 n 位的幂值 `x&(1<<(n-1))`
- 将第 n 位设置为 1 `x|(1<<n)`
- 将第 n 为设置为0 `x&(~(1<<n))`
- 将 x 最高位至第 n 位（含）清零 `x&((1<<n)-1)`
- 将第 n 位至第 0 位（含）清零 `x&(~((1<<(n+1))-1))`

## 贪心算法

只取当前的最优解，这个解可能并不是最终的最终解。

比如我们有18 块钱，然后拆分成最少的金额张数，金额面值分别是 10元，9元，1元。如果使用贪心算法第一次会先使用一张10元的(这是第一次的最优解)，然后再 8 张 1 元的(还剩8元，不够9元)。但是最少的拆分方法是两张 9 元的。所以使用贪心算法有可能并不是全局最优解。

## 动态规划

## [布隆过滤器（Bloom Filter）](https://www.liunaijie.top/2019/10/15/算法与数据结构/布隆过滤器/)

