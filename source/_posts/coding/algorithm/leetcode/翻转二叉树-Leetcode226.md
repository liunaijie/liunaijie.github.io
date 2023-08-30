---
title: 翻转二叉树—LeetCode226
date: 2019-11-01 10:13:30
tags: 
	- leetcode
	- java

---

# 题目描述

> 翻转一棵二叉树。
>
> **示例：**
>
> 输入：
>
> ```
>      4
>    /   \
>   2     7
>  / \   / \
> 1   3 6   9
> ```
>
> 输出：
>
> ```
>      4
>    /   \
>   7     2
>  / \   / \
> 9   6 3   1
> ```

# 代码实现

```java
public TreeNode invertTree(TreeNode root) {
    if (root == null) {
        return null;
    }
    TreeNode right = invertTree(root.right);
    TreeNode left = invertTree(root.left);
    root.left = right;
    root.right = left;
    return root;
}
```



