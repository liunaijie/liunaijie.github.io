---
title: 卸载oracle
date: 2018-05-07 14:04:12
toc: true
tags: 
	- oracle
---

由于Oracle安装之后卸载并不简单，所以将自己这几天的经验总结一下。
首先将计算机服务中的Oracle服务停掉。

![计算机管理](https://raw.githubusercontent.com/liunaijie/images/master/70.png)
将Oracle开头的都停止。
然后是将服务文件删除。
在运行窗口输入`regedit`，打开注册表。然后展开HKEY_LOCAL_MACHINE\SOFTWARE，找到oracle，删除。
找到HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services中，删除所有oracle开头的项。
展开HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog\Application，删除所有oracle开头的项；
在HKEY_CLASSES_ROOT，删除以ora开头的项。
最后将Oracle安装目录和Oracle开始目录都删除。安装目录是你当时安装时选择的目录。在win10中打开 `C:\Users\xxxxx\AppData\Roaming\Microsoft\Windows\Start Menu\Programs` 目录，其中xxx是你电脑用户名。

然后重启一下电脑，主要让电脑重读一下配置。开机之后你的Oracle就是完全卸载了。