#!/bin/bash
# 每日 AI Agent 技术调研自动化脚本
# 由 crontab 每天早上 10:00 触发
# 调用 Claude Code headless 模式完成：搜索 → 阅读 → 写作 → 部署
set -e

PROJECT_DIR="/Users/xiedonghua/Desktop/AI/github/mao_mao_chong_diary"
LOG_FILE="/tmp/mao-mao-chong-diary-research.log"
DATE=$(date +%Y-%m-%d)

echo "===== [$DATE $(date +%H:%M:%S)] 开始每日调研 =====" >> "$LOG_FILE"

# 确保 claude、pnpm、node 在 PATH 中
export PATH="/usr/local/bin:/Users/xiedonghua/.nvm/versions/node/v22.17.0/bin:$PATH"

# 进入项目目录
cd "$PROJECT_DIR"

# 确保 git 在 main 分支
git checkout main 2>/dev/null

# 调研主题列表（轮换）
# 每周一个主题循环
TOPICS=(
  "ReAct 模式 — Agent 的推理+行动范式"
  "Tool Use — Agent 如何调用外部工具"
  "Multi-Agent — 多 Agent 协作设计模式"
  "Memory 系统 — Agent 的记忆架构"
  "Planning — Agent 的任务规划能力"
  "Agent 评测 — 如何评估 Agent 质量"
  "MCP 协议 — Model Context Protocol"
)

# 根据星期几选择主题 (0=周日, 1=周一, ...)
DAY_OF_WEEK=$(date +%u)  # 1-7 (周一到周日)
TOPIC_INDEX=$(( (DAY_OF_WEEK - 1) % 7 ))
TOPIC="${TOPICS[$TOPIC_INDEX]}"

echo "[$DATE] 今日主题: $TOPIC" >> "$LOG_FILE"

# 调用 Claude Code headless 模式执行调研
# --print: 非交互模式，输出到 stdout
# --allowedTools: 限定可用工具范围
PROMPT="你是毛毛虫日记的每日 AI Agent 调研员。今天的任务是：

1. 搜索一篇关于「$TOPIC」的高质量技术文章（英文或中文）
2. 用 web_fetch_exa 阅读全文
3. 在 src/content/posts/ 下创建今日调研文章，文件名格式：${DATE}-调研主题关键词.md
4. 文章必须包含以下 frontmatter：
   ---
   title: \"调研：文章标题\"
   published: ${DATE}
   description: \"一句话总结\"
   tags: [\"AI Agent\", \"调研\", \"其他相关标签\"]
   category: \"调研笔记\"
   ---
5. 文章正文结构：原文信息、一句话总结、核心观点（3-5个）、技术细节（如有）、我的思考（以毛毛虫的第一人称视角）、延伸阅读
6. 我的思考部分要真诚、有洞察力，结合自己的学习阶段来写
7. 写完后执行 pnpm build
8. 然后执行 scripts/deploy.sh 部署到 GitHub Pages
9. 最后把源码文章提交到 main 分支并推送

注意：
- 调研文章的字数不少于 1500 字
- 技术细节要准确，引用原文数据要标明
- 我的思考部分要有深度，不能泛泛而谈
- 确保部署成功后再结束"

claude --print \
  --model sonnet \
  --allowedTools "WebSearch,WebFetch,mcp__exa__web_search_exa,mcp__exa__web_fetch_exa,Read,Write,Edit,Bash,Glob,Grep" \
  "$PROMPT" >> "$LOG_FILE" 2>&1

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "[$DATE] 调研完成！退出码: $EXIT_CODE" >> "$LOG_FILE"
else
  echo "[$DATE] 调研失败！退出码: $EXIT_CODE" >> "$LOG_FILE"
fi

echo "===== [$DATE $(date +%H:%M:%S)] 每日调研结束 =====" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

exit $EXIT_CODE
