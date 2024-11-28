---
title: 独特的电子邮件地址-LeetCode929
date: 2018-12-21 20:55:48
tags:
  - 算法与数据结构/Leetcode
related-project: "[[Blog Posts/coding/algorithm/leetcode/leetcode|leetcode]]"
---

# 题目描述

>  每封电子邮件都由一个本地名称和一个域名组成，以 @ 符号分隔。
>
> 例如，在 alice@leetcode.com中， alice 是本地名称，而 leetcode.com 是域名。
>
> 除了小写字母，这些电子邮件还可能包含 '.' 或 '+'。
>
> 如果在电子邮件地址的本地名称部分中的某些字符之间添加句点（'.'），则发往那里的邮件将会转发到本地名称中没有点的同一地址。例如，"alice.z@leetcode.com” 和 “alicez@leetcode.com” 会转发到同一电子邮件地址。 （请注意，此规则不适用于域名。）
>
> 如果在本地名称中添加加号（'+'），则会忽略第一个加号后面的所有内容。这允许过滤某些电子邮件，例如 m.y+name@email.com 将转发到 my@email.com。 （同样，此规则不适用于域名。）
>
> 可以同时使用这两个规则。
>
> 给定电子邮件列表 emails，我们会向列表中的每个地址发送一封电子邮件。实际收到邮件的不同地址有多少？
>
> 示例：
>
> 输入：\["test.email+alex@leetcode.com","test.e.mail+bob.cathy@leetcode.com","testemail+david@lee.tcode.com"]
> 输出：2
> 解释：实际收到邮件的是 "testemail@leetcode.com" 和 "testemail@lee.tcode.com"。
>
>
> 提示：
>
> 1 <= `emails[i]`.length <= 100
> 1 <= emails.length <= 100
> 每封 `emails[i]` 都包含有且仅有一个 '@' 字符。

<!--more-->

# 解题思路

先根据`@`将本地名称与域名进行区分，域名不用做任何操作。

将本地名称根据规则进行修改

然后再将两个信息合并添加到set中，最后返回set的数量即可。

**代码实现：**

```java
public int numUniqueEmails(String[] emails) {
  Set<String> all = new HashSet<String>();
  for (String email : emails) {
    //用@符号将两者分隔
    String[] address = email.split("@");
    //得到本地名称
    String localName = address[0];
    //判断是否有+，如果有只截取+前面的内容
    String plus = "+";
    if (localName.contains(plus)) {
				localName = localName.substring(0, localName.indexOf(plus));
		}
    //判断是否有. 如果有则替换
    String point = ".";
    if (localName.contains(point)) {
      localName = localName.replace(point, "");
    }
    //然后再将两者拼接添加到set中
    all.add(localName + "@" + address[1]);
  }
  return all.size();
}
```

