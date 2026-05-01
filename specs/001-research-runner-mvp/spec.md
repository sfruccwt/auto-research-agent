# Feature Specification: Research Runner MVP

**Feature Branch**: `001-research-runner-mvp`
**Created**: 2026-05-01
**Status**: Draft
**Input**: User description: "Research runner MVP: pull flagged ideas from wiki, execute SOP-driven research with user-in-the-loop revision, deliver content-finalized markdown to wiki inbox"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - 单 idea 端到端跑通 (Priority: P1)

用户已在 wiki 里写好一个 idea 文件（例如 `D:/Personal LLM Wiki/research/ideas/2026-05-01-modernity-wang-minan-thirteen-lectures.md`），告诉 runner "处理这个 idea"。Runner 在本工作区开一个 run 目录，按 SOP 跑完研究、产出内容定稿，与用户多轮修订到用户认可，最终把单个 markdown 文件写入 wiki inbox。

**Why this priority**: 这是 runner 存在的全部理由。如果这一条不成立，剩下的 queue / flag / 调度都没有意义。MVP 的最小验证就是这一条端到端跑通。

**Independent Test**: 给 runner 一个已写好的 idea 文件路径（例如 4 个迁移 idea 之一），观察是否能产出 wiki inbox 里一份**用户认可的、结构完整、引用可追溯的**研究成果文件。无需其他任何机制配合。

**Acceptance Scenarios**:

1. **Given** wiki 中有一个已写好的 idea 文件，**When** 用户在本工作区会话里告诉 runner "跑这个 idea"，**Then** runner 在 `runs/<id>/` 下创建工作目录，把 idea 冻结快照为 `idea.md`
2. **Given** run 目录已建立、SOP 文件存在于 `sop/`，**When** runner 开始研究，**Then** runner 按 SOP 流程产出至少：开题判断、第一轮信息地图、综合判断、最终成稿草稿
3. **Given** 草稿已就位，**When** 用户审阅并提出修改要求，**Then** runner 在同一个 run 目录中迭代修改，不重新启动研究
4. **Given** 用户认可当前草稿，**When** runner 投递，**Then** wiki inbox 里出现一个符合 `templates/inbox-output.md` 约定的 markdown 文件，且 `runs/<id>/` 中保留完整过程留痕
5. **Given** 一份成果已投递，**When** 用户检查，**Then** wiki 中的原 idea 文件**未被修改**，runner 工作区**未触碰** wiki 中除 inbox 外的任何位置

---

### User Story 2 - 扫描对齐与候选呈报 (Priority: P2)

用户问 runner "有什么可以跑"。runner 扫描 wiki `research/ideas/`（含 `done/` 子目录），读每个 idea 的 frontmatter `status`，与本地 `queue/done/` 比对，分类呈报：可跑哪些、已投递但 wiki 未消化的有哪些、闭环了哪些、有没有"wiki 标 done 但 runner 没参与"的异常。用户根据这个清单决定跑哪个。

**Why this priority**: P1 跑通后，第二个痛点是"我有十几个 idea，记不清哪些跑过哪些没跑、哪些闭环了哪些卡在中间"。扫描对齐是 runner 与 wiki 异步通信的真源，比"手动维护 flag" 健壮。但 P1 不依赖此功能——P1 用户直接给路径就能跑，所以排 P2。

**Independent Test**: wiki `research/ideas/` 中有混合状态（部分 pending、部分 done、部分已投递但 wiki 未 INGEST），跑扫描对齐，看 runner 能否正确分类并明确呈报四象限。

**Acceptance Scenarios**:

1. **Given** wiki 中有 N 个 idea 文件混合状态，**When** 用户问 runner "有什么可跑"，**Then** runner 列出按四象限分类的清单，每条带 idea slug 和 wiki 状态
2. **Given** 某 idea 在 runner `queue/done/` 中已有投递记录，**When** 用户尝试再次跑这个 idea，**Then** runner 警告"已投递过，是否真的要重跑"，等待显式确认
3. **Given** wiki 中某 idea 在 runner 本地 abandoned 集合中有记录，**When** 扫描对齐，**Then** runner 标"previously abandoned"列出，需用户显式确认才能再跑

