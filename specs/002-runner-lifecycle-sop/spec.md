# Feature Specification: Runner Lifecycle & SOP Refinement

**Feature Branch**: `002-runner-lifecycle-sop`
**Created**: 2026-05-07
**Status**: Draft
**Input**: User description: "基于 MVP 两次测试 run（ai-trust-layer、local-embedding-gpu-deploy）暴露的 known-gaps 和 SOP backlog，执行第二轮改进：补全 idea 生命周期管理、增加轻量结项机制、修订 SOP 模板与流程。"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - 双 idea 池与就地创建 (Priority: P1)

维护两套 idea 池：**Wiki 池**（`D:/Personal LLM Wiki/research/ideas/`，长期孵化、跨项目的研究想法）和 **Runner 本地池**（runner 工作区 `ideas/` 目录，临时的、与当前工作直接相关的想法）。用户在 runner 工作区里说"我想研究 X"，runner 在本地池创建 idea 并直接开跑，不要求先去 wiki 写文件。从 wiki 池拉取 idea 的现有路径保持不变。扫描对齐时两边都扫，合并呈报。

**Why this priority**: MVP 测试中最大的摩擦点。每次想跑一个临时研究都要先去 wiki 写 idea 文件，流程太重。双池架构让两个工作区各自有正式的 idea 落地位置，消除不必要的跨工作区依赖。

**Independent Test**: 用户在会话中口述一个研究主题，runner 直接建 run 目录开跑，无需 wiki 侧有对应 idea 文件。研究完成后仍然能正常投递到 wiki inbox。

**Acceptance Scenarios**:

1. **Given** 用户在会话中说"我想研究 X"（未提供 wiki idea 路径），**When** runner 启动 run，**Then** runner 在本地池 `ideas/` 中创建 idea 文件，同时在 `runs/<id>/idea.md` 中生成冻结快照，`source_idea` 指向本地池路径，run 正常推进
2. **Given** 一个从本地池启动的 run 完成并投递，**When** 用户检查 inbox 文件，**Then** frontmatter 中 `source_idea` 指向本地池路径（非 wiki 路径）
3. **Given** 用户同时提供了 wiki idea 路径，**When** runner 启动 run，**Then** 行为与 MVP 一致——从 wiki 冻结 idea，`source_idea` 指向 wiki 路径
4. **Given** 用户要求扫描对齐，**When** runner 扫描两个池，**Then** Wiki 池和本地池的 idea 合并呈报，按来源标注分类

---

### User Story 2 - 轻量结项（有结论但不投递） (Priority: P1)

一个 run 跑完后有明确结论，但不适合产出正式 output（结论需更大课题展开、memo 质量不达标、方向发生根本转向等）。用户希望记录结论、标记 run 为已结项，但不投递到 wiki inbox。

**Why this priority**: MVP 测试暴露的核心问题是**树状研究结构**——大课题（如"人机协作"）在第一轮检索后往往分裂为多个子节点，而子节点必须先各自研究清楚，大课题才能写。ai-trust-layer 正是这种情况：课题本身有结论（"锚定在 spec 层"），但结论依赖的子概念（"生成前规范"）还没解释清楚，直接投递读者看不懂。轻量结项是树状研究的机制保障——母课题记下结论和方向，子课题各自开 run，子课题完成后再回填或链接到母课题。当前只有 delivered 和 abandoned 两种终态，无法支撑这种"先拆后合"的研究模式。

**Independent Test**: 跑一个 run 到有结论阶段，选择轻量结项而非投递，验证结论被记录、run 被正确标记、不产生 inbox 文件。

**Acceptance Scenarios**:

1. **Given** 一个 run 已有结论但不适合投递，**When** 用户告诉 runner "这个课题轻量结项"，**Then** runner 在 `runs/<id>/notes/` 下写一个 `closing-summary.md`（含结论摘要、不投递原因、后续方向建议），`log.md` 记录 `closed` 事件
2. **Given** 一个 run 被轻量结项，**When** runner 更新本地跟踪，**Then** `queue/` 中该 run 标记为 `closed`（区别于 `delivered` 和 `abandoned`），扫描对齐时此 idea 不再列入"可跑"
3. **Given** 一个被轻量结项的 run，**When** 用户后续想基于该结论开新课题，**Then** `closing-summary.md` 中的后续方向建议可作为新 run 的起点参考

