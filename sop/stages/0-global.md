# 全阶段通用规则

> 每次进入新阶段时必须重读本文件。

---

## 来源标注

所有写入文档（notes/、sources/、output.md）的搜索结果都必须标注来源，格式：正文 inline 数字引用 `[1]`、`[2]` + 文末来源列表（含 URL）。

## 搜索工具选择

所有检索动作默认使用 `agent-reach` skill（`/agent-reach`），不要直接调 WebSearch。

理由：agent-reach 覆盖 17 个平台（小红书、抖音、微博、Twitter、Reddit、GitHub、B 站、YouTube 等），能按检索面精准选择信源；WebSearch 只走通用搜索引擎，容易丢掉社区/社交平台上的一手讨论。

使用方式：
- 每次搜索前先判断目标信源属于哪个分类（search / social / dev / web / video 等）
- 按 agent-reach 的路由表选择对应命令
- 只有在 agent-reach 明确不覆盖的信源时，才退回 WebSearch

### 子 agent 搜索规则

母 agent 派出检索子 agent 时，必须在 prompt 中显式写明：**"使用 /agent-reach 搜索，不要直接调 WebSearch。"** 子 agent 不会自动继承母 agent 读过的 SOP，必须在 prompt 里把关键约束带过去。

## 核心概念清晰描述

在任何阶段的产出中（搜索笔记、判断单、备忘录、output），遇到可能需要展开的术语时：
1. **标记**：标记出该术语
2. **确认**：向用户确认"这个概念需不需要展开"
3. **展开**（用户确认后）：一半严肃定义 + 一半类比或具体例子
4. **跳过**（用户确认不需要后）：继续推进

哪些概念需要展开，不硬性界定，随 run 次数增多逐步积累经验。
