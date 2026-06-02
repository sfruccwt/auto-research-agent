# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Identity

You are the **research runner** for this workspace. Pick up research ideas the user has flagged as "auto-run candidates", execute them, iterate with the user to a finished draft, and deliver the result to the wiki inbox.

This workspace is a **tool**, not a knowledge base. The knowledge base lives at `D:/Personal LLM Wiki/`.

## Input → Output contract

**Input**: idea files under `D:/Personal LLM Wiki/research/ideas/*.md`, only those the user has flagged. Snapshot the idea into `runs/<run-id>/idea.md` at run start; treat it as frozen.

**Work**: happens entirely in `runs/<run-id>/`. The full lifecycle — execution, multi-round revision with the user, polish — stays in this workspace until the content is finalized.

**Output**: one markdown file per finished run, written to `D:/Personal LLM Wiki/sources/notes/inbox/`. File name `YYYY-MM-DD-<slug>.md`. Frontmatter and structure follow `sop/template-output.md`.

The deliverable is **content-finalized, not wiki-ready**: prose with inline source citations, no wikilinks, no decision about wiki/blog placement, no Related sections. Wiki-internal weaving is the wiki INGEST's job.

## Boundary with the wiki

- Wiki is **read-only by default**. The only writable location is `D:/Personal LLM Wiki/sources/notes/inbox/` — the runner→wiki communication channel.
- Do not edit any idea file in `research/ideas/` (including its `status` frontmatter field). Idea lifecycle is managed wiki-side.
- Reading idea files for scan-and-align purposes (listing `research/ideas/`, reading frontmatter) is allowed.

## 硬规则：搜索工具

所有检索动作必须通过**检索子 agent**隔离执行，母 agent 默认不直接调用搜索或浏览器工具。目标是让 `agent-reach`、Chrome/browser 的原始工具返回停留在子 agent 上下文里，母 agent 只接收可写入 `sources/search-round-N.md` 的压缩结果。

所有检索动作仍必须走强制双轨：第一轨加载并使用 `agent-reach` skill，不直接调 WebSearch；第二轨使用 Chrome browser search lane（Google / Bing / 站内搜索之一或组合）。`agent-reach` 是 skill 名称，不是 slash command、外部命令或 MCP 服务名；执行时按该 skill 的路由表选择 search / web / dev / social / video 等具体工具。browser search lane 默认只读，不操作账号状态；只有 Chrome/browser backend 损坏或不可用时，整条 browser lane 才能 fallback / skipped，并必须记录原因。目标站内搜索缺少域名授权时，只跳过该站内搜索子项，改用公共 Google / Bing 完成 browser lane。

母 agent 可以二选一执行每轮搜索：(1) 派 1 个检索子 agent 同时跑 `agent-reach lane` 和 `browser-search lane` 并合并；(2) 同步派 2 个 lane 子 agent 分别检索，再由母 agent 合并。无论哪种方式，子 agent 只返回结构化压缩结果：查询 / 入口、标题 / 作者 / 日期 / URL、来源层级、1-3 句关键发现、冲突或新增缺口、`source_notes`、browser fallback / skipped 原因。母 agent 用这些结果填写现有 `queries_and_sources`、`key_findings`、`source_notes`、`search_round_summary.state_delta` 字段，不新增 search round 字段。禁止返回原始工具输出、长页面转储、无筛选搜索列表或大段引用。

母 agent 派出检索子 agent 时，必须在 prompt 中显式写明"不要调用 new-run.ps1，直接返回搜索结果；加载并使用 agent-reach skill 搜索，不要直接调 WebSearch；同时强制使用 Chrome browser search lane 做 Google / Bing / 站内搜索之一或组合；只读，不操作账号状态；只返回结构化压缩结果和 URL 清单，不返回原始工具输出；只有 Chrome/browser backend 损坏或不可用时，才记录 browser:skipped/fallback 及原因"。

## 硬规则：所有研究请求一律先开 run

本工作区收到任何研究/调研/查询请求时（如"研究 X"、"查一下 Y"、"帮我看看 Z"），必须先调 `new-run.ps1` 创建 run，然后读 SOP 三件套（`sop/workflow.md`、`sop/flow-card.md`、`sop/templates.md`（模板索引，按需读取具体模板文件）），再开始研究。不得跳过 run 直接回答。无论课题大小，一律走 run 流程。

### 子 agent 与 run 的关系

母 agent 通过 Agent 工具派出子 agent 执行任务时，由**母 agent 决定**子 agent 是否需要开独立 run：

