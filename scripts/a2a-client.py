#!/usr/bin/env python3
"""
毛毛虫日记 — A2A 客户端

通过 A2A 协议与其他 Agent 通信。
支持两种模式：
    1. 调用远程 A2A Agent（需要 Agent URL）
    2. 调用本地质检 Agent（自动启动 agent-qa.py 作为子进程）

用法：
    # 调用本地质检 Agent 检查文件
    python3 scripts/a2a-client.py --check src/content/posts/2026-06-12-example.md

    # 调用远程 A2A Agent
    python3 scripts/a2a-client.py --agent-url http://localhost:5100 --message "你好"

    # 调用远程 Agent 检查文件
    python3 scripts/a2a-client.py --agent-url http://localhost:5100 --check-file article.md
"""

import argparse
import json
import os
import subprocess
import sys
import time
import urllib.request
import urllib.error
import signal
from typing import Any

# python-a2a 客户端
try:
    from python_a2a import A2AClient, Message, TextContent, MessageRole
except ImportError:
    print("错误: 需要安装 python-a2a", file=sys.stderr)
    print("运行: pip3 install python-a2a", file=sys.stderr)
    sys.exit(1)


def check_agent_available(url: str, timeout: int = 5) -> bool:
    """检查 Agent 是否在线"""
    try:
        agent_url = url.rstrip("/")
        if not agent_url.endswith("/.well-known/agent.json"):
            agent_url = f"{agent_url}/.well-known/agent.json"
        req = urllib.request.Request(agent_url)
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.status == 200
    except Exception:
        return False


def call_agent(url: str, message: str, timeout: int = 30) -> dict[str, Any]:
    """调用远程 A2A Agent"""
    try:
        client = A2AClient(url)

        # 获取 Agent 信息
        agent_name = "未知 Agent"
        try:
            card = client.agent_card
            if card and hasattr(card, "name"):
                agent_name = card.name
        except Exception:
            pass

        # 发送消息
        msg = Message(
            content=TextContent(text=message),
            role=MessageRole.USER,
        )
        response = client.send_message(msg)

        return {
            "success": True,
            "agent_name": agent_name,
            "response": response.content.text if response else "",
        }
    except Exception as e:
        return {
            "success": False,
            "agent_name": "未知 Agent",
            "error": str(e),
        }


def check_article_local(file_path: str) -> dict[str, Any]:
    """
    本地模式：自动启动质检 Agent，检查文章，然后关闭。
    这是最常用的模式——毛毛虫自己就能完成质检。
    """
    if not os.path.exists(file_path):
        return {
            "success": False,
            "error": f"文件不存在: {file_path}",
        }

    # 读取文章内容
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # 尝试通过 A2A 协议调用本地 Agent
    qa_url = "http://localhost:5100"
    qa_script = os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "agent-qa.py"
    )

    # 如果 Agent 已经在运行，直接调用
    if check_agent_available(qa_url):
        print("发现本地质检 Agent 正在运行，直接调用...")
        result = call_agent(qa_url, content)
        if result["success"]:
            return {
                "success": True,
                "mode": "a2a-remote",
                "report": result["response"],
            }

    # Agent 没在运行，启动子进程
    print("启动本地质检 Agent...")
    proc = None
    try:
        proc = subprocess.Popen(
            [sys.executable, qa_script, "--port", "5100"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

        # 等待 Agent 启动
        max_wait = 15
        for i in range(max_wait):
            if check_agent_available(qa_url):
                break
            time.sleep(1)
        else:
            # 启动失败，回退到 CLI 模式
            print("Agent 启动超时，回退到 CLI 模式...")
            return _check_article_cli(file_path, qa_script)

        # 调用 Agent
        result = call_agent(qa_url, content)

        return {
            "success": result["success"],
            "mode": "a2a-server",
            "report": result.get("response", result.get("error", "")),
        }

    finally:
        if proc:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()


def _check_article_cli(file_path: str, qa_script: str) -> dict[str, Any]:
    """
    CLI 回退模式：直接运行 agent-qa.py --check-file，不走 A2A 协议。
    当 A2A 服务启动失败时使用。
    """
    try:
        result = subprocess.run(
            [sys.executable, qa_script, "--check-file", file_path],
            capture_output=True,
            text=True,
            timeout=30,
        )
        return {
            "success": result.returncode == 0,
            "mode": "cli-fallback",
            "report": result.stdout,
        }
    except Exception as e:
        return {
            "success": False,
            "mode": "cli-fallback",
            "error": str(e),
        }


def discover_agents(registry_url: str) -> list[dict[str, Any]]:
    """从 Agent Registry 发现可用 Agent"""
    try:
        url = f"{registry_url.rstrip('/')}/agents"
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode())
            return data if isinstance(data, list) else [data]
    except Exception as e:
        return [{"error": f"无法连接 Registry: {e}"}]


def main():
    parser = argparse.ArgumentParser(
        description="毛毛虫日记 A2A 客户端 — 与其他 Agent 通信"
    )
    parser.add_argument(
        "--agent-url",
        type=str,
        default=None,
        help="远程 A2A Agent 的 URL（如 http://localhost:5100）",
    )
    parser.add_argument(
        "--check-file",
        type=str,
        default=None,
        help="检查指定文章文件的质量",
    )
    parser.add_argument(
        "--message",
        type=str,
        default=None,
        help="向 Agent 发送的消息",
    )
    parser.add_argument(
        "--discover",
        type=str,
        default=None,
        help="从 Registry URL 发现可用 Agent",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="以 JSON 格式输出结果（用于脚本集成）",
    )

    args = parser.parse_args()

    # 模式 1: 发现 Agent
    if args.discover:
        agents = discover_agents(args.discover)
        if args.json:
            print(json.dumps(agents, ensure_ascii=False, indent=2))
        else:
            print("发现的 Agent:")
            for a in agents:
                print(f"  - {a.get('name', '未知')}: {a.get('url', 'N/A')}")
        return

    # 模式 2: 检查文章
    if args.check_file:
        if args.agent_url:
            # 调用指定 Agent
            result = call_agent(args.agent_url, open(args.check_file).read())
        else:
            # 本地模式
            result = check_article_local(args.check_file)

        if args.json:
            print(json.dumps(result, ensure_ascii=False, indent=2))
        else:
            if result["success"]:
                print(f"质检完成 (模式: {result.get('mode', 'unknown')})")
                print(result.get("report", ""))
            else:
                print(f"质检失败: {result.get('error', '未知错误')}", file=sys.stderr)
                if result.get("report"):
                    print(result["report"])
                sys.exit(1)
        return

    # 模式 3: 发送消息
    if args.message and args.agent_url:
        result = call_agent(args.agent_url, args.message)
        if args.json:
            print(json.dumps(result, ensure_ascii=False, indent=2))
        else:
            if result["success"]:
                print(f"[{result['agent_name']}]: {result['response']}")
            else:
                print(f"通信失败: {result.get('error', '未知错误')}", file=sys.stderr)
                sys.exit(1)
        return

    # 没有参数时显示帮助
    parser.print_help()
    print("\n示例:")
    print("  # 检查今天的日记")
    print('  python3 scripts/a2a-client.py --check-file "src/content/posts/$(date +%Y-%m-%d)-*.md"')
    print()
    print("  # 调用远程 Agent")
    print('  python3 scripts/a2a-client.py --agent-url http://localhost:5100 --message "你好"')
    print()
    print("  # 检查文章并输出 JSON（用于脚本集成）")
    print("  python3 scripts/a2a-client.py --check-file article.md --json")


if __name__ == "__main__":
    main()
