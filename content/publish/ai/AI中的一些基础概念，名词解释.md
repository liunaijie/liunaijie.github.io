---
title: AI中的一些基础概念，名词解释
date: 2026-05-29
categories:
  - publish
tags:
  - AI
---
# TL;DR
这篇文章不讲模型训练，不讲太底层的技术细节，只整理 AI 应用层最常见的一批名词。目标不是把每个词讲得非常学术，而是用尽量通俗的方式，把它们之间的关系讲清楚。
<!--more-->

# 先用一句人话讲清楚
如果把一个 AI 应用比作“请一位很聪明的助理帮你办事”，那大概可以这样理解：

- `LLM` 是这个助理的大脑
- `Prompt` 是你给它的任务说明
- `Context` 是它现在手边能看到的资料
- `Tools` 是它可以调用的外部工具
- `RAG` 是“先查资料再回答”
- `MCP` 是让它统一连接工具和资料的接口标准
- `Agent` 是这个助理开始自己分步骤干活的形态
- `Skills` 是它处理某类任务时采用的一套固定方法

如果只记一句话，可以记这个：

> AI 应用这件事，本质上就是：让一个会理解语言的“大脑”，拿着足够的上下文，按提示词和流程，去调用外部工具，把事情做完。

# 生活类比图解
可以把一套常见的 AI 应用，想象成一个“数字助理办公室”：
![](Pasted%20image%2020260531123637.png)

这个图里最重要的区别是：

- `LLM` 负责“想”
- `Context` 负责“给它看什么”
- `Tools` 负责“让它做什么”
- `Workflow / Agent` 负责“按什么顺序做”

# 第一部分：主线上的核心名词

## 1. LLM 大模型
LLM 是 `Large Language Model`，中文通常叫“大语言模型”。

最通俗的理解，可以把它看成一个“见过海量文本、很会接话、很会组织语言的大脑”。你给它一句话，它会根据以前学到的大量语言规律，生成最合适的下一步回答。

它擅长的事情通常包括：

- 聊天
- 写作
- 总结
- 翻译
- 改写
- 代码辅助

但它也有边界：

- 它不天然联网
- 它不天然知道你公司的私有资料
- 它不天然会调用外部工具
- 它也可能一本正经地说错话

一句话理解：`LLM 是 AI 应用的语言大脑。`

## 2. Prompt 提示词
Prompt 就是你给 AI 的输入指令。

最简单的 Prompt，可能就是一句话：

> 帮我把这段内容总结成 3 个要点。

复杂一点的 Prompt，可能会同时规定：

- 角色
- 目标
- 输出格式
- 限制条件
- 示例

通俗地说，Prompt 就像你在给一个助理布置任务。你说得越清楚，结果通常越稳定。

一句话理解：`Prompt 决定你想让 AI 干什么。`

## 3. System Prompt / User Prompt
这两个词很容易一起出现。

- `System Prompt` 可以理解成系统层面的总规则
- `User Prompt` 就是用户当前这次提的具体要求

比如：

- 系统规则可能是：你是一个客服助手，回答要简洁，不能编造售后政策
- 用户要求可能是：帮我写一段退款说明

通俗理解：`System Prompt` 像公司制度，`User Prompt` 像今天交给你的任务单。

## 4. Context 上下文
Context 就是模型当前这一轮能看到的全部信息。

它通常包括：

- 你的问题
- 前面的对话历史
- 系统规则
- 上传的文件
- 外部检索到的内容
- 工具返回的结果

最通俗的比方，是 AI 桌上现在摊开的那几页纸。纸上写了什么，它就能参考什么；没摆到桌上的，它就看不到。

一句话理解：`Context 决定 AI 回答时手里有什么材料。`

## 5. Context Window 上下文窗口
Context Window 可以理解成“这张桌子到底有多大”。

因为模型能一次看到的内容不是无限的，所以能放进上下文的内容也有限。这个上限通常就叫 `Context Window`。

通俗理解：

- `Context` 是桌上的资料
- `Context Window` 是桌子的大小

桌子太小，资料放不下；资料太多，前面的内容可能被挤掉。

## 6. Tools / Tool Use / Function Calling
这几个词本质上在讲一件事：`让模型不只会说，还能调用外部能力。`

常见工具包括：

- 搜索网页
- 查数据库
- 读文件
- 调日历
- 发消息
- 运行代码
- 调业务接口

