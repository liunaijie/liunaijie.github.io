---
title: Airflow调度系统
date: 2022-04-09 10:08:12
categories:
- [big_data, scheduler, airflow]
tags: 
- scheduler
- airflow
---

# 前言

我们组内使用Airflow来做日常的任务调度也有一年多的时间了, 今天写这篇文章来对Airflow进行一下记录.

# 组件

Airflow需要的几个基础组件为:

- airflow-scheduler

- airflow-webserver

- airflow-worker

- airflow-flower

- mysql(也可以使用其他数据库)

- redis(也可以使用其他消息队列)

	前缀为airflow的是airflow的内部组件, 除此之外还需要数据库和一个消息队列

<!--more-->

![](https://raw.githubusercontent.com/liunaijie/images/master/371649498716_.pic.jpg)

我们根据这个架构图一起看下这些组件分别是什么作用:

首先来解释一个名词 : DAG文件, 在airflow中将一个任务的整体流程称为一个DAG, 这个DAG里面可以有多个子任务. 由于Airflow是使用python编写的, 所以需要将这个DAG的流程定义为一个python文件.

- airflow-scheduler

	airflow的核心组件, 作用是扫描dag存入数据库. 检查任务的依赖状态, 如果可以执行则将任务放到消息队列中

	默认是单节点, 当使用MySQL 8.x版本以上以及Postgres 9.6版本以上可以实现多节点. 

- airflow-webserver

	UI页面, 提供可视化操作, 监控、管理dag.

- airflow-worker

	真正干活的节点, 执行任务和上报任务的状态

- airflow-flower

	监控airflow集群的状态

- mysql(也可以使用其他数据库)

	存储调度信息、任务状态等元数据信息

- redis(也可以使用其他消息队列)

	scheduler将需要运行的任务放到消息队列中, worker拉取任务去执行

# 支持的执行器(Operators)类型

operator执行器代表如何去运行一个任务. 这里简单介绍一下两种类型:

1. BashOperator

	在Bash shell中执行命令, 可以直接执行命令也可以去执行shell脚本

	```py
	bash_task1 = BashOperator(
			    task_id = 'bash_task1',
			    bash_command = 'echo 123',
			    dag = dag
	)
	```

	命令中也可以使用参数模版

	```pyt
	bash_task2 = BashOperator(
	    task_id='bash_task2',
	    bash_command='echo "run_id={{ run_id }} | dag_run={{ dag_run }}"',
	    dag=dag
	)
	```

	如果要去执行shell脚本, 则需要注意在脚本名词后要添加空格

	```py
	bash_task3 = BashOperator(
	    task_id='bash_task3',
	    # 如果不添加空格, 会报错
	    bash_command="/home/batcher/test.sh ",
	    dag=dag
	   )
	```

2. PythonOperator

	也可以编写python函数来实现一些功能

	```pyth
	 def print_context ( ds , ** kwargs ):
	    pprint ( kwargs )
	    print ( ds )
	    return 'Whatever you return gets printed in the logs'
	
	python_task1 = PythonOperator (
	    task_id = 'python_task1' ,
	    provide_context = True ,
	    python_callable = print_context ,
	    dag = dag 
	 )
	```

	这里就是去执行了上面的python函数.

# 配置

## 关键项

- dags_folder: 存储dag的文件夹
- default_timezone : 时区设置
- parallelism : 任务的并行度, 整个集群可以同时运行的任务数量, 包括正在运行的, 等待运行的, 重试的等等. 当任务达到上限后, 其他任务都会排队等待. 相当于消息队列的长度.
- dag_concurrency :  单个dag运行同时执行的数量
- plugins_folder : 自定义插件的位置

## webserver

- expose_config : 是否在UI上展示配置项