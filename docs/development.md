# 开发指南

本文档介绍项目的开发环境配置、代码规范和测试流程。

## 开发环境

### 必备工具

- **fvm** - Flutter 版本管理工具，确保团队使用一致的 Flutter 版本
- **Git** - 版本控制

### 初始化环境

```bash
# 安装 fvm (如未安装)
dart pub global activate fvm

# 项目根目录执行，自动下载指定的 Flutter 版本
fvm install

# CLI 工具依赖
cd nga_fetcher_dart && fvm dart pub get

# Flutter 应用依赖
cd nga_app && fvm flutter pub get
```

## 代码规范

### 命名规则

| 类型 | 风格 | 示例 |
|------|------|------|
| 变量/函数 | lowerCamelCase | `fetchThreads`, `currentUrl` |
| 类/类型 | UpperCamelCase | `ThreadItem`, `NgaRepository` |
| 文件名 | snake_case | `forum_screen.dart`, `nga_cookie_store.dart` |

### 格式化代码

```bash
# Dart CLI 项目
cd nga_fetcher_dart && fvm dart format .

# Flutter 应用
cd nga_app && fvm dart format .
```

### 静态分析

```bash
# Dart CLI 项目
cd nga_fetcher_dart && fvm dart analyze

# Flutter 应用
cd nga_app && fvm flutter analyze
```

## 测试

### 运行 CLI 工具测试

```bash
cd nga_fetcher_dart && fvm dart test
```

### 手动测试 CLI

确保 `.env` 文件已配置有效的 `NGA_COOKIE`，然后：

```bash
# 测试版面抓取
./scripts/fetch_dart fid=7

# 测试帖子抓取
./scripts/fetch_dart tid=45060283

# 测试回帖功能
./scripts/reply --tid <tid> --fid <fid> --content "测试回复"
```

### 输出验证

抓取结果保存在 `out/` 目录：

- `meta.json` - 请求元数据
- `threads.json` - 版面帖子列表
- `thread.json` - 单个帖子详情

## 提交规范

使用 [Conventional Commits](https://www.conventionalcommits.org/) 格式：

```
feat: 添加帖子收藏功能
fix: 修复 GBK 编码解析错误
chore: 更新依赖版本
docs: 补充 API 文档
```

## 安全注意事项

- **永远不要**提交包含 Cookie 的 `.env` 文件
- 截图和日志中**务必**脱敏 Cookie 数据
- 敏感文件放在 `private/` 目录（已被 `.gitignore` 忽略）

## 常见问题

### Cookie 无效

**现象**：只能抓取前几页或无法回复

**解决**：重新从浏览器获取最新 Cookie，更新 `.env` 文件

### 请求超时

**现象**：抓取时长时间无响应

**解决**：增加 `--timeout` 参数值（默认 30 秒）

```bash
./scripts/fetch_dart fid=7 --timeout 60
```

### 编码乱码

**现象**：帖子内容显示乱码

**解决**：检查 `codec/` 模块的解码逻辑，确保 GBK 降级正常工作
