---
title: 最小的k个数-LeetCodeM40
date: 2020-04-13 12:29:33
tags:
  - 算法与数据结构
  - 算法与数据结构/Leetcode
related-project: "[[Blog-Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

> 输入整数数组 arr ，找出其中最小的 k 个数。例如，输入4、5、1、6、2、7、3、8这8个数字，则最小的4个数字是1、2、3、4。 
>
> 示例 1：
>
> 输入：arr = \[3,2,1], k = 2
> 输出：\[1,2] 或者 \[2,1]
> 示例 2：
>
> 输入：arr = \[0,1,2,1], k = 1
> 输出：\[0]
>
>
> 限制：
>
> 0 <= k <= arr.length <= 10000
> 0 <= `arr[i]` <= 10000

给定一个数组，找出最小的k个数，对这k个数的大小顺序没有要求。

# 解题思路

这个题目我最开始的想法是用堆来解决的，但我解答完成看题解的时候发现了一种做法：

排序后取前k个元素

在评论区中有很多人在讨论这一种解法，虽然的他复杂度比较高，实现方式很简单，有一些专业人士在鄙视这种做法，也有一些人说这个题目的难度是简单，所以用这个也没什么问题。我的看法是支持这种做法，并不因为他的难度级别，而是解决问题的思路。在解决问题的时候每一种思路都是可取的。

<!--more-->

## 排序

```java
public int[] getLeastNumbersSort(int[] arr, int k) {
  Arrays.sort(arr);
  int[] result = new int[k];
  System.arraycopy(arr, 0, result, 0, k);
  return result;
}
```

对于数据先进行排序，然后取前k个元素返回即可。这个解决思路简单，代码简洁易懂，但复杂度高。

## 堆

由于我们要获取的是最小的k个值，使用堆的时候构建一个大顶堆，至于为什么不构建一个小顶堆在后面实现的部分会进行描述。

我们来分析一下这个堆要做的一些事情：

1. 我们建立一个`k`大小的堆

2. 前`k`个元素按照堆的定义直接插入。
3. 数量超过k时，先与堆顶元素进行比较，由于是大顶堆，所以堆顶元素是堆内的最大值。如果当前值比堆顶值小，则说明此元素需要保留，将堆顶元素删除。如果比堆顶值大，说明这个值不是我们要查找的值进行丢弃。
4. 将值插入到堆中
5. 数组全部插入完成后，将堆返回

用代码来实现：

```java
private class M40HeapHelp {
  //存储堆的数组
  private int[] heap;
  //数组中存储的元素数量
  private int count;
  //堆的数量，即元素最大存储数量
  private int length;

  public M40HeapHelp(int capacity) {
    this.heap = new int[capacity + 1];
    count = 0;
    length = capacity;
  }


  public void add(int val) {
    ...
     //需要判断是否超过最大存储数量
     //超过数量后判断val是否需要插入到堆中
  }

  public void removeTop() {
		...
  }

  public int[] getHeap() {
    ...
  }
}
```

这里的删除堆顶元素和获取堆数组方法我在堆的那一篇文章中写过，在此处没有什么区别，直接拿过来。

这里需要改动的地方是添加元素的方法。要判断容量，容量超过后判断插入条件。

我这里将代码写出来，

```java
public void add(int val) {
  if (count >= length) {
    //当堆内元素超过最大值后进行判断
    if (val < heap[1]) {
      //如果要插入的元素比堆内的最大值小，则将最大值删除，后面将值进行插入
      removeTop();
    } else {
      //否则直接返回
      return;
    }
  }
  addVal(val);
}

private void addVal(int val) {
  //数量加一
  ++count;
  //将值添加到最后一个位置
  heap[count] = val;
  //此时可能破坏了堆的规则，所以需要重新建堆
  int i = count;
  //判断是否需要与父节点进行替换
  while (i / 2 > 0 && heap[i] > heap[i / 2]) {
    //首先是数组越界判断，然后判断当前节点是否比父节点大，如果大则需要替换
    int temp = heap[i / 2];
    heap[i / 2] = heap[i];
    heap[i] = temp;
    //然后向上继续判断
    i = i / 2;
  }

}
```

使用堆来实现的完整代码如下：

