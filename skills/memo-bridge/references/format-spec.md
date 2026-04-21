# memo-bridge.md Format Specification v0.1

## Overview

The `memo-bridge.md` format is the standard interchange format for AI memory migration. It uses Markdown with YAML front matter to store structured memory data in a human-readable, LLM-friendly format.

## Structure

```
---
(YAML front matter: metadata)
---

# 用户画像
## 身份
## 沟通偏好
## 工作模式

---

# 知识积累
## Section Title (count)
| # | 主题 | 日期 | 掌握度 |

---

# 项目上下文
## Project Name (status)

---

# 关注的信息流

---

# 原始记忆

---

# 扩展数据
(fenced YAML block with tool-namespaced data)
```

All sections except `用户画像` / the front matter are optional — absent
data simply omits the whole section. Serializers must not emit empty
sections (e.g. `# 知识积累` with no body) so the file stays compact.

## YAML Front Matter

```yaml
version: "0.1"
exported_at: "2026-04-20T20:00:00+08:00"  # ISO 8601
source:
  tool: codebuddy          # ToolId
  tool_version: "0.1.0"    # optional
  workspace: "/path"        # optional; "/a | /b" when merged from multiple
  extraction_method: file   # file | api | prompt_guided | chat_reverse
owner:                      # optional
  id: "user-id"
  locale: "zh-CN"
  timezone: "Asia/Shanghai"
stats:
  total_memories: 65        # recomputed after any merge
  categories: 4
  earliest: "2026-03-24"
  latest: "2026-04-20"
```

## Supported ToolId Values

- `codebuddy` — CodeBuddy IDE
- `openclaw` — OpenClaw
- `hermes` — Hermes Agent
- `claude-code` — Claude Code
- `cursor` — Cursor IDE
- `chatgpt` — ChatGPT
- `doubao` — 豆包 (Doubao)
- `kimi` — Kimi

Unknown tool ids are rejected at CLI boundary via the `isToolId` guard.

## Sections

### User Profile (用户画像)

Key-value pairs organized into three sub-sections:
- **身份 / Identity**: name, role, location, interests
- **沟通偏好 / Preferences**: output style, language, tools
- **工作模式 / Work Patterns**: daily routines, schedules

Format: `- key：value` (Chinese colon) or `- key: value`

Section headings accept both Chinese (`## 身份`) and English
(`## Identity` / `## Preferences` / `## Work Patterns`).

### Knowledge (知识积累)

Organized into sections with Markdown tables:
- H2 header with optional count: `## AI 基础知识（19条）`
- Table: `| # | 主题 | 日期 | 掌握度 |`
- Mastery values: `learned` / `reviewed` / `mastered`

### Projects (项目上下文)

- H2 header with status: `## Project Name（进行中）` or `## Project Name (active)`
- Bullet points for key insights
- Status values: `进行中`/`active`, `已完成`/`completed`, `暂停`/`paused`

### Information Feeds (关注的信息流)

Pipe-separated fields:
```
- Feed Name | every HH:MM | N issues
```

When parsing, `每日 ` prefix on the schedule column and `期` suffix on the
issue count are stripped so round-tripping yields the original scalar
values.

### Raw Memories (原始记忆)

HTML comment carries the metadata; the next bullet line is the content.

**Current format (v0.1):**
```
<!-- source: file.md | confidence: 0.85 | created: 2026-04-20 | updated: 2026-04-25 -->
- memory content text
```

Fields are written as `key: value` separated by ` | `. Recognized keys:
- `source` (required) — origin file or identifier
- `confidence` (required) — float 0.0 to 1.0
- `created` (optional) — creation date
- `updated` (optional) — last modification date

**Legacy format (still parsed for back-compat):** the trailing field
without a `key:` prefix is treated as `created`:
```
<!-- source: file.md | confidence: 0.85 | 2026-04-20 -->
- memory content text
```

### Extensions (扩展数据)

Tool-specific structured data that doesn't fit into the common sections.
Stored as a fenced YAML block, keyed by ToolId so different tools never
collide during multi-source merges.

```markdown
# 扩展数据

​```yaml
hermes:
  skills:
    - code-review
    - doc-writer
openclaw:
  soul: "brief personality snapshot..."
  dreams:
    chars: 1234
​```
```

**Rules:**
- Emitted only when at least one tool namespace has non-empty data.
- Parser accepts both ` ```yaml ` and ` ``` ` fences, and both the
  Chinese (`# 扩展数据`) and English (`# Extensions`) section headings.
- Malformed YAML silently degrades to `extensions = undefined` rather
  than throwing — this is the parser's robustness contract.
- Merger: within the same tool namespace, later source wins on
  conflicting keys; different tool namespaces are union'd.

**Typical extension contents:**
- Hermes: `{ skills: string[] }`
- OpenClaw: `{ soul: string, dreams: { chars: number } }`
- Others: empty (their structured data fits into the common sections)

Importers default to **ignoring** extensions. This is intentional: tool-
specific data rarely translates across tools. A tool-specific importer
may opt in to read back its own namespace.

## Size Limits

- Parser rejects input larger than **10 MB** (`MAX_PARSE_SIZE`).
- Front matter block is capped at 10 KB; malformed or oversized front
  matter silently falls back to sensible defaults rather than throwing.
- Extensions YAML block is capped at 100 KB.
