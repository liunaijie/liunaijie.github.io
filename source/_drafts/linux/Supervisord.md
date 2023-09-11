---
title: Linux-supervisord
date: 2020-06-20 19:33:15
categories:
- [coding, linux]
tags: 
- linux
---

进程管理工具, 可以方便的对用户编写的进程进行启动, 关闭, 重启. 并且可以对意外关闭的进程进行重启.

官网文档: [http://supervisord.org/](http://supervisord.org/)

## 安装

```bash
pip install supervisor
```

## 使用

首先在在配置文件编写我们自己的配置.

```bash
; 在配置文件中, 分号;表示注释

[program:update_ip] ; 这个项目的名称
directory = /home/xxxx/works/ip_update/ip_update_on_server_no_1/ ; 程序的启动目录
command = python /home/xxxx/works/ip_update/ip_update_on_server_no_1/update_ip_internal.py  ; 启动命令，可以看出与手动在命令行启动的命令是一样
autostart = true     ; 在 supervisord 启动的时候也自动启动
startsecs = 5        ; 启动 5 秒后没有异常退出，就当作已经正常启动了
autorestart = true   ; 程序异常退出后自动重启
startretries = 3     ; 启动失败自动重试次数，默认是 3
user = shimeng          ; 用哪个用户启动
redirect_stderr = true  ; 把 stderr 重定向到 stdout，默认 false
stdout_logfile_maxbytes = 50MB  ; stdout 日志文件大小，默认 50MB
stdout_logfile_backups = 20     ; stdout 日志文件备份数
; stdout 日志文件，需要注意当指定目录不存在时无法正常启动，所以需要手动创建目录（supervisord 会自动创建日志文件）
stdout_logfile = /home/xxxx/works/ip_update/ip_update_on_server_no_1/supervisor.log
loglevel=info ;日志级别
```

以指定配置文件启动

```bash
supervisord -c /etc/supervisord.conf
```

启动后查询运行状态

```bash
supervisorctl status

# 当我们以上面的配置文件运行后, 应该显示如下的结果
# 项目名称  项目状态  进程号  运行时间

update_id     RUNNING   pid 1530, uptime 250 days, 23:41:39
```

常用的几个命令

```bash
supervisorctl status [project_name] # 查看所有, 或单独项目的运行状态
supervisorctl stop project_name # 停止某个服务
supervisorctl start project_name # 启动某个服务
supervisorctl restart project_name # 重启某个服务
supervisorctl reread # 读取有更新的配置文件, 不会启动新添加的项目
supervisorctl update # 重启修改过的项目
supervisorctl pid [project_name] # 查看某个项目的进程号
supervisorctl shutdown # 关停supervisord
```