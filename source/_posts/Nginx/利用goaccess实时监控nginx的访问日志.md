---
title: 利用goaccess实时监控nginx的访问日志
date: 2018-12-15 20:15:40
toc: true #是否显示文章目录
categories: nginx
tags: 
	- nginx
	- goaccess
---

这篇文章主要写一下我在利用goaccess查看nginx生成的访问日志时的经历。

​	最终会生成一个下面类似的网页：

![goaccess网页](https://raw.githubusercontent.com/liunaijie/images/master/image-20181220155818036.png)

<!--more-->

# 配置Nginx

​	我们在nginx配置文件中可以对总体的访问或单个项目的访问生成日志，我们可以对日志生成网页更加直观的查看访问信息。

这是我在`nginx`配置文件中的配置:

```nginx
http {
    include       mime.types;
    default_type  application/octet-stream;
	# 日志格式 名称为 main
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  logs/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    gzip  on;
    ......省略
    
    server {
         ......省略
         location /robot/ {
             access_log  logs/robot_access.log  main;
             ......省略
         }
         ......省略
    }
```

# 安装 goaccess

​		在安装之前我们要先安装基础环境

```shell
#为方便最终日志统计时显示IP地理位置，需要安装依赖项GeoIP-devel：
yum install GeoIP-devel.x86_64
#安装ncurses-devel开发库：
yum install ncurses-devel
#安装tokyocabinet-devel开发库：
yum install tokyocabinet-devel
#安装openssl-devel开发库：
yum install openssl-devel
```

​	然后正式安goaccess

```shell
wget https://tar.goaccess.io/goaccess-1.3.tar.gz
tar -xzvf goaccess-1.3.tar.gz
cd goaccess-1.3/
./configure --enable-utf8 --enable-geoip=legacy
make
make install
```

​	这里要注意的是，如果我们使用`https`，我们要在`configure`中添加一个`--with-openssl`不然我们使用`https`时`ws`会跳转到`wss`但是会被拒绝掉。

# 启动

然后我们进入到nginx下的logs目录中。执行以下命令生成网页(`report.html`)：

```shell
goaccess /usr/local/nginx/logs/access.log -o /usr/local/nginx/html/report.html --real-time-html --time-format='%H:%M:%S' --date-format='%d/%b/%Y' --log-format=COMBINED --daemonize
```

​	我们加`--daemonize`参数是为了后台执行，执行这个的前提是有`--real-time-html`这个参数。如果我们是https的还需要添加` --ssl-cert=crt文件目录 --ssl-key=key文件目录`这两个参数才可以实现`wss`

​	完成后我们就可以输入地址进行访问。

# 权限访问

​	最后我们这个生成的网页并不想让所有人都看到，那我们可以设置一个密码，输入密码后才可以访问。这里我们利用`htpasswd`这个工具。

​	先进行安装`yum  -y install httpd-tools`

​	然后设置用户名和密码，并把用户名、密码保存到指定文件中（这里生成的用户名为userTest，存放到nginx下的passwd文件中）

```shell
htpasswd -c /usr/local/nginx/passwd userTest
New password: 
Re-type new password: 
Adding password for user coderschool 
```

​	然后配置nginx中的访问：

```nginx
location /report.html {
    alias /usr/local/nginx/html/report.html;
    auth_basic "请输入用户名和密码！"; #这里是验证时的提示信息 
    auth_basic_user_file /usr/local/nginx/report_passwd; #这是你生成密码存放的文件
    proxy_http_version 1.1; # 这三行是为了实现websocket
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
}
```

​	至此，我们就完成了用goaccess对nginx日志的实现监控。

​	打开链接会首先让我们输入用户名和密码，然后就可以看到我们统计的信息了，并且是通过websocket连接，请求数据都会实时改变。

![网页访问加限制](https://raw.githubusercontent.com/liunaijie/images/master/auth1.png)

​	