---

### User Story 3 - 研究过程中派生新 idea / 拆分子课题 (Priority: P2)

一个 run 过程中联想出新的研究点（如 ai-trust-layer 派生出三个子课题），或者发现母课题过大需拆分为子课题分别研究。runner 能记录这些派生 idea，用户可选择后续跑或忽略。子课题完成后，结论可回填到母课题或由母课题直接链接子课题产出。

**Why this priority**: 每次 run 都会派生新想法，MVP 中这些想法只能口头记住或手动去 wiki 写。更关键的是，对于实用导向的研究，大课题往往需要先把子概念做清楚才能产出有用的结论——派生机制是树状研究的基础设施。但这不影响当前 run 的完成，所以排 P2。

**Independent Test**: 跑一个 run，中途 runner 或用户提出派生 idea，验证派生 idea 被记录、母 run 继续推进不受影响、派生 idea 后续可被扫描或直接开跑。

**Acceptance Scenarios**:

1. **Given** 一个 run 正在进行中，**When** 用户或 runner 识别出一个派生研究点，**Then** runner 在 `runs/<id>/notes/derived-ideas.md` 中追加记录（含标题、一句话描述、与母课题的关系），不中断当前 run
2. **Given** 一个 run 结项（任何终态）且有派生 idea，**When** 用户问"有什么可跑"，**Then** 扫描对齐结果中增加一个"派生 idea"分类，列出所有未处理的派生 idea 及其来源 run
3. **Given** 用户选择跑一个派生 idea，**When** runner 启动新 run，**Then** 新 run 的 `idea.md` 中引用母 run id 和派生来源，研究过程可参考母 run 的中间产物

---

### User Story 4 - SOP 模板与流程修订 (Priority: P2)

基于两次测试 run 积累的 10 条 SOP backlog，批量修订 SOP 模板和流程文档，使后续 run 的执行质量更高。

**Why this priority**: SOP 改进直接提升每次 run 的输出质量，但属于"基础设施"改进——不改也能跑，改了更好。与派生 idea 并列 P2。

**Independent Test**: 修订完 SOP 后跑一个新 run，验证新流程是否自然引导出更高质量的产出（如开题卡是否迭代填写、motivation 是否中途校准、搜索路径是否双路并行）。

**Acceptance Scenarios**:

1. **Given** SOP backlog 中"开题卡迭代式填写"已修订，**When** runner 为一个不熟悉领域的 idea 开题，**Then** 开题卡先写粗粒度版本，第一轮建图后反问用户细化，而非一次性预填
2. **Given** SOP backlog 中"搜索路径默认开 agent-reach"已修订，**When** runner 执行第一轮广搜，**Then** 自动双路并行（WebSearch + agent-reach），任务卡中有工具分配行
3. **Given** SOP backlog 中"motivation 持续捕获"已修订，**When** 第一轮建图完成进入中途门前，**Then** runner 用搜到的关键词反问用户做 motivation 校准，用户补充的约束被记录并影响后续判断
4. **Given** SOP backlog 中"核心概念展开"已修订为全阶段要求，**When** 任何阶段产出中出现对零背景读者不自明的术语，**Then** 紧跟展开描述（一半严肃定义 + 一半类比/例子），或向用户确认是否需要展开
5. **Given** SOP backlog 中"不可靠信息直接删除"已修订，**When** 判定某条证据不可靠，**Then** 直接从备忘录中删除，不设"不可信信息跳点"展示区

---

### Edge Cases

