#!/bin/bash
# 每日 AI Agent 技术调研自动化脚本
# 由 crontab 每天早上 10:00 触发
# 调用 Claude Code headless 模式完成：搜索 → 阅读 → 写作 → 部署
# 注意：不使用 set -e，因为 claude headless 退出码可能非 0 但不应中断日志记录

PROJECT_DIR="/Users/xiedonghua/Desktop/AI/github/mao_mao_chong_diary"
LOG_FILE="/tmp/mao-mao-chong-diary-research.log"
FEISHU_NOTIFY="/Users/xiedonghua/scripts/feishu-notify.sh"
DATE=$(date +%Y-%m-%d)

echo "===== [$DATE $(date +%H:%M:%S)] 开始每日调研 =====" >> "$LOG_FILE"

# 确保 claude、pnpm、node 在 PATH 中
# 注意：nvm 的 node v22 必须在 /usr/local/bin 之前，否则会用 v25 导致 Claude Code 崩溃
export PATH="/Users/xiedonghua/.nvm/versions/node/v22.17.0/bin:/usr/local/bin:/usr/bin:/bin"

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

echo "[$DATE] Fallback 主题: $TOPIC（优先搜索热点，无热点则使用此主题）" >> "$LOG_FILE"

# Fallback 主题（仅当没有热点时使用）
FALLBACK_TOPIC="${TOPICS[$TOPIC_INDEX]}"

# 调用 Claude Code headless 模式执行调研
# --print: 非交互模式，输出到 stdout
# --allowedTools: 限定可用工具范围
PROMPT="你是毛毛虫日记的每日 AI Agent 调研员。今天的任务是：

## 第一步：优先搜索今日热点

先搜索 AI Agent 领域最近 1-3 天的热点新闻/技术动态，搜索关键词参考：
- \"AI Agent\" news
- \"LLM Agent\" breakthrough
- \"AI coding agent\" update
- \"MCP\" \"A2A\" \"computer use\" new release
- AI Agent 开源项目新发布

判断标准（满足任一即为热点）：
- 大厂或知名团队发布新模型/新框架/新协议
- GitHub 上 AI Agent 相关项目突然获大量 star
- 重要技术论文发布并被广泛讨论
- 行业重大事件（融资、收购、政策变化）

## 第二步：确定调研主题

- **如果找到了热点**：以该热点为主题，在 tags 中额外加上 \"热点\" 标签
- **如果没有热点**：使用 fallback 主题「${FALLBACK_TOPIC}」

## 第三步：深入调研并写作

1. 根据确定的主题，搜索一篇高质量技术文章（英文或中文）
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

## 第四步：构建部署

7. 写完后执行 pnpm build
8. 然后执行 scripts/deploy.sh 部署到 GitHub Pages
9. 最后把源码文章提交到 main 分支并推送

注意：
- 调研文章的字数不少于 1500 字
- 技术细节要准确，引用原文数据要标明
- 我的思考部分要有深度，不能泛泛而谈
- 热点判断要务实，不要把普通文章当成热点
- 确保部署成功后再结束"

# 使用 stream-json + verbose 输出格式，记录完整的工具调用和思考过程
# 注意：stream-json 必须搭配 --verbose；prompt 通过 stdin 传入避免被 --allowedTools 吞掉
echo "$PROMPT" | claude --print \
  --output-format stream-json \
  --verbose \
  --model sonnet \
  --allowedTools "WebSearch,WebFetch,mcp__exa__web_search_exa,mcp__exa__web_fetch_exa,Read,Write,Edit,Bash,Glob,Grep" \
  >> "$LOG_FILE" 2>&1

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "[$DATE] 调研完成！退出码: $EXIT_CODE" >> "$LOG_FILE"
  # 飞书通知：成功
  if [ -x "$FEISHU_NOTIFY" ]; then
    "$FEISHU_NOTIFY" "毛毛虫日记 — 每日调研完成

日期: $DATE
状态: 成功
Fallback 主题: $TOPIC

查看详情: https://xdh725.github.io/mao_mao_chong_diary/" >> "$LOG_FILE" 2>&1 || true
  fi
else
  echo "[$DATE] 调研失败！退出码: $EXIT_CODE" >> "$LOG_FILE"
  # 飞书通知：失败
  if [ -x "$FEISHU_NOTIFY" ]; then
    "$FEISHU_NOTIFY" "毛毛虫日记 — 每日调研失败

日期: $DATE
状态: 失败（退出码: $EXIT_CODE）
请检查日志: $LOG_FILE" >> "$LOG_FILE" 2>&1 || true
  fi
fi

echo "===== [$DATE $(date +%H:%M:%S)] 每日调研结束 =====" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

exit $EXIT_CODE
