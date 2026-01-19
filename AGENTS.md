# Repository Guidelines

## Project Structure & Module Organization

- `nga_app/`: Flutter 移动端论坛浏览应用。
- `.env`: 本地 Cookie 输入（敏感信息，已被 git 忽略；请勿提交 secrets）。
- `out/`: 生成的产物目录（已被 git 忽略）。

## Build, Test, and Development Commands

- 确保 `fvm` 已安装并且 Flutter/Dart SDK 已配置。
- 安装依赖: `cd nga_app && fvm flutter pub get`
- 运行应用: `cd nga_app && fvm flutter run`
- 运行测试: `cd nga_app && fvm flutter test`
- 代码分析: `cd nga_app && fvm flutter analyze`

## Coding Style & Naming Conventions

- Dart: 遵循现有风格，保持格式一致（需要时使用 `fvm dart format .`）。
- 命名规范 (Dart): 变量/函数使用 `lowerCamelCase`，类型使用 `UpperCamelCase`，文件名使用 `snake_case`。
- 保持修改专注：优先编写小型纯函数，修改用户可见行为时更新相关帮助文本。

## Testing Guidelines

- Flutter 测试位于 `nga_app/test/`；运行命令: `cd nga_app && fvm flutter test`。
- 至少在 PR 描述中包含可复现的手动测试步骤（具体命令 + 预期结果）。

## Commit & Pull Request Guidelines

- 使用 Conventional Commits 格式（如 `feat: ...`、`fix: ...`、`chore: ...`）。
- PR 应包含：目的/摘要、运行方式（命令）、以及任何解析/兼容性注意事项。
- 永远不要提交 secrets：Cookie headers 或复制的 cURL 片段；在日志和截图中隐藏 `Cookie` 值。
