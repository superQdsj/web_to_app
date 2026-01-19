# NGA App - Flutter 移动应用

一个基于 Flutter 开发的 NGA 论坛客户端应用，支持通过 WebView 登录获取 Cookie，浏览版面帖子列表和帖子详情。

## 功能特性

- **WebView 登录** - 弹出 WebView 完成 NGA 官方登录流程，自动捕获 Cookie
- **版面浏览** - 输入版面 ID (fid) 加载帖子列表
- **帖子阅读** - 查看帖子正文和所有楼层回复
- **编码兼容** - 自动处理 NGA 的 GBK/GB18030 编码

## 技术架构

```
nga_app/lib/
├── main.dart                 # 应用入口
├── screens/                  # UI 界面
│   ├── forum_screen.dart     # 版面列表页
│   ├── thread_screen.dart    # 帖子详情页
│   └── login_webview_sheet.dart  # WebView 登录弹窗
├── data/
│   └── nga_repository.dart   # 数据仓库层
└── src/
    ├── auth/                 # 认证模块
    │   └── nga_cookie_store.dart  # Cookie 存储
    │   └── nga_user_store.dart    # 用户信息（登录成功后捕获）
    ├── http/                 # HTTP 客户端
    ├── codec/                # 编码解码 (GBK/UTF-8)
    ├── model/                # 数据模型
    └── parser/               # HTML 解析器
```

### 数据流

```
用户操作 → Screen → Repository → HTTP Client → NGA 服务器
                                      ↓
                            Codec (编码转换)
                                      ↓
                            Parser (HTML 解析)
                                      ↓
                            Model (数据模型)
```

## 核心模块

### Cookie 认证流程

应用通过 WebView 实现 NGA 登录，流程如下：

1. 用户点击登录按钮，弹出 `LoginWebViewSheet`
2. WebView 加载 NGA 登录页面
3. 用户完成登录后，WebView 内部会发起 `login_set_cookie_quick` 等请求写入 Cookie（常为 iframe/xhr，主页面不一定跳转）
4. App 监听到该请求后，延迟片刻（等待 Cookie 落盘）并通过 `WebviewCookieManager` 主动读取 Cookie
5. Cookie 存储到 `NgaCookieStore` 供后续请求使用，登录页自动关闭

> 仍保留 **Use Login** 按钮作为兜底：当自动捕获失败时，可手动触发一次 Cookie 读取。

```dart
// 关键代码 - 捕获 Cookie
final cookies = await cookieManager.getCookies(loginUri.toString());
final cookieHeader = cookies
    .map((c) => '${c.name}=${c.value}')
    .join('; ');
NgaCookieStore.setCookie(cookieHeader);
```

### 用户信息捕获

登录页在成功后通常会通过 `console.log("loginSuccess : {...}")` 输出用户信息（如 `uid/username/avatar`）。
App 会在 WebView 内注入一个非常窄的 hook，仅用于提取该 JSON 并保存到 `NgaUserStore`（不打印明文、也不依赖 `document.cookie`）。

### 编码处理

NGA 使用 GBK/GB18030 编码。`codec/` 模块提供了优先尝试 UTF-8、失败后自动转用 GBK 的解码逻辑：

```dart
// DecodeBestEffort: UTF-8 优先，自动降级到 GBK
String decode(List<int> bytes) {
  try {
    return utf8.decode(bytes);
  } catch (_) {
    return gbk.decode(bytes);
  }
}
```

## 安装与运行

### 环境要求

- [fvm](https://fvm.app/) 已安装
- Flutter SDK 3.10.7+

### 安装依赖

```bash
cd nga_app
fvm flutter pub get
```

### 运行应用

```bash
# iOS 模拟器
fvm flutter run -d ios

# Android 模拟器
fvm flutter run -d android
```

### 核心依赖

| 依赖包 | 用途 |
|--------|------|
| `webview_flutter` | WebView 组件 |
| `webview_cookie_manager_plus` | Cookie 管理 |
| `http` | HTTP 请求 |
| `html` | HTML 解析 |
| `charset` | 编码转换 |

## 使用说明

1. **启动应用** - 首次打开显示版面列表页
2. **登录** - 点击右上角登录图标，在 WebView 中完成登录
3. **加载版面** - 输入版面 ID（如 `7` 为水区），点击 **Load**
4. **浏览帖子** - 点击列表项进入帖子详情页
