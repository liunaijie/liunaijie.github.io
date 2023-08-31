---
title: 'Mybatis是如何防止SQL注入的,不用Mybatis如何实现SQL注入'
date: 2020-01-06 15:00:12
tags: 
- mybatis
---

![](https://raw.githubusercontent.com/liunaijie/images/master/happy-new-year-4718894_640.png)

Mybatis这个框架在日常开发中用的很多，比如面试中经常有一个问题：`$`和`#`的区别，它们的区别是使用`#`可以防止SQL注入，今天就来看一下它是如何实现SQL注入的。

# 什么是SQL注入

在讨论怎么实现之前，首先了解一下什么是SQL注入，我们有一个简单的查询操作：根据id查询一个用户信息。它的sql语句应该是这样：`select * from user where id = `。我们根据传入条件填入id进行查询。

如果正常操作，传入一个正常的id，比如说2，那么这条语句变成`select * from user where id =2`。这条语句是可以正常运行并且符合我们预期的。

但是如果传入的参数变成` '' or 1=1`，这时这条语句变成`select * from user where id = '' or 1=1`。让我们想一下这条语句的执行结果会是怎么？它会将我们用户表中所有的数据查询出来，显然这是一个大的错误。这就是SQL注入。

<!--more-->

# Mybatis如何防止SQL注入

在开头讲过，可以使用`#`来防止SQL注入，它的写法如下：

```sql
<select id="safeSelect" resultMap="testUser">
   SELECT * FROM user where id = #{id}
</select>
```

在mybatis中查询还有一个写法是使用`$`，它的写法如下：

```sql
<select id="unsafeSelect" resultMap="testUser">
   select * from user where id = ${id}
</select>
```

当我们在外部对这两个方法继续调用时，发现如果传入安全的参数时，两者结果并无不同，如果传入不安全的参数时，第一种使用`#`的方法查询不到结果(`select * from user where id = '' or 1=1`)，但这个参数在第二种也就是`$`下会得到全部的结果。

并且如果我们将sql进行打印，会发现添加`#`时，向数据库执行的sql为:`select * from user where id = ' \'\' or 1=1 '`，它会在我们的参数外再加一层引号，在使用`$`时，它的执行sql是`select * from user where id = '' or 1=1`。

## 弃用`$`可以吗

我们使用`#`也能完成`$`的作用，并且使用`$`还有危险，那么我们以后不使用`$`不就行了吗。

并不是，它只是在我们这种场景下会有问题，但是在有一些动态查询的场景中还是有不可代替的作用的，比如，动态修改表名`select * from ${table} where id = #{id}`。我们就可以在返回信息一致的情况下进行动态的更改查询的表，这也是mybatis动态强大的地方。

# 如何实现SQL注入的，不用Mybatis怎么实现

其实Mybatis也是通过jdbc来进行数据库连接的，如果我们看一下jdbc的使用，就可以得到这个原因。

`#`使用了`PreparedStatement`来进行预处理，然后通过set的方式对占位符进行设置，而`$`则是通过`Statement`直接进行查询，当有参数时直接拼接进行查询。

所以说我们可以使用jdbc来实现SQL注入。

看一下这两个的代码:

```java
public static void statement(Connection connection) {
  System.out.println("statement-----");
  String selectSql = "select * from user";
  // 相当于mybatis中使用$，拿到参数后直接拼接
  String unsafeSql = "select * from user where id = '' or 1=1;";
  Statement statement = null;
  try {
    statement = connection.createStatement();
  } catch (SQLException e) {
    e.printStackTrace();
  }
  try {
    ResultSet resultSet = statement.executeQuery(selectSql);
    print(resultSet);
  } catch (SQLException e) {
    e.printStackTrace();
  }
  System.out.println("---****---");
  try {
    ResultSet resultSet = statement.executeQuery(unsafeSql);
    print(resultSet);
  } catch (SQLException e) {
    e.printStackTrace();
  }
}

public static void preparedStatement(Connection connection) {
  System.out.println("preparedStatement-----");
  String selectSql = "select * from user;";
  //相当于mybatis中的#，先对要执行的sql进行预处理，设置占位符，然后设置参数
  String safeSql = "select * from user where id =?;";
  PreparedStatement preparedStatement = null;
  try {
    preparedStatement = connection.prepareStatement(selectSql);
    ResultSet resultSet = preparedStatement.executeQuery();
    print(resultSet);
  } catch (SQLException e) {
    e.printStackTrace();
  }
  System.out.println("---****---");
  try {
    preparedStatement = connection.prepareStatement(safeSql);
    preparedStatement.setString(1," '' or 1 = 1 ");
    ResultSet resultSet = preparedStatement.executeQuery();
    print(resultSet);
  } catch (SQLException e) {
    e.printStackTrace();
  }
}

public static void print(ResultSet resultSet) throws SQLException {
  while (resultSet.next()) {
    System.out.print(resultSet.getString(1) + ", ");
    System.out.print(resultSet.getString("name") + ", ");
    System.out.println(resultSet.getString(3));
  }
}
```

# 总结

- Mybatis中使用`#`可以防止SQL注入，`$`并不能防止SQL注入
- Mybatis实现SQL注入的原理是调用了jdbc中的`PreparedStatement`来进行预处理。