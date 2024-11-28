---
title: Spark-参数配置
date: 2022-04-01 23:10:23
categories:
  - - coding
    - big_data
    - spark
tags:
  - big_data/spark
---

https://spark.apache.org/docs/latest/configuration.html

<!--more-->

# 查看应用的配置
打开Spark UI, 点击`Environment` tab, 就可以看到设置的参数


# 设置
## Deploy

| 参数名称 | 默认值 | 参数说明 |
|-|-|-|
|spark.submit.deployMode|none|client或者cluster. client模式下提交的进程就是Driver, cluster模式下会新启一个机器作为Driver|


## Driver
| 参数名称 | 默认值 | 参数说明 |
|-|-|-|
|spark.app.name|none| 这个application的名称, 会显示在UI和log里, 重复也没关系 |
|spark.driver.cores|1| driver的核数, 只在cluster模式下生效 |
|spark.driver.memory|1g| driver的内存大小, 如果在client模式下, 需要在启动之前设置 |
|spark.driver.maxResultSize|1g| 限制单个action下所有分区返回的序列化结果总大小, 至少为1M.  或者为0则不进行限制, 但是可能会造成Driver OOM异常 |

## Executor
| 参数名称 | 默认值 | 参数说明 |
|-|-|-|
|spark.executor.memory|1g| executor的内存大小 |
|spark.executor.memoryOverhead| executorMemory * `spark.executor.memoryOverheadFactor`, with minimum of 384 | |
|spark.executor.memoryOverheadFactor| 0.1 ||


## Runtime 
| 参数名称 | 默认值 | 参数说明 |
|-|-|-|
|spark.driver.extraClassPath|none||
|spark.driver.defaultJavaOptions|none||
|spark.driver.extraJavaOptions|none||
|spark.driver.extraLibraryPath|none||
|spark.driver.userClassPathFirst|false||
|spark.executor.extraClassPath|none||
|spark.executor.defaultJavaOptions|none||
|spark.executor.extraJavaOptions|none||
|spark.executor.extraLibraryPath|none||
|spark.executor.userClassPathFirst|false||
|spark.files|||
|spark.jars|||



##  Shuffle Behavior
| 参数名称 | 默认值 | 参数说明 |
|-|-|-|
| spark.reducer.maxSizeInFlight | 48m |  |
| spark.reducer.maxReqsInFlight | Int.MaxValue |  |
| spark.reducer.maxBlocksInFlightPerAddress | Int.MaxValue |  |
| spark.shuffle.compress | true |  |
| spark.shuffle.file.buffer | 32k |  |
| spark.shuffle.io.maxRetries | 3 |  |
| spark.shuffle.io.backLog | -1 |  |
| spark.shuffle.io.connectionTimeout | value of `spark.network.timeout` |  |
| spark.shuffle.service.enabled | false |  |
| spark.shuffle.service.removeShuffle | false ||
| spark.shuffle.sort.bypassMergeThreshold | 200 |  |
| spark.shuffle.spill.compress | true |  |
| spark.files.io.connectionTimeout | value of `spark.network.timeout` |  |
| spark.shuffle.checksum.enabled | true |  |
| spark.shuffle.checksum.algorithm | ADLER32 |  |
|spark.shuffle.service.fetch.rdd.enabled|||

## Compression and Serialization

| 参数名称 | 默认值 | 参数说明 |
|-|-|-|
| spark.broadcast.compress | true | 是否对广播变量做压缩,压缩格式使用`spark.io.compression.codec` |
| spark.rdd.compress | false| 是否对序列化的RDD分区做压缩 ,压缩格式使用`spark.io.compression.codec` |
| spark.io.compression.codec | lz4 | 内部数据压缩格式, Spark默认提供了四种方式: lz4, lzf, snappy, zstd |
| spark.io.compression.lz4.blockSize | 32k | lz4压缩算法的区块大小 |
| spark.io.compression.snappy.blockSize | 32k | snappy压缩算法的区块大小 |
| spark.io.compression.zstd.level | 1 | zstd压缩级别 |
| spark.io.compression.zstd.bufferSize | 32k | zstd压缩算法的参数 |
| spark.kryoserializer.buffer.max | 64m |  |
| spark.kryoserializer.buffer | 64k |  |
| spark.serializer | org.apache.spark.serializer.JavaSerializer | 对象序列化方法, 默认值比较慢, 推荐使用`org.apache.spark.serializer.KryoSerializer` and configuring Kryo serialization |

