---
title: Linux用户命令
date: 2020-06-20 19:33:15
tags: 
- devops/linux
---

创建用户：

```bash
useradd new_user_name # 新建用户
userdel [-r] user_name # 删除用户, -r 删除用户的home目录
passwd user_name # 修改用户密码, 修改自己密码则无需输入用户名
usermod [settings] user_name # 修改用户属性
	-d new_home_path # 修改用户的home目录
chage # 修改用户属性
id user_name  #验证用户
```

组管理命令：

```bash
groupadd group_name
	usermod -g group_name user_name #修改user_name的用户组为group_name
	useradd -g group_name user_name #创建用户时指定用户组
groupdel group_name #删除用户组
```

切换用户：

```bash
su [-] user_name #切换用户, 带 - 号则一同切换环境
```

更改文件属性：

```bash
chown target_user:target_group file # 对文件修改属主和属组
```

文件属性：

```bash
r: 4
w: 2
x: 1
```

修改文件权限：

```bash
chmod [u/g/o/a][+/-/=][rwx] file_name
[u/g/o/a] # 分别代表当前用户，组，其他，全部
[+/-/=] # 分别表示增加权限，删除权限，修改权限
[rwx] # 表示读，写，执行权限。可以任意组合。

chmod 754 file_name #表示将当前用户的权限设置为7, r+w+x. 当前组的权限为5, r+x. 其他用户权限为4, w.
```

新创建的文件权限默认为

```bash
666 - umask文件的值
```