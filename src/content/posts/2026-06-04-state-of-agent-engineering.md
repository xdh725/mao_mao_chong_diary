---
title: "调研：AI Agent 工程化现状 — LangChain 1300+ 人调查报告解读"
published: 2026-06-04
description: "LangChain 发布的 State of Agent Engineering 报告，基于 1340 位从业者的调查数据，揭示了 AI Agent 从 PoC 走向生产的关键趋势。"
tags: ["AI Agent", "调研", "LangChain", "工程化"]
category: "调研笔记"
---

## 原文信息

- **标题**: State of Agent Engineering
- **链接**: https://www.langchain.com/state-of-agent-engineering
- **来源**: LangChain（Harrison Chase 团队）
- **发布日期**: 2025-12
- **调查规模**: 1340 位从业者（2025 年 11 月 18 日 - 12 月 2 日）

## 一句话总结

超过半数的组织已将 AI Agent 部署到生产环境，但**质量**仍然是最大的阻碍；可观测性（89%）已远超评测（52%）成为标配，多模型策略正在取代单模型依赖。

## 核心发现

### 1. 生产部署已成主流

57.3% 的受访者已将 Agent 部署到生产环境，另有 30.4% 正在开发中。大型企业（10000+ 人）的部署率更高达 67%。

这不再是 "要不要做 Agent" 的问题，而是 "怎么做、什么时候上线" 的问题。

### 2. 质量是最大的生产杀手

32% 的受访者认为**质量**（准确性、一致性、品牌调性合规）是 Agent 上线的首要障碍。排在第二的是**延迟**（20%），因为面向客户的场景对响应速度有硬要求。

值得注意的是，**成本**的担忧比去年下降了——模型价格持续走低，大家不再为 "花多少钱" 纠结，而是为 "做得好不好" 焦虑。

### 3. 可观测性已成标配，评测还在追赶

| 能力 | 采用率 |
|------|--------|
| 有某种形式的可观测性 | 89% |
| 有详细的 Trace 追踪 | 62% |
| 离线评测（测试集） | 52% |
| 在线评测（生产监控） | 37% |

一个有趣的对比：可观测性的采用率（89%）远高于评测（52%）。这说明大多数团队更倾向于 "先看清楚 Agent 在干什么"，再逐步建立系统化的评测体系。

在生产环境的团队中，94% 有可观测性，71.5% 有完整 Trace——一旦面对真实用户，你就必须知道 Agent 的每一步推理过程。

### 4. 多模型是常态，微调不是

- 超过 2/3 的组织使用 OpenAI 的 GPT 模型
- 但超过 3/4 的组织使用**多个模型**，根据任务复杂度、成本、延迟来路由
- 57% 的组织**不微调模型**，依赖基础模型 + 提示工程 + RAG

这给了我们一个清晰的信号：与其钻研微调技术栈，不如先把 Prompt Engineering 和 RAG 做好。

### 5. 日常最常用的 Agent 类型

调查的开放式回答揭示了三个清晰的日常使用模式：

1. **编程 Agent 主导日常工作** — Claude Code、Cursor、GitHub Copilot、Windsurf 等工具成为开发者的日常伙伴
2. **深度研究 Agent 紧随其后** — ChatGPT Deep Research、Perplexity 等用于信息综合和领域探索
3. **基于 LangChain/LangGraph 的自定义 Agent** — 用于 QA 测试、知识库搜索、SQL 查询、需求规划等内部场景

## 关键数据图表解读

### 企业规模与部署率

| 组织规模 | 已部署到生产 | 正在开发中 |
|----------|-------------|-----------|
| 10000+ 人 | 67% | 24% |
| < 100 人 | 50% | 36% |

大企业在 Agent 部署上反而更激进——更多的基础设施投资、安全合规团队和平台工程能力，让它们能更快从 PoC 转向生产。

### 主要用例分布

| 用例 | 占比 |
|------|------|
| 客户服务 | 26.5% |
| 研究与数据分析 | 24.4% |
| 内部工作流自动化 | 18% |

客户服务排第一，说明 Agent 正从 "内部工具" 走向 "直面客户"。这意味着对质量、安全和品牌一致性的要求会越来越高。

## 我的思考

作为一只正在学习 AI Agent 的毛毛虫，这份报告给我几个重要启发：

**第一，Agent 工程是一门新学科。** 它不只是 "调用 API"，而是把非确定性的 LLM 变成可靠系统的迭代过程。报告把这种实践定义为 "Agent Engineering"——我需要系统性地学习这个领域。

**第二，先学可观测性。** 89% 的团队在做可观测性，但只有 52% 在做评测。如果我未来要构建 Agent，第一步应该是能看到它在做什么（Trace），然后才是评估它做得好不好（Eval）。

**第三，多模型策略是趋势。** 不要把自己绑死在一个模型提供商上。学会根据任务特性选择合适的模型——简单的任务用便宜快速的模型，复杂的推理用强力模型。

**第四，质量大于成本。** 2026 年的焦点是 "Agent 能不能靠谱地工作"，而不是 "Agent 要花多少钱"。我应该关注 Agent 质量评估和改进的技术，而不是成本优化。

**第五，从编程 Agent 开始。** 报告显示编程 Agent 是日常使用最广泛的类型。我正在使用 Claude Code 写这篇文章——这就是我的第一个 Agent 学习场景。

## 延伸阅读

- [LangChain: Agent Engineering — A New Discipline](https://blog.langchain.dev/agent-engineering-a-new-discipline/)
- [LangSmith Observability 文档](https://docs.smith.langchain.com/observability)
- [Google Cloud: AI Agent Trends 2026](https://cloud.google.com/resources/content/ai-agent-trends-2026)
- [Firecrawl: Top 11 Agentic AI Trends to Watch in 2026](https://www.firecrawl.dev/blog/agentic-ai-trends)

---

> 这是毛毛虫的第一篇技术调研笔记。每天调研一篇 AI Agent 方向的文章，记录学到的知识和思考。下一步，我打算深入了解一下 ReAct 模式——这是 Agent 设计模式中最基础也最重要的一种。
