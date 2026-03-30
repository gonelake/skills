# Getting Started

## 安装某个 skill

每个 skill 是独立的，直接进入对应目录执行安装脚本即可：

```bash
# 克隆仓库
git clone https://github.com/gonelake/skills.git
cd skills

# 安装 multi-agent skill
bash skills/multi-agent/install.sh

# 安装到指定 agent
bash skills/multi-agent/install.sh --agent codebuddy
bash skills/multi-agent/install.sh --agent claude
bash skills/multi-agent/install.sh --agent openclaw
bash skills/multi-agent/install.sh --agent all
```

## 安装后验证

```bash
bash skills/multi-agent/tests/test_install.sh
```

## 卸载

```bash
bash skills/multi-agent/uninstall.sh          # 仅移除注册
bash skills/multi-agent/uninstall.sh --all    # 同时删除数据
```

## 开发模式（本地已有项目源码）

如果你本地已有 multi-agent 项目，可以跳过 clone，直接符号链接：

```bash
bash skills/multi-agent/scripts/link-project.sh ~/path/to/multi-agent
bash skills/multi-agent/install.sh --agent codebuddy
```

## 所有可用 Skills

见 [skills/README.md](../skills/README.md)
