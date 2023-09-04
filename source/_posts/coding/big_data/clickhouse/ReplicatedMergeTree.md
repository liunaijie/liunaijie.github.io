---
title: ClickHouse-ReplicatedMergeTree
date: 2022-10-09 20:25:23
categories:
- [coding, big_data, olap, clickhouse]
tags: 
- clickHouse
---

ClickHouse的备份机制依赖于zookeeper来实现，并且只有MergeTree系列的表可以支持副本。

副本是表级别的，不是整个服务器级别的，所以在相同的服务器(cluster)上可以同时存在备份表和非备份表。

副本不依赖与分片，每个分片都有它自己的独立副本。

## 修改配置

如果要使用副本，需要在配置文件中设置zookeeper集群的地址。例如：

```xml
<zookeeper>
    <node index="1">
        <host>192.168.10.1</host>
        <port>2181</port>
    </node>
    <node index="2">
        <host>192.168.10.2</host>
        <port>2181</port>
    </node>
    <node index="3">
        <host>192.168.10.3</host>
        <port>2181</port>
    </node>
</zookeeper>
```

对于不同的机器，这个配置不相同。

```xml
<macros>
    <layer>05</layer>
    <shard>02</shard>
    <replica>example05-02-1.yandex.ru</replica>
</macros>
```

如果配置文件中没有设置zk，则无法创建复制表，并且任何现有的复制表都将变为只读。

在zk中存储元数据的路径是在创建表时指定的。

## DDL

```sql
CREATE TABLE test_table
(
    EventDate DateTime,
    CounterID UInt32,
    UserID UInt32,
    ver UInt16
) ENGINE = ReplicatedReplacingMergeTree('/clickhouse/tables/{layer}-{shard}/test_table', '{replica}', ver)
PARTITION BY toYYYYMM(EventDate)
ORDER BY (CounterID, EventDate, intHash32(UserID))
```

**Replicated*MergeTree的参数**

-   `zoo_path` — 在ZooKeeper中元数据的存储路径.
-   `replica_name` — 该节点在ZooKeeper中的名称.
-   `other_parameters` — Parameters of an engine which is used for creating the replicated version, for example, version in `ReplacingMergeTree`.

这里给的例子是创建了一个ReplacingMergeTree的备份表，Replace的规则是字段`ver`。这个表的元数据存储在zk的位置是：`/clickhouse/tables/05-02/test_table` 。

## 数据写入过程

由于ClickHouse是多主架构，所以可以在任意一个阶段进行数据写入，数据写入后会将元信息存储到zk中，包括（哪个节点写入了数据，数据存储的位置等）。其他节点检测到变换后会通过元信息向写入数据的阶段来拉取数据。

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/b714a228-604e-4bda-abe5-05a536636e76/Untitled.png)

## 其他操作类型信息同步流程

1.  **Optimize Table**

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/4fcfb483-8386-41be-aabc-6b90ffb422b2/Untitled.png)

1.  **Alert Delete**

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/11cef192-a3e0-4772-8fd9-c3f32f0d962d/Untitled.png)

1.  **Alert Table**