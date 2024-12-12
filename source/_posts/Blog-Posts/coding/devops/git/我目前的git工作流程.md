---
title: 我目前的git工作流程
date: 2020-06-20
categories:
  - notes
tags:
  - git
---

好久没写博客了。。。

记录一下我在现在公司的一个git工作流程。

我之前使用git是不同用户在同一个git仓库下进行操作，而现在是使用fork出自己的仓库，通过提pr的方式来进行提交代码。

<!--more-->

通过`git fork`操作后，自己的账号下就有了一个仓库，本地下载后又会出现一个本地仓库，这时一个有：

- 原仓库
- 远程仓库
- 本地仓库

我在这里分别给它们以代号，原仓库为（upstream），远程仓库为（origin），本地仓库为（local）

![](https://raw.githubusercontent.com/liunaijie/images/master/1592655787033.jpg)



1. 在本地开发时，从`upstream`的`master`分支中切出一个分支，在这个基础上进行开发。

2. 开发完成需要进行测试时，本地切换到`stg`分支，从`upstream`的`stg`分支中拉取最新的代码，然后再`merge`本地的其他分支，这一步就将冲突全部放在本地进行解决，避免在提交pr时与原仓库存在冲突。

3. 将本地的`stg`分支提交到远程仓库`origin`的`stg`分支上。

4. 提交pr，`merge`后就可以拿`upsteam`的`stg`分支进行测试。

	

	当测试完成后，基本按照刚才的流程进行`master`的提交操作。

1. 本地切换到`master`分支，从`upsteam`中拉取最新的代码
2. `merge`开发完成的`feature`分支，如果有冲突本地解决。
3. 提交到`origin`的`master`分支
4. 提交pr，完成merge后，任务开发完成。

在这个流程中，`origin`的仓库只是起到一个中间的作用，并且在本地处理冲突，可以避免在GitHub上处理冲突时，造成