---
title: java解决经典问题
date: 2017-11-27 15:52:41
categories: 
	- [code, java]
toc: true
tags: 
	- java
	- 算法
---

# 反转排序

以相反的顺序把原有数组的内容重新排序
```
/**
*基本思想：将数组的最后一个元素与第一个元素替换，倒数第二个元素与第二个元素替换
*/
public void ReverseSort(int[] array){
    for(int i=0;i<array.length/2;i++){
        int temp=array[i];
        array[i]=array[array.length-1-i];
        array[array.length-1-i]=temp;
    }
}
```


# 费氏数列
题目：古典问题：有一对兔子，从出生后第3个月起每个月都生一对兔子，小兔子长到第四个月后每个月又生一对兔子，假如兔子都不死，问第n个月的兔子数量为多少？
分析：兔子的数量规律为：1,1,2,3,5,8,13,21....
当n>=3时，fn=f(n-1)+f(n-2); n为下标

java实现：

```
public int getCount(int N){
    if(N==1||N==2){
        return 1;
    }else {
        return getCount(N-1)+getCount(N-2);
    }
}
```

# 判断素数个数并输出
素数：除了1和它本身以外不再有其他因数
判断N到M直接素数的个数，并输出（N < M）

```
/**
* 两次循环
*第一次循环是n到m，取每个数
*第二个循环是判断这个数是不是素数
*/
public void judgePrimeNumber(int N;int M){
    int count=0;
    for(int i=N;i<=M;i++){
        boolean flag=true;
        //从2到自身-1，如果有因数，则退出判断
        for(int j=2;j<i;j++){
            if(i%j==0){
                flag=flase;
                break;
            }
        }
        //判断这个数是不是素数，如果是则数量加1并打印
        if(flag==true){
            count+=1;
            System.out.print(i+" ");
        }
    }
    System.out.println("从"+N+"到"+M+"有"+count+"个素数");
}
```

# 打印图形类
菱形：
```
   * 
  *** 
 *****
*******
 *****
  ***
   *
```
java实现：
```
/**
*主要分两部分实现，上三角形和下三角形
*上三角形规律：空格数逐层减1，* 逐层加2
*下三角规律：空格数加1；* 逐层减3
*/
public void lingxing(){
    //控制上三角的循环
    for(int i=1;i<=4;i++){
        //打印空白
        for(int k=1;k<=4-i;k++){
            System.out.print(" ");
        }
        //打印 *
        for(int j=1;j<=2*i-1;j++){
            System.out.print("*");
        }
        //换行
        System.out.print();
    }
    //下三角
    for(i=3;i>=1;i--){
        for(int k=1;k<= 4-i;k++){
            System.out.print(" ");
        }
        for(int j=1;j<=2*i-1;j++){
            System.out.print("*");
        }
        System.out.println();
    }
}
```
打印三角形
```
*
***
******
********
******
***
*
```
代码是菱形去掉打印空格的部分