---
title: IDEA导入elipse项目
date: 2018-05-15 09:31:50
tags: 
	- idea
	- elipse
---

![选择导入方式](https://raw.githubusercontent.com/liunaijie/images/master/ideaimportProject.png)
选择导入类型，我们是导入的elipse项目，如果导入的是maven项目则选择maven  

<!-- more -->

![选择路径](https://raw.githubusercontent.com/liunaijie/images/master/selectdirectory.png)
 这里是导入文件路径。默认即可  
 ![选择项目](https://raw.githubusercontent.com/liunaijie/images/master/70001.png)
  选择导入的项目。  
  ![选择jdk版本](https://raw.githubusercontent.com/liunaijie/images/master/70002.png) 
  选择jdk版本，如果没有则可以点击绿色加号添加。  
![修改项目结构](https://raw.githubusercontent.com/liunaijie/images/master/70003.png) 
 项目导入后点击 file -> project structure 或点击右上侧的图标修改项目。  
 ![修改项目jdk和输入路径](https://raw.githubusercontent.com/liunaijie/images/master/70004.png) 
 点击 project 修改项目的jdk版本，和编译文件存放位置。
 ![修改modules](https://raw.githubusercontent.com/liunaijie/images/master/70005.png) 
 点击 modules 修改项目的jdk和删除飘红的jar包。

在 libraries中添加项目中的lib下的jar包
![添加jar包](https://raw.githubusercontent.com/liunaijie/images/master/70006.png)
点击 factes 添加web，然后选择项目。
![添加可执行文件](https://raw.githubusercontent.com/liunaijie/images/master/70007.png) 
点击artifacts 添加web application exploded 从项目中导入，

**然后将项目添加到tomcat中**
![添加到tomcat中](https://raw.githubusercontent.com/liunaijie/images/master/70008.png)
点击这个箭头，然后添加tomact server local 
![修改deployment](https://raw.githubusercontent.com/liunaijie/images/master/70009.png)
然后修改deployment，后面的路径名为启动时localhost:8080/后面的路径。
最后启动tomact就可以了。