---
title: 如何将多个git commit合并成一个
date: 2021-07-04
categories:
  - publish
tags:
  - git
---
这篇文章记录下使用`Git`时的一些进阶操作, 命令.

# 合并多个Commit
在开发过程中, 有时代码的测试无法在本地进行, 需要提交代码, 而测试流程又可能会反复多次进行, 那么就有可能在最后完成时提交记录中出现很多个提交记录.
我们可以将这些提交记录进行合并, 从而可以使得提交记录变得更加感觉, 整洁, 可追踪.
- IDE合并
我当前使用的是`IDEA`, 在编辑器里的`Git`页面里就可以任意选择`commit`进行合并.
选择所需要合并的`commit`后, 右键选择`Squash Commits...`, 然后在弹出页面中编辑提交信息后, 就可以完成合并了
- 命令行合并
我们也可以在命令行中进行合并, 使用`rebase`命令
具体步骤为:
1. 获取要合并的`commit`的前一个`commit id`
2. 运行`git rebase -i <pre_commit_id>
3. 在弹出的页面中, 对我们所需要合并的`commit`, 修改前面的信息, 将`pick`修改为`s`或`squash` ，保存退出
![https://raw.githubusercontent.com/liunaijie/images/master/Untitled_1.png](https://raw.githubusercontent.com/liunaijie/images/master/Untitled_1.png)
4. 保存退出后, 进入修改`commit`信息的页面, 修改为最终要记录的`commit`信息, 保存退出


# 拆分commit
有时候在一个commit内掺杂了多个不同模块的改动, 希望将一次commit提交信息中的多个文件改动提交为不同的commit, 这时就需要用到拆分commit
首先获取到要拆分的commit的前一个commit id
```shell
git log --oneline
```
获取到前一个commit之后, 运行
```shell
git rebase -i <pre_commit_id>
```
在显示页面将需要拆分的commit, 前面的`pick`修改为`e` (即 edit)
然后保存退出
执行
```shell
git reset HEAD~
```
执行完上面的命令就可以看到我们要拆分的commit中的信息已经被添加到修改区.
重新将每个文件分别进行提交即可

将所有文件提交完成后, 执行
```shell
git rebase --continue
```

# Hook文件
在`.git/hook`下有一些文件, 这些文件会在相应的动作执行前运行, 例如当我们需要我们的代码进行格式化之后才能提交, 可以新建`pre-commit`文件
里面的内容为:
这里给出的例子为: 
使用gradle的spotless进行代码格式检查, 当代码格式不满足时, 会自动进行格式化并且进行提交
```Shell
./gradlew spotlessCheck
result=$?
if [[ "$result" = 0 ]] ; then
	exit 0
else

echo "
	....
	will auto update code style and commit it
	....
	"
	./gradlew spotlessApply
	git add .
	exit 0
fi
```
也可以新建`commit-msg`文件, 在这个文件中对提交的commit信息格式进行检查.

注意, 这些文件都需要给予可执行权限.
