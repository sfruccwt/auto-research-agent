# SOP Backlog

## 待改进

- [x] Research state / slot lifecycle 接入 SOP（2026-06-01，文档层已实施）
  - 目标：把 slot 从 opening clarification 字段升级为贯穿 run 的 `research-state.md`，并让每轮搜索产生 `search_round_summary.state_delta`。
  - 任务文档：`sop/tasks/research-state-slot-lifecycle.md`
  - 迁移计划：`sop/tasks/research-state-slot-lifecycle-migration-plan.md`
  - 测试方案：`sop/tasks/research-state-slot-lifecycle-test-cases.md`
  - 来源 run：`runs/2026-05-24-llm-web-search-principles-auto-research-optimization/sub/research-agent-sop-design-patterns/`

## 已改进

- [x] 开题卡：关键词压测（FR-120，2026-05-10）
- [x] 搜索路径：社区/案例面默认开 agent-reach 路搜索（FR-115，2026-05-10）
- [x] Motivation 持续捕获机制（FR-116，2026-05-10）
- [x] 路径定义清晰度（FR-122，2026-05-10）
- [x] 备忘录/产出物的核心概念必须展开（FR-117 + FR-121，2026-05-10）
- [x] 备忘录 vs output 文件区分（FR-119，2026-05-10）
- [x] 不可靠信息直接删除，不展示（FR-118，2026-05-10）
- [x] 备忘录模板增加"关键概念展开"区块（FR-117e，2026-05-10）
- [x] 开题卡迭代式填写（FR-114，2026-05-10）
- [x] 子课题拆分检查（FR-120a，2026-05-10）
- [x] 子课题拆分触发位置前移（2026-05-14，改为持续触发 + 中途门兜底）
- [x] 搜索笔记/来源记录时机（2026-05-14，改为全阶段来源标注规则）
- [x] 产出后追问/补查机制（2026-05-14，log 记 amendment 事件，轻量处理）
- [x] 关键词探针阶段——移除，搜索方向调整是正常行为（2026-05-14）
- [x] usefulness 判断模式提炼——移至 context-infrastructure 工作区（2026-05-14）
