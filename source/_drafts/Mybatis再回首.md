---
title: Mybatis 再回首
date: 2019-11-15 10:11:10
toc: true
categories: "mybatis"
tags: 
	- mybatis
	- java
thumbnail: https://raw.githubusercontent.com/liunaijie/images/master/top-view-photo-of-boat-on-seashore-2555656.jpg
---

在项目中一直使用`mybatis`作为 orm 框架，不管是之前的 ssm，还是现在的 springboot+mybatis，都是用的 mybatis 框架。

# 文档

## xml 映射文件

在 xml 映射文件中有几个顶级元素

- resultMap-最复杂也是最强大的元素，用来描述如何从数据库结果集中来记载对象
- sql-可被其他语句引用的可重用语句块
- insert-映射插入语句
- update-映射更新语句
- delete- 映射删除语句
- select-映射查询语句

### select

首先来看一下查询的映射语句块，最简单的写法是：

```xml
<select id="selectPerson" parameterType="int" resultType="hashmap">
  SELECT * FROM PERSON WHERE ID = #{id}
</select>
```

这个语句是从 person 表中查询 id 为参数的行。接受一个 int 类型的参数，返回一个 hashmap，其中的键是列名，值便是结果行中的对应值。

我们使用了`#{id}`，这会让 mybatis 创建一个预处理语句参数。与在 jdbc 中的`?`类型。就像这样：

```java
String selectPerson = "SELECT * FROM PERSON WHERE ID = ?"；
PreparedStatement ps = conn.prepareStatement(selectPerson);
ps.setInt(1,id);    
```

这样会防止 sql 注入。



# 项目实战

使用 springboot+mybatis+mysql 来构建一个项目。



# #与$的区别

先来看两段语句：

```sql
SELECT * FROM user WHERE id = #{Id}

SELECT * FROM user WHERE id = ${Id}
```

第一段参数使用了`#{id}`

# 参考

- [mybatis 官方文档](https://mybatis.org/mybatis-3/zh/sqlmap-xml.html)





