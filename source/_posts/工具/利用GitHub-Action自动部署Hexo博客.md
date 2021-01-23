---
title: 利用GitHub Action自动部署Hexo博客
date: 2021-01-23 15:24:51
categories: "软件列表"
tags: 
	- Github
	- Hexo
	- 自动化
---

# 前言

之前使用Hexo和Github写博客的时候都需要先在本地安装好Hexo环境，然后编写完博客后执行几条命令对文章进行部署，同时再将写的md文章保存到GitHub上，今天发现了一个更加简单的方法，可以在将文章推送到GitHub后自动进行博客的更新推送。利用了GitHub的Action。

# 前提

1. 电脑生成私钥公钥，公钥已经设置到Github上。
2. GitHub上有`user-name.github.io`仓库
3. 设置私钥到`user-name.github.io`仓库下，打开该仓库，找到`setting/secrets/New repository secret`将本地`~/.ssh/id_ras`文件复制进来，名称可以随便取，不过在下面使用的时候需要对应起来，比如我用了`ACTION_DEPLOY_KEY`这个名称。

![](https://raw.githubusercontent.com/liunaijie/images/master/20210123154250.png)

<!--more-->

# 开始操作

1. 下载`user-name.github.io`
2. 新建`Hexo`分支
3. 将`Hexo`分支下的内容删除，将`Hexo`的内容复制到该目录下。
4. 编写`Hexo`分支下`.github/workflows/main.yaml`文件，需要自己新建。内容为：

```yaml
name: Deploy Blog
# 监听hexo分支，当有push动作时触发这个Action
on:
  push:
    branches:
      - hexo
jobs:
  build:
    runs-on: ubuntu-latest # 选择基础镜像

    steps: # 需要多步完成
      - name: Checkout source # 下载代码
        uses: actions/checkout@v1
        with:
          ref: hexo
      - name: Use Node.js ${{ matrix.node_version }} # Node js环境
        uses: actions/setup-node@v1
        with:
          version: ${{ matrix.node_version }}
      - name: Setup hexo # 安装设置Hexo
        env:
          ACTION_DEPLOY_KEY: ${{ secrets.ACTION_DEPLOY_KEY }}
        run: |
          mkdir -p ~/.ssh/
          echo "$ACTION_DEPLOY_KEY" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh-keyscan github.com >> ~/.ssh/known_hosts
          git config --global user.email "liunaijie1996@163.com"
          git config --global user.name "Jarvis"
          npm install hexo-cli -g
          npm install
      - name: Hexo deploy # 部署
        run: |
          hexo clean
          hexo d
```



# 最终效果

在`user-name.github.io`这个仓库中，`master`分支为Hexo生成的Html页面内容，`hexo`分支为原始文件，包括md文件，hexo的配置信息等。当我们编写完文章中，只要推送到了远端仓库，就可以帮我们自动完成发布，如果遇到异常还会给你发送邮件提醒。

# 注意事项：

在hexo的配置文件中，部署的GitHub地址需要使用`git`不能使用`http`。