#!/usr/bin/env python3
"""
毛毛虫日记 — 文章质检 Agent（A2A Server）

基于 A2A 协议，提供文章质量检查服务。
毛毛虫写完日记后，通过 A2A Client 调用此 Agent 进行质量审查。

启动方式：
    python3 scripts/agent-qa.py [--port PORT] [--api-key KEY]

质检维度：
    1. 字数检查（不低于 1500 字）
    2. frontmatter 完整性
    3. 微信排版兼容性（禁止嵌套列表、斜体、外部图片）
    4. 写作风格一致性（第一人称、口语化）
    5. 结构完整性（开头引入、今日感悟）
"""

import argparse
import json
import os
import re
import sys
import yaml
from typing import Any

# python-a2a A2A Server
from python_a2a import (
    A2AServer,
    AgentCard,
    AgentSkill,
    Message,
    MessageRole,
    TextContent,
    run_server,
)


class ArticleQA:
    """文章质检逻辑"""

    MIN_WORD_COUNT = 1500

    def __init__(self):
        self.errors: list[str] = []
        self.warnings: list[str] = []
        self.suggestions: list[str] = []

    def check(self, article_content: str) -> dict[str, Any]:
        """执行全部质检项，返回质检报告"""
        self.errors = []
        self.warnings = []
        self.suggestions = []

        self._check_frontmatter(article_content)
        self._check_word_count(article_content)
        self._check_wechat_compatibility(article_content)
        self._check_style_consistency(article_content)
        self._check_structure(article_content)

        passed = len(self.errors) == 0
        return {
            "passed": passed,
            "errors": self.errors,
            "warnings": self.warnings,
            "suggestions": self.suggestions,
            "summary": self._generate_summary(passed),
        }

    def _parse_frontmatter(self, content: str) -> tuple[dict, str]:
        """解析 frontmatter，返回 (metadata, body)"""
        match = re.match(r"^---\s*\n(.*?)\n---\s*\n(.*)", content, re.DOTALL)
        if not match:
            return {}, content
        try:
            meta = yaml.safe_load(match.group(1)) or {}
        except yaml.YAMLError:
            meta = {}
        return meta, match.group(2)

    def _check_frontmatter(self, content: str):
        """检查 frontmatter 完整性"""
        meta, _ = self._parse_frontmatter(content)

        if not meta:
            self.errors.append("frontmatter 缺失或格式错误")
            return

        required_fields = ["title", "published"]
        for field in required_fields:
            if field not in meta or not meta[field]:
                self.errors.append(f"frontmatter 缺少必填字段: {field}")

        optional_fields = ["description", "tags", "category"]
        for field in optional_fields:
            if field not in meta or not meta[field]:
                self.warnings.append(f"frontmatter 建议填写字段: {field}")

        # 检查 title 格式
        title = meta.get("title", "")
        if title and not re.search(r"第\d+天", title):
            self.suggestions.append(
                "标题建议使用「第N天 — 简短描述」格式，保持与其他日记一致"
            )

    def _check_word_count(self, content: str):
        """检查字数"""
        _, body = self._parse_frontmatter(content)
        # 去掉 Markdown 标记统计纯文字
        clean = re.sub(r"[#*`\[\]()>|~\-]", "", body)
        clean = re.sub(r"\s+", "", clean)
        count = len(clean)

        if count < self.MIN_WORD_COUNT:
            self.errors.append(
                f"字数不足: 当前约 {count} 字，要求至少 {self.MIN_WORD_COUNT} 字"
            )
        elif count < 2000:
            self.suggestions.append(
                f"当前约 {count} 字，可以再丰富一些内容"
            )

    def _check_wechat_compatibility(self, content: str):
        """检查微信排版兼容性"""
        _, body = self._parse_frontmatter(content)

        # 禁止嵌套列表：列表项缩进后紧跟列表标记
        lines = body.split("\n")
        in_list = False
        for i, line in enumerate(lines):
            stripped = line.strip()
            is_list_item = bool(re.match(r"^[-*+]\s", stripped)) or bool(
                re.match(r"^\d+\.\s", stripped)
            )
            if is_list_item and in_list and line.startswith("  "):
                self.errors.append(
                    f"第 {i + 1} 行: 发现嵌套列表，微信不支持嵌套列表渲染，请改用平铺段落"
                )
            if is_list_item:
                in_list = True
            elif stripped == "":
                in_list = False

        # 禁止斜体
        italic_pattern = re.compile(r"(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)")
        matches = italic_pattern.findall(body)
        if matches:
            self.errors.append(
                f"发现 {len(matches)} 处斜体语法，微信渲染不一致，请用加粗代替"
            )

        # 禁止外部图片
        img_pattern = re.compile(r"!\[.*?\]\(https?://")
        img_matches = img_pattern.findall(body)
        if img_matches:
            self.errors.append(
                f"发现 {len(img_matches)} 处外部图片链接，微信会过滤外部图片，请用文字描述代替"
            )

        # 禁止列表项内多段落
        list_block_pattern = re.compile(
            r"(?:^[-*+]\s.+\n)(?:\n.+)+", re.MULTILINE
        )
        multi_para = list_block_pattern.findall(body)
        if multi_para:
            self.warnings.append(
                "列表项内可能包含多段落（空行分隔），微信中可能断裂为独立段落"
            )

    def _check_style_consistency(self, content: str):
        """检查写作风格一致性"""
        _, body = self._parse_frontmatter(content)

        # 检查是否用第一人称
        first_person = len(re.findall(r"我[的了吗？呢！]", body))
        if first_person < 3:
            self.warnings.append(
                "第一人称表达较少，日记应以毛毛虫第一人称视角写作"
            )

        # 检查是否过于正式
        formal_words = ["因此", "综上所述", "由此可见", "总而言之", "笔者"]
        for word in formal_words:
            if word in body:
                self.suggestions.append(
                    f"发现较正式的表达「{word}」，建议改为口语化表达"
                )

    def _check_structure(self, content: str):
        """检查文章结构完整性"""
        _, body = self._parse_frontmatter(content)

        # 检查开头引入
        if not re.search(r"第\d+天", body[:200]):
            self.warnings.append(
                "文章开头建议用「第N天」引入，交代日期和心情"
            )

        # 检查今日感悟
        if "今日感悟" not in body and "感悟" not in body:
            self.warnings.append(
                "建议在结尾添加「今日感悟」，从今天的经历中提炼见解"
            )

    def _generate_summary(self, passed: bool) -> str:
        """生成质检摘要"""
        status = "通过" if passed else "未通过"
        parts = [f"质检结果: {status}"]
        if self.errors:
            parts.append(f"错误: {len(self.errors)} 项")
        if self.warnings:
            parts.append(f"警告: {len(self.warnings)} 项")
        if self.suggestions:
            parts.append(f"建议: {len(self.suggestions)} 项")
        return " | ".join(parts)


