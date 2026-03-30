# skills

AI agent skills 统一管理仓库。`skills/` 目录下每个 skill 完全独立，可单独安装、使用和维护。

## 项目结构

```
skills/
├── skills/                    # 所有 skills 集合
│   ├── multi-agent/           # 多智能体写作流水线
│   └── ...                    # 更多 skills
├── docs/
│   ├── getting-started.md     # 快速开始
│   └── skill-template.md      # 新 skill 开发模板
└── .github/workflows/
    └── validate-skills.yml    # CI：验证 SKILL.md 格式
```

## 快速开始

```bash
# 安装 multi-agent skill（自动检测已安装的 agent）
bash skills/multi-agent/install.sh

# 安装到指定 agent
bash skills/multi-agent/install.sh --agent codebuddy
```

详见 [docs/getting-started.md](docs/getting-started.md)

## 支持的 AI Agents

- [CodeBuddy Code](https://cnb.cool/codebuddy/codebuddy-code) → `~/.codebuddy/skills/`
- [Claude Code](https://claude.ai/code) → `~/.claude/skills/`
- [OpenClaw](https://github.com/openclaw/openclaw) → `~/.openclaw/skills/`

## 开发新 Skill

参考 [docs/skill-template.md](docs/skill-template.md)
