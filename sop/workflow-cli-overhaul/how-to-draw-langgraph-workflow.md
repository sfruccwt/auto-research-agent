# 怎么样去画 LangGraph 的流程图

状态：调研汇总草案
核对时间：2026-06-17

## 0. 结论先行

这份文档汇总两轮检索结果：第一轮找真实 LangGraph workflow 案例，第二轮补社区讨论和小红书图文笔记。它回答一个问题：当一个 workflow 里每个节点都不轻，比如 `Opening`、`Search Round`、`Round Review` 内部都有较重逻辑时，总图应该画到什么颗粒度。

核心结论：

1. 总图不应该照官方示例那样过度简化，也不应该把 prompt、字段、工具调用全部摊平。
2. 总图应该画“会改变控制流、状态边界、人工审批、并行汇合或产物交接”的节点。
3. 复杂节点应该折叠成一个主节点，再给子图和节点契约表。
4. 人工介入如果会暂停、审批、修改、恢复 workflow，就应该是显式节点，不只是边上的注释。
5. `xray=True` / 展开图适合调试和校验，不适合作为用户首先阅读的总图。

推荐文档结构：

```text
总览图：主流程、人工 gate、关键产物边界
局部图：Opening / Search Round / Round Review / Child Run / Delivery
节点契约表：每个节点读什么、写什么、谁触发、失败后去哪
调试图：需要时保存 LangGraph xray / Mermaid 原始输出
```

## 1. 画图颗粒度规则

| 应该进总图 | 不应该进总图 |
|---|---|
| 用户可审阅的工作单元 | 单个 prompt |
| 会暂停等待人的 review gate | 具体 UI 渠道，如 Slack、网页表单 |
| 会改变路线的 judgment / router / grader | judgment prompt 的细节 |
| 并行 fan-out / fan-in 的汇合点 | 每个搜索 query 或 API 参数 |
| 子流程 / 子 run 的入口和回填口 | 子流程内部所有节点 |
| 关键 artifact 生成点 | artifact 的完整字段 |
| 失败、拒绝、超时、重试的控制出口 | 底层异常栈或重试实现 |

节点命名应该用“可审计动作”，不要用泛化词：

| 泛化命名 | 更好的命名 |
|---|---|
| `Process` | `Opening Brief` |
| `Handle` | `Round Review Gate` |
| `Search` | `Search Round: Evidence Collection` |
| `Judge` | `Enoughness / Next-step Judgment` |
| `Human` | `Human Review Gate` |
| `Write` | `Memo Draft` / `Output Draft` |

## 2. 真实案例给出的规律