`Function Calling` 或 `Tool Calling`，说白了就是：模型先判断现在需要哪个工具，然后按照约定格式发起调用，再根据工具返回结果继续回答。

通俗理解：以前 AI 只能“动嘴”，现在开始能“伸手拿工具”了。

## 7. Knowledge Base 知识库
Knowledge Base 可以理解成“专门给 AI 查的资料库”。

它里面可能放的是：

- 公司文档
- 产品手册
- FAQ
- 会议纪要
- 项目资料
- 规范说明

当你不想让 AI 只靠它训练时见过的公共知识回答，而希望它更依赖你自己的资料时，就往往会用到知识库。

一句话理解：`Knowledge Base 是 AI 的专用资料柜。`

## 8. RAG 检索增强生成
RAG 是 `Retrieval-Augmented Generation`，常翻成“检索增强生成”。

它的核心意思是：

1. 先去知识库或资料库里找相关内容
2. 把找到的内容塞进上下文
3. 再让模型基于这些内容来回答

所以 RAG 最通俗的理解就是：

> 先开卷查资料，再组织答案。

它常被用来减少胡编，也让回答更贴近你自己的数据。

这里很容易混淆的一个点是：

- `Knowledge Base` 是资料库本身
- `RAG` 是“先检索再回答”的工作方式

## 9. MCP
MCP 是 `Model Context Protocol`。

最通俗的理解，可以把它看成“AI 连接外部世界的一套通用插头标准”。官方也常用类似 `USB-C for AI` 的比喻。

以前每接一个新工具，都像要单独拉一根线；有了 MCP 之后，只要 AI 应用和工具双方都支持这套协议，连接方式就会统一很多。

它能连接的通常包括：

- 文件
- 数据库
- 搜索
- 业务系统
- 第三方应用
- 工作流

一句话理解：`MCP 不是模型，而是模型连接工具和数据的标准接口。`

## 10. Agent 智能体
Agent 一般翻成“智能体”。

如果只看普通聊天，通常是“你问一句，它答一句”；但 Agent 更像“会自己分步骤做事的 AI 助手”。

比如你说：

> 帮我整理这周销售会议的重点，提炼行动项，再同步到团队文档。

一个 Agent 可能会这样工作：

1. 先读会议纪要
2. 再抽取重点
3. 生成待办事项
4. 调文档工具写进去
5. 需要的话再发一条提醒

所以 Agent 往往不只是一个模型，而是一套组合：

`Agent = 模型 + 上下文 + 工具 + 目标 + 执行流程`

一句话理解：`Agent 是开始自己拆步骤、调工具、完成任务的 AI 形态。`

## 11. Workflow 工作流
Workflow 就是“做事步骤的编排”。

有些 AI 应用看起来很聪明，其实背后不一定是完全自由发挥的 Agent，而是提前设计好的流程，例如：

1. 先分类问题
2. 再搜索知识库
3. 然后生成回答
4. 最后检查格式

这种时候，AI 更像是在一条既定流水线上工作。

通俗理解：`Workflow` 是“这件事应该按什么步骤做”。

## 12. Automation 自动化
Automation 是“把流程自动跑起来”。

比如：

- 新邮件来了，先总结，再写草稿回复
- 新会议记录生成后，自动提炼行动项
- 每天定时汇总销售数据并生成日报

如果说 `Workflow` 是步骤设计，`Automation` 就更强调“这套步骤自动执行，不用人每次手动点”。

## 13. Memory 记忆
Memory 可以理解成“AI 在多轮使用中保留下来的信息”。

它不一定等于模型真的像人一样记住，而更常见的是系统层面帮它保存了一些信息，比如：

- 你的偏好
- 项目背景
- 常用格式
- 上次任务的中间结果

通俗理解：`Memory` 是让 AI 下次别又从零开始。

## 14. Skills
Skills 可以理解成“给 AI 的专长卡”或者“做事方法包”。

一个 Skill 往往会规定：

- 什么任务触发它
- 应该按什么流程做
- 优先看哪些资料
- 用哪些工具
- 输出长什么样

所以 Skill 不等于模型本身，而更像是“这类事情最好按这套方法办”。

通俗理解：

- `LLM` 是大脑
- `Agent` 是开始做事的助手
- `Skills` 是这个助手处理某类任务时采用的固定工作方法

