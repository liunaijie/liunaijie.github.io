---
title: nginx源码编译安装
date: 2019-04-11 12:29:40
toc: true
categories: 
	- [code, tool]
tags: 
	- nginx
---

在一些平台上我们可以轻松的使用命令安装nginx，但是安装完成的软件在某些时候可能并不能满足我们的需求，这时候可能就需要从源码来进行编译安装了。

# 提前需要安装的软件

Ubuntu

```shell
sudo apt-get install gcc automake autoconf make libpcre3 libpcre3-dev
sudo apt-get install openssl # 开启ssl、https时需要
```

centos

```shell
yum -y install gcc gcc-c++ zlib zlib-devel openssl openssl-devel pcre pcre-devel unzip zip
yum -y install openssl-devel # 开启ssl、https时需要
```

树莓派

```shell
sudo apt-get install -y make gcc libpcre3 libpcre3-dev  libperl-dev libssl-dev libcurl4-openssl-dev
```

<!-- more -->

# 下载、解压

去官网找到最近的稳定版本，右键复制下载链接

```shell
wget 下载链接
tar -zxvf 下载的压缩包
```

# 编译

进入解压完成的文件夹，执行编译命令

```shell
./configure
```

我常用的命令有这些：

| 命令                      | 说明                                                         |
| :------------------------ | ------------------------------------------------------------ |
| --prefix=path             | 指定nginx的安装目录，默认是安装在/usr/local/nginx文件夹下    |
| --with-http_ssl_module    | 开启ssl模块，即网站支持https访问，这个默认是不开启的，需要编译时开启后配置文件中的配置才能生效 |
| --with-http_realip_module | 开启realip模块，获取用户访问的真实ip                         |

其他还有很多的配置项，可以从[http://nginx.org/en/docs/configure.html](http://nginx.org/en/docs/configure.html)网站上自行查阅并配置。

我常用的编译命令就是：

```shell
./configure --with-http_ssl_module --with-http_realip_module
```

# 安装

执行` make `,`make install`

# 运行

如果没有指定安装目录则默认安装在了`/usr/local/nginx`里面，进入该文件夹。  

执行`./sbin/nginx`即可开启nginx，如果提示权限不足，前面添加`sudo`即可。  

这时访问`127.0.0.1`即可看到nginx默认的访问页面。  

设置开机自启，修改`/etc/rc.local`文件，在后面添加`/usr/local/nginx/sbin/nginx`，如果权限不足，在前面添加`sudo`即可。

# 修改配置文件，重新启动

nginx的配置文件在`conf/nginx.conf`文件中。在这个文件中对根据我们的需求进行修改即可。修改完成后执行`./sbin/nginx -t`这是测试我们的配置文件是否格式正确，也可直接使用`./sbin/nginx -s reload`执行重启命令，执行重启命令时也会执行检查配置文件格式。如果我们的配置文件格式有错误，都会在命令行中提示错误的位置，进入查看修改即可。

一般的web服务器配置都像这样：

```nginx

#user  nobody;  ## 指定nginx的用户，默认为nobody 我们也可以修改为root
worker_processes  1;

# 以下几个配置都是指定日志文件和启动的id路径，不用管它
#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;


events {
    worker_connections  1024;
}

# http模块，这是我们主要进行配置的地方
http {
    include       mime.types;
    default_type  application/octet-stream;

    # 设置访问日志的格式，log_format 是命令 main是这个格式的名称后面直接用名称就知道是这个格式了 再后面的就是具体的日志格式了
    log_format  main  '$remote_addr $server_port  - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
	# 指定访问日志的存储路径和日志格式
    access_log  logs/access.log  main;
    # ip黑名单(从其他配置文件中读取配置)
    include ip_deny.conf;
	
    server_tokens off; # 关闭nginx版本号
    sendfile        on;
    tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    gzip  on; # 开启gzip压缩

    # 负载均衡的配置，这个配置也值得拿出来单独记录，我这里就是简单的配置了一下
    upstream users {
         server 192.168.0.13:8001 weight=2; #权重为2 3次访问中会有两次到这个机器上去
         server 192.168.0.14:8001 weight=1;
     }

    

    # 设置无法通过其他域名,ip访问(即除了我们配置的server_name所有请求都会被阻拦)
    server {
        listen 80 default;
        server_name _name_;
        return 403;
    }

    # liunaijie page settings
    #
    server {
        listen       80;
        # server_name 可以配置多个域名
        server_name www.liunaijie.top liunaijie.top;
        # 强制将http重定向到https
        rewrite ^ https://www.liunaijie.top$request_uri? permanent;
    }

    # HTTPS server
    #
    server {
        access_log  logs/liunaijie.log  main;
        listen       443 ssl;
        server_name  www.liunaijie.top;
        charset utf-8; # 设置文件编码格式
        ssl_certificate      /usr/top.pem; #这两个是https的ssl证书路径
        ssl_certificate_key  /usr/key;
        ssl_session_timeout 5m;
        ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
        ssl_protocols TLSv1.2;
        ssl_prefer_server_ciphers on;

        # location是指定对域名下访问路径的处理
        location / {
            # 什么都不写表示直接访问域名
            access_log logs/blog.log main;
            root   html;
         }
        
		# 对 /videos 开启文件访问
        location /videos {
                alias /aaa/bbb/ccc/ddd/videos; # 指定文件夹
                autoindex on; #开启索引
                autoindex_localtime on; # 显示时间
                autoindex_exact_size on; #显示文件大小
        }
		
        # 这个是对我写的项目的一个配置
         location /users {
             # 下面三行是开启 websocket 配置
             proxy_http_version 1.1;
             proxy_set_header Upgrade $http_upgrade;
             proxy_set_header Connection "upgrade";
             proxy_pass http://users; #开启负载均衡
             # 解决跨域
             add_header 'Access-Control-Allow-Origin' '$http_origin';
             add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
             add_header 'Access-Control-Allow-Headers' 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type';
             add_header 'Access-Control-Allow-Credentials' 'true';
        } 

    }

}
```



# 停止

停止nginx有几种方式，使用nginx自己的停止方式或者找到nginx的进程然后杀掉他

-   `nginx -s quit`这个命令是优雅的停止，会先完成当前正在进行的工作后再停止。
-   `nginx -s stop`这个就直接停止了，不管有没有正在进行的工作
-   `kill nginx`这个是使用的系统命令直接杀死进程。