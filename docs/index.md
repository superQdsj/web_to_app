# NGA 论坛工具集

一个用于抓取和浏览 [NGA 论坛](https://bbs.nga.cn) 内容的跨平台工具集。

## 项目组成

本仓库包含两个主要子项目：

| 子项目 | 类型 | 说明 |
|--------|------|------|
| [nga_fetcher_dart](./nga_fetcher.md) | Dart CLI | 命令行抓取工具，导出结构化 JSON |
| [nga_app](./nga_app.md) | Flutter App | 移动端论坛浏览应用 |

## 快速开始

### 环境要求

- [fvm](https://fvm.app/) (Flutter Version Manager)
- Dart SDK 3.10.7+（通过 fvm 自动配置）

### 安装依赖

```bash
# CLI 工具
cd nga_fetcher_dart && fvm dart pub get

# Flutter 应用
cd nga_app && fvm flutter pub get
```

### 运行 CLI 抓取工具

1. 配置 Cookie（在项目根目录创建 `.env` 文件）：

```bash
NGA_COOKIE=ngaPassportUid=123; ngaPassportToken=abc...
```

2. 执行抓取命令：

```bash
# 抓取版面帖子列表
./scripts/fetch_dart fid=7

# 抓取单个帖子详情
./scripts/fetch_dart tid=45060283
```

### 运行 Flutter 应用

```bash
cd nga_app && fvm flutter run
```

应用启动后，点击右上角登录按钮，通过 WebView 完成登录即可自动获取 Cookie。

## 文档导航

- [项目总览](./index.md) - 当前页面
- [Flutter 应用文档](./nga_app.md) - 移动应用架构和使用说明
- [开发指南](./development.md) - 代码规范、测试和贡献指南

## 许可证

[MIT](../LICENSE)