# 第二部分：这些词之间到底是什么关系
如果把上面这些词串起来，一套最典型的 AI 应用，大概是这样工作的：

1. 用户先给出 `Prompt`
2. 系统再把规则和资料整理成 `Context`
3. 如果上下文不够，就去 `Knowledge Base` 做 `RAG`
4. 如果需要行动，就调用 `Tools / Function Calling`
5. 如果工具太多、接法太散，就用 `MCP` 统一连接
6. 如果整件事要按步骤完成，就形成 `Workflow`
7. 如果这套流程能自己持续执行，就更像 `Agent`
8. 如果某类任务有固定处理套路，就会配上 `Skills`

一句特别适合记忆的话：

> `LLM` 负责理解语言，`Prompt` 负责交代任务，`Context` 负责提供材料，`Tools` 负责动手，`MCP` 负责接线，`Workflow` 负责排步骤，`Agent` 负责把事情做完。

# 术语关系总览表
| 名词 | 最通俗的理解 | 它主要解决什么问题 | 和谁最容易一起出现 |
| --- | --- | --- | --- |
| `LLM` | AI 的大脑 | 理解和生成语言 | Prompt, Context, Agent |
| `Prompt` | 你交代的任务 | 告诉 AI 该干什么 | System Prompt, User Prompt |
| `System Prompt` | 系统层规则 | 约束 AI 的整体行为 | User Prompt |
| `User Prompt` | 用户这次的具体要求 | 发起当前任务 | System Prompt |
| `Context` | AI 当前能看到的材料 | 给回答提供依据 | Context Window, RAG |
| `Context Window` | 上下文容量上限 | 限制一次能看多少内容 | Context |
| `Tools / Function Calling` | AI 可调用的工具 | 让 AI 不只会说，还能做事 | Agent, MCP |
| `Knowledge Base` | 给 AI 查的资料库 | 提供私有或专属知识 | RAG, Grounding |
| `RAG` | 先查资料再回答 | 降低胡编，提高贴合度 | Knowledge Base, Context |
| `Grounding` | 让回答落在证据上 | 减少飘、减少编 | RAG, Context |
| `Hallucination` | 一本正经地说错话 | 提醒你不要盲信输出 | Grounding, RAG |
| `MCP` | AI 世界的通用插头 | 统一连接工具和数据 | Tools, Agent |
| `Workflow` | 做事步骤编排 | 让任务有稳定流程 | Automation, Agent |
| `Automation` | 自动跑流程 | 减少手动重复操作 | Workflow, Agent |
| `Memory` | 帮 AI 留存信息 | 让后续任务别总从零开始 | Context, Agent |
| `Agent` | 会拆步骤干活的 AI 助手 | 把多步任务真正执行完 | Tools, Workflow, MCP |
| `Skills` | AI 的做事方法包 | 让某类任务表现更稳定 | Agent, Workflow |

# 最后给自己一个简单记忆法
如果以后再看到这些词，可以先别急着查定义，先问自己 4 个问题：

1. 这是在说 AI 的“大脑”吗
2. 这是在说 AI“看到了什么”吗
3. 这是在说 AI“能调用什么工具”吗
4. 这是在说 AI“怎么把一件事做完”吗

很多术语其实都能塞回这 4 个篮子里：

- 大脑类：`LLM`
- 输入和材料类：`Prompt`、`Context`、`Knowledge Base`、`RAG`
- 工具连接类：`Tools`、`Function Calling`、`MCP`
- 执行方式类：`Workflow`、`Automation`、`Agent`、`Skills`

# 参考
- [IBM: What are large language models (LLMs)?](https://www.ibm.com/topics/large-language-models)
- [OpenAI: Prompt engineering](https://platform.openai.com/docs/guides/prompt-engineering)
- [OpenAI: Function calling](https://platform.openai.com/docs/guides/function-calling?api-mode=chat)
- [OpenAI: Using tools](https://platform.openai.com/docs/guides/tools?api-mode=chat)
- [OpenAI: File search](https://platform.openai.com/docs/guides/tools-file-search/)
- [OpenAI: Why language models hallucinate](https://openai.com/index/why-language-models-hallucinate/)
- [Model Context Protocol 官方介绍](https://modelcontextprotocol.io/introduction)
- [Anthropic: Building effective agents](https://www.anthropic.com/engineering/building-effective-agents)
- [Anthropic: Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
