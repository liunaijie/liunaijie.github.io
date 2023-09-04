---
title: ClickHouse-SummingMergeTree
date: 2022-10-09 20:25:23
categories:
- [big_data, olap, clickhouse]
tags: 
- clickHouse
---

假设有这样一种需求，用户只需要查询数据的汇总结果，不关心明细数据，并且数据汇总的维度都是明确的（GROUP BY条件明确，不会随意改变）

对于这样的查询场景，在ClickHouse中最直接的方法就是使用MergeTree引擎存储数据，然后每次查询通过GROUP BY聚合查询，利用SUM聚合函数汇总结果。

但是这样存在两个问题：

1.  存在额外的存储开销：用户不关心明细数据，只关系汇总结果，而我们会一直存储明细数据
2.  额外的查询开销：对于相同的查询，每次都需要走一遍聚合计算

SummingMergeTree引擎可以解决这样的应用场景，它可以按照预先定义的维度进行聚合汇总数据，将同一分组下的多行数据汇总合并成一行，这样即可以减少数据量，也可以减少后期查询的运算量。

在MergeTree的每个数据分区内，数据会按照ORDER BY表达式排序。主键索引也会按照PRIMARY KEY表达式取值并排序。而且ORDER BY可以替代主键。所以之前一直使用ORDER BY来定义主键。

```
如果同时需要定义ORDER BY与PRIMARY KEY，通常只有一种可能，就是明确希望ORDER BY与PRIMARY KEY不同，这种情况只会使用在SummingMergeTree与AggregatingMergeTree时才会出现。因为SummingMergeTree与AggregatingMergeTree都需要根据GROUP BY条件来进行预先聚合，这个时候使用来ORDER BY来定义GROUP BY的字段，所以需要使用PRIMARY KEY来修改主键的定义
```

## 示例：

假如我们有一个表，这里面有A，B，C，D，E，F。6个字段，当我们需要按照A，B，C，D字段进行汇总时，则设置为：`ORDER BY(A, B, C, D)`。但是在查询过程中，我们只会对A字段进行过滤，所以我们只需要对A字段设置主键，这样表的定义就变成了：

```sql
ORDER BY(A, B, C, D)
PRIMARY KEY(A)
```

如果同时声明PRIMARY KEY与ORDER BY，则需要PRIMARY KEY是ORDER BY的前缀

# 定义：

```sql
ENGINE = SummingMergeTree((col1, col2, ...))
```

col1, col2为columnar的参数值，这是选填参数，用于设置除主键外其他数值类型字段，以指定被SUM汇总的列字段。如果参数为空，则会将所有非主键的数值类型字段进行SUM汇总。

# 总结：

对ORDER BY中字段相同值的记录进行提前聚合。