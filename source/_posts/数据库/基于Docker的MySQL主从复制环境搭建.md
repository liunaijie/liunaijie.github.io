---
title: 基于Docker的MySQL主从复制环境搭建
date: 2020-01-30 12:27:27
categories: "mysql"
tags: 'mysql'
---

# 1. 前言

之前的程序架构可能是这样的一种形式：

![](https://raw.githubusercontent.com/liunaijie/images/master/20200130131404.png)

当程序体量扩大后，我们进行扩展，可能会扩展多个后台服务实例，但数据库还是只有一个，所以系统的瓶颈还是在数据库上面，所以这次的主要任务就是对数据库进行扩展，主要形式为：扩展多台数据库实例，实现读写分离，对于一些写的任务分配到主数据库，对于读的任务使用子数据库进行读取。从而提高系统性能。

修改后的架构如下所示：

![](https://raw.githubusercontent.com/liunaijie/images/master/截屏2020-01-3017.03.05.png)

<!--more-->

# 2. 环境预搭建

这次使用docker来进行这个环境的搭建，使用MySQL版本为5.7.13。

```shell
docker pull mysql:5.7.13
```

整体结构为:

- 1个master主节点，作为写的节点。

- 2个slave从节点，作为读的节点。


先分别将这几个节点启动，映射到不同的端口。在本机使用数据库连接工具连接，测试是否正常启动且正常连接。

```shell
docker run -p 3307:3306 --name mysql-master -e MYSQL_ROOT_PASSWORD=123456 -d mysql:5.7.13
docker run -p 3308:3306 --name mysql-slave1 -e MYSQL_ROOT_PASSWORD=123456 -d mysql:5.7.13
docker run -p 3309:3306 --name mysql-slave2 -e MYSQL_ROOT_PASSWORD=123456 -d mysql:5.7.13
```

我这里分别将主节点（mysql-master）映射为`3307`端口，两个从节点（mysql-slave1,2）分别为`3308`和`3309`端口。然后设置MySQL的root密码为`123456`。

然后可以使用`navicat`等工具连接测试MySQL。

![](https://raw.githubusercontent.com/liunaijie/images/master/截屏2020-01-3109.19.54.png)

分别进入这几个节点，编辑配置文件。

```shell
docker exec -it mysql-master /bin/bash
```

我使用的是name来进入容器，也可以根据id来选择，即`docker exec -it 对应容器的id /bin/bash`。

由于没有预先安装`vi`和`vim`程序，然后要下载时需要执行`apt update`命令，这时会从国外源进行下载。由于众所周知的原因，速度很慢。我就将下载源更改为国内源。

进入到`/etc/apt`文件夹中，首先将原有的文件进行备份：

```shell
mv sources.list sources.list.bak
```

然后使用如下命令新建文件并输入内容：

```shell
echo deb http://mirrors.aliyun.com/ubuntu/ xenial main restricted universe multiverse > sources.list
```

然后我们再执行`apt update`等操作，最后安装`vim`即可。

# 3. 进行主从配置

1. 主节点（master）配置

进入主节点容器后，进入`/etc/mysql`文件夹中，会有一个`my.cnf`文件，主要对它进行修改。

编辑这个文件，找到`[mysqld]`，在这个下面添加如下命令：

```shell
[mysqld]
...
...
## 唯一的编号
server-id=101
## 这个是关键配置项
log-bin=mysql-bin
```

配置完成后，需要重启MySQL服务使配置生效。使用`service mysql restart`命令进行重启，重启完成后会关闭MySQL的容器，我们还要重启容器`docker restart mysql-master`。

2. 从节点（slave）配置

同主节点一样，编辑`/etc/mysql/my.cnf`文件

```shell
[mysqld]
...
...
## 唯一的编号
server-id=103
## 选，如果需要将该节点作为其他节点的主节点则需要添加
# log-bin=mysql-bin
```

3. 链接主节点和从节点

***主节点***

在主节点容器中进入MySQL`mysql -u root -p`，密码就是启动容器时设置的`123456`。

进入MySQL后执行`show master status;`：

![](https://raw.githubusercontent.com/liunaijie/images/master/20200131095802.png)

从这里我们得到两个信息`File`和`Position`的值，我这里分别是`mysql-bin.000001`和`154`。

***从节点***

进入MySQL，执行如下的命令：

```mysql
change master to master_host='***', master_port=3306, master_user='root', master_password='123456',  master_log_file='****', master_log_pos= ***;
```

<br>

分别解释一下这几个参数代表的意思：

- master_host：主节点的ip地址，可以在本机使用中如下命令来查看容器的ip地址

  ```shell
  docker inspect --format='{{.NetworkSettings.IPAddress}}' 容器名称|容器id
  ```

  

- master_port：mysql的端口号，不是对外映射的端口号

- master_user：mysql中的用户，要有权限，我直接使用了root，也可以新建用户来使用

- master_password：用于同步的mysql帐户密码

- master_log_file：用于同步的文件，就是从主节点查询到的文件，我这里是`mysql-bin.000001`

- master_log_pos：binlog文件开始同步的位置， 就是从主节点查询到的位置，我这里是`154`

执行刚刚的命令后在MySQL终端执行`show slave status \G;`来查看主从同步状态。

<img src="https://raw.githubusercontent.com/liunaijie/images/master/20200131101232.png" style="zoom:50%;" />

我们可以从这里查看配置的信息来进行核查，然后可以看到两个属性`slave_io_running`和`slave_sql_running`都是no，也就是关闭状态。

我们可以执行`start slave`来开启主从复制，执行后再次执行`show slave status \G;`命令可以看到两个属性都变成了`yes`，则说明主从复制已经开启。

**如果启动未成功，我们可以检查网络是否连通，同步用到的mysql密码是否正确，还有就是同步文件名称和位置是否正确！**

### 测试

我们可以在主库中新建一个数据库，到从库中如果看到这个库的存在就表示主从同步完成。

# 4. 级联配置

我想再加一个备份节点，并且这个节点是从slave1节点进行备份的，也就是slave1节点作为backup节点的主节点。这就构成了master->slave->backup这样一个级联关系。

我本来是按照上面的步骤，先在slave的`my.cnf`中添加了

```shell
log-bin=mysql-slave-bin #为了区分，我对文件名进行了修改 
```

接着在backup节点执行的

```shell
change master to master_host='***', master_user='root', master_password='123456', master_port=3306, master_log_file='****', master_log_pos= ***;
```

命令换成对应slave节点的ip等属性。结果发现不行。在主节点有更改后，备份节点并没有变更！

于是我开始了排查，发现在slave节点中的binlog文件并没有更改信息的记录，而backup节点相当于监听这个文件变更，这个文件没有变更所以backup节点也就不会有更改。这里延伸一点，mysql的binlog记录了我们所有更改的操作，所以理论上我们可以通过binlog来恢复任一时间刻的数据库内容。

于是问题就转变成，主节点变更后如何让从节点的binlog日志有记录。

我们可以在编辑`my.cnf`文件时再添加一行：`log_slave_updates=1`即可，让slave在接到master同步后也将二进制日志写到自己的binlog中。

这样就可以完成，主节点进行更改后，从节点和备份节点都会进行变更，备份节点的数据是从从节点备份过去的。

# 参考

- https://blog.csdn.net/youngwizard/article/details/8530725