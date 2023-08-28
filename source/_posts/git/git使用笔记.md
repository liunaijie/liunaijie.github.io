---
title: git使用笔记
date: 2019-05-29 10:18:45
toc: true
categories: 
	- [code, tool]
tags: 
	- git
---

# 安装

## mac

### 通过`brew`安装

```shell
brew install git
```



###  通过安装包安装

去官网下载mac系统的安装包，下载完成后安装即可

## windows

去官网下载Windows系统的安装包，除了选择安装目录时修改为自己想要的目录，其他一直点击next即可

# 配置

安装完git后我们需要配置个人信息，姓名和邮箱，这些信息在以后提交时都会显示在提交信息中

```shell
# 全局配置 整体有效
git config --global user.name "提交时显示的名字"
git config --global user.email "提交时显示的邮箱"
# 局部配置 对单个项目有效，如果进行了局部配置，会覆盖全局配置
git config --local user.name "提交时显示的名字"
git config --local user.email "提交时显示的邮箱"
```

配置完成后我们可以通过命令来查看我们的配置信息，例如下面这就会显示我们配置的名称

```shell
git config user.name
```

<!-- more -->



# 常用命令

## 初始化

```shell
git init
```



## 添加文件

```shell
git add test.md
```



## 提交注释

```shell
git commit -m '注释内容'
```

## 关联远程仓库

```shell
git remote add [shortname] [url]	
```

## 查看当前的远程库

```shell
git remote
origin
# 也可添加 -v 选项 显示对应的克隆地址
git remote -v

origin  git://github.com/schacon/ticgit.git (fetch)
origin  git://github.com/schacon/ticgit.git (push)
```



# 推送到远程仓库

```shell
# remote-name默认为origin ，branch-name默认为master
git push [remote-name] [branch-name]
```

# 从远程仓库拉取代码

```shell
git pull
```



# 修改注释

这个主要分为以下几种情况

-   修改未推送到远程分支的上一次注释
-   修改已经推送到远程分支上的上一次注释
-   修改历史提交过的注释
-   修改已经推送到远程分支上的历史注释

1.  先来看修改最近一次提交的注释  

使用`git commit --amend`命令  

![](https://raw.githubusercontent.com/liunaijie/images/master/20190828172200.png)

然后再出来的编辑页面，编辑注释信息，然后保存  

2.  修改历史提交的注释

首先使用`git rebase -i HEAD~5`，这里的5表示向前推5次。

![](https://raw.githubusercontent.com/liunaijie/images/master/20190828172433.png)

然后在出来的页面中选择要修改从那一次，将前面的`pick`修改为`edit`。然后保存退出。  

这是再次执行`git commit --amend`就会修改我们刚刚选择的那个注释了，修改完成后保存。  

这时查看我们刚刚修改的那个变成了日志的最后一次提交了，所以我们要将其修改回原来的时间状态。  

使用`git rebase --continue`命令即可  

3.  这时如果之前的提交注释都没有推送到远程上就完成了，但是如果推送到远程上，还需要将我们的注释修改推送到远程。

使用`git push --force`强制推送，这时要注意我们这时候推送上去的会覆盖原来的代码，所以最好在提交之前做一次拉取更新。

## 删除关联远程仓库

```shell
git remote rm [orgin_name]
```



# 参考

[https://git-scm.com/book/zh/v1/Git-%E5%9F%BA%E7%A1%80-%E8%BF%9C%E7%A8%8B%E4%BB%93%E5%BA%93%E7%9A%84%E4%BD%BF%E7%94%A8](https://git-scm.com/book/zh/v1/Git-基础-远程仓库的使用)