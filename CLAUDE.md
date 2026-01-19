# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NGA App 是一个用于浏览 [NGA 论坛](https://bbs.nga.cn) 的 Flutter 移动应用。支持通过 WebView 登录获取 Cookie，浏览版面帖子列表和帖子详情。

## Common Commands

```bash
# 安装依赖
cd nga_app && fvm flutter pub get

# 运行应用
cd nga_app && fvm flutter run

# 运行测试
cd nga_app && fvm flutter test

# 运行代码分析
cd nga_app && fvm flutter analyze

# 格式化代码
cd nga_app && fvm dart format .

# Parallel Development (see docs/development.md)
./scripts/gwt.sh <branch-name>
```

## Parallel Development Policy

- **Worktree builds:** Avoid running `fvm flutter run` in parallel worktrees (build directories are huge).
- **Validation:** Use IDE syntax checking or `fvm flutter analyze` for verification.

## Architecture

```
nga_app/
├── lib/
│   ├── main.dart                # 应用入口
│   ├── screens/                 # 页面
│   │   ├── forum_screen.dart    # 版面帖子列表
│   │   └── thread_screen.dart   # 帖子详情
│   ├── widgets/                 # 可复用组件
│   ├── services/                # 服务层 (HTTP, Cookie 管理)
│   └── models/                  # 数据模型
├── test/                        # 测试文件
└── pubspec.yaml                 # 依赖配置
```

## Key Conventions

- **Naming:** `lowerCamelCase` for vars/functions, `UpperCamelCase` for types, `snake_case` for files
- **Commits:** Conventional Commits (`feat:`, `fix:`, `chore:`)
- **Secrets:** Never commit cookies; use `private/` folder (git-ignored)

## Authentication

应用使用 WebView 实现登录，从 WebView Cookie 中提取：
- `ngaPassportUid` - 用户 ID
- `ngaPassportCid` / Token - 登录令牌

登录后 Cookie 自动保存，用于后续 API 请求认证。