---

### User Story 3 - 中断后可恢复 (Priority: P3)

某个 idea 跑到一半，用户关掉会话或换机器。下次回到本工作区，runner 能识别 `runs/<id>/` 中未完成的 run，告诉用户"上次跑到第几步、留了什么、可以从哪继续"。

**Why this priority**: 真实研究 run 不是一蹴而就，可能跨多次会话。但 P1/P2 不依赖此功能就能跑通 happy path，所以排 P3。

**Independent Test**: 主动跑一个 idea 跑到中途停下，重启会话，告诉 runner "继续"，看是否能正确恢复上下文。

**Acceptance Scenarios**:

1. **Given** 一个 run 跑到中途、`runs/<id>/log.md` 有最近一次状态记录，**When** 用户在新会话里告诉 runner "继续 <run-id>"，**Then** runner 读取 `idea.md` + `log.md` + 中间产物，能复述当前进度并提出下一步建议
2. **Given** 一个 run 已被用户判定放弃，**When** 用户告诉 runner "归档 <run-id>"，**Then** run 目录保留但被标记，对应 queue 项移到 done 并标 abandoned

---

### Edge Cases

- **idea 文件 frontmatter 缺字段**：runner 容忍缺失字段，仅记录到 `log.md`，不阻塞研究开始；扫描对齐时 status 缺失视为 `pending`
- **同一个 idea 被显式确认重跑**：允许并存两个 run，run-id 用日期+slug 自然区分；新投递文件自动加序号
- **wiki inbox 已存在同名文件**：不覆盖，自动加序号后缀 `<slug>-2.md`
- **runner 投递后 wiki 长期未 INGEST**：扫描对齐时此 idea 持续显示 "awaiting ingest"；MVP 不主动追究，只如实呈报
- **研究中途出现"信息不可得"**（工具不可用、来源拿不到）：runner 在 `output.md` 中显式标记"未能获取 X，结论限于 Y"，**不得编造**
- **用户长时间不回复修订请求**：runner 不自行投递，draft 状态无限期保留在 `runs/<id>/`，等待用户回话

## Requirements *(mandatory)*

### Functional Requirements

#### 输入 / 启动
- **FR-001**: Runner MUST 接受一个 wiki 中 idea 文件的路径作为输入，启动一次 run
- **FR-002**: Runner MUST 在启动时把 idea 文件**完整冻结**为 `runs/<id>/idea.md`，run 期间不再读 wiki 原文件
- **FR-003**: Runner MUST 在 `runs/<id>/` 下维护至少 `idea.md`、`log.md`、`output.md` 三个文件，可按需要增加 `notes/`、`sources/` 子目录

#### SOP 执行
- **FR-004**: Runner MUST 在 run 启动时读取 `sop/workflow.md`、`sop/flow-card.md`、`sop/templates.md` 并据此组织研究过程
- **FR-005**: Runner MUST 在研究过程中至少产出与 SOP 三个产物模板（研究任务卡 / 判断单 / 决策导向研究备忘录）对应的中间产物或综合结果
- **FR-006**: Runner MUST 在 SOP 三道门（开题门 / 中途门 / 收尾门）每一道都等待用户显式信号才能进入下一阶段。等待期间 runner MUST 把当前门对应的判断（任务卡 / 判断单 / 决策备忘录）写出来供用户审阅
- **FR-007**: Runner MUST 在 `output.md` 中保留可追溯的来源引用（链接、文件名或其他可核实的标识），不得编造来源
- **FR-008**: 当 SOP 要求的某项信息因工具或资料不可得而无法取得时，Runner MUST 在 `output.md` 中显式标记该缺口，不得用编造内容填充