- **本地池 idea 与 wiki 池 idea 重复**：runner 不做跨池去重检测（无法可靠判断），由用户自行判断。扫描对齐时两池独立列出，按来源标注
- **轻量结项后又想投递**：允许——用户可以说"把 <run-id> 的结论正式投递"，runner 基于 `closing-summary.md` 和 `notes/memo.md` 生成 output 并走投递流程
- **子课题完成但母课题已结项**：允许回填——用户可指示将子课题结论追加到已结项母 run 的 `notes/` 中，或开新 run 整合多个子课题结论
- **派生 idea 数量过多**：`derived-ideas.md` 是追加式文件，不设上限。扫描对齐时全部列出，由用户决定跑哪个
- **SOP 修订后旧 run 的中间产物格式不一致**：不做迁移。旧 run 保持原样，新模板只适用于新 run
- **轻量结项的 run 包含敏感中间产物**：与 MVP 一致，不做隐私过滤，`runs/<id>/` 目录完整保留

## Requirements *(mandatory)*

### Functional Requirements

#### 双 idea 池与就地创建（扩展 FR-001）
- **FR-101**: Runner MUST 维护本地 idea 池（`ideas/` 目录），与 Wiki 池（`D:/Personal LLM Wiki/research/ideas/`）并列为两个独立的 idea 来源
- **FR-102**: 用户在会话中直接描述研究主题时，Runner MUST 在本地池 `ideas/` 中创建 idea 文件，同时在 `runs/<id>/idea.md` 中生成冻结快照，`source_idea` 指向本地池路径
- **FR-103**: 从本地池启动的 run 在投递时，inbox 文件 frontmatter 的 `source_idea` MUST 如实记录本地池路径（非 wiki 路径）。wiki INGEST 对非 wiki 路径的处理属于 wiki 侧后续完善范围，本 feature 不做约束
- **FR-104**: 本地池的 idea 不自动同步到 wiki `research/ideas/`——两个池独立管理，用户按需手动迁移
- **FR-104a**: 扫描对齐 MUST 同时扫描 Wiki 池和本地池，合并呈报，按来源标注分类

**Contract 影响**：现有 `scripts/new-run.ps1` 需扩展以支持本地池 idea 路径（及从口述主题直接创建 idea 的场景）；`scripts/scan-and-align.ps1` 需扩展以支持双池扫描。均为修改现有 contract，不新增脚本

#### 轻量结项
- **FR-105**: Runner MUST 支持第三种 run 终态 `closed`：有结论、不投递。`closed` 可从任何中间状态转入——何时结项由用户判断，Runner 不限制来源状态
- **FR-106**: 轻量结项时 Runner MUST 在 `runs/<id>/notes/closing-summary.md` 中记录：结论摘要（1-3 句话）、不投递原因、后续方向建议（如有）
- **FR-107**: 轻量结项后 Runner MUST 在 `log.md` 中追加 `closed` 事件，在 `queue/closed/<quarter>.json` 中记录一条跟踪记录
- **FR-108**: 轻量结项的 run 中所有中间产物（task-card、judgment、memo）MUST 完整保留在 `runs/<id>/` 中，不删除
- **FR-109**: 扫描对齐时，`closed` 状态的 run 对应的 idea 不再列入"可跑"分类，但 MUST 在"已结项（未投递）"分类中列出

#### 派生 idea 与子课题拆分
- **FR-110**: Runner MUST 支持在 run 过程中记录派生 idea，写入 `runs/<id>/notes/derived-ideas.md`
- **FR-111**: 每条派生 idea 记录 MUST 包含：标题、一句话描述、与母课题的关系、记录时间；当子课题 run 启动后，回填 `child_run: <run-id>`
- **FR-112**: 扫描对齐 MUST 增加"派生 idea"分类，汇总所有 run 的 `derived-ideas.md` 中未被处理的条目
- **FR-113**: 当用户选择跑一个派生 idea 时，新 run 的 `idea.md` MUST 引用母 run id（`derived_from: <母run-id>`）
- **FR-113a**: 子课题拆分的判断由用户做出。Runner 在中途门可向用户提示"当前课题是否需要拆分子课题"，但最终决定权在用户
- **FR-113b**: 子课题 run 完成后，Runner MUST 支持将子课题结论回填到母 run（追加到母 run 的 `notes/` 或 `output.md` 对应区域），或由母 run 直接链接子课题的产出文档。具体回填方式由用户指示 *（→ 实现细节在 Plan 中设计）*
- **FR-113c**: 母课题在子课题进行期间的状态由用户决定：可暂停等待、可轻量结项、可继续推进其他部分。Runner 不强制某种处理方式

