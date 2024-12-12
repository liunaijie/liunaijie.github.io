---
title: maven
date: 2021-01-23
categories:
  - notes
tags:
  - maven
---

*Dependency-reduced-pom.xml**

这个文件会在使用maven-shade-plugin插件时生成，可以修改配置来避免产生这个文件

```xml
<plugin>
   <groupId>org.apache.maven.plugins</groupId>
   <artifactId>maven-shade-plugin</artifactId>
   <version>2.4.3</version>
   <configuration>
      <createDependencyReducedPom>false</createDependencyReducedPom>
   </configuration>
</plugin>
```

-U 强制更新

**打包时将依赖同时打入jar包内**

```xml
<plugins>
    <plugin>
        <artifactId>maven-assembly-plugin</artifactId>
          <configuration>
              <descriptorRefs>
                  <descriptorRef>jar-with-dependencies</descriptorRef>
              </descriptorRefs>
          </configuration>
          <executions>
              <execution>
                  <id>make-assembly</id> 
                  <phase>package</phase> 
                  <goals>
                      <goal>single</goal>
                  </goals>
              </execution>
          </executions>
    </plugin>
</plugins>
```