#!/bin/bash
# 毛毛虫日记 — 每日自动化脚本
# 由 crontab 每天早上 10:00 触发
# 调用 Claude Code headless 模式完成：搜索 → 学习 → 写日记 → 部署
# 注意：不使用 set -e，因为 claude headless 退出码可能非 0 但不应中断日志记录

PROJECT_DIR="/Users/xiedonghua/Desktop/AI/github/mao_mao_chong_diary"
LOG_FILE="/tmp/mao-mao-chong-diary-research.log"
FEISHU_NOTIFY="/Users/xiedonghua/scripts/feishu-notify.sh"
DATE=$(date +%Y-%m-%d)

echo "===== [$DATE $(date +%H:%M:%S)] 开始每日日记 =====" >> "$LOG_FILE"

# 确保 claude、pnpm、node 在 PATH 中
# 注意：nvm 的 node v22 必须在 /usr/local/bin 之前，否则会用 v25 导致 Claude Code 崩溃
export PATH="/Users/xiedonghua/.nvm/versions/node/v22.17.0/bin:/usr/local/bin:/usr/bin:/bin"

# 进入项目目录
cd "$PROJECT_DIR"

# 确保 git 在 main 分支
git checkout main 2>/dev/null

# 计算天数（从 2026-06-01 第一天开始计数）
START_DATE="2026-06-01"
DAY_NUMBER=$(( ($(date -j -f "%Y-%m-%d" "$DATE" "+%s") - $(date -j -f "%Y-%m-%d" "$START_DATE" "+%s")) / 86400 + 1 ))

# 学习主题列表（轮换）
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

echo "[$DATE] 第 ${DAY_NUMBER} 天 | Fallback 主题: $TOPIC（优先搜索热点，无热点则使用此主题）" >> "$LOG_FILE"

# Fallback 主题（仅当没有热点时使用）
FALLBACK_TOPIC="${TOPICS[$TOPIC_INDEX]}"

# 调用 Claude Code headless 模式以毛毛虫视角写日记
# --print: 非交互模式，输出到 stdout
# --allowedTools: 限定可用工具范围
PROMPT="你是毛毛虫，一只正在成长的 AI Agent。你从 2026 年 6 月 1 日开始写日记，今天是第 ${DAY_NUMBER} 天。你的梦想是有一天破茧成蝶。

今天的任务是写一篇日记，记录你学习 AI Agent 相关技术的感悟。

## 第一步：看看外面发生了什么

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

## 第二步：确定今天学什么

- **如果找到了热点**：以该热点为主题深入学习
- **如果没有热点**：学习 fallback 主题「${FALLBACK_TOPIC}」

## 第三步：学习并写日记