#### SOP 模板修订
- **FR-114**: `sop/templates.md` 中的开题卡模板 MUST 标记"真正要回答的问题"为迭代字段，附注"第一轮建图后回来细化"
- **FR-115**: `sop/templates.md` 中的开题卡模板 MUST 在"优先开的检索面"下增加工具分配行，默认双路（WebSearch + agent-reach）
- **FR-116**: `sop/workflow.md` MUST 在中途门前增加"motivation 校准"步骤：用第一轮搜索的关键发现反问用户做 motivation 补充，补充内容记录到 `notes/task-card.md` 的 motivation 区域
- **FR-117**: 核心概念清晰描述为**全阶段要求**（搜索、判断单、备忘录、output 均适用），不仅限于备忘录。采用"标记 + 确认"流程：
  - (a) Runner 在任何阶段产出中遇到自己判断可能需要展开的术语时，MUST 标记出来并向用户确认"这个概念需不需要展开"
  - (b) 用户确认需要展开时，展开格式：一半严肃定义 + 一半类比或具体例子
  - (c) 用户确认不需要时，跳过展开，继续推进
  - (d) 哪些类型的概念需要展开，不在 spec 中硬性界定，随 run 次数增多逐步积累经验，沉淀到 SOP 作为示例参考
  - (e) `sop/templates.md` 中的备忘录模板增加"关键概念展开"结构化位置，其他阶段模板在适用处加相应提示
- **FR-118**: `sop/templates.md` 中的判断单和备忘录模板 MUST 删除"不可信信息跳点"字段/区块
- **FR-119**: `sop/workflow.md` MUST 明确区分 memo（`notes/memo.md`，收尾门中间产物）和 output（`output.md`，最终投递物），禁止将中间产物直接写到 output 位置

#### SOP 流程修订
- **FR-120**: `sop/workflow.md` 中的开题门 MUST 改为"关键词压测"流程：对任务卡"要回答的问题"中每个关键词做范围确认（主语、领域、动作），必要时反问用户
- **FR-120a**: `sop/workflow.md` 中的中途门 MUST 增加"子课题拆分检查"：第一轮广搜完成后，runner 向用户提示当前课题是否需要拆分子课题（如发现某子概念需独立研究才能支撑母课题结论）。判断权在用户，runner 仅提示
- **FR-121**: `sop/workflow.md` MUST 在备忘录写作指引中增加"证据链扣紧"要求：每条来源不仅列名字，还要说明"这个来源说明了什么、为什么支撑这个结论"
- **FR-122**: `sop/workflow.md` 中路径比较 MUST 要求每条路径写明：(1) 人类具体做什么操作；(2) 人类不做什么；(3) 与相邻路径的分界线

#### 产出后追问 / 补查（继承自 MVP，轻量机制）
- **FR-123**: Runner MUST 支持在 output 阶段接受用户追问并在现有 output 基础上修补，不回退到开题重走
- **FR-124**: 追问触发的补查结果 MUST 追加到 `output.md` 对应区域，`log.md` 记录 `supplement` 事件，git commit 留痕

*注：FR-123/124 是对 MVP 多轮修订流程（FR-009）的自然延伸，不属于本 feature 的四个 User Story，仅作为补充约束记录。*

### Key Entities