#### 用户多轮修订
- **FR-009**: Runner MUST 支持用户在本工作区会话中对 `output.md` 提出修改要求，并在同一 run 目录中迭代，不重启研究
- **FR-010**: Runner MUST 在用户明确表示认可当前 draft 之前，不得自行投递到 wiki inbox
- **FR-011**: 多轮修订的过程 MUST commit 到 git，便于后续回顾（git history 替代显式 draft 编号）

#### 投递
- **FR-012**: 投递时 Runner MUST 写一个 markdown 文件到 `D:/Personal LLM Wiki/sources/notes/inbox/`，文件名格式 `YYYY-MM-DD-<slug>.md`，frontmatter 与结构遵循 `templates/inbox-output.md`
- **FR-013**: 投递文件中 MUST NOT 包含 wikilink、Related 段落、wiki 内部位置决策——这些是 wiki INGEST 的职责
- **FR-014**: 投递后 Runner MUST 在 `runs/<id>/log.md` 中记录投递的目标路径和时间戳
- **FR-015**: 若 wiki inbox 中已存在同名文件，Runner MUST 自动加序号后缀避免覆盖

#### 投递文件中的 idea 反向引用
- **FR-016**: Runner 投递的 inbox 文件 frontmatter MUST 包含 `source_idea` 字段，指向 wiki 中对应 idea 文件的相对路径（例如 `research/ideas/2026-05-01-modernity-wang-minan-thirteen-lectures.md`），便于 wiki INGEST 直接定位无需猜测

#### 边界保护
- **FR-017**: Runner MUST NOT 修改 wiki 中除 `sources/notes/inbox/` 外的任何文件
- **FR-018**: Runner MUST NOT 修改 wiki 中原 idea 文件（包括其 frontmatter 的 `status` 字段；改 `status` 是 wiki INGEST / retire 流程的职责）
- **FR-019**: Runner MAY 读取 wiki `research/ideas/`（含 `done/` 子目录）下任意 idea 文件的内容与 frontmatter——这属于"扫描对齐"必要的只读访问

#### 完成跟踪与扫描对齐（P2）
- **FR-020**: Runner MUST 维护 `queue/done/<quarter>.md`，每次成功投递后追加一条记录，包含 idea slug、run-id、投递时间、inbox 目标路径
- **FR-021**: Runner MUST 在启动一个 idea 的 run 之前检查本地 done 集合；若该 idea slug 已有投递记录，MUST 警告用户并要求显式确认是否真的要重跑
- **FR-022**: Runner MUST 提供"扫描对齐"动作（用户问"有什么可跑"时触发）：列出 wiki `research/ideas/` 及 `research/ideas/done/` 下所有 idea 文件，读 frontmatter 的 `status` 字段，与本地 done / abandoned 集合对齐，按下表分类呈报：

  | wiki status | runner 本地状态 | 分类 | runner 行为 |
  |---|---|---|---|
  | pending | 无记录 | 可跑 | 列入候选 |
  | pending | 有 done 记录 | 已投递、wiki 未消化 | 标"awaiting ingest"，不列入候选 |
  | pending | 有 abandoned 记录 | 之前 runner 放弃过 | 标"previously abandoned"，列出但需用户确认才能再跑 |
  | done / abandoned | * | 不关 runner 的事（含初始化遗留） | 过滤，不呈报 |

- **FR-023**: Runner MUST 在扫描对齐结果中明确区分"可跑"、"awaiting ingest"、"previously abandoned"三类，避免用户误判
- **FR-024**: Runner 中途放弃一个 run 时（无投递就停下）MUST 在 `queue/abandoned/<quarter>.md` 记录一条，含 idea slug、run-id、放弃时间、放弃原因摘要

#### 恢复（P3）
- **FR-025**: Runner MUST 在新会话开始且收到"继续 <run-id>"指令时，能从 `runs/<id>/` 恢复 context 并继续推进

### Key Entities

