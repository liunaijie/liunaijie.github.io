---
title: Iceberg
date: 2023-11-23 21:23
categories:
  - - coding
tags:
  - iceberg
---
# 前言
本文将记录一下iceberg表的文件存储结构, 数据写入流程, 查询流程的等. 基于Spark引擎.
<!-- more -->
# 准备工作
1. java8
2. spark binary
3. iceberg jar, 并放到spark binary的`jars`文件夹下

# 启动
在spark binary下, 使用如下命令启动. 在这个命令中, 我们创建了一个`local`的catalog, 并指定warehouse的位置在当前文件夹下的`warehouse`文件夹下.
我们后续所有的操作都基于这个catalog, 以及需要观察这个文件夹下的文件变动.
```
./bin/spark-sql \
--conf spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions \
    --conf spark.sql.catalog.spark_catalog=org.apache.iceberg.spark.SparkSessionCatalog \
    --conf spark.sql.catalog.spark_catalog.type=hive \
    --conf spark.sql.catalog.local=org.apache.iceberg.spark.SparkCatalog \
    --conf spark.sql.catalog.local.type=hadoop \
    --conf spark.sql.catalog.local.warehouse=$PWD/warehouse
```

1. Create table 
```sql
create table local.test_db.test_table01 (id bigint not null, name string) using iceberg;
```
表创建完成之后, 在warehouse文件夹下,会根据我们创建的数据库, 表名创建同名的文件夹.
`test_db/test_table01`
在这个表的文件夹下, 有一个`metadata`的子文件夹, 里面有`v1.metadata.json`, `version-hint.text` 两个文件
**version-hint.text** 这个文件永远会指向当前使用到的metadata文件, 目前为`1`
**v1.metadata.json** 这个文件记录了当前表的表结构, 路径信息.

2. Insert data
```
INSERT INTO local.test_db.test_table01 VALUES (1,'name1'), ... , (100,'name100')
```
在写入这100条数据后, 出现了`data`文件夹,里面文件为parquet格式.
在`metadata`文件夹下, 出现了`v2.matadata.json`, 并且`version-hint.text`内容也变成了2. 同时出现了两个avro文件.










![](https://iceberg.apache.org/img/iceberg-metadata.png)




# Reference
- [# Iceberg Table Spec [](https://iceberg.apache.org/spec/#iceberg-table-spec)](https://iceberg.apache.org/spec/)
- [# Iceberg 原理分析](https://zhuanlan.zhihu.com/p/488467438)
- 