| 案例 | URL | 画图方式 | 可借鉴点 |
|---|---|---|---|
| Paper2Manim | https://github.com/jwj1342/Paper2Manim/blob/aec202768124e5e2c318793ad843d6e8354b66e2/docs/graphs.md | 父图画 `parser / summarizer / storyboarder / run_scene / concat`，`run_scene` 再单独画子图 | 最适合本项目：父图 + 子图 + 节点读写表，不把复杂循环塞进一张图 |
| Cisco Agents Workshop HITL | https://github.com/langchain-ai/cisco-agents-workshop/blob/a73e0f429c4ac0de08a74efe78ba98d090aab4eb/notebooks/hitl.ipynb | `triage_router / triage_interrupt_handler / response_agent / interrupt_handler` | 人审节点直接暴露 interrupt / review handler 语义，比抽象写 `review` 更可审计 |
| Elastic HITL LangGraph | https://www.elastic.co/search-labs/blog/human-in-the-loop-hitllanggraph-elasticsearch | 法律先例检索中显式画搜索、选择、验证、澄清、草稿、最终分析 | 复杂判断节点仍折叠，但人审、澄清、验证是主流程节点 |
| Self-RAG notebook | https://github.com/yip-kl/enhanced-self-rag/blob/c7b2a8e2d427dd9f8b41953ca1e2dfaecfa39a8f/langgraph_self_rag.ipynb | `retrieve / grade_documents / generate / transform_query` | 判断节点本身要画出来；路由结果通过边标签表达 |
| Multi-agent notebook | https://github.com/PradipNichite/FutureSmart-AI-Blog/blob/8f1ed20f09ac6720b4201dc23c54f8b6fdfd0d2d/Multi%20Agent%20system%20with%20LangGraph/Multi_agent_LangGraph.ipynb | 先画单 agent 工具循环，再画 supervisor + worker 总图 | 多 agent 不要把每个 worker 的 tool 细节摊到主图 |
| Red Canary osquery agent | https://github.com/redcanaryco/osquery-forensics-agent/blob/835f525176178c103a3f63857b41c15afaf2ac1d/README.md | 先 `prepare_input_data`，再多个并行 analysis nodes，最后 `aggregate_results` 和 report nodes | 并行节点可以进总图，但必须有显式汇合节点 |
| Stateful customer support bot | https://www.codersarts.com/post/how-to-build-a-stateful-customer-support-bot-with-langgraph-hitl-and-zendesk-auto-ticketing | `Intake / KB Retrieval / Sentiment Classifier / Router / HITL Handler / Response Generator / Ticket Creator` | HITL 是一级节点；复杂细节放到节点说明 |
| Multi-agent research assistant | https://www.codersarts.com/post/how-to-build-a-multi-agent-research-assistant-with-langgraph-fastapi-and-next-js | `Planner -> Researcher Fan-out -> Join -> Critic -> Synthesiser -> Formatter` | fan-out、join、critic loop 值得进总图；单个 researcher 内部检索细节下沉 |
| Data analysis agent | https://github.com/izgorodin/langgraph-data-analysis-agent | `plan -> synthesize_sql -> validate_sql -> execute_sql -> analyze_df -> report` | 安全校验如果改变控制流，应是总图节点 |

共同规律：

- 真实案例不是只画 `START -> A -> B -> END`。
- 真实案例通常画到“业务功能节点 / 判断节点 / 人审节点 / agent 节点”。
- 复杂节点多数折叠，靠子图、代码说明、节点契约表展开。
- 判断节点如果会改变路线，应该画成节点，而不是只做边标签。
- 边标签很重要，常见标签包括 `approved`、`rejected`、`retry`、`continue`、`give_up`、`pass`、`fail`。

## 3. 小红书研究类 workflow 笔记

用户提供的小红书笔记：

- 标题：`Day22 demo级深度研究智能体langgraph拆解`
- URL: https://www.xiaohongshu.com/explore/69764719000000000a03dd03?xsec_token=ABkuhDH2VVsnEpaJpDMGjMua6Q_vCkRuzXJX2WYxOfUMU=&xsec_source=pc_search&source=web_explore_feed

这条内容和本项目高度相关。它拆的是一个基于 LangGraph 的 demo 级深度研究系统，主图大致是：

`用户输入 / CLI 界面层 / Coordinator / Planner / Human Review / Researcher / Rapporteur / Markdown 或 HTML 报告`。其中 `Human Review` 会回到 `Planner` 修改计划，`Researcher` 内部有继续搜索循环。

它的正文还给出这些实现点：

- `state.py` 定义 `ResearchState`，包括查询语句、研究计划、已搜集结果等。
- `research_results: Annotated[list, operator.add]` 表示新研究结果追加到列表，而不是覆盖。
- `nodes.py` 定义 `planner_node`、`human_review_node`、`researcher_node`、`rapporteur_node`。
- `graph.py` 用 `workflow.add_edge` 表达固定跳转，用 `workflow.add_conditional_edges` 表达动态分支。
- 人审机制用 `interrupt_before=["human_review"]`，在进入 `human_review` 前暂停，等待人工审批研究计划。
- 执行时通过 `stream()` 逐节点执行，遇到 `__interrupt__` 后取当前状态快照，人工审批后从中断点继续。

对本项目的启发：