```java
public int[] getLeastNumbersHeap(int[] arr, int k) {
  if (k == 0 || arr.length == 0) {
    return new int[0];
  }
  M40HeapHelp heap = new M40HeapHelp(k);
  for (int i : arr) {
    heap.add(i);
  }
  return heap.getHeap();
}

private class M40HeapHelp {
  private int[] heap;
  private int count;
  private int length;

  public M40HeapHelp(int capacity) {
    this.heap = new int[capacity + 1];
    count = 0;
    length = capacity;
  }


  public void add(int val) {
    if (count >= length) {
      //当堆内元素超过最大值后进行判断
      if (val < heap[1]) {
        //如果要插入的元素比堆内的最大值小，则将最大值删除，后面将值进行插入
        removeTop();
      } else {
        //否则直接返回
        return;
      }
    }
    addVal(val);
  }

  private void addVal(int val) {
    //数量加一
    ++count;
    //将值添加到最后一个位置
    heap[count] = val;
    //此时可能破坏了堆的规则，所以需要重新建堆
    int i = count;
    //判断是否需要与父节点进行替换
    while (i / 2 > 0 && heap[i] > heap[i / 2]) {
      //首先是数组越界判断，然后判断当前节点是否比父节点大，如果大则需要替换
      int temp = heap[i / 2];
      heap[i / 2] = heap[i];
      heap[i] = temp;
      //然后向上继续判断
      i = i / 2;
    }

  }

  public void removeTop() {
    if (count <= 0) {
      //堆内没有元素
      return;
    }
    //将堆内的最后一个元素放到最大值位置上，
    heap[1] = heap[count];
    //数量减一
    --count;
    //这时堆可能不满足堆的规则，需要进行重新建堆
    rebuildHeap(heap, count, 1);
  }

  private void rebuildHeap(int[] a, int n, int i) {
    while (true) {
      //当前节点的数据可能比子节点的数据大，所以与两个子节点对比，找到最大值后进行替换
      int maxPos = i;
      //需要注意不能下标越界
      if (i * 2 <= n && a[i] < a[i * 2]) {
        maxPos = i * 2;
      }
      //先判断左子节点，然后判断左子节点与右子节点的大小
      if (i * 2 + 1 <= n && a[maxPos] < a[i * 2 + 1]) {
        maxPos = i * 2 + 1;
      }
      if (maxPos == i) {
        //如果父节点比两个子节点都大，则不需要替换满足条件，直接返回
        break;
      }
      //将父节点与最大子节点进行替换
      int temp = a[i];
      a[i] = a[maxPos];
      a[maxPos] = temp;
      //然后递归判断子节点是否满足条件，直到满足条件后退出
      i = maxPos;
    }
  }

  /**
		 * 返回堆的内容，由于堆是从1开始存放，所以将结果重新放到新数组中，从0开始放。
		 */
  public int[] getHeap() {
    int[] result = new int[count];
    System.arraycopy(heap, 1, result, 0, count);
    return result;
  }

}
```

这里使用大顶堆而不是小顶堆的元素是：大顶堆的堆顶元素是堆内的最大值，我们要保留小的元素，所以直接与最大值比较即可，如果比最大值大则丢弃，小则保留。

而如果使用小顶堆，堆顶元素是最小值，当我们判断元素是否需要保留时无法使用堆顶元素，在不排序的情况下也无法保证最后一个元素是最大值。如果采用小顶堆还需要将小顶堆排序取堆内最大值然后比较。实现和复杂度都比大顶堆复杂。

## 快排思想

这个题目还可以利用快排的思想来解决。首先我们来复习一下快排的过程：

1. 对于全部数组找到一个分区点，将小于分区点的元素移动到左侧，大于分区的元素移动到右侧。
2. 从分区点开始，分为两个数组，左侧和右侧在递归调用
3. 当数组不能再拆分后退出，此时已经完成排序

我们看一下第一步的结果是不是与这道题的要求比较相似。如果分区点左侧的元素有k个。那么我们就可以将分区点左侧的元素进行返回。

如果左侧元素小于k个，我们就需要向右侧移动。否则向左侧移动。

在实际编码过程中，分区点返回的是下标，那么我们只要满足`index=k-1`就表示找到了结果。

用代码实现以下：

```java
public int[] getLeastNumbersQuickSort(int[] arr, int k) {
  if (k == 0 || arr.length == 0) {
    return new int[0];
  }
  //由于返回的是元素下标，所以为长度-1
  return quickSortHelp(arr, 0, arr.length - 1, k - 1);
}

private int[] quickSortHelp(int[] arr, int left, int right, int k) {
  //快排是用到了分区点这个概念，会将小于分区点的元素放到左边，大于分区点的元素放到右边。
  //如果分区点左边的元素是k个或k-1个，那么我们就获取到了最小的k个元素
  int[] result = new int[k];
  int partition = partition(arr, left, right);
  if (partition == k) {
    System.arraycopy(arr, 0, result, 0, k);
    return result;
  }
  //当元素数量小于k时，我们需要向右分，当数量大于k时需要向左分，直到获取到k个元素
  return partition > k ? quickSortHelp(arr, left, partition - 1, k) : quickSortHelp(arr, partition + 1, right, k);
}


private int partition(int[] a, int left, int right) {
  //设置分区点为数组最后一个元素
  int pivot = a[right];
  //开始分区
  int i = left;
  for (int j = left; j < right - 1; j++) {
    //从左向右找到比分区点小的元素
    // 找到下标为j，将他从i开始向右放，找到后较
    if (a[j] < pivot) {
      //如果元素比分区点小，则将元素从左侧开始放，将原来左侧的数据换到现在这个位置上
      //i表示左侧的位置，交换后就加一
      swap(a, i, j);
      i++;
    }
  }
  //最后将分区点放到对应位置上
  //交换后，i左侧为比分区点小的元素，右侧为比分区点大的元素
  swap(a, i, right);
  return i;
}

private void swap(int[] a, int first, int second) {
  int temp = a[first];
  a[first] = a[second];
  a[second] = temp;
}
```



## 总结

在三种解决思路中，使用快排的方法是实现最高效的，但是如果没有一定的练习或许想不到这样的解题思路。

而第一种排序后取前k个元素的做法虽然效率低，但是我的想法是这种解决的思路一定不要忘了，有时候一件事件的解决方法不要想的过于复杂，有时候想多了也不见得会好。