## Memory Management

| 参数名称 | 默认值 | 参数说明 |
|-|-|-|
| spark.memory.fraction | 0.6 | Execution + Storage Memory占用的比例  |
| spark.memory.storageFraction | 0.5 | Storage Memory的占用比例 |
| spark.memory.offHeap.enabled | false | 是否使用堆外内存, 大小为`spark.memory.offHeap.size` |
| spark.memory.offHeap.size | 0 | 堆外内存的大小 |


## Execution Behavior

| 参数名称 | 默认值 | 参数说明 |
|-|-|-|
| spark.broadcast.blockSize | 4m |  Size of each piece of a block for `TorrentBroadcastFactory`  |
| spark.broadcast.checksum | true |  使用需要使用checksum来进行数据校验 |
| spark.executor.cores | 1 | executor的核数 |
| spark.default.parallelism | | 默认的并行度 |
| spark.executor.heartbeatInterval | 10s | 每个executor与Driver的心跳间隔, 此参数要小于spark.network.timeout |




## Network

| 参数名称 | 默认值 | 参数说明 |
|-|-|-|
| spark.rpc.message.maxSize | 128 |  RPC通信的消息大小, MB为单位  |
| spark.network.timeout | 120s | 超时时间 |
| spark.rpc.io.connectionTimeout | value of `spark.network.timeout` |  |


## Scheduling
| 参数名称 | 默认值 | 参数说明 |
|-|-|-|
| spark.task.cpus | 1 |  每个Task使用的核数  |

## Dynamic Allocation

| 参数名称 | 默认值 | 参数说明 |
|-|-|-|
| spark.dynamicAllocation.enabled | false |  是否启用动态资源分配 |
| spark.dynamicAllocation.initialExecutors | spark.dynamicAllocation.minExecutors | Executor的初始数量 |
| spark.dynamicAllocation.maxExecutors | infinity | 最大的executor数量 |
| spark.dynamicAllocation.minExecutors | 0 | 最小的executor数量 |


## Spark SQL

| 参数名称 | 默认值 | 参数说明 |
|-|-|-|
| spark.sql.adaptive.enabled | true | 是否开启自适应执行 |
| spark.sql.adaptive.coalescePartitions.enabled | true | 是否开启自动分区合并 |
| spark.sql.adaptive.advisoryPartitionSizeInBytes | value of `spark.sql.adaptive.shuffle.targetPostShuffleInputSize` | shuffle时每个partition的数据量大小, 作用在合并小文件以及处理数据倾斜 |
| spark.sql.adaptive.coalescePartitions.minPartitionSize | 1MB | shuffle partition的最小值 |
| spark.sql.adaptive.autoBroadcastJoinThreshold | | 广播表的阈值, 表大小小于这个值时会进行广播 |
| spark.sql.adaptive.skewJoin.enabled | true | 开启后, 会对倾斜分区做拆分, 拆分后再进行join |
| spark.sql.adaptive.skewJoin.skewedPartitionFactor | 5 | 如何判断一个分区是否倾斜, 需要这个分区是中位数的N倍以上 |
| spark.sql.adaptive.skewJoin.skewedPartitionThresholdInBytes | 256MB| 倾斜分区的大小还要大于这个值 |
| spark.sql.autoBroadcastJoinThreshold | 10MB | 小表自动广播的阈值 |
| spark.sql.broadcastTimeout | 300 | broadcast join时的超时时间(秒) |