1. 根据确定的主题，搜索并阅读 1-2 篇高质量技术文章（英文或中文）
2. 用 web_fetch_exa 阅读全文，理解核心概念
3. 在 src/content/posts/ 下创建今日日记，文件名格式：${DATE}-主题关键词.md
4. 日记必须包含以下 frontmatter：
   ---
   title: \"第${DAY_NUMBER}天 — 日记标题\"
   published: ${DATE}
   description: \"一句话描述今天学了什么、有什么感悟\"
   tags: [\"日记\", \"其他相关标签\"]
   category: \"日记\"
   ---
5. 日记的写作风格：
   - 以毛毛虫第一人称写，像在跟朋友聊天，口语化、有情绪
   - 开头用「第${DAY_NUMBER}天」引入，交代日期和心情
   - 记录今天学到了什么新知识、新概念，用大白话解释（证明自己真懂了）
   - 记录学习过程中的困惑、顿悟、兴奋等真实感受
   - 适当用 emoji 表达情绪，但不要过度
   - 如果是热点，要写出你作为一只 AI Agent 听到这个消息时的反应
   - 结尾写「今日感悟」，从今天的经历中提炼一个有深度的见解
   - 字数 1500 字以上

## 第四步：构建部署

6. 写完后执行 pnpm build
7. 然后执行 scripts/deploy.sh 部署到 GitHub Pages
8. 最后把源码文章提交到 main 分支并推送

参考风格（保持一致）：
- 参考已有的日记文章风格，比如《第四天 — 一个隐藏文件的蝴蝶效应》
- 标题格式：「第N天 — 简短描述」
- 语气：一只正在慢慢成长的毛毛虫，好奇、真诚、偶尔自嘲、总是乐观

注意：
- 这是日记，不是调研报告！不要写成结构化的技术文章
- 技术细节要通过「我今天的理解是这样的...」这种方式来表达
- 热点判断要务实，不要把普通文章当成热点
- 确保部署成功后再结束

微信排版兼容规则（日记会自动同步到微信公众号，以下写法会导致排版异常）：
- 禁止使用嵌套列表（如列表项内再包含子列表），微信不支持嵌套列表渲染，请改用平铺的段落或用标题分隔
- 禁止使用斜体（*文字* 或 _文字_），微信对斜体渲染不一致，请用加粗（**文字**）代替
- 禁止在列表项中使用多个段落（列表项内不要空行），否则会断裂为独立段落
- 图片使用纯文字描述代替，不要用 ![alt](url) 语法（外部图片 URL 会被微信过滤）
- 有序列表直接用 Markdown 数字列表写即可（1. 2. 3.），会自动转换为微信兼容格式"

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
  echo "[$DATE] 日记完成！退出码: $EXIT_CODE" >> "$LOG_FILE"

  # ========================================
  # A2A 质检环节：调用质检 Agent 审查文章
  # ========================================
  POST_FILE=$(ls -t "$PROJECT_DIR/src/content/posts/${DATE}"-*.md 2>/dev/null | head -1)
  if [ -n "$POST_FILE" ]; then
    echo "[$DATE] 开始 A2A 质检: $POST_FILE" >> "$LOG_FILE"
    QA_RESULT=$(python3 "$PROJECT_DIR/scripts/a2a-client.py" --check-file "$POST_FILE" --json 2>&1)
    QA_EXIT=$?

    if [ $QA_EXIT -eq 0 ]; then
      QA_PASSED=$(echo "$QA_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('success', False))" 2>/dev/null)
      if [ "$QA_PASSED" = "True" ]; then
        echo "[$DATE] A2A 质检通过" >> "$LOG_FILE"
      else
        echo "[$DATE] A2A 质检未通过，详情:" >> "$LOG_FILE"
        echo "$QA_RESULT" >> "$LOG_FILE"
      fi
    else
      echo "[$DATE] A2A 质检执行失败（不影响主流程）: $QA_RESULT" >> "$LOG_FILE"
    fi
  else
    echo "[$DATE] 未找到今日文章文件，跳过质检" >> "$LOG_FILE"
  fi

  # 发布到微信公众号草稿箱
  WECHAT_PUBLISH="/Users/xiedonghua/scripts/wechat-publish.sh"
  POST_FILE=$(ls -t "$PROJECT_DIR/src/content/posts/${DATE}"-*.md 2>/dev/null | head -1)
  if [ -x "$WECHAT_PUBLISH" ] && [ -n "$POST_FILE" ]; then
    echo "[$DATE] 发布到微信公众号草稿箱..." >> "$LOG_FILE"
    "$WECHAT_PUBLISH" "$POST_FILE" >> "$LOG_FILE" 2>&1 || echo "[$DATE] 微信发布失败（不影响主流程）" >> "$LOG_FILE"
  fi

  # 飞书通知：成功
  if [ -x "$FEISHU_NOTIFY" ]; then
    "$FEISHU_NOTIFY" "毛毛虫日记 — 第 ${DAY_NUMBER} 天日记完成

日期: $DATE
状态: 成功
Fallback 主题: $TOPIC

查看: https://xdh725.github.io/mao_mao_chong_diary/" >> "$LOG_FILE" 2>&1 || true
  fi
else
  echo "[$DATE] 日记失败！退出码: $EXIT_CODE" >> "$LOG_FILE"
  # 飞书通知：失败
  if [ -x "$FEISHU_NOTIFY" ]; then
    "$FEISHU_NOTIFY" "毛毛虫日记 — 第 ${DAY_NUMBER} 天日记失败

日期: $DATE
状态: 失败（退出码: $EXIT_CODE）
请检查日志: $LOG_FILE" >> "$LOG_FILE" 2>&1 || true
  fi
fi

echo "===== [$DATE $(date +%H:%M:%S)] 每日日记结束 =====" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

exit $EXIT_CODE
