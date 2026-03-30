# Skills

每个子目录是一个完全独立的 skill，互不依赖。

## 已有 Skills

| Skill | 描述 | 状态 |
|-------|------|------|
| [multi-agent](./multi-agent/) | 多智能体写作流水线（热点抓取→撰写→审校） | ✅ 可用 |

## 添加新 Skill

每个 skill 必须包含以下文件：

```
skills/<skill-name>/
├── SKILL.md       # 必须：skill 定义，包含 YAML frontmatter
├── install.sh     # 必须：独立安装脚本
├── uninstall.sh   # 推荐：卸载脚本
├── README.md      # 推荐：使用说明
├── scripts/       # 可选：辅助脚本
├── config/        # 可选：配置模板
└── tests/         # 可选：安装验证测试
```

### SKILL.md frontmatter 格式

```yaml
---
name: <skill-name>
description: <触发场景描述，AI 通过此字段决定何时调用该 skill>
location: user
allowed-tools: Bash, Read
---
```

参考 `../docs/skill-template.md` 获取完整模板。
