# Phase 0 Research: Research Runner MVP

所有 spec 阶段的 NEEDS CLARIFICATION 已通过 spec 内回写解决。本文件记录 plan 阶段的技术决策——这些决策来自 spec→plan 之间的对话，落在此处便于后续 plan 修订时回查动机。

---

## D1. Runner 实现形态

**Decision**: Claude Code 作为运行时（在本工作区按 `CLAUDE.md` + `sop/` 规约运作），加上少量 PowerShell 脚本承接机械动作。**MVP 不封装任何 slash skill**。

**Rationale**:
- 研究执行本身是 Claude 全程对话——很难把"思考、对话、迭代"封装成 skill 而不损失灵活性。
- 机械、可重复的步骤（扫描对齐、建 run 目录、投递）写成脚本 → 行为稳定、可独立测试、Claude 调用即可。
- 早期项目对外暴露度比抽象封装更值钱：每一步 user 都看得见、可改、可断。等流程稳定到"每次都同样套路"再回来封装 skill。

**Alternatives considered**:
- A. **Pure Claude，无脚本**：每次 run 都要 Claude 临场决策机械步骤（扫描、对齐、文件操作），可能漂移。
- C. **Claude + 脚本 + slash skill**：把常用入口（`/runner-scan`、`/runner-start`、`/runner-deliver`、`/runner-resume`）做成 skill。被否决——MVP 阶段，skill 把步骤跳跃放大，且一旦行为还在调整，skill 会成为束缚。

---

## D2. SOP 加载方式

**Decision**: CLAUDE.md 用一行交代 `sop/` 存在 + 何时该读；Claude 在 run 启动到对应步骤时主动 Read 三份 SOP 文件。

**Rationale**:
- 渐进式披露——SOP 内容只在跑 run 时需要，不必常驻 CLAUDE.md 上下文。
- 三份 SOP（workflow / flow-card / templates）总长约 700 行，常驻太重。
- 文件独立存在便于修订（修 SOP 不动 CLAUDE.md）。

**Alternatives considered**:
- 把 SOP 全文贴进 CLAUDE.md：CLAUDE.md 膨胀且每次会话都加载。
- 把 SOP 包进 skill：skill MVP 不做（见 D1）。

---

## D3. 状态文件格式

**Decision**: `queue/*.json` 是机器可读的真源；如果某个文件未来需要人浏览版本，单独维护一个对应 `.md`，由 `queue.ps1` 从 JSON 渲染（懒生成，需要时再做）。MVP 只做 JSON。

**Rationale**:
- queue 主要被 `scan-and-align.ps1` 等脚本读写，JSON 解析最稳。
- 量小（同时 active < 10、done 累积），用 JSON 不影响人工偶尔翻看的可读性。
- MD-for-human + JSON-for-machine 双源同步是负债，等真有人读 MD 的需求再加。

**Alternatives considered**:
- 全 MD（带 yaml frontmatter）：需要解析 markdown 表格，脚本麻烦。
- SQLite：杀鸡用牛刀，违反 constitution 隐含的"纯文件"风格。

---

## D4. 默认搜索栈

**Decision**: 默认 **agent-reach**；不可用时按顺序回退 Exa MCP → Claude Code 内置 WebSearch / WebFetch。

**Rationale**:
- agent-reach 已配置且覆盖 17 平台（搜索 / 社交 / 学术 / 视频），是当前最广的入口。
- Exa MCP 已配置（`mcporter.json` 里有），覆盖学术语义搜索。
- WebSearch / WebFetch 是 Claude Code 内置兜底。

**Alternatives considered**:
- SearXNG MCP（OpenClaw `TODO.md` 提到的备选）：还没安装、未做安全审计、价值未验证。已作为独立 idea 写入 wiki，由 runner 自己跑研究后再决定是否引入。
- 只用 Claude Code 内置：覆盖太窄，错过 agent-reach 的社交 / 学术 / 视频源。

**SOP 中如何引导工具选择**：在跑研究时由 Claude 按"开题门"判定的检索面（官方 / 市场 / 学术 / 社区案例）映射到工具——不在 plan 里写死映射表，避免僵化。

---

## D5. 边界情况策略

**Decision**: MVP 不预设规模化 edge case 处理。

**Rationale**:
- 当前 wiki 仅十几个 idea，同时 active run 通常 1 个。
- 真出现边界问题再加处理，比预先猜要准。
- 已确认的两个 edge case 行为（initialization 遗留 done 全部过滤、abandoned 需要确认才能再跑）在 spec 里有 FR/Assumption 覆盖。

**Alternatives considered**:
- 在 plan 阶段就写出"100+ idea 时的扫描缓存方案"——过度设计。

---

## D6. Skill 封装策略

**Decision**: MVP 0 个 skill。下表中的候选作为后续 spec 输入，不在本 spec 范围。

| 候选 | 用途 | 后续考虑顺序 |
|---|---|---|
| `/runner-scan` | 扫 + 对齐报告 | 最值得封装（纯机械、user 触发频繁）；等流程稳定后第一个加 |
| `/runner-deliver` | 投递 | 第二顺位 |
| `/runner-start` | 启动 run | 不太值得封装——与 Claude 对话天然衔接 |
| `/runner-resume` | 恢复中断 run | 同上 |

**Rationale**: 见 D1。

**Negative guidance**: 真要加 skill 时，记得 `.claude/commands/<name>.md` 薄壳文件不能少（slash 调用入口）；只改 SKILL.md 的 user-invocable 字段不够。

---

## D7. 测试策略

**Decision**: MVP 阶段以 4 个迁移 idea（modernity / SearXNG / Beijing rental / desktop host）为 smoke 用例做端到端验证。脚本层不引入自动测试框架。

**Rationale**:
- spec SC-002 已明确："4 个迁移 idea 中至少 2 个能跑通端到端到 inbox"——这就是 MVP 的验收标准。
- 脚本只有 4 个、逻辑简单（文件读写 + JSON 操作），手测覆盖率高。
- 等真出现 regression 再引入 Pester。

**Alternatives considered**:
- 一开始就上 Pester：4 个脚本+无逻辑分支，测试代码量可能比脚本本身还多，价值低。
