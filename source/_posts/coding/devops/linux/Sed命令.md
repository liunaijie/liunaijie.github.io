---
title: Linux-Sed命令
date: 2020-06-20 19:33:15
tags: 
- devops/linux/sed
---

行编辑器，主要使用这个命令去替换

sed的模式空间

# 基本工作方式为:

-   将文件以行为单位读取到内存(模式空间)
-   使用sed的每个脚本对该行进行操作
-   处理完成后输出该行

# 替换命令`s`

-   `sed 's/oldWork/newWord' filename` 将每一行中的第一次出现的oldWord替换为newWord并返回
-   `sed -e 's/oldWord1/newWord1' -e 's/oldWord2/newWord2' filename` 可以使用`-e`来同时替换多个词
-   `sed -i 's/oldWord1/newWord1' 's/oldWord2/newWord2' filename` 使用`-i`可以修改源文件

使用正则表达式

-   `sed 's/正则表达式/newWord' filename`
-   `sed -r 's/扩展正则表达式/newWord' filename`

加强

-   sed 's/oldWord/newWord/g' filename 全局替换复合条件的字符串
-   sed 's/oldWord/newWord/2' filename 替换第二次出现的字符串
-   sed 's/oldWord/newWord/p' filename 打印模式空间的内容，即将复合条件的行打印出来，在输出中可以看到两条重复的记录，一条为正常打印，一条为模式空间内的打印
    -   sed -n 's/oldWord/newWord' filename 只打印复合条件的记录

处理指定范围内的数据，例如只处理10-20行的记录

-   `/正则表达式/s/oldWord/newWord/g`
    
-   `行号s/oldWord/newWord/g`
    
    -   行号可以是具体的行，也可以是最后一行`$`符号
    -   可以使用两个寻址符号，也可以混合使用行号和正则地址
    
    `sed '1s/oldWord/newWord' filename` - 只处理第一行
    
    `sed '1,3s/oldWord/newWord' filename` - 处理1~3行
    
    `sed '5,$s/oldWord/newWord' filename` - 第5行到最后一行
    
    `sed '/^bin/5,10s/oldWord/newWork' filename` - 处理5～10行中以bin开头的行
    
    匹配多条命令
    
    /regular/{s/oldWord1/newWord1/;s/oldWord2/newWord2}
    
    加载脚本文件
    
    `sed -f sedScript filename`
    

# 删除

删除命令无法同时处理多条命令

sed '/deleteWord/d' filename 删除存在deleteWord的行

# 追加，插入和更改

-   追加命令a，在匹配关键字的下一行进行插入
    -   sed '/word/a hello' filename - 在存在word的每一行的前面插入一行hello
-   插入命令i，在匹配关键字的上一行进行插入
    -   sed '/word/i hello' filename - 在存在word的每一行的后面插入一行hello
-   更改命令c，将匹配关键字的当前行替换
    -   sed '/word/c hello' - 将存在word的每一行替换为hello

读文件命令 r

写文件命令 w

打印行号命令 =

下一行命令 n

# 退出命令`q`

退出命令的执行效率比其他命令高，因为当遇到退出命令时，后面的文件不会在进行读取，而其他命令是读取完整文件，在处理时仅处理n行