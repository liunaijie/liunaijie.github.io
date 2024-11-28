---
title: 二叉树的锯齿形层次遍历-LeetCode103
date: 2020-03-31 09:34:50
tags:
  - 算法与数据结构/二叉树
  - 算法与数据结构/Leetcode
related-project: "[[Blog Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

> 给定一个二叉树，返回其节点值的锯齿形层次遍历。（即先从左往右，再从右往左进行下一层遍历，以此类推，层与层之间交替进行）。
>
> 例如：
> 给定二叉树 \[3,9,20,null,null,15,7],
>
> ```
>  	  3
>    / \
>   9  20
>     /  \
>    15   7
> ```
>
> 返回锯齿形层次遍历如下：
>
> ```
> \[
>   \[3],
>   \[20,9],
>   \[15,7]
> ]
> ```

所谓的锯齿形遍历，即是在第一层从左向右遍历，在第二层从右向左遍历，依次遍历完成。

<!--more-->

# 解题思路

我们将从根节点开始从0开始计数，那么就是在偶数层从左向右遍历，在奇数层从右向左遍历，如果我们能得到每一层的节点，那么在奇数层从后向前取，在偶数层从前向后取。

如果能做到从两端取值呢？我这里使用了双向链表`LinkedList`。

我们在遍历第n层时，要将这一次的数据放到结果集中，还要将下一次的节点按照先后顺序放到链表中。以上面的例子为例，在遍历第0层时，下一次的节点要按照(9,20)这样的顺序，在遍历第1层时，下一层的顺序要按照(15,7)这样的顺序。

这样就可以在每一层遍历开始前得到这一层的节点数量，然后对这一层的节点进行遍历。

我们如何保证在遍历节点时让下一层的节点按照我们想要的顺序呢？

看上面的例子，在第一层我们先获取`20`节点，这时先放了`15,7`这两个节点，如果`9`节点还有子节点那么我们要保证`9`节点的数据在`20`节点的数据之前。

除此之外，在每一层遍历时虽然得到了这一层节点的数量，但是我们并不是一次将他们全部取出，而这时子节点也需要放到链表中。我们要保证子节点不能与当前层的数据混合。

我使用了一个更加复杂一些的例子花了一个流程图，看完这个应该能更好理解：

![](https://raw.githubusercontent.com/liunaijie/images/master/leetcode-103.png)

**代码实现：**

```java
public List<List<Integer>> zigzagLevelOrder(TreeNode root) {
  if (root == null) {
    return Collections.emptyList();
  }
  List<List<Integer>> result = new ArrayList<>();
  LinkedList<TreeNode> queue = new LinkedList<>();
  queue.addFirst(root);
  int level = 0;
  while (!queue.isEmpty()) {
    int size = queue.size();
    List<Integer> con = new LinkedList<>();
    if (level % 2 == 0) {
      for (int i = 0; i < size; i++) {
        TreeNode node = queue.pollFirst();
        con.add(node.val);
        if (node.left != null) {
          queue.addLast(node.left);
        }
        if (node.right != null) {
          queue.addLast(node.right);
        }
      }
    } else {
      for (int i = 0; i < size; i++) {
        TreeNode node = queue.pollLast();
        con.add(node.val);
        if(node.right!=null){
          queue.addFirst(node.right);
        }
        if(node.left!=null){
          queue.addFirst(node.left);
        }
      }
    }
    result.add(con);
    level++;
  }
  return result;
}
```

这里是先从左到右，然后从右到左的顺序。如果题目要求先从右到左，在从左到右的顺序。可以在代码中将`pollLast`与`pollFirst`进行交换即可。