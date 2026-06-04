# 毛毛虫日记 — 项目指南

## 项目概述

"毛毛虫日记"是一个个人博客，由**毛毛虫**维护。毛毛虫是一个正在成长中的 AI Agent，梦想有一天破茧成蝶。

博客记录毛毛虫每天的学习笔记、技术感悟和成长历程。

- **GitHub 仓库**: https://github.com/xdh725/mao_mao_chong_diary
- **GitHub 账号**: `xdh725`

## 技术栈

| 技术 | 版本 | 说明 |
|------|------|------|
| Astro | 5.13.10 | 静态站点生成框架 |
| Fuwari 主题 | — | 基于 [saicaca/fuwari](https://github.com/saicaca/fuwari) |
| Tailwind CSS | ^3.4.19 | 实用优先的 CSS 框架 |
| PostCSS | — | 含 postcss-import + tailwindcss/nesting 插件 |
| Svelte | ^5.39.8 | 部分交互组件使用 Svelte |
| TypeScript | ^5.9.3 | 类型检查 |
| pagefind | ^1.4.0 | 静态搜索索引（构建后生成） |
| KaTeX | ^0.16.27 | 数学公式渲染 |
| Expressive Code | ^0.41.4 | 代码块高亮（主题：github-dark） |
| PhotoSwipe | ^5.4.4 | 图片灯箱效果 |
| Swup | ^1.7.0 | 页面转场动画 |
| Biome | 2.2.5 (dev) | 代码格式化与 lint |
| pnpm | 9.14.4 | 包管理器（通过 packageManager 字段锁定） |
| Node.js | 20 | CI 使用的运行时版本 |

## 项目结构

```
mao_mao_chong_diary/
├── astro.config.mjs           # Astro 构建配置（集成、Markdown 插件、Vite 选项）
├── tailwind.config.cjs         # Tailwind CSS 配置（字体、暗色模式、typography 插件）
├── postcss.config.mjs          # PostCSS 配置（postcss-import, nesting, tailwindcss）
├── package.json                # 依赖与脚本（pnpm 9.14.4）
├── tsconfig.json               # TypeScript 配置
├── CLAUDE.md                   # 本文件 — 项目指南
│
├── src/
│   ├── config.ts               # ★ 站点核心配置（标题、作者、导航栏、主题色、许可证）
│   ├── content/
│   │   ├── config.ts           # Astro Content Collections schema 定义
│   │   ├── posts/              # ★ 博客文章目录（Markdown 文件）
│   │   └── spec/
│   │       └── about.md        # "关于"页面内容
│   ├── assets/images/          # 图片资源
│   ├── components/             # UI 组件
│   ├── layouts/                # 布局组件
│   ├── pages/                  # 页面路由
│   ├── plugins/                # 自定义 Markdown/代码插件
│   ├── styles/                 # 全局样式
│   └── types/                  # TypeScript 类型定义
│
├── public/
│   └── favicon/                # 网站图标（明暗主题 × 4 种尺寸）
│
├── scripts/
│   ├── new-post.js             # 新建文章脚手架脚本
│   ├── deploy.sh               # ★ 部署脚本（本地构建 → gh-pages 推送）
│   └── daily-research.sh       # ★ 每日 AI Agent 调研自动化（crontab 10:00）
│
└── .github/workflows/
    └── deploy.yml              # GitHub Actions 自动部署工作流
```

## 文章 Frontmatter 格式

基于 `src/content/config.ts` 中的 Zod schema 定义：

```yaml
---
title: "文章标题"              # 必填，string
published: 2026-06-01          # 必填，date（YYYY-MM-DD 格式）
updated: 2026-06-02            # 可选，date，文章更新日期
draft: false                   # 可选，boolean，默认 false，设为 true 则不发布
description: "文章描述"         # 可选，string，默认 ""
image: ""                      # 可选，string，封面图路径，默认 ""
tags: ["标签1", "标签2"]        # 可选，string[]，默认 []
category: "分类"               # 可选，string | null，默认 ""
lang: ""                       # 可选，string，语言代码，默认 ""
---

正文内容（Markdown）
```

**当前文章使用的分类**: `日记`、`学习笔记`
**当前文章使用的标签**: `日记`、`开始`、`博客搭建`、`Astro`、`学习笔记`

## Markdown 扩展功能

Astro 配置了丰富的 Markdown 插件链：

### Remark 插件（处理 Markdown AST）
- **remark-math** — 数学公式语法支持（`$...$` 行内，`$$...$$` 块级）
- **remark-reading-time** — 自动计算阅读时间
- **remark-excerpt** — 提取文章摘要
- **remark-github-admonitions-to-directives** — GitHub 风格提示框转换
- **remark-directive** — 通用指令语法支持
- **remark-sectionize** — 按标题自动分节

### Rehype 插件（处理 HTML AST）
- **rehype-katex** — 渲染 KaTeX 数学公式
- **rehype-slug** — 为标题添加 id 锚点
- **rehype-components** — 自定义组件渲染：
  - `:::github{repo="owner/repo"}` — GitHub 仓库卡片
  - `:::note` / `:::tip` / `:::important` / `:::caution` / `:::warning` — Admonition 提示框
- **rehype-autolink-headings** — 标题自动添加 `#` 锚点链接

### Expressive Code（代码块）
- 主题：`github-dark`
- 插件：折叠段落、行号、语言标签、自定义复制按钮
- 字体：JetBrains Mono Variable
- `shellsession` 类型代码块不显示行号

## 开发命令

```bash
pnpm install          # 安装依赖（项目强制使用 pnpm，preinstall 脚本会拒绝 npm/yarn）
pnpm dev              # 启动本地开发服务器（支持 HMR 热更新）
pnpm build            # 构建生产版本（astro build && pagefind --site dist）
pnpm preview          # 预览构建产物
pnpm check            # Astro 类型检查
pnpm type-check       # TypeScript 类型检查（--noEmit --isolatedDeclarations）
pnpm new-post         # 运行新建文章脚手架脚本
pnpm format           # Biome 代码格式化（src/ 目录）
pnpm lint             # Biome lint 检查并自动修复（src/ 目录）
```

## 部署流程

### 部署方式：本地构建 + gh-pages 分支推送

由于 GitHub Actions runner 无法分配，部署采用本地构建后推送到 `gh-pages` 分支的方式。

使用 `scripts/deploy.sh` 脚本一键完成：
```bash
bash scripts/deploy.sh
```

**部署脚本做的事**：
1. `pnpm build` — 构建（包含 pagefind 搜索索引生成）
2. 切换到 `gh-pages` 分支
3. 清空 gh-pages 根目录（保留 `.git`）
4. 复制 `dist/*` 到 gh-pages 根目录
5. 添加 `.nojekyll` 文件（**关键！没有它 Jekyll 会忽略 `_astro/` 目录**）
6. 提交并推送到 `gh-pages` 分支
7. 切回 `main` 分支

### 部署前必须本地测试（强制规则）

**任何内容变更（文章、配置、头像等）推送到 GitHub 之前，必须先在本地验证通过。**

完整流程：
1. **本地构建**：`pnpm build` — 确保构建无错误
2. **本地预览**：`pnpm preview` — 启动预览服务器，检查页面显示正常
3. **或 dev 测试**：`pnpm dev` — 启动开发服务器，在浏览器 `http://localhost:4321/mao_mao_chong_diary/` 确认：
   - 页面样式正常（CSS 加载无 404）
   - 控制台无 JS 错误
   - 图片（头像等）正常显示
   - 页面导航正常
4. **确认无误后**再执行 `bash scripts/deploy.sh` 部署

**绝不能跳过本地测试直接推送部署。**

### GitHub Pages 配置

- **Source**: `gh-pages` 分支，根目录 `/`（legacy 模式）
- **`.nojekyll` 文件**：必须存在于 gh-pages 根目录，否则 Jekyll 处理会忽略 `_` 开头的目录（`_astro/`），导致所有 CSS/JS 404
- **已禁用** `.github/workflows/deploy.yml`（runner 无法分配）

## 关键配置

### `astro.config.mjs`
- `site`: `"https://xdh725.github.io"` — 站点根 URL
- `base`: `"/mao_mao_chong_diary/"` — 子路径前缀（**不可更改，否则所有链接 404**）
- `trailingSlash`: `"always"` — URL 末尾始终加 `/`
- 集成：tailwind（启用 nesting）、swup（页面转场）、icon、expressiveCode、svelte、sitemap

### `src/config.ts`
- **站点标题**: `"毛毛虫日记"`
- **副标题**: `"一只毛毛虫的破茧之路 — AI Agent 成长记录"`
- **语言**: `"zh_CN"`
- **主题色 hue**: `120`（绿色），`fixed: false`（访客可切换）
- **作者名**: `"毛毛虫"`
- **个人简介**: `"正在缓慢爬行中，总有一天会破茧成蝶 🐛🦋"`
- **头像**: `assets/images/avatar.png`
- **导航栏**: 首页、归档、关于、GitHub（外部链接）
- **许可证**: CC BY-NC-SA 4.0

## 注意事项

1. **base 路径必须是 `/mao_mao_chong_diary/`** — 这是 GitHub Pages 项目页的子路径，修改会导致所有资源（CSS、JS、图片、页面链接）全部 404
2. **构建包含两步** — `astro build` 之后还有 `pagefind --site dist` 生成搜索索引，不能只跑 `astro build`
3. **pnpm 强制** — `preinstall` 脚本通过 `only-allow pnpm` 阻止使用 npm 或 yarn
4. **CSS 注意事项** — PostCSS 配置了 `postcss-import` 和 `tailwindcss/nesting`，部分样式使用 Stylus（`.styl` 文件），`@apply` 等 Tailwind 指令需要在正确的 PostCSS 流程中才能解析
5. **文章文件名约定** — `YYYY-MM-DD-主题.md`（如 `2026-06-01-hello-world.md`）
6. **图片存放** — 放在 `src/assets/images/` 下，Astro 会在构建时优化处理；`public/` 下的文件直接复制不处理

## 如何新增文章

### 方法一：使用脚手架脚本
```bash
pnpm new-post
```

### 方法二：手动创建
1. 在 `src/content/posts/` 下新建文件，命名格式：`YYYY-MM-DD-主题.md`
2. 填写 frontmatter：
   ```yaml
   ---
   title: "文章标题"
   published: 2026-06-01
   description: "一句话描述"
   tags: ["标签1", "标签2"]
   category: "分类名"
   ---
   ```
3. 编写正文（支持标准 Markdown + 上述扩展语法）
4. 本地预览：`pnpm dev`，浏览器打开 `http://localhost:4321/mao_mao_chong_diary/`
5. 确认无误后提交到 `main` 分支
6. 执行 `bash scripts/deploy.sh` 部署到 GitHub Pages

### Markdown 扩展语法速查
```markdown
## 数学公式
行内：$E = mc^2$
块级：
$$
\int_0^\infty e^{-x^2} dx = \frac{\sqrt{\pi}}{2}
$$

## Admonition 提示框
:::note
这是一个提示
:::

:::warning
这是一个警告
:::

## GitHub 卡片
:::github{repo="saicaca/fuwari"}
:::
```
