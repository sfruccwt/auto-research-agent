# Search API eval API keys

状态：待填写
创建日期：2026-06-19

## 0. 使用规则

本文件只记录待测试服务的注册状态、环境变量名和 key 配置位置，不记录参数能力摘要。

默认不要把真实 API key 写进本文件。推荐做法：

1. 在各服务后台注册并获取 API key。
2. 将 key 配置到本机环境变量。
3. 本文件只把注册状态从 `pending` 改成 `ready`，并注明配置位置为 `local environment variable`。

如果必须临时把真实 key 写入 Markdown，先确认该文件不会被提交，并补充 `.gitignore` 规则。真实 key 不应进入 git history。

## 1. Key 状态表

| 服务 | 是否测试 | 注册状态 | 环境变量名 | Key 填写 / 配置位置 | 备注 |
|---|---|---|---|---|---|
| OpenAI Responses `web_search` | yes | pending | `OPENAI_API_KEY` | local environment variable | 用于 OpenAI Responses API `web_search`。 |
| Exa | yes | pending | `EXA_API_KEY` | local environment variable | 如果直接走 AgentReach 既有 Exa 配置，也在备注中说明。 |
| Tavily | yes | pending | `TAVILY_API_KEY` | local environment variable | 用于 Tavily Search API。 |
| Brave Search API | yes | pending | `BRAVE_SEARCH_API_KEY` | local environment variable | 用于 Brave Search API。 |
| Serper.dev | yes | pending | `SERPER_API_KEY` | local environment variable | 用于 Serper.dev Search endpoint。 |
| SerpAPI | no | unavailable | n/a | n/a | 注册不可用，本轮排除。 |

## 2. 本机环境变量检查命令

PowerShell 示例：

```powershell
$env:OPENAI_API_KEY
$env:EXA_API_KEY
$env:TAVILY_API_KEY
$env:BRAVE_SEARCH_API_KEY
$env:SERPER_API_KEY
```

只确认变量是否存在时，不要把 key 打印到聊天或日志里。可以用以下方式检查是否已设置：

```powershell
@(
  'OPENAI_API_KEY',
  'EXA_API_KEY',
  'TAVILY_API_KEY',
  'BRAVE_SEARCH_API_KEY',
  'SERPER_API_KEY'
) | ForEach-Object {
  [pscustomobject]@{
    name = $_
    configured = [bool][Environment]::GetEnvironmentVariable($_)
  }
}
```

## 3. 注册状态值

| 状态 | 含义 |
|---|---|
| `pending` | 还未注册或还未配置 key。 |
| `registered` | 已注册账号，但 key 未配置到本机。 |
| `ready` | key 已配置到本机环境变量，可以进入实测。 |
| `blocked` | 注册、支付、地区、风控或账号限制导致暂不可测。 |
| `skipped` | 本轮主动跳过。 |
| `unavailable` | 当前不可注册或不可用。 |

## 4. 备注填写建议

备注只记录操作状态，不记录敏感内容。可以写：

- `free quota available`
- `requires credit card`
- `payment blocked`
- `using existing AgentReach config`
- `dashboard accessible`
- `rate limit unknown`

不要写：

- API key 原文
- token 前缀 / 后缀
- 账号邮箱
- 手机号
- 支付信息
- cookies / headers
