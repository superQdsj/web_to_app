# NGA Fetcher (Dart)

一个用于抓取 NGA 论坛页面并导出结构化 JSON 的命令行工具（当前仅保留 Dart 实现）。

## 依赖

- 安装并配置 `fvm`
- Dart SDK (由 `fvm` 管理)

## 配置 Cookie（必需）

把你的 Cookie 放到仓库根目录的 `nga_cookie.txt`：

- 支持直接放 cookie 值：`a=1; b=2`
- 支持 `Cookie: a=1; b=2`
- 支持粘贴完整 cURL 片段（包含 `-b '...'`）

注意：`nga_cookie.txt` 是敏感信息文件，已在 `.gitignore` 中忽略，不要提交。

## 安装依赖

```bash
cd nga_fetcher_dart
fvm dart pub get
```

## 使用

推荐用根目录脚本：

### 导出版面主题列表（fid）

```bash
./fetch_dart fid7
./fetch_dart fid=7
```

输出示例：
- `out/nga_fid7_dart/meta.json`
- `out/nga_fid7_dart/threads.json`
- `out/nga_fid7_dart/forum.html`（默认保存）

### 导出单个帖子（tid）

```bash
./fetch_dart tid=45060283
./fetch_dart 45060283
```

输出示例：
- `out/thread_45060283_dart/thread.json`
- `out/thread_45060283_dart/thread.html`（默认保存）

## 运行测试

```bash
cd nga_fetcher_dart
fvm dart test
```
