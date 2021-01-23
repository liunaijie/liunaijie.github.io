---
title: list循环添加相同的map
date: 2017-09-25 10:55:04
categories: "java"
tags: 
	- java
---

list里面嵌套map，如果map相同，后面的map信息会替代前面的map信息，所以要将map的new放在循环里

如果将map放在循环外，list的信息将全为最后一个map的信息

```
Map map=new HashMap();
List list=new ArrayList();
for (int i=0;i<10;i++){
   map.put("first",i);
   map.put("second",i+1);
   list.add(map);
}
System.out.println(list);
```
结果为[{first=9,second=10}]

```
List list=new ArrayList();
for (int i=0;i<10;i++){
  Map map=new HashMap();
  map.put("first",i);
  map.put("second",i+1);
  list.add(map);
}
System.out.println(list);
```

结果为[{first=0,second=1},.....,{first=9,second=10}]

因为map添加相同的键，后面的值会覆盖前面的值，所以我们在循环的时候需要重新new这个map