---
title: Spark内容整理
date: 2024-01-20 14:10:23
categories:
  - - publish
    - coding
    - big_data
    - spark
tags:
  - big_data/spark
---

最近在换工作, 抽个时间把这几年所学的内容整理一下.
接触spark已经3年多的时间, 把之前写的一些文章进行一下综合性的整理.
<!--more-->

# Spark是什么
Spark是一套基于内存的分布式大规模数据处理框架, 而我对于spark的应用场景主要是做数据处理, 数据分析.
Spark内的数据抽象为弹性分布式数据集(Resilient Distributed Dataset - RDD), 通过这个抽象类来对数据进行描述.
对于数据处理, 数据分析. 我主要通过高层API - DataFrame. DataFrame中添加了对数据集的结构描述, 让我们来更加方便的处理结构化数据.

# Spark的Job提交过程
[Spark的提交流程](Spark的提交流程.md)
我在这篇之前的文章中整理了Spark以Yarn为资源管理器的提交过程.
在此总结一下: 使用策略模式/工厂模式, 根据传递的参数, 来调用不同的调度器实现类, 将程序部署到不同的资源管理器上. 然后通过代理模式调用用户的代码, 对执行逻辑进行分析, 生成最终的执行计划. 后续通过配置信息以及执行计划来申请资源去做真正的数据运算操作.

# Spark执行计划的生成
[SparkContext的源码分析](SparkContext的源码分析.md)
通过SparkContext我们可以了解spark是如何对我们的任务进行划分, 调度等.

# 一些常见的问题
## 数据倾斜
http://www.jasongj.com/spark/skew/
这篇文章中很好的总结了数据倾斜的一些可能性以及处理方式.
在这里对处理方式做一下总结:
- 修改并行度, 增大/调小都可能会优化
- 将小表做broadcast, 让可能会倾斜的大表不去做分发, 在map端就可以完成计算
- 如果倾斜的key已知, 可以单独抽出来做额外的处理
- 如果倾斜的key不确定, 可以通过添加盐的方式来打散数据

## Spark的容错机制
在大数据, 分布式的处理中, 出错是很常见的事情, spark通过以下几点来做容错
- 调度层
stage失败, 通过调度器来重新启动
- 血缘层
任务重新计算时, 不需要计算全部的数据, 只需要计算失败job所依赖的部分数据
- checkpoint机制
可以通过checkpoint来将job做切分, 强行划分action, 将中间结果缓存, 后续计算可以根据这一份结果来继续计算, 而不需要从源头在进行计算

# 参考
- 极客时间《Spark 性能调优实战》
- http://www.jasongj.com/spark/skew/



