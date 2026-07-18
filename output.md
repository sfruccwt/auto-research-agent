---
source: auto_research_agent
source_idea: ideas/2026-05-26-sop-workflow-solidification.md
captured: 2026-05-29
route: wiki
route_reason: "形成通用的 SOP 固化判断框架，可迁移到研究、写作、资料整理等个人 agent workflow"
status: pending
---

# 从半显性认知到可执行工作流：SOP 固化的分层路径

一个人的工作流往往不是一开始就能写成完整 SOP。更常见的状态是：人知道大概怎么做，也能判断什么结果好，但说不清每一步的规则、例外和边界。此时直接把流程写进 `AGENTS.md`、`CLAUDE.md` 或 n8n 节点图，通常会过早固化一个并不稳定的理解。

更可行的路径是：先让人和 AI 半自动协作完成任务，保留输入、输出、人工修改、失败原因和成功样例；再把重复出现、可检查、出错代价高的部分逐步升级为脚本、schema、eval、hook、state/gate 或人工审批。OpenAI 的 self-improving tax agents 案例就是类似逻辑：先从 production traces 中发现重复修正，把这些修正变成 failure signals，再转成 bounded evals 和产品改动；模糊案例继续交给人工 review [2]。

## 核心判断

SOP 固化不是“把流程写进文档”，而是“把确定性逻辑从 LLM 判断中移出”。文档和 skill 负责表达背景、偏好、术语、开放判断；真正更硬的控制来自模型外部的系统：脚本判断、parser/validator、eval gate、状态机迁移、hook 阻断和人工审批 [1,3,4,5]。

这意味着 hook、state、schema、eval、approval 这些词本身并不天然比文档硬。它们只有在改变执行路径时才更硬：

- hook 如果只是注入上下文，本质仍是动态文档；如果在工具执行前调用脚本并 deny，则是运行时阻断 [3]。
- state 如果只是 markdown 里的状态说明，仍然是文档；如果 runner 每一步都读取机器状态并据此允许或禁止迁移，才是状态机。
- schema 如果只是 prompt 中的格式要求，仍然是软约束；如果 parser 或 strict schema 校验失败就拒绝进入下一步，才是硬约束 [4]。
- eval 如果只是事后复盘，约束力有限；如果不通过就不能升级 skill、发布 workflow 或 merge 改动，才是 gate [2]。
- approval 如果只是让 AI 自我检查，不是审批；如果必须等外部人或 policy approve/deny，才是授权边界 [5]。

## 一条渐进固化路线

适合个人工作流的路线可以概括为：

> 认知外化 -> 半自动执行 -> trace/失败沉淀 -> 确定逻辑外置化 -> 渐进自动化

第一步不是问“完整 SOP 是什么”，而是收集真实案例：成功的一次、失败的一次、卡住的一次、最后人工改了什么。把案例拆成 `input -> intermediate decision -> output -> human correction -> reason`。这些材料先进入文档、template 或 skill，作为 agent 的上下文。

第二步让 agent 半自动跑任务，但要求保存 trace、人工修改和失败原因。重复失败不要只在对话里纠正，而要判断能否升级为 checklist、schema、eval、hook 或 state gate。

第三步只把确定逻辑变硬。比如“output 必须有 frontmatter 和来源列表”可以用 parser 检查；“opening 之后才能进入 research”可以用 state machine 检查；“删除文件必须人工确认”可以用 hook + approval 阻断。仍需人类审美、判断、取舍的部分，不应过早写死。

## 控制层分级

| 层级 | 固定什么 | 何时使用 | 风险 |
|---|---|---|---|
| 文档 / skill | 背景、偏好、术语、常规步骤 | 规则仍开放、需要人类解释 | 模型可能忽略或误解 |
| checklist | 重复步骤和人工 review 问题 | 漏步骤比判断错误更常见 | 仍靠 agent 或人执行 |
| schema / parser | 输出结构和最低格式 | 字段、章节、JSON、frontmatter 可机器检查 | 只能保结构，不能保事实正确 |
| eval / test | 质量样例和回归标准 | 有成功/失败样本，可形成测试集 | 覆盖不到未知失败 |
| hook / script | 必须发生或必须阻断的动作 | 出错代价高、可由脚本判定 | 脚本本身需要维护 |
| state / gate | 阶段、状态迁移、恢复 | 流程有明确阶段和过门条件 | 会把错误流程固化 |
| approval | 高风险、不可逆、合规动作 | 删除、发布、转账、跨边界写入 | 人工成本和阻塞 |
| workflow engine | 长运行、跨工具、可恢复流程 | n8n、LangGraph、Temporal 等场景 | 复杂度较高 [5,6] |

