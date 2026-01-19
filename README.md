# NGA App

一个用于浏览 [NGA 论坛](https://bbs.nga.cn) 的 Flutter 移动应用。

## 功能特性

- **WebView 登录**: 通过内置 WebView 完成论坛登录，自动获取 Cookie
- **版面浏览**: 查看论坛版面帖子列表
- **帖子详情**: 阅读帖子正文及所有楼层回复
- **编码处理**: 自动处理 NGA 特有的 GBK/GB18030 编码

## 项目结构

```text
.
├── nga_app/                    # Flutter 应用主项目
│   ├── lib/
│   │   ├── main.dart           # 应用入口
│   │   ├── screens/            # 页面组件
│   │   ├── widgets/            # 可复用组件
│   │   ├── services/           # 服务层
│   │   └── models/             # 数据模型
│   └── test/                   # 测试文件
├── docs/                       # 项目文档
├── private/                    # 本地敏感文件目录 (已忽略)
└── out/                        # 数据输出目录 (已忽略)
```

## 系统要求

- [fvm](https://fvm.app/) (Flutter Version Manager)
- Flutter SDK (通过 fvm 自动配置)

## 安装与运行

### 1. 安装依赖

```bash
cd nga_app && fvm flutter pub get
```

### 2. 运行应用

```bash
cd nga_app && fvm flutter run
```

应用启动后，进入「个人」页点击登录按钮，通过 WebView 完成登录即可自动获取 Cookie（正常情况下会自动捕获并返回；也可点 **Use Login** 手动兜底）。

## 开发指南

### 代码格式化

```bash
cd nga_app && fvm dart format .
```

### 代码分析

```bash
cd nga_app && fvm flutter analyze
```

### 运行测试

```bash
cd nga_app && fvm flutter test
```

## 许可证

[MIT](LICENSE)