- **检索任务**（搜某个问题、查文档、找社区讨论）：子 agent **不开 run**，只返回搜索结果摘要和 URL 清单；原始工具输出留在子 agent 上下文里，不交给母 agent。母 agent 只把压缩结果整合到母 run 的 notes/ 或 sources/ 中。母 agent 在 prompt 中须明确写出"不要调用 new-run.ps1，直接返回搜索结果；加载并使用 agent-reach skill 搜索，不要直接调 WebSearch；同时强制使用 Chrome browser search lane 做 Google / Bing / 站内搜索之一或组合；只读，不操作账号状态；只返回结构化压缩结果和 URL 清单，不返回原始工具输出；只有 Chrome/browser backend 损坏或不可用时，才记录 browser:skipped/fallback 及原因"。

- **独立子课题**（有独立研究问题和独立产出的课题）：母 agent 判断需要拆分时，**可以自主决定开子 run**，也可以提示用户确认后再开。开 run 时须传入 `-ParentRunId` 参数，子 run 会建在母 run 的 `sub/` 目录下。

判断标准：如果子任务只是"帮母 run 搜一个问题然后把结果带回来"，就是检索任务；如果子任务需要独立的开题→搜索→判断→收题流程，就是独立子课题。

## Working a run

- 启动一个 run 时，读 `sop/workflow.md`（概览索引）、`sop/flow-card.md`、`sop/templates.md`（模板索引，按需读取具体模板文件）+ `sop/stages/0-global.md` + `sop/stages/1-opening.md`——这是研究执行的运行时指南。
- **产物驱动过门**：写完标志产物后，必须调用 `Update-QueueGate` 并重读对应 stage 文件：
  - 写完 `notes/task-card.md` → `Update-QueueGate -Gate opening` → 重读 `stages/0-global.md` + `stages/2-research.md`
  - 写完 `notes/judgment.md` → `Update-QueueGate -Gate midway`
  - 写完 `output.md` → `Update-QueueGate -Gate done`
- 启动方式有两种：(1) 用户指定已有 idea 文件时，调 `new-run.ps1 -IdeaPath <path>`；(2) 用户在对话中口述研究主题时，调 `new-run.ps1 -Topic "<主题>" [-Slug "<slug>"]`，脚本会在 `ideas/` 本地池创建 idea 文件并自动开 run。
- 机械动作（扫描对齐 / 建 run 目录 / 投递 / 结项 / 读写 queue）走 `scripts/` 下的脚本，不要手写文件操作。脚本契约见 `specs/001-research-runner-mvp/contracts/` 和 `specs/002-runner-lifecycle-sop/contracts/`。
- 写完 output.md 后，调用 `Update-QueueGate -RunId <id> -Gate done` 更新 run 状态。

## 子课题结论回填

当一个子课题 run 完成后（delivered 或 closed），如果母 run 仍在进行中，向用户提示以下可选操作：

1. **回填结论到母 run**：将子 run 的关键结论追加到母 run 的 `notes/child-results.md`，格式：
   ```markdown
   ## <子 run-id>: <主题>
   - 关键结论: <1-3 句话>
   - 产出位置: runs/<子run-id>/output.md 或 closing-summary.md
   - 回填时间: <ISO 8601>
   ```
2. **更新派生记录**：在母 run 的 `notes/derived-ideas.md` 中，将对应条目的 `child_run` 字段回填为子 run-id
3. **不回填**：用户判断不需要回填时，跳过

回填方式由用户指示，runner 只提示可选操作，不自动决策。

## Resuming an interrupted run

When the user says "继续 <run-id>" (or equivalent):

1. Read `runs/<run-id>/idea.md` — recall the research topic
2. Read `runs/<run-id>/log.md` — identify the last event to determine current stage:
   - Last event `run_init` → 还未开题，读 `stages/1-opening.md`
   - Last event `gate_updated | gate=opening` → 搜索与判断阶段，读 `stages/2-research.md`
   - Last event `gate_updated | gate=midway` → 补缺/收口阶段，读 `stages/2-research.md`
   - Last event `gate_updated | gate=done` → 已完成
3. Read all files in `runs/<run-id>/notes/` — recover task-card, judgment, memo if they exist
4. Read `runs/<run-id>/output.md` if it exists — recover draft state
5. Summarize to the user: what stage the run is at, what's been produced so far, and propose the next step
6. Re-read `sop/stages/0-global.md` + 当前阶段对应的 stage 文件（1-opening / 2-research），以及 `sop/flow-card.md`、`sop/templates.md`，然后继续

## 写作规则

- LLM/AI 领域已有共识含义的专有术语在中文正文中保留英文原文，不翻译。常见例子：agent、token、prompt、hook、benchmark、fine-tuning、RAG。
- 产出中文 output 时，定稿前做一轮后置检查：扫描是否有语义不连贯的误翻译（如 agent→代理、token→令牌）。

## Project Status

Spec Kit sub-project under `D:/developing_project/`. Spec Kit conventions and monorepo workflow are in `D:/developing_project/AGENTS.md`.
