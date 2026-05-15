# Contract 变更: new-run.ps1

**变更类型**: 扩展（新增参数，保持向后兼容）

## 新 Invocation

```
pwsh scripts/new-run.ps1 -IdeaPath <path> [-Force]
pwsh scripts/new-run.ps1 -Topic <string> [-Slug <string>]
```

`-IdeaPath` 和 `-Topic` 属于不同参数集，互斥。

### 新增参数

| 参数 | 默认值 | 说明 |
|---|---|---|
| `-Topic` | （与 IdeaPath 互斥） | 用户口述的研究主题（一句话或短段落）。触发本地池 idea 创建 |
| `-Slug` | 自动生成 | 可选。指定 idea 文件名的 slug 部分。不传时由脚本从 Topic 中取前 5 个英文词（或拼音缩写）生成 |

## 新增 Behavior（-Topic 路径）

1. 校验 `-Topic` 非空字符串
2. 生成 slug：若传了 `-Slug` 则使用，否则取 Topic 前若干词生成（全小写、连字符连接、截断到 50 字符）
3. 计算 idea 文件名：`ideas/YYYY-MM-DD-<slug>.md`
4. 确保 `ideas/` 目录存在（不存在则创建）
5. 写入 idea 文件（复用 Wiki idea 的 frontmatter schema）：
   ```yaml
   ---
   source: runner-local
   source_file:
   captured: <YYYY-MM-DD>
   route: research
   route_reason: "<Topic 原文截取前 80 字符>"
   status: pending
   ---

   # <Slug 可读化作标题>

   <Topic 原文>
   ```
6. 将新创建的 idea 文件路径作为 `IdeaPath`，进入 Step 2（已有流程）
7. `idea.md` 冻结快照的 frontmatter 中 `source_idea` 指向本地池路径（如 `ideas/2026-05-10-topic-slug.md`）

## 对已有 Behavior 的修改

**Step 5（冻结快照）**: idea.md 的 frontmatter 中追加 `source_idea` 字段，记录 idea 的原始路径（本地池或 wiki 路径）。

**无其他变更**。现有 `-IdeaPath` 路径的行为完全不变。

## Exit codes（新增）

- `5` — `-Topic` 为空字符串

## 不做的事（延续 + 新增）

- 不对本地池 idea 做跨池去重检测
- 不自动同步本地池 idea 到 wiki
- Slug 生成不保证唯一性——如遇重名文件，追加 `-2`、`-3` 后缀
