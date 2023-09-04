---
title: Mysql的ibtmp1文件过大
date: 2019-08-21 21:08:39
categories:
- [coding, database]
tags: 
- mysql
---

今天早上接到一个任务，说服务器磁盘容量告警让我去排查一下原因。磁盘容量在一天内突然暴涨了好几十个G。  

# 查看磁盘占用

使用命令

```shell
du -h --max-depth=1
```

查看磁盘占用情况，我是在根目录下执行的命令，后面的`max-depth=1`指定深入目录的层数，为1就指定1层。然后经过排查后发现了这个文件是`Mysql`的`ibtmp1`文件。

# ibtmp1是什么

我们使用的`Mysql`版本是5.7.24。`ibtmp1`文件是 MySQL5.7的新特性,MySQL5.7使用了独立的临时表空间来存储临时表数据，但不能是压缩表。临时表空间在实例启动的时候进行创建，shutdown的时候进行删除。即为所有非压缩的innodb临时表提供一个独立的表空间，默认的临时表空间文件为ibtmp1。

# 解决

`Mysql`创建的这个文件肯定不能在`Mysql`还运行时就直接删了，否则可能会出问题。重启`Mysql`会重置这个文件，但是后面如果不加以限制肯定还会让磁盘爆满。所以说要找一个能彻底解决的办法。

-   修改`my.cnf`配置文件

    这个文件我是在`/etc/my.cnf`下，有的可能在`/etc/mysql/my.cnf`下，先找到这个文件然后在后面添加`innodb_temp_data_file_path = ibtmp1:12M:autoextend:max:5G`这句  

    限制这个文件最大增加到5G。

-   设置`innodb_fast_shutdown`参数

    进入`mysql`命令行，执行`SET GLOBAL innodb_fast_shutdown = 0;`命令

然后重启`Mysql`即可。

# 原因

刚才说的了这个文件是临时表空间。那肯定是使用了临时表。那么什么情况下会使用临时表呢。  

-   **GROUP BY 无索引字段或GROUP  BY+ ORDER  BY 的子句字段不一样时**
-   **order by  与distinct 共用，其中distinct与order by里的字段不一致（主键字段除外）**
-   **UNION查询（MySQL5.7后union all已不使用临时表）**
-    **insert into select ...from ...**

所以在平常写sql时还是要多注意一下。

# 参考文章

http://mysql.taobao.org/monthly/2019/04/01/

https://cloud.tencent.com/developer/article/1491411

https://zhuanlan.zhihu.com/p/66847189