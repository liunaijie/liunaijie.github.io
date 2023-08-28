---
title: JAVA知识整理
date: 2019-09-10 20:33:24
toc: true
categories: 
	- [code, java]
tags: 
	- java
---

# JAVA基础

## 类的初始化顺序

静态变量和静态语句块会优先于实例变量和普通语句块

```java
public static String s = "静态变量";

static {
    System.out.println("静态语句块");
}

public String z = "实例变量";

{
    System.out.println("普通语句块");
}

public InitClass(){
    System.out.println("构造函数");
}
```

- 父类（静态变量，静态语句块）
- 子类（静态变量，静态语句块）
- 父类（实例变量，普通语句块）
- 父类（构造函数）
- 子类（实例变量，普通语句块）
- 子类（构造函数）

<!--more-->

## 集合

- System.arraycopy()

这个是标准类库中提供的复制数组的方法，他复制对象的时候是复制的引用，看下面这个例子，我复制完成后，对复制前的元素进行修改，复制完成的内容也发生改变。其实从这里也看出来了，原始数组也是对象的引用，因为的对元素修改后原始数组的内容也发生了改变。

![](https://raw.githubusercontent.com/liunaijie/images/master/20190912135459.png)

## 抽象类与接口

接口和抽象类都不能被实例化。抽象类是对类的抽象，而接口是对行为的抽象

- 抽象类`abstract`

加在方法上，表示该方法为抽象的，不能有方法体，一个类中一旦有方法为抽象的，则类的声明上也必须添加`abstract`关键字。抽象类中可以有非抽象方法。

- 接口`interface`

在jdk1.8之后在接口中也可以声明方法体了，但是要加`default`关键字

其实接口也是一种抽象，在jdk1.8之后他们的使用已经没有了太大的区别，所以了解他们主要还是了解他们两个的设计目的，为什么要用，什么情况下用，这是我从知乎上看到的一段解释

> 接口的设计目的，是对类的行为进行约束（更准确的说是一种“有”约束，因为接口不能规定类不可以有什么行为），也就是提供一种机制，可以强制要求不同的类具有相同的行为。它只约束了行为的有无，但不对如何实现行为进行限制。对“接口为何是约束”的理解，我觉得配合泛型食用效果更佳。
>
> 而抽象类的设计目的，是代码复用。当不同的类具有某些相同的行为(记为行为集合A)，且其中一部分行为的实现方式一致时（A的非真子集，记为B），可以让这些类都派生于一个抽象类。在这个抽象类中实现了B，避免让所有的子类来实现B，这就达到了代码复用的目的。而A减B的部分，留给各个子类自己实现。正是因为A-B在这里没有实现，所以抽象类不允许实例化出来（否则当调用到A-B时，无法执行）。

## 线程

[链接](https://www.baidu.com)

# 反射

**Class.getName方法在应用于数组类型的时候会返回一个奇怪的名字**

- Double[].class.getName()

  返回`[Ljava.lang.Double;`

- int[].class.getName()

  返回`[I`

## JAVA8新特性

- lambda
- Stream API
- Date Time API 
- 函数式编程
- 接口实现方法，hashmap红黑树
- 。。。

# 数据结构

## 链表

1. 给定一个单向链表，给定一个链表中的节点，要求删除这个节点，怎么删除？

答：根据头部节点，拿到这个要删除节点的上一个节点，记做`before`，然后将`before`节点的`next`节点指向要删除节点的`next`节点。将这个节点信息置空。完成删除。 

追问：如果不使用`before`或不给定头部节点，能不能完成删除，怎么删除？

我这个问题没有回答上来，回来后想了一下，应该是这样的解决方法：

答：拿到要删除的节点记做A，再根据这个节点获取下一个节点记做B，然后将B的值赋给A，将B的`next`也赋给A，然后将B置空。完成删除。

## 数组

1. 给定两个有序数组nums1,nums2。要求合并成一个有序数组（使用数组实现）。

答：对两个数组进行循环，得到两个值a1,b1。然后毕竟这两个元素的大小，谁小就将其放到结果数组中，然后对比下一个元素。例如：a1<b1，则下一次比较a2与b1的关系。最后有可能两个数组不一样长，有的元素没有放进去，还需要将没放进去的元素放到结果数组中。

## Map

1. 有一个`List<String>`集合，放着几个单词，比如(abc,zxy,bca,yzx,mn)最终返回的结果是((abc,bcz)(zxy,yzx)(mn))。

    ```java
    public List<List<String>> merge(List<String> list) {
      Map<String, List<String>> map = new HashMap<String, List<String>>();
      for (int i = 0; i < list.size(); i++) {
        String word = list.get(i);
        char[] chars = word.toCharArray();
        Arrays.sort(chars);
        if (map.containsKey(chars.toString())) {
          List<String> temp = map.get(chars.toString());
          temp.add(word);
        } else {
          List<String> temp = new ArrayList<String>();
          temp.add(word);
          map.put(chars.toString(), temp);
        }
      }
      List<List<String>> result = new ArrayList<List<String>>();
      Set<String> set = map.keySet();
      for (String word : set) {
        result.add(map.get(word));
      }
      return result;
    }
    ```

    