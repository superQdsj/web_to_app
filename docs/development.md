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
cd nga_app && fvm dart format .
```

### 静态分析

```bash
cd nga_app && fvm flutter analyze
```

## 测试

### 运行 Flutter 应用测试

```bash
cd nga_app && fvm flutter test
```

### 手动测试

1. 运行应用: `cd nga_app && fvm flutter run`
2. 点击登录按钮，通过 WebView 完成登录
   - 正常情况下会自动捕获 Cookie 并自动返回
   - 若未自动返回，可点击 **Use Login** 手动兜底
3. 验证版面列表和帖子详情页面正常加载

## 并行开发 (Git Worktree)

为了支持多个特性并行开发而不干扰当前工作区，项目提供了一个简易脚本 `scripts/gwt.sh`。

### 快捷创建工作树

```bash
# 在项目根目录下运行:
./scripts/gwt.sh <分支名>
```

该脚本会自动：
1. 在平级目录创建 `web_to_app_<分支名>` 文件夹。
2. 检出/创建对应分支。
3. 自动执行 `fvm flutter pub get` 初始化环境。

### 性能与构建建议

- **无需全量构建验证**：由于 Flutter 的 `build/` 文件夹占用极大（数 GB），在并行工作树中**除非必须调试运行，否则不建议执行 `fvm flutter run` 或 `build` 命令**。
- **语法检查优先**：在工作树中修改代码后，只需确保 `fvm flutter analyze` 通过即可。
- **定期清理**：不再使用的并行工作树应通过 `git worktree remove` 删除。

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

**现象**：无法正常浏览需要登录的内容

**解决**：重新通过 WebView 登录获取新的 Cookie

### 编码乱码

**现象**：帖子内容显示乱码

**解决**：检查编码解码逻辑，确保 GBK 降级正常工作
