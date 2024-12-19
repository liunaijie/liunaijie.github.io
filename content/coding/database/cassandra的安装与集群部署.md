---
title: cassandra的安装与集群部署
date: 2017-11-22
categories:
  - notes
tags:
  - Cassandra
---

# 前提
安装jdk1.8以上，python2.7

<!-- more -->

# 安装Cassandra
Cassandra的下载地址：http://cassandra.apache.org/download/
下载后将文件解压到某目录下，
然后配置环境变量
`CASSANDRA_HOME`为你解压的目录，
path为`%CASSANDRA_HOME%\bin`
然后用管理员身份运行cmd（不然可能提示权限不够）
进入Cassandra目录下的bin，
执行`cassandra`
![执行cassandrs](https://raw.githubusercontent.com/liunaijie/images/master/SouthEast.png)
然后如果成功会出一大堆东西，并且不能再输入命令；
# 查询状态
再打开一个cmd窗口，原来的不要关闭
进入bin文件夹
执行`nodetool status`
![nodetool status](https://raw.githubusercontent.com/liunaijie/images/master/nodetool.png)
这是成功状态，
然后输入`cqlsh`进入编写sql
![执行cqlsh](https://raw.githubusercontent.com/liunaijie/images/master/cqlsh.png)

*如果执行cqlsh时出现`Can't detect python version`需要到pylib目录下执行`python setup.py install`*

出现cqlsh>开头就表示你现在正在编写sql；
# 查询命令
查看表空间 `describe keyspaces`；
查看已有表：`describe tables`;
查看表结构：`describe table table_name`;

# 多节点部署

**以上是单个几点的安装，下面是多个节点的集群部署：**
修改配置文件：`cassandra.yaml`
`cluster_name`：集群名称。
如果启动过数据库再修改集群名称需要先执行命令:
进入cqlsh执行
`UPDATE system.local SET cluster_name = '你修改后的名称' where key='local';`
退出cqlsh状态，执行`nodetool flush system`
`seeds`节点，将每个节点的ip加进去，`"x.x.x.x,xx.xx.xx.xx"`不用加尖括号！
`listen_address`改为自己的ip地址
`rpc_address`改为自己的ip地址
重启数据库。
再次执行cqlsh命令，后面需要加自己的ip