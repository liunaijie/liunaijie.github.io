---
title: Linux-AWK命令
date: 2020-06-20 19:33:15
categories:
- [coding, linux]
tags: 
- linux
---

kpi.txt

```
user1 70 80 90
user2 50 60 70
user3 50 100 30
```

对于上面的这个文件，求每个用户的平均分数：

```bash
awk '{sum=0; for(c=2;c<=NF;c++) sum+=$c; print sum/(NF-1) }' kpi.txt
```

NF表示有多少行

# 函数

## 算数函数

-   sin(); cos()
-   int()
-   rand() - 0-1直接的随机数，伪随机数，第二次获取的随机数与之前一致
-   srand() - 修改随机数的种子，配合rand()函数使用，使得每次获取的随机数不一致

## 字符串函数
