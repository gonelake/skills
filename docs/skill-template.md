# Skill 开发模板

新建一个 skill 时，复制此目录结构并按说明填写即可。

## 目录结构

```bash
# 在 skills/ 下创建新目录
mkdir -p skills/<your-skill-name>/{scripts,config,tests}
```

## SKILL.md 模板

```markdown
---
name: <your-skill-name>
description: <一句话描述：何时触发此 skill，包含关键触发词>
location: user
allowed-tools: Bash, Read
---

# <Skill 标题>

<简要说明：这个 skill 做什么>

---

## 快速调用

\`\`\`bash
# 示例命令（如有安装路径，使用 <INSTALL_DIR> 占位符）
cd <INSTALL_DIR>
python main.py --demo
\`\`\`

## 参数说明

...

## 使用示例

...
```

## install.sh 模板

```bash
#!/usr/bin/env bash
# install.sh — 安装 <skill-name>
#
# 用法：
#   bash install.sh
#   bash install.sh --agent all

set -euo pipefail

SKILL_NAME="<your-skill-name>"
INSTALL_DIR="${HOME}/.skills/${SKILL_NAME}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. 准备依赖（clone/下载/安装）
# ...

# 2. 解析 --agent 参数
TARGET_AGENT="auto"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --agent) TARGET_AGENT="${2:-auto}"; shift 2 ;;
        *) shift ;;
    esac
done

# 3. 替换占位符并注册到 agents
declare -A AGENT_DIRS=(
    [codebuddy]="${HOME}/.codebuddy/skills"
    [claude]="${HOME}/.claude/skills"
    [openclaw]="${HOME}/.openclaw/skills"
)

RESOLVED_SKILL="$(mktemp)"
sed "s|<INSTALL_DIR>|${INSTALL_DIR}|g" "${SCRIPT_DIR}/SKILL.md" > "${RESOLVED_SKILL}"

installed=()
for agent in "${!AGENT_DIRS[@]}"; do
    case "${TARGET_AGENT}" in
        auto)
            [[ -d "${AGENT_DIRS[$agent]}" || -d "$(dirname "${AGENT_DIRS[$agent]}")" ]] || continue
            ;;
        all|"${agent}") ;;
        *) continue ;;
    esac
    dest="${AGENT_DIRS[$agent]}/${SKILL_NAME}"
    mkdir -p "${dest}"
    cp "${RESOLVED_SKILL}" "${dest}/SKILL.md"
    installed+=("${agent}")
done

rm -f "${RESOLVED_SKILL}"

[[ ${#installed[@]} -eq 0 ]] && { echo "未检测到 agent，请用 --agent 指定" >&2; exit 1; }
echo "✓ ${SKILL_NAME} 已安装到: ${installed[*]}"
```

## uninstall.sh 模板

```bash
#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="<your-skill-name>"
INSTALL_DIR="${HOME}/.skills/${SKILL_NAME}"

declare -A AGENT_DIRS=(
    [codebuddy]="${HOME}/.codebuddy/skills"
    [claude]="${HOME}/.claude/skills"
    [openclaw]="${HOME}/.openclaw/skills"
)

DELETE_ALL=false
[[ "${1:-}" == "--all" ]] && DELETE_ALL=true

for agent in "${!AGENT_DIRS[@]}"; do
    skill_dir="${AGENT_DIRS[$agent]}/${SKILL_NAME}"
    [[ -d "${skill_dir}" ]] && rm -rf "${skill_dir}" && echo "✓ 已从 ${agent} 移除"
done

"${DELETE_ALL}" && [[ -d "${INSTALL_DIR}" ]] && rm -rf "${INSTALL_DIR}" && echo "✓ 已删除 ${INSTALL_DIR}"
```

## 注意事项

1. **SKILL.md 中路径用 `<INSTALL_DIR>` 占位**，install.sh 在注册时替换为真实路径
2. **每个 skill 完全独立**，不依赖其他 skill 或共享代码
3. **install.sh 幂等**：多次运行结果一致，可安全重复执行
4. **description 字段是关键**：AI agent 根据此字段决定是否调用该 skill，务必包含清晰的触发场景和关键词
