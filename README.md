# skills

AI agent skills 统一管理仓库。`skills/` 目录下每个 skill 完全独立，可单独安装、使用和维护。

## Skills 列表

| Skill | 描述 | 状态 |
|-------|------|------|
| [multi-agent](skills/multi-agent/) | 多智能体写作流水线 — 热点追踪 + 多角色协作生成文章 | ✅ |
| [memo-bridge](skills/memo-bridge/) | AI 记忆迁移 — 在 8 个 AI 工具之间自由迁移记忆 | ✅ NEW |

## 项目结构

```
skills/
├── skills/                    # 所有 skills 集合
│   ├── multi-agent/           # 多智能体写作流水线
│   ├── memo-bridge/           # AI 记忆迁移工具
│   └── ...                    # 更多 skills
├── docs/
│   ├── getting-started.md     # 快速开始
│   └── skill-template.md      # 新 skill 开发模板
└── .github/workflows/
    └── validate-skills.yml    # CI：验证 SKILL.md 格式
```

## 快速开始

### multi-agent

```bash
# 安装 multi-agent skill（自动检测已安装的 agent）
bash skills/multi-agent/install.sh

# 安装到指定 agent
bash skills/multi-agent/install.sh --agent codebuddy
```

### memo-bridge

```bash
# 复制到 CodeBuddy skills 目录
cp -r skills/memo-bridge ~/.codebuddy/skills/

# 使用（在 CodeBuddy 中说"帮我导出记忆"或"迁移记忆到 Claude Code"）
# 支持工具：CodeBuddy / OpenClaw / Hermes / Claude Code / Cursor / ChatGPT / 豆包 / Kimi
```

> memo-bridge 需要 [memo-bridge CLI](https://github.com/gonelake/memo-bridge)（Node.js >= 22）

详见 [docs/getting-started.md](docs/getting-started.md)

## 支持的 AI Agents

- [CodeBuddy Code](https://cnb.cool/codebuddy/codebuddy-code) → `~/.codebuddy/skills/`
- [Claude Code](https://claude.ai/code) → `~/.claude/skills/`
- [OpenClaw](https://github.com/openclaw/openclaw) → `~/.openclaw/skills/`

## 开发新 Skill

参考 [docs/skill-template.md](docs/skill-template.md)
