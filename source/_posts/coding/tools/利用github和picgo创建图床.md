---
title: 利用github和picgo创建图床
date: 2019-06-28 17:28:39
categories:
- [coding, tools]
tags: 
- github
- picgo
---

在写博客的时候需要存储一些图片，网上有一些图床工具，有免费的也有收费的。免费的肯定没有保障，我就看到很多人使用一些免费的图床，然后提供方不再提供后图床就挂了。所以我准备使用github作为图床存储，有一定的网络延迟，但也可以接受。

# 前期准备：

下载并安装[picgo](https://github.com/Molunerfinn/PicGo)，选择自己系统对应的版本下载安装即可。

# 注册github  

## 创建存储图片的项目

这里要注意的是把项目设置成*公开*的，不用设置私有，不然我们图片是无法访问的。  

这里的图片其他人都是可以查看的，注意不要放一些与自己隐私相关的东西哦。。。

<!--more-->

## 生成github的token  

打开`github`->`setting`->`developer settings`->`personal access tokens`

![设置的路径](https://raw.githubusercontent.com/liunaijie/images/master/1561714944899.jpg)

点击生成新的token

![token设置](https://raw.githubusercontent.com/liunaijie/images/master/1561715301721.jpg)

这里我们填写我们这个token的名称和权限，权限就只选repo就可以。

点击生成token，这时候会显示一串字符，这个信息只出现一次以后是看不到的，所以我们要把它保存下来。

# picgo设置  

然后就是设置picgo了。  



![picgo设置](https://raw.githubusercontent.com/liunaijie/images/master/1561715524096.jpg)



仓库名称添加自己创建的仓库名称即可，分支就默认写master，token是我们上一步获取到的token  

最后就是自定义域名了，一般的规律是`https://raw.githubusercontent.com/你的github名称/仓库名称/分支名称(默认就是master)`

也可以先预上传一张图片，然后新标签页打卡，查看图片地址，去掉图片名即可。

然后将github设置成默认图床就可以了  