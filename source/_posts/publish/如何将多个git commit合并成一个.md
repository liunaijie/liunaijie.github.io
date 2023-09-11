---
title: 如何将多个git commit合并成一个
date: 2021-07-04 11:18:23
categories:
- [publish, coding, devops]
tags: 
- git
---

# 如何将多个git commit合并成一个

在日常开发过程中，有一些代码无法在本地测试，需要放到线上环境测试，而这个测试过程就可能产生很多个commit，有时候就会出现一次commit只修改一行代码，然后有很多次commit的记录，当我们需要把这个代码合并到master进行release时，就会显得很难看，所以这篇文章就记录一下如何将多个commit合并成一个

# 场景重现

我对一个文件进行初始化后，分别进行了三次修改和提交，每次提交都是在后面添加一行信息

![https://raw.githubusercontent.com/liunaijie/images/master/20210704115926.png](https://raw.githubusercontent.com/liunaijie/images/master/20210704115926.png)

现在需要将这三次的提交记录合并成一个

<!--more-->

# 合并过程

首先使用`git log` 命令获取到我们要恢复到的`commit id` ，这里是需要将init记录保留，后续的三个合并成一个，所以我们需要的id是`d4417` 

![https://raw.githubusercontent.com/liunaijie/images/master/Untitled.png](https://raw.githubusercontent.com/liunaijie/images/master/Untitled.png)

然后执行命令：`git rebase -i d4417`，出现下面这样的页面，出现了我们提交过的三次commit，对于第一次commit我们无需改动，对于后面两个commit，我们将前面的`pick`修改为`s`或`squash` ，保存退出

![https://raw.githubusercontent.com/liunaijie/images/master/Untitled_1.png](https://raw.githubusercontent.com/liunaijie/images/master/Untitled_1.png)

保存退出后得到如下的页面，这个页面就是需要我们修改我们提交记录的commit，由于我是需要将这三个记录合并成一个，所以我将这三次提交注释删掉后修改为`merged commit` 

![https://raw.githubusercontent.com/liunaijie/images/master/Untitled_2.png](https://raw.githubusercontent.com/liunaijie/images/master/Untitled_2.png)

 至此已经修改完成，我们可以通过`git log`来验证我们的结果

![https://raw.githubusercontent.com/liunaijie/images/master/Untitled_3.png](https://raw.githubusercontent.com/liunaijie/images/master/Untitled_3.png)

# 撤销

当合并出现错误时，我们可以使用`git rebase —abort` 命令来取消这次的合并操作