---
title: SBT加速
date: 2021-01-23 08:24:39
categories: "编程"
toc: true
tags: 
	- sbt
	- 编译工具

---

最近有一个项目使用到了sbt作为构建工具，在电脑上即便有科学工具，下载依赖也是巨慢无比，有时候一天都下不下来。所以这篇文章就记录一下如何对sbt进行加速。

- 编辑配置文件，添加国内源：

	```shell
	vim ~/.sbt/repository
	```

	将这个文件的信息修改为：

	```
	[repositories]
		local
		aliyun-ivy: http://maven.aliyun.com/nexus/content/groups/public, [organization]/[module]/(scala_[scalaVersion]/)(sbt_[sbtVersion]/)[revision]/[type]s/[artifact](-[classifier]).[ext]
		aliyun-maven: http://maven.aliyun.com/nexus/content/groups/public
		typesafe: http://repo.typesafe.com/typesafe/ivy-releases/, [organization]/[module]/(scala_[scalaVersion]/)(sbt_[sbtVersion]/)[revision]/[type]s/[artifact](-[classifier]).[ext], bootOnly
		typesafe2: http://repo.typesafe.com/typesafe/releases/
		sbt-plugin: http://repo.scala-sbt.org/scalasbt/sbt-plugin-releases/
		sonatype: http://oss.sonatype.org/content/repositories/snapshots
		uk_maven: http://uk.maven.org/maven2/
		repo2: http://repo2.maven.org/maven2/
	```

	

- 更改IDE配置

	![](https://raw.githubusercontent.com/liunaijie/images/master/20210123083342.png)

	我使用的是IDEA，找到sbt配置项，在`VM parameters`中填入：

	```
	-Dsbt.override.build.repos=true
	-Dsbt.repository.config=~/.sbt/repositories
	```