- **Idea**：研究主题的种子。存放于两个独立的池：Wiki 池（`D:/Personal LLM Wiki/research/ideas/`，长期孵化）和 Runner 本地池（`ideas/`，临时/直接相关）。扫描对齐时两池合并呈报。
- **Run**：生命周期扩展为：created → researching → drafting → revising → delivered / closed / abandoned。新增 `closed` 终态。
- **Closing Summary**：一个 run 结项时的总结产物，`runs/<id>/notes/closing-summary.md`。含结论摘要、不投递原因、后续方向建议。典型场景：子课题完成后，将结论回填到母 run 时，closing-summary 是回填内容的来源。方向是**子→母**。
- **Derived Idea**：母课题 run 过程中派生出的新研究点，记录在 `runs/<id>/notes/derived-ideas.md`。含标题、描述、与母课题关系、`child_run`（子课题启动后回填）。方向是**母→子**——母 run 记录"我派生了哪些子课题"。未被处理的派生 idea 在扫描对齐时汇总呈报。
- **SOP 三件套**：`sop/workflow.md`、`sop/flow-card.md`、`sop/templates.md`。本 feature 修订其内容但不改变其角色定位。

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-101**: 用户从口述到 run 启动的时间 **≤1 分钟**（就地创建 idea 路径），对比 MVP 需先写 wiki idea 文件的路径缩短 **50%** 以上
- **SC-102**: 在后续 3 个 run 中，至少 **1 个** 使用轻量结项路径，且结项过程流畅（用户无需额外解释或手动操作）
- **SC-103**: 在后续 3 个 run 中，至少 **2 个** 产出派生 idea 记录，且派生 idea 可在扫描对齐中被发现
- **SC-104**: SOP 修订后首次 run 的开题卡在第一轮建图后经历至少 **1 次**用户参与的 motivation 校准
- **SC-105**: SOP 修订后首次 run 中，runner 对可能需要展开的术语 **100%** 执行了"标记 + 向用户确认"流程（用户确认展开的术语附带定义 + 类比/例子）
- **SC-106**: SOP 修订后首次 run 的第一轮广搜 **默认双路**（WebSearch + agent-reach）执行

## Assumptions

- **与 MVP spec 的关系**：本 feature 是 001-research-runner-mvp 的增量改进，不重写 MVP 的核心流程。所有 MVP 的 FR 保持有效，本 feature 的 FR 编号从 101 起以示区分。
- **idea 合并暂缓**：known-gaps 中的 1.1（idea 合并）在本轮不实现。合并场景目前出现频率低，需要更多实际案例来定义合理行为。
- **课题纵深 / 树状研究本轮实现**：known-gaps 中的 1.3（课题纵深/多级课题）通过轻量结项（US2）+ 派生 idea / 子课题拆分（US3）的组合机制实现。子课题拆分的判断由用户做出，runner 在中途门提示但不自动决策。
- **双 idea 池独立管理**：Wiki 池和 Runner 本地池各自独立，不自动同步。派生 idea 记录在 runner 本地（母 run 或本地池），用户按需手动迁移到 wiki。这避免了 runner 对 wiki 的写权限扩大。
- **SOP backlog 全量修订**：10 条 backlog 在本 feature 中全部处理，不分批。这些都是模板/流程文本层面的修改，工作量可控。
- **向后兼容**：所有改动不影响 MVP 已完成的 run（ai-trust-layer、local-embedding-gpu-deploy）。旧 run 目录保持原样，新机制仅适用于新 run。
- **queue 目录结构扩展**：新增 `queue/closed/<quarter>.json`，与现有 `queue/done/` 和 `queue/abandoned/` 并列。
- **扫描对齐扩展**：原有四象限分类扩展为六类，完整分类表如下：

  | 来源 | idea/run 状态 | 分类 | runner 行为 |
  |---|---|---|---|
  | Wiki 池 | wiki status=pending, 无本地记录 | 可跑 | 列入候选 |
  | Wiki 池 | wiki status=pending, 本地有 done 记录 | 已投递、wiki 未消化 | 标 awaiting ingest |
  | Wiki 池 | wiki status=pending, 本地有 abandoned 记录 | 之前放弃过 | 标 previously abandoned，需用户确认 |
  | Wiki 池 | wiki status=done/abandoned | 不关 runner 的事 | 过滤，不呈报 |
  | 本地池 | 无对应 run | 可跑（本地） | 列入候选，标来源=本地 |
  | 本地池 | 有 done/closed/abandoned 记录 | 已处理 | 按终态分类呈报 |
  | 任意 run | 有未处理的 derived-ideas.md 条目 | 派生 idea | 单独分类列出，标来源 run |
  | 任意 run | closed 终态 | 已结项（未投递） | 单独分类列出 |
