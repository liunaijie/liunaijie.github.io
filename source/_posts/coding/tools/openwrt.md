---
title: Ubuntu16编译openwrt
date: 2019-01-22 09:08:39
tag:
	- openwrt
---

## Ubuntu16编译openwrt

​	新安装的Ubuntu首先更新软件源

​	`sudo apt update`

​	更新系统软件

​	`sudo apt dist-upgrade`

​	安装系统openwrt需要的环境

`sudo apt-get install build-essential subversion libncurses5-dev zlib1g-dev gawk gcc-multilib flex git-core gettext libssl-dev unzip`

​	下载openwrt

`git clone https://github.com/openwrt/openwrt.git`

​	更新feeds

````shell
cd openwrt
./scripts/feeds update -a
./scripts/feeds install -a
````

​	使用默认配置

`make defconfig`

​	使用界面编译

`make menuconfig`

​	开始编译

`make V=s`

编译完成后会在bin/target目录下生成固件



刷机

使用breed uboot

开启sftp服务

```shell
opkg update 
opkg install vsftpd
/etc/init.d/vsftpd enable
/etc/init.d/vsftpd start
```

安装nginx

​	由于nginx使用80端口，和默认luci配置页面有冲突，我们先将luci端口修改。

```shell
vi /etc/config/uhttpd
```

将`list listen_http        0.0.0.0:80​  的80端口进行修改，比如修改为8001     

list listen_http        [::]:80` 的80端口进行修改，两个要修改一致。

```shell
opkg install nginx
```

​	完成后修改`/etc/nginx/nginx.conf`添加以下内容

```nginx
location / {
	root  /mnt/www/html;
	index  index.html index.htm;
}

location /luci/ {                   
	proxy_pass http://127.0.0.1:8001/luci/;
}                                                                     

location /luci-static/ {                                    
	alias /www/luci-static/;
} 
```

​	我们是将默认目录改为`/mnt/www/html`下，记得要授予权限，或者nginx使用root。对luci进行转发，端口是我们上面设置的端口。

 完成后我们可以在`192.168.1.1`打开nginx页面，在`192.168.1.1:8001`打开luci路由器配置页面

