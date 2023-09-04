---
title: git fork后如何与原仓库同步
date: 2020-05-08 21:08:39
categories:
- [coding, devops]
tags: 
- devops/git
---

# 背景

当参与到开源项目开发后，我们需要先将代码fork到自己的仓库，对代码进行修改后再提交pr。

如果在这中间原仓库有提交过代码，我们这边是无法得知的，所以我们需要在提pr前先进行merge操作，先将原仓库的内容更新下来再进行提交。

大体流程如下所示：
![](https://raw.githubusercontent.com/liunaijie/images/master/git%20fork.png)

<!--more-->



# 实现

首先打开代码所在文件目录，然后打开终端：

执行命令：

```shell
git remote -v
```

当我们没有进行操作前，它会显示如下的内容：

```shell
origin	git@****自己仓库的地址.git (fetch)
origin	git@****自己仓库的地址.git (push)
```

然后这时我们需要添加原仓库的地址，执行如下命令：

```shell
git remote add upstream git@***原仓库地址.git
```

执行命令后，没有任何响应，我们需要再次执行`git remote -v`，这是显示出来的信息与之前的发生了变化：

```shell
origin	git@****自己仓库的地址.git (fetch)
origin	git@****自己仓库的地址.git (push)
upstream	git@***原仓库地址.git (fetch)
upstream	git@***原仓库地址.git (push)
```

这时我们就将原仓库地址关联到我们的项目中。

当我们本地开发完成后，可以先从自己`fork`出来的仓库中进行更新，执行：

```shell
//先拉取原仓库的代码
git fetch upstream
//然后将当前分支与 upstream/master分支合并，分支可以更改
git merge upstream/master
```

这里是先将原仓库的更新拉取下来，然后在当前分支上`merge`原仓库的代码，原仓库使用的分支是`master`，可以自行修改成所需要merge的分支。

这时就可以将原仓库的更改拉取到我们的仓库，执行`git push`将变动推送到我们自己的仓库。



这时再去提`pr`就可以了，现在我们fork出来的仓库与原仓库的区别只有我们更改的文件。