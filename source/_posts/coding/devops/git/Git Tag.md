---
title: GitTag
date: 2022-03-09 20:25:23
categories:
  - - coding
    - devops
tags:
  - devops/git
---

Git commit是一次文件提交.
而Git Tag则是对某个时间点的提交进行标记, 例如版本1, 版本2等等.

# 基本命令

## 列出标签
```shell

git tag
# 列出符合 1.0.*的所有标签
git tag -l "v1.0.*"
```

## 创建标签
### 轻量标签

```
git tag <tag_name>
git tag v1.1
```

### 附注标签

```
git tag -a <tag_name> "<commit_info>"
git tag -a v1.1 "这是1.1版本"
```

### 对历史的commit打标签

```
git tag -a <tag_name> <commit_id>
```

## 查看标签

```
git show <tag_name>
```

## 推送标签

```
git push origin <tag_name>
```

### 推送所有的标签

```
git push origin --tags
```

## 删除标签

```
git tag -d <tag_name> # 此操作不会删除远程标签
```

### 删除远程标签

```
git push origin --delete <tag_name> 

```

## 检出标签

```
git checkout <tag_name> # 只检出不会创建新的分支, 通常不推荐这样做
git checkout -b <new_branch_name> <tag_name> # 从这个tag检出, 并创建一个新分支

```