1. 研究 workflow 的主图可以把 `Planner / Human Review / Researcher / Rapporteur` 这种角色化节点画出来。
2. `Human Review` 不应该隐藏在 `Planner` 内部，因为它是暂停、修改计划、恢复执行的控制点。
3. `Researcher` 内部可以有继续搜索循环，但主图只画“继续搜索 / 生成报告”的分支。
4. `state` 应作为贯穿节点的共享对象单独说明，不必把每个 state 字段塞进主图。

## 4. 社区讨论给出的补充判断

| 来源 | URL | 发现 |
|---|---|---|
| Reddit: Human intervention in agent workflows | https://www.reddit.com/r/LangChain/comments/1bjnmu4/human_intervention_in_agent_workflows/ | HITL 更像异步 checkpoint / inbox / webhook，而不是普通聊天回复；human 决策可能覆盖 AI output |
| Reddit: Complex Multi-Agent System | https://www.reddit.com/r/LangChain/comments/1byz3lr/insights_and_learnings_from_building_a_complex/ | 复杂系统应按 separation of concern 拆成 main graph 和多个 subgraph，不要把所有 agent 平铺 |
| Reddit: LangGraph QA workflow | https://www.reddit.com/r/LangChain/comments/1bsblmu/langgraph_workflow_for_quality_assurance/ | 法律文档 QA 的社区拆法包含 manual submission、pre-processing、policy checker、error suggestion、final review、approval marking |
| GitHub issue: subgraph Command.PARENT visualization | https://github.com/langchain-ai/langgraph/issues/7653 | `Command.PARENT` 这类动态跨子图路由不会天然生成完整静态图，可能需要 rendering-only destinations |
| GitHub issue: nested graph display | https://github.com/langchain-ai/langgraph/issues/2607 | 多层嵌套图和 `xray=True` 展开存在版本和深度问题，不能把展开图当唯一文档 |
| StackOverflow: subgraphs visualization | https://stackoverflow.com/questions/79769461/langgraph-subgraphs-vizualization | `get_graph(xray=True)` 可展开直接子图，但递归多层仍可能有限 |
| StackOverflow: mermaid.ink timeout | https://stackoverflow.com/questions/79575640/mermaid-ink-timeout-error-when-using-short-node-name-in-langgraph-diagram | Mermaid PNG 渲染链路不总稳定，建议保存 Mermaid 源码并准备替代渲染方式 |
| 博客园：复杂 AI 工作流子图架构 | https://www.cnblogs.com/muzinan110/p/18540191 | 复杂节点适合画成主图里的 `sub_workflow`，旁边再展开子图内部 |
| 博客园：检查点与人机交互 | https://www.cnblogs.com/muzinan110/p/18540164 | 人审节点通常和 checkpoint 绑定，适合画成“判断 / 暂停 / 恢复”结构 |
| 菜鸟教程 LangGraph 入门 | https://m.runoob.com/ai-agent/langgraph-quick-start.html | 对初学者展示 `START/END`、节点、条件边、ReAct loop、HITL 审批等基础图元 |

社区结果比官方文档多出的新信息：

- 图不只是文档插图，也可以是 debug / trace / 状态观察面板的一部分。
- 人审 gate 的真实形态通常是：暂停 workflow -> 产出 review item -> 人在队列或 inbox 中决策 -> 更新状态并 resume。
- 展开图有实现限制，尤其是 nested subgraph、`Command.PARENT`、Mermaid 渲染服务。
- 图的可读性来自层级和边标签，不来自把所有细节放在同一张图。

## 5. 与目标流程文档的关系

本文件只保留调研结论和画图原则，不再维护本项目的具体 Mermaid 图。项目自己的总图、`Search Round` 子图、`Round Review Gate` 子图、`Child Run / backfill` 树图和节点契约表，统一迁入 `workflow-cli-target-flow.md`。

一句话原则：

> 总图画“控制权、状态边界、人工 gate、产物交接”；子图画“节点内部怎么执行”；契约表写“读写什么、失败去哪”。
