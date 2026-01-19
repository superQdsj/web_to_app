# NGA App 文档

一个用于浏览 [NGA 论坛](https://bbs.nga.cn) 的 Flutter 移动应用。

## 项目组成

| 子项目 | 类型 | 说明 |
|--------|------|------|
| [nga_app](./nga_app.md) | Flutter App | 移动端论坛浏览应用 |

## 快速开始

### 环境要求

- [fvm](https://fvm.app/) (Flutter Version Manager)
- Flutter SDK（通过 fvm 自动配置）

### 安装依赖

```bash
cd nga_app && fvm flutter pub get
```

### 运行 Flutter 应用

```bash
cd nga_app && fvm flutter run
```

应用启动后，进入「个人」页点击登录按钮，通过 WebView 完成登录即可自动获取 Cookie（自动捕获失败时可点 **Use Login** 手动兜底）。

## 文档导航

- [项目总览](./index.md) - 当前页面
- [Flutter 应用文档](./nga_app.md) - 移动应用架构和使用说明
- [开发指南](./development.md) - 代码规范、测试和贡献指南

## 许可证

[MIT](../LICENSE)
