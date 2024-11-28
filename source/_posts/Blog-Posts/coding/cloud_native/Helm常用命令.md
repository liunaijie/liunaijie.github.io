---
title: Helm常用命令
date: 2020-06-20 19:33:15
categories:
  - - coding
    - cloud_native
    - kubetnetes
    - helm
tags:
  - devops/kubetnetes
  - devops/helm
---
安装：

```
helm install -f xxx.yaml server-name chart-dir
```

更新：

```
helm upgrade -f xxx.yaml server-name chart-dir
```

查看部署记录

```
helm history [xxx]
 

REVISION	UPDATED                 	STATUS    	CHART           	APP VERSION	DESCRIPTION
1       	Wed Oct 21 18:33:37 2020	superseded	clickhouse-1.0.1	19.14      	Install complete
2       	Wed Oct 21 18:49:18 2020	deployed  	clickhouse-1.0.1	19.14      	Upgrade complete

```

回滚：

```
helm rollback [xxx] [version]
helm rollback clickhouse 1 #回滚到版本1

```

卸载：

```
helm uninstall server-name

```