这个表的关键不是“越往下越好”，而是“只把值得变硬的部分变硬”。对个人工作流，早期最有价值的组合通常是：文档/skill 表达语义，trace 记录失败，schema/eval 检查格式和质量，hook/script 阻断高风险动作，state/gate 保证流程不跳步，human review 保留在判断不稳的地方。

## n8n、LangGraph、Temporal 的位置

n8n 适合固定稳定节点、外部服务调用、通知、审批和 API glue。它不适合直接承载尚未外化的专家判断。比如写作工作流中，“把草稿发给 Notion、Slack 通知我 review、审批后发布”适合 n8n；但“这篇文章的论证是否成立”不应一开始写成 n8n 节点。

LangGraph 和 Temporal 属于更重的 durable workflow 层。它们适合跨天/跨周、需要 checkpoint、恢复、人工中断、审计和复杂状态的流程 [6]。如果只是个人本地 workflow，先用 `state.json + validate script + gate command + hook` 往往更现实。

## 对 contextinfra 的启发

如果 contextinfra 已经在沉淀“失败 -> 可复用资产”，下一步不是简单增加更多文档，而是给资产分层：

- `context-only`：只适合召回给 agent 看。
- `checklist`：适合在人工 review 时逐项检查。
- `schema`：可以被 parser 校验格式。
- `eval`：可以成为回归样例或评分集。
- `hook`：可以在工具调用前后触发脚本。
- `gate`：可以阻止状态迁移或交付。

一个经验资产只有在“重复出现、可检测、出错代价高”时，才值得升级为硬规则。否则它更适合作为 context 或 checklist。

## 可迁移案例

研究工作流可以先固定 opening/midway/done gate、引用格式、搜索记录、判断单；开放部分保留给 agent 搜索和判断；memo 前设置人工 review。

写作工作流可以先固定读者对象、论点卡、素材清单、结构草稿、修改记录和发布前 checklist；文风和论证强弱先保留人工 review，等积累足够修改样本后再写成 skill 或 eval。

资料整理工作流可以先固定来源、命名规范、元数据、去重和投递路径；AI 负责提取和初步归类，人类审查边界案例；重复分类错误再沉淀为 schema、rules 或 eval。

## 下一步

当前证据足以支持一个轻量实验：选一个非研究类 workflow，例如写作工作流，先不做全自动，而是建立 `task template + trace log + validation script + review checklist`。如果同类错误重复出现，再把它升级为 schema、eval 或 hook。

暂不建议直接把所有 SOP 迁移到 n8n，也不建议追求完全无人值守。对于个人系统，早期更重要的是保证结构级风险可控：密钥、删除、跨工作区写入、不可恢复发布等动作必须有外部 gate。

## 来源

[1] Anthropic. "Building effective agents." 2024.
    URL: https://www.anthropic.com/engineering/building-effective-agents

[2] OpenAI. "Building self-improving tax agents with Codex." 2026.
    URL: https://openai.com/index/building-self-improving-tax-agents-with-codex/

[3] Anthropic. "Automate workflows with hooks."
    URL: https://code.claude.com/docs/en/hooks-guide

[4] OpenAI. "Introducing Structured Outputs in the API." 2024.
    URL: https://openai.com/index/introducing-structured-outputs-in-the-api/

[5] n8n Docs. "Human-in-the-loop for AI tool calls."
    URL: https://docs.n8n.io/advanced-ai/human-in-the-loop-tools/

[6] LangChain / LangGraph Docs. "Persistence."
    URL: https://docs.langchain.com/oss/python/langgraph/persistence
