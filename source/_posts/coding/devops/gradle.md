---
title: gradle笔记
date: 2020-06-20 19:33:15
categories:
- [coding, devops]
tags: 
- devops/gradle
---
编译打包时，将依赖也打入jar包，在build.gradle文件中，添加这一部分即可

```
jar {
    from {
        configurations.runtime.collect { zipTree(it) }
    }
    enabled = true
}

```

去除依赖：

```
    compile('com.ebay.fount:managed-fount-client:0.1.1') {
        exclude group: 'com.ebay.platform.security', module: 'trustfabric-client'
    }

```