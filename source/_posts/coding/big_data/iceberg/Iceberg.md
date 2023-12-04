---
title: Iceberg
date: 2023-11-23 21:23
categories:
  - - coding
tags:
  - iceberg
---
# Introduction
本文将记录一下iceberg表的文件存储jie go
<!-- more -->

# Prepare
1. java8 (when i use java 17, i has got some error)
2. spark binary
3. iceberg library and move into spark binary's `jars` folder.

# 
As we already put the iceberg library into spark `jars` folder, so we can start with this command:
in this command we special a catalog `local`, and it's warehouse dir is `$PWD/warehouse`, we will observe the data change in this folder.
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
In warehouse folder, will create a `test_db/test_table01` folder. This folder will save all information about this table.
After create table, there will has `metadata/v1.metadata.json`, `version-hint.text` files. 
**version-hint.text** record the current used metadata file. For now, it's 1. It will always point to the current active metadata file.
**v1.metadata.json** it record the table schema, table path information.

2. Insert data
```
INSERT INTO local.test_db.test_table01 VALUES (1,'name1'), ... , (100,'name100')
```
在写入这100条数据后, 出现了`data`文件夹,里面文件为parquet格式.
在`metadata`文件夹下, 出现了`v2.matadata.json`, 并且`version-hint.text`内容也变成了2. 同时出现了两个avro文件







![](https://iceberg.apache.org/img/iceberg-metadata.png)




# Reference
- [# Iceberg Table Spec [](https://iceberg.apache.org/spec/#iceberg-table-spec)](https://iceberg.apache.org/spec/)
- [# Iceberg 原理分析](https://zhuanlan.zhihu.com/p/488467438)
- 