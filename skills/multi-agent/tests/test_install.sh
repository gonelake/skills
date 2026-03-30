#!/usr/bin/env bash
# test_install.sh — 验证 multi-agent skill 安装是否正确
#
# 用法：bash tests/test_install.sh

set -euo pipefail

SKILL_NAME="multi-agent"
INSTALL_DIR="${HOME}/.skills/multi-agent"
PASS=0
FAIL=0

check() {
    local desc="$1"
    local condition="$2"
    if eval "${condition}"; then
        echo "  ✓ ${desc}"
        ((PASS++))
    else
        echo "  ✗ ${desc}"
        ((FAIL++))
    fi
}

echo "── 检查项目代码 ──────────────────────────────────"
check "项目目录存在"          "[[ -d '${INSTALL_DIR}' ]]"
check "main.py 存在"          "[[ -f '${INSTALL_DIR}/main.py' ]]"
check "orchestrator.py 存在"  "[[ -f '${INSTALL_DIR}/orchestrator.py' ]]"
check "agents.py 存在"        "[[ -f '${INSTALL_DIR}/agents.py' ]]"
check "requirements.txt 存在" "[[ -f '${INSTALL_DIR}/requirements.txt' ]]"

echo ""
echo "── 检查 Python 依赖 ──────────────────────────────"
check "Python 可用"          "command -v python3 &>/dev/null || command -v python &>/dev/null"

PYTHON=$(command -v python3 || command -v python)
check "duckduckgo_search 已安装" "${PYTHON} -c 'import duckduckgo_search' 2>/dev/null"
check "openai 已安装"           "${PYTHON} -c 'import openai' 2>/dev/null"

echo ""
echo "── 检查 Skill 注册 ───────────────────────────────"
for agent_dir in "${HOME}/.codebuddy/skills" "${HOME}/.claude/skills" "${HOME}/.openclaw/skills"; do
    agent=$(basename "$(dirname "${agent_dir}")" | sed 's/^\.//')
    skill_file="${agent_dir}/${SKILL_NAME}/SKILL.md"
    if [[ -f "${skill_file}" ]]; then
        check "已注册到 ${agent}" "true"
        check "  SKILL.md 不含未替换的占位符" "! grep -q '<INSTALL_DIR>' '${skill_file}'"
    fi
done

echo ""
echo "── 检查 Demo 模式 ────────────────────────────────"
check "demo 模式可执行" "${PYTHON} ${INSTALL_DIR}/main.py --demo --topic 'test' --words 100 &>/dev/null"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  通过: ${PASS}  失败: ${FAIL}"
[[ ${FAIL} -eq 0 ]] && echo "  ✓ 所有检查通过" || echo "  ✗ 有检查未通过"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit ${FAIL}
