---
title: LSM-Tree
date: 2023-09-10
categories:
  - notes
tags:
  - LSM-Tree
---

![](https://raw.githubusercontent.com/liunaijie/images/master/202309112128645.png)


写入流程：
1. 先将记录写到WAL Log中（磁盘）
2. 将数据写到内存中的MemTable，MemTable使用树或其他可以有序的结构进行存储
3. 当Memtable数据满了，将MemTable变成Immutable Memtable即不可变数据，将这个数据落地，并新建Memtable来接收数据
4. 在level0层，接收的是Immutable Memtable落地的数据块，这一层每个SSTable里数据有序，但整层是无序的，并且还可能重复
5. 定时触发Campaction操作
    即将level0层的数据块合并，写到level1层，将level1层的数据块合并写到level2层。。。
    从level1层之后每一层的数据全局有序，唯一。
    每一层的数据块大小不一致，越往下容量越大
