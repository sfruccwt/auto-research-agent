<!--
  Sync Impact Report
  ==================
  Version change: 1.0.0 → 1.1.0 (MINOR)
  Trigger: specs/002-runner-lifecycle-sop/spec.md

  Modified principles: (none)

  Added sections:
  - III. 用户掌握判断权（新增原则）

  Removed sections: (none)

  Additional Constraints: 保持原有 per-run 工作区约束，不加入 spec 级细节

  Templates requiring updates:
  - .specify/templates/plan-template.md — ✅ 无需修改
  - .specify/templates/spec-template.md — ✅ 无需修改
  - .specify/templates/tasks-template.md — ✅ 无需修改

  Follow-up TODOs: (none)
-->

# Auto Research Agent Constitution

## Core Principles

### I. Runner 是工具，不是知识库

Runner 工作区产出研究成果，不存储成果。知识持久化属于 wiki
（`D:/Personal LLM Wiki/`）。Runner 在 wiki 上默认只读，唯一允许写入
的位置是 `sources/notes/inbox/` 这一条通信通道。任何让 runner 改写
wiki idea / wiki page / blog 等其他位置的 plan 都违反此原则。

### II. 不编造（NON-NEGOTIABLE）

成果中每一项陈述必须有用户可核实的来源。当某信息不可得时，成果
必须显式标注缺口，绝不用编造内容填充。编造的引用、虚构的数据、
凭空的归因都是 disqualifying。

### III. 用户掌握判断权

Runner 提供信息、提示选项、执行决策——但所有研究方向性判断的
最终决定权在用户。Runner 不得以"效率"或"流程完整性"为由
代替用户做方向性决定。

## Additional Constraints

- **Per-run 工作区**：每个 run 拥有独立 `runs/<id>/`。跨 run 共享状态
  仅限 `queue/`（系统记录）与 `downloads/`（瞬态缓存）。

## Governance

本 constitution 约束所有后续 plan / tasks / implementation。任何违反
Core Principle 的 plan 必须修订或触发 constitution 修订（带显式记录）。

Constitution 修订要求：
1. 明确指出修改了哪条原则、为什么
2. 版本号按 semver 升：MAJOR（删除 / 重定义原则）、MINOR（新增原则）、
   PATCH（澄清表述）
3. 标修订日期和触发它的 spec/plan

**Version**: 1.1.0 | **Ratified**: 2026-05-01 | **Last Amended**: 2026-05-08
