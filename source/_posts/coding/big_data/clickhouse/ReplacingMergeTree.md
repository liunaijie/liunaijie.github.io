---
title: ClickHouse-ReplacingMergeTree
date: 2022-10-09 20:25:23
categories:
- [coding, big_data, olap, clickhouse]
tags: 
- clickHouse
---

在MergeTree的写入过程中可以看到，ClickHouse无法保证主键的唯一性。

如果在数据写入时做主键校验，那么这个时候就需要维护一个主键的列表，然后每次写入时都需要进行判断，这样做的话就降低了吞吐量。

ClickHouse利用了MergeTree需要合并相同分区的特性，实现了在合并过程中进行主键校验的过程。

## 例子

```sql
CREATE TABLE table_001
(
    id UInt32,
    name String,
  	age UInt8
) ENGINE = ReplacingMergeTree()
ORDER BY id
PARTITION BY age
```

这个表定义主键为id，分区在age字段上。

写入两条初始化数据：`insert into table_001 values(1,'name1',18),(2,'name2',18);`

这两条数据属于相同分区，但是主键值不一样，我们这个时候进行查询，可以查询到这两条数据。

然后再写入一条分区相同id相同的数据`insert into table_001 values(1,'name3',18);`

当插入完成后进行查询时，还是可以看到这条数据，因为合并文件夹不是立即生效的，而当我们过一段时间后再去进行查询就会看到第一次写入的`name1` 这一行已经被替换掉了。我们也可以设置替换规则，来决定当遇到多条相同主键数据时的保留策略。

再来写一条不同分区下的相同id数据: `insert into table_001 values(1,'name3',19);`

这条记录的id与之前的重复了，但是它并不会替换之前的值，因为它们属于不同的分区下，在merge过程中并不会被merge到一起，不会触发替换的过程。

## 数据替换策略

ReplacingMergeTree的引擎定义中可以传递一个参数，这个参数的类型可以是UInt*，Date或者DateTime类型的字段。

DDL：

```sql
create table replace_table_v1(
	id String,
	code String,
	create_time DateTime
) Engine = ReplacingMergeTree(create_time)
Partition By toYYYYMM(create_time)
Order By id
```

当我们向这个表进行插入时，当遇到重复数据时，会保留create_time最大的那一条记录。

# 总结

简单梳理一下它的处理逻辑：

1.  使用Order By排序键作为判断重复数据的唯一键
2.  只有在合并分区的时候才会触发替换重复数据的逻辑
3.  以分区为单位替换重复数据。当分区合并时，同一分区内的重复数据会被替换，而不同分区之间的重复数据不会被替换。
4.  在进行数据去重时，由于分区内的数据已经基于Order By进行了排序，所以很容易找到那些相邻的重复数据。
5.  数据的去重策略有两种：
    -   当没有设置版本去重策略时，保留同一组重复数据中的最后一行
    -   当设置了去重策略后，保留字段最大的那一行。

# 延伸

1.  ReplacingMergeTree引擎也只能实现相同分区内的主键去重，不能实现全局的主键唯一性，而且还是延迟生效的。
2.  数据去重时，最好指定去重策略，因为保留数据的最后一行有时候可能并不是我们真正想保留的数据。