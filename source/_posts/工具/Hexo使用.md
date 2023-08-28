---
title: Hexo使用
date: 2019-01-17 16:51:39
categories: 
	- [tools]
toc: true
tags: 
	- hexo
---



其实根据官网文档就很容易进行安装了，[官网文档链接](https://hexo.io/zh-cn/docs/)，所以也不写安装和启动的流程了。

# 安装主题

# 修改配置

1. 项目配置
2. 主题配置

# 部署、发布

修改`_config.yml`配置文件，支持多个配置信息，如果多个需要如下填写

```shell
# 单个配置
deploy:
  type: git
  repo:
# 多个配置
deploy:
- type: git
  repo:
- type: sftp
  repo:
```



-   发布到github

    先进行安装`npm install hexo-deployer-git --save`

    ```shell
    deploy:
      type: git
      repo: # 仓库地址，最好使用http的协议，使用ssh协议时有可能会报错
      branch: #发布的分支，默认是 master
      message: # 提交的信息
    ```

-   发布到个人服务器（sftp）

    先进行安装`npm install hexo-deployer-sftp --save`

    ```shell
    deploy:
      type: sftp
      host: <host> # 远程主机的地址
      user: <user> # 用户名
      pass: <password> # 密码
      remotePath: [remote path] # 发布到的路径
      port: [port] # 端口 默认为22
    ```

经过如上配置后，执行`hexo -d`后就会将生产的静态文件发布到git和服务器上。

# 草稿

有时候建立一些草稿，还没写完不需要发布的时候我们可以使用以下的方式来实现。

```shell
# 新建草稿
hexo new draft 'md_name'
```

执行这个命令后会在`source/_drafts`文件夹下新建一个`md_name.md`文件，所以我们不需要加文件后缀。  

然后我们启动hexo后并不能看到草稿，如果需要看到草稿可以使用以下方案

-   修改配置文件

    将配置文件中的`render_drafts`改为`true`

-   启动hexo时加参数

    ```shell
    hexo server --drafts
    ```

当我们写完草稿后将其变成正式文章，执行以下命令：

```shell
hexo publish 'md_name'
```

这里也不需要加后缀名，如果文件名称是中文，在shell中无法输入中文可以执行以下操作  

先对`~/.bash_profile`配置文件进行修改，添加或修改这一行信息：

```shell
export LANG=en_US.UTF-8
```

然后执行`source ~/.bash_profile`，让配置生效。

最后重新打开终端就可以输入中文了。



# 参考文章

https://hexo.io/zh-cn/docs/

https://blog.csdn.net/j754379117/article/details/53897115