class QAAgentServer(A2AServer):
    """质检 Agent — A2A Server 实现"""

    def __init__(self, api_key: str | None = None):
        agent_card = AgentCard(
            name="毛毛虫日记质检 Agent",
            description="检查毛毛虫日记的文章质量，包括字数、frontmatter、微信排版兼容性、写作风格等",
            url="http://localhost:5100",
            version="0.1.0",
            skills=[
                AgentSkill(
                    name="文章质检",
                    description="对 Markdown 格式的日记文章进行质量检查",
                    examples=[
                        "检查这篇文章的质量",
                        "帮我审核一下今天的日记",
                    ],
                ),
            ],
            capabilities={
                "streaming": False,
                "pushNotifications": False,
            },
        )
        super().__init__(agent_card=agent_card, api_key=api_key)
        self.qa = ArticleQA()

    def handle_message(self, message: Message) -> Message:
        """处理 A2A 消息：接收文章内容，返回质检报告"""
        article_content = message.content.text

        if not article_content or not article_content.strip():
            return Message(
                content=TextContent(
                    text=json.dumps(
                        {
                            "passed": False,
                            "errors": ["文章内容为空"],
                            "warnings": [],
                            "suggestions": [],
                            "summary": "质检结果: 未通过 | 错误: 1 项",
                        },
                        ensure_ascii=False,
                        indent=2,
                    )
                ),
                role=MessageRole.AGENT,
                parent_message_id=message.message_id,
                conversation_id=message.conversation_id,
            )

        report = self.qa.check(article_content)
        return Message(
            content=TextContent(
                text=json.dumps(report, ensure_ascii=False, indent=2)
            ),
            role=MessageRole.AGENT,
            parent_message_id=message.message_id,
            conversation_id=message.conversation_id,
        )


def main():
    parser = argparse.ArgumentParser(description="毛毛虫日记质检 Agent (A2A Server)")
    parser.add_argument(
        "--port", type=int, default=5100, help="服务端口 (默认: 5100)"
    )
    parser.add_argument("--api-key", type=str, default=None, help="API Key (可选)")
    parser.add_argument(
        "--check-file",
        type=str,
        default=None,
        help="直接检查文件而不启动服务（用于 CLI 模式）",
    )
    args = parser.parse_args()

    qa = ArticleQA()

    # CLI 模式：直接检查文件
    if args.check_file:
        if not os.path.exists(args.check_file):
            print(f"文件不存在: {args.check_file}", file=sys.stderr)
            sys.exit(1)
        with open(args.check_file, "r", encoding="utf-8") as f:
            content = f.read()
        report = qa.check(content)
        print(json.dumps(report, ensure_ascii=False, indent=2))
        sys.exit(0 if report["passed"] else 1)

    # Server 模式：启动 A2A 服务
    agent = QAAgentServer(api_key=args.api_key)
    print(f"质检 Agent 启动在端口 {args.port}...")
    print(f"Agent Card: http://localhost:{args.port}/.well-known/agent.json")
    run_server(agent, host="0.0.0.0", port=args.port)


if __name__ == "__main__":
    main()
