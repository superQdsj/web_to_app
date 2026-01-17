# NGA Fetcher (Dart 版)

一个用于抓取 [NGA 论坛](https://bbs.nga.cn) 页面并导出结构化 JSON 数据的 Dart 命令行工具。

## 项目简介

NGA Fetcher 旨在为开发者提供一个简单高效的方式来获取 NGA 论坛的主题列表和帖子内容。它支持自动编码转换（GBK/GB18030）、Cookie 认证以及离线解析功能。

## 功能特性

- **导出版面主题列表**: 根据版面 ID (fid) 获取帖子列表。
- **导出帖子详情**: 根据帖子 ID (tid) 获取帖子正文及所有楼层回复。
- **命令行快速回帖**: 支持通过 CLI 直接向指定帖子发送回复。
- **离线 HTML 解析**: 支持对已保存的 HTML 文件进行本地解析。
- **编码自动处理**: 完美解决 NGA 特有的 GBK/GB18030 编码解码问题。

## 项目结构

```text
.
├── nga_fetcher_dart/           # Dart CLI + 解析库
│   ├── bin/
│   │   └── nga_fetcher_dart.dart  # CLI 入口
│   ├── lib/src/
│   │   ├── codec/              # 编码解码 (GBK/GB18030)
│   │   ├── cookie/             # Cookie 解析 (支持 cURL/Header/Raw)
│   │   ├── http/               # HTTP 客户端封装
│   │   ├── model/              # 数据模型 (ThreadItem, ThreadDetail 等)
│   │   ├── parser/             # HTML 解析器 (ForumParser, ThreadParser)
│   │   └── util/               # 工具类
│   └── test/                   # 自动化测试
├── scripts/
│   ├── fetch_dart              # 便捷抓取脚本 (支持 fid 和 tid)
│   └── reply                   # 便捷回帖脚本
├── private/                    # 本地敏感文件目录 (已忽略)
└── out/                        # 数据输出目录 (已忽略)
```

## 系统要求

- [fvm](https://fvm.app/) (Flutter Version Manager)
- Dart SDK 3.10.7+ (通过 fvm 自动配置)

## 安装与配置

### 1. 安装依赖

```bash
cd nga_fetcher_dart && fvm dart pub get
```

### 2. 配置 Cookie

在项目根目录创建 `.env` 文件，并设置 `NGA_COOKIE=...`。

支持以下三种输入格式（工具会自动提取/归一化）：

1. **原始 Cookie 字符串**: `ngaPassportUid=123; ngaPassportToken=abc...`
2. **标准 Header 格式**: `Cookie: ngaPassportUid=123; ...`
3. **cURL 片段**: 直接粘贴包含 `-b '...'` 的 cURL 片段，工具会自动提取 `-b` 参数中的值。

> **注意**: `.env` 属于敏感信息文件，请勿提交到 Git 仓库。

## 使用指南

### 使用便捷脚本 (推荐)

项目提供了 `scripts/` 下的脚本，简化了命令调用：

```bash
# 导出版面 (fid=7 为水区)
./scripts/fetch_dart fid7
./scripts/fetch_dart fid=390

# 导出帖子 (tid=45060283)
./scripts/fetch_dart tid=45060283

# 回复帖子
./scripts/reply --tid 45960168 --fid -444012 --content "回复内容"
```

### 详细 CLI 命令

你也可以直接通过 `fvm dart run` 调用各条子命令：

1. **`export-forum`**: 导出版面主题
   - 参数: `--fid`, `--out-dir`, `--save-html`, `--timeout`
2. **`export-thread`**: 导出帖子详情
   - 参数: `--tid`, `--out-dir`, `--save-html`, `--timeout`
3. **`parse-forum-file`**: 解析本地 HTML 文件
   - 参数: `--in`
4. **`reply`**: 发表回复
   - 参数: `--tid`, `--fid`, `--content`, `--timeout`

## 输出数据格式

抓取结果默认保存在 `out/` 目录下，包含以下 JSON 文件：

### `threads.json` (版面主题列表)
包含字段：`tid`, `url`, `title`, `replies`, `author`, `author_uid`, `post_ts`, `last_replyer`。

### `thread.json` (帖子详细内容)
包含字段：
- `tid`, `url`, `fetched_at`
- `posts`: 楼层数组，每项包含 `floor`, `author`, `author_uid`, `content_text`。

### `meta.json` (抓取元数据)
包含字段：`url`, `status`, `fetched_at`, `thread_count`。

## 开发指南

### 运行测试

```bash
cd nga_fetcher_dart && fvm dart test
```

### 编码说明
工具内部使用 `DecodeBestEffort` 逻辑，优先尝试 UTF-8，失败后自动转向 GBK/GB18030。如果遇到解析乱码，请检查源文件编码或在 `codec/` 模块中调整逻辑。

## 常见问题排查

1. **Cookie 无效**: 表现为只能抓取前几页或无法回复。请尝试重新从浏览器获取最新的 Cookie。
2. **请求超时**: 如果网络环境较差，可通过 `--timeout` 参数增加超时时长（默认 30 秒）。
3. **回复失败**: 请确保 `fid` 正确（某些子版面为负数），且回复内容不违反论坛规范，并注意回复频率限制。

## 许可证

[MIT](LICENSE)