- **Idea**：wiki 中一个研究主题的种子文件，含 frontmatter（source / captured / route / route_reason / status）和 free-form body。本 feature 中是只读输入。
- **Run**：一次完整的研究执行实例。生命周期：created → researching → drafting → revising → delivered（或 abandoned）。物理上对应 `runs/<id>/` 一个目录，`<id>` 形如 `YYYY-MM-DD-<slug>`，与 wiki 中 idea slug 通常对应但不强一致。
- **Output**：runner 的最终交付物，一个 markdown 文件。在 run 期间为 `runs/<id>/output.md`，投递后副本写入 wiki inbox。内容定稿（content-finalized），不带 wikilink、不做 wiki 内部位置决策。
- **Done Record**：runner 本地完成跟踪表中的一条记录，含 idea slug、run-id、投递时间、inbox 目标路径。物理上写在 `queue/done/<quarter>.md`。
- **Alignment Report**：runner 执行"扫描对齐"动作时产出的当前候选/异常清单，按四象限组织。临时呈现给用户，不需要落盘。

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 给定一个写好的 idea，从用户告诉 runner "跑这个" 到 wiki inbox 出现初版 draft，**单次会话内可完成**（不要求当场完成研究质量，但不需跨多次会话才能拿到第一版 draft）
- **SC-002**: 在 4 个迁移 idea（modernity / SearXNG / Beijing rental / desktop host）中至少 **2 个**能跑通端到端到 inbox，且用户认为"质量达到值得投递"水准
- **SC-003**: 投递到 inbox 的文件 **100%** 包含可追溯的来源引用，**0%** 包含编造来源
- **SC-004**: 用户对一个 draft 平均进行 **≤3 轮修订** 即可达到投递条件（衡量 runner 初始 draft 是否可接受）
- **SC-005**: 一个 run 从启动到投递期间，**0 次** 触碰 wiki 中 `inbox/` 之外的文件（边界硬约束）
- **SC-006**: 当某项信息确实不可得时，**100%** 的此类情况在 `output.md` 中显式标记缺口而不是编造内容

## Assumptions

- **触发模型**：MVP 假设 runner 由用户在 Claude Code 会话中显式触发（"跑这个 idea"），不实现常驻后台扫描或定时调度。后台模式属于后续迭代。
- **并发**：MVP 假设同一时刻只有一个 run 处于 active 状态。Queue 有 in_flight 列表只是为了表达数据结构，不假设真实并发执行。
- **SOP 形态**：MVP 假设直接复用 `sop/` 下三件套作为 runner 的运行时指南，runner 在过程中产出对应模板的填充版本。不在本 feature 中重写 SOP；如需重写，是单独的下游 feature。
- **多轮修订流程**：修订发生在"runner 出 draft → 用户审 → runner 改"循环中，用户每次反馈通过会话表达，runner 用 git commit 留痕。
- **idea 来源**：idea 已经存在于 wiki `research/ideas/`。本 feature 不负责创建 idea。扫描已纳入 P2 范围。
- **wiki INGEST 边界**：runner 投递到 inbox 之后，wiki 那边的 INGEST + retire 流程（包括把 idea frontmatter 改 `status: done` + 填 `output:` + 移到 `done/`）由 wiki 侧自行处理，runner 不跨界干预。
- **拒收与重做**：wiki INGEST 拒收 runner 成果属于 wiki 侧的事，runner 不设 rejection 信道。如用户希望 runner 重跑某个已投递的 idea，按 FR-021 走（runner 警告已投递，用户显式确认）。
- **初始化遗留**：wiki 中早于本 runner 运行的、已经 `status: done` 的 idea 全部被扫描对齐过滤，不视为异常。
- **工具可用性**：本工作区可用的搜索 / 抓取工具至少包含 Claude Code 内置 WebSearch / WebFetch、Exa MCP、agent-reach；具体工具选择是 plan 阶段决定，不影响 spec。
- **用户角色**：单用户场景。不考虑多用户、协作权限、共享 queue 等。
- **隐私**：MVP 不在投递文件中过滤敏感内容（早期阶段假设所有 idea 都是用户自己的、wiki 也是私人的）。后续若 wiki 上线公开，相关 idea / inbox 走 `.gitignore` 而非 runner 内过滤。
