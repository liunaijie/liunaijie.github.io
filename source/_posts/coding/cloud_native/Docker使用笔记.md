---
title: Docker使用笔记
date: 2019-07-03 17:08:39
tags: 
- cloud_native/docker
---

Docker是一个使用了Linux Namespace和Cgroups的虚拟化工具

# 安装

- mac

  从官网下载安装包进行安装即可

- 树莓派

  使用ssh连接树莓派后执行

  `curl -sSL https://get.docker.com | sh`  

  就可以安装了，不过这是国外的安装源，速度可能会比较慢一些。

  如果在安装过程中提示缺少某些包根据提示进行安装即可。

# 配置

- mac

  修改国内源

  点击应用图标后打开`daemon`选项，在`registry mirrors`中可以看到我们的镜像下载源，我们可以搜索一些国内源进行替换。

  比如阿里云：

  1. 进入阿里的容器镜像服务：https://cr.console.aliyun.com/cn-hangzhou/instances/repositories
  2. 进入镜像加速器，创建加速器
  3. 复制加速器地址进行替换

- 树莓派

  将docker设置为开机自启动

  `sudo systemctl enable docker`  

  然后我们启动 Docker 守护程序，或者重启树莓派来完成启动docker

  `sudo systemctl start docker`  

  **将当前用户添加到docker用户组**

  现在安装完成后的docker还只能由`root`用户或者`docker`组的用户使用，所以如果你不是使用的root用户，例如跟我一样使用的pi用户、或者其他用户。还需要将用户加到docker组中，下面这个命令就是将当前用户加到docker组中

  `sudo usermod -aG docker $USER`    

  完成此操作后，当前用户还是不能操作docker，需要注销后重新连接即可。  

  重新连接后运行`docker run hello-world`就可以运行hello-world的镜像了。


# 常用命令

- 查找镜像
`docker search [OPTIONS] TERM`
比如我们需要查找一个MySQL镜像，我们可以`docker search mysql`

- 获取镜像
`docker pull [选项] [Docker Registry 地址[:端口号]/]仓库名[:标签]`
当我们对地址和标签缺省时，默认为当前仓库最新的镜像

- 列出本地镜像
`docker image`
将列出下载到本地的所有镜像

- 列出本地历史运行镜像
`docker ps -a`

- 删除本地镜像
`docker image rm [选项] <镜像1> [<镜像2> ...]`

- 进入镜像内部
`docker exec -it id|name  /bin/bash`
可以选定镜像的id或者名称来进入镜像内部
## DockerFile

设置时区：

```xml
TZ=Etc/GMT+7
```

# 参考

- [https://docker_practice.gitee.io/zh-cn/](https://docker_practice.gitee.io/zh-cn/)