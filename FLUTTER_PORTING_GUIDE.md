# Flutter 移植指导：NGA 线程 HTML 解析（DOM + 引用回填）

本文指导你把当前仓库里 `dom_mvp/bin/full_parse.dart` 的 DOM 解析思路，移植到 Flutter App 中，目标是：

- 通过 API 拿到每页 `raw html`（例如 `page=1`、`page=2`…），每页解析得到 `ThreadData -> List<ThreadPost>`。
- 在列表中展示每层楼正文，并支持“引用楼层”显示被引用的内容（同页可回填，跨页依赖缓存）。
- 解析不阻塞 UI（在 isolate 执行）。

## 审核结论（建议按此补齐）

文档整体与 `dom_mvp/bin/full_parse.dart` 的实现一致，可直接落地；但为了让 Flutter 侧“更不踩坑”，建议补齐这些关键点：

- **内容提取要严格对齐脚本**：不要直接用 `Element.text`；需要 `<br>` -> `\n`、去标签、解实体、再做 UBB/quote 清洗。
- **isolate 返回值要可传输**：优先在 isolate 内产出 `Map<String, Object?>` 或 JSON `String`，主 isolate 再 `fromJson`。
- **分页追加要去重**：网络重试/刷新/并发加载可能导致重复楼层；以 `pid` 去重最稳妥。
- **缓存要限定作用域与体积**：建议按 `tid` 维度维护 `postByPidCacheByTid`，并设置上限（避免超长帖 OOM）。

---

## 1. 推荐的数据结构（Flutter 展示友好）

建议沿用你现有 JSON 字段语义，但在模型中补齐“用于关联”的关键字段：

- `ThreadPost.pid`：当前楼的 pid（从 `pid{pid}Anchor` 提取）。
- `PostQuote.quotedPid`：当楼层文本是 `Reply to [pid=...]` 时，解析出被引用 pid。
- `PostQuote.content`：引用内容；同页可回填，跨页可用缓存补全。

建议的 Dart 模型（字段名示例）：

- `ThreadData { String topicTitle; List<ThreadPost> posts; }`
- `ThreadPost { int pid; int floor; bool isTopicPost; PostAuthor author; String content; String replyTime; int likeCount; String deviceType; PostQuote? quote; String? editedTime; }`
- `PostQuote { int? quotedPid; String quotedUser; String quotedTime; String content; }`

> UI 列表的主数据依然是 `List<ThreadPost>`；`pid`/`quotedPid` 用来做引用关联与缓存检索。

---

## 2. 依赖与工程落点

### 2.1 依赖

你的 Flutter 工程已经有 `html: ^0.15.6` 时，无需额外依赖；否则在 `pubspec.yaml` 增加：

```yaml
dependencies:
  html: ^0.15.6
```

解析入口使用：

```dart
import 'package:html/parser.dart' as hp;
```

### 2.2 文件组织（建议）

```text
lib/
  data/
    models/
      thread_data.dart
      thread_post.dart
    parsers/
      nga_thread_dom_parser.dart
    repositories/
      nga_thread_repository.dart
  domain/ (可选)
  presentation/
```

---

## 3. 解析流程（每页一次）

把 `raw html` 解析成 `ThreadData` 的推荐流程（和 `dom_mvp/bin/full_parse.dart` 一致）：

1. `doc = hp.parse(rawHtml)`
2. `topicTitle = doc.getElementById('currentTopicName')?.text.trim()`
3. 从 JS 里提取 `commonui.userInfo.setAll(...)` 得到 `uid -> author` 的信息（可选；失败也可退化）
4. 提取 `commonui.postArg.proc(...)`（用于 `likeCount`、`device` 等；可选；失败也可退化为 0/''）
5. 遍历楼层节点（`tr[id^="post1strow"]`）构建 `ThreadPost`：
   - `floor`：来自 `tr.id = post1strow{floor}`
   - `pid`：来自同一个 `tr` 下的 `a[id^="pid"][id$="Anchor"]`
   - `content`：来自 `#postcontent{floor}` 的 `innerHtml -> text`（需要保留换行，做 UBB/quote 清洗，见下方“内容提取”）
   - `replyTime`：来自 `#postdate{floor}`
   - `author.uid`：从 `#postauthor{floor}` 的 `href` 里解析 `uid=...`，再去 userInfo 映射里补充昵称/等级/注册时间
6. **同页引用回填**：
   - 建 `Map<int, ThreadPost>`：`pid -> post`
   - 对每个 `post.quote?.quotedPid != null && quote.content.isEmpty`，用 `pidMap[quotedPid]` 回填 `quote.content`
7. 结果按 `floor` 排序

> 关键点：引用的“Reply to pid”头本身不带正文，必须用 `quotedPid` 去索引对应楼层内容；同页索引即可回填，跨页需要缓存。

### 3.1 内容提取（建议与脚本一致）

NGA 正文节点里混有 HTML 标签与实体，直接用 `Element.text` 往往会丢换行/空行，导致引用回填与正文展示不一致。建议按脚本的顺序处理：

1. 取 `innerHtml`
2. `<br>`/`<br/>`/`<br />` 替换成 `\n`
3. 去除剩余 HTML 标签（`<...>`）
4. 解 HTML 实体（`&amp;`、`&nbsp;`、`&#39;` 等）
5. 合并多余空行（例如连续空行折叠）
6. 再做 UBB/quote 清洗（例如 `[quote]...[/quote]`、`Reply to [pid=...]` 头、`[img]`/`[url]` 替换策略）

如果你希望 Flutter 侧输出与 `outputs/thread_dom_full.json` 的 `content` 逐字一致，建议把脚本里的 `_innerHtmlToText`、`_cleanHtmlContent`、`_cleanContent` 这三段逻辑原样迁移。

---

## 4. Flutter 侧：分页加载 + 引用缓存策略

### 4.1 每页加载

- 首次进入帖子：请求 `page=1` 的 HTML -> 解析 -> `List<ThreadPost>`
- 上拉加载：请求下一页 HTML -> 解析 -> append 到列表

### 4.2 缓存（跨页引用）

建议在内存里维护一个仓库级别缓存（推荐按 `tid` 分桶；避免多线程/多标签页互相污染）：

- `Map<int, Map<int, ThreadPost>> postByPidCacheByTid`（`tid -> (pid -> post)`）

每次解析一页后：

- 把这一页的所有 `ThreadPost` 写入缓存（必要时做去重/覆盖）
- 对列表里已有的 `post.quote.quotedPid`，若 `quote.content` 为空而缓存里存在被引用 pid，则补全（可在 UI 层或 repository 层做一次“补齐”）

UI 渲染引用时的逻辑：

- 若 `post.quote.content` 非空：直接展示
- 否则若当前 `tid` 的缓存里存在 `quotedPid`：展示缓存里的 `content`
- 否则：展示占位（例如“引用内容未加载”）或提供点击跳转/加载

### 4.3 去重与内存上限（强烈建议）

- **去重**：分页追加时用 `pid` 去重最稳妥（同一楼在重试/刷新/并发加载下可能重复出现）。
- **上限**：超长帖会让缓存无界增长；建议做 LRU/按页裁剪/仅缓存被引用楼层（例如只缓存 `pid -> content`）。

---

## 5. 性能：务必放到 isolate（避免掉帧）

DOM 解析 + 文本清洗会占用 CPU，建议在 Flutter 里用 isolate：

### 5.1 `compute`（简单）

```dart
import 'package:flutter/foundation.dart';

Future<Map<String, dynamic>> parseThreadMapInIsolate(String rawHtml) {
  return compute(_parseEntry, rawHtml);
}

Map<String, dynamic> _parseEntry(String rawHtml) {
  final parser = NgaThreadDomParser();
  return parser.parse(rawHtml).toJson();
}
```

注意：

- `_parseEntry` 必须是顶层函数或静态函数。
- 自定义模型通常**不可跨 isolate 传输**；稳妥做法是在 isolate 内输出 `Map<String, dynamic>` 或 JSON `String`，主 isolate 再 `ThreadData.fromJson(...)`。

### 5.2 `Isolate.run`（更灵活）

与 5.1 二选一；保留其中一种实现即可（函数名可保持一致）。

```dart
import 'dart:isolate';

Future<Map<String, dynamic>> parseThreadMapInIsolate(String rawHtml) {
  return Isolate.run(() => NgaThreadDomParser().parse(rawHtml).toJson());
}
```

---

## 6. 最小 MVP 接入步骤（建议顺序）

1. 在 Flutter 工程创建模型：`ThreadData` / `ThreadPost` / `PostQuote` / `PostAuthor`（包含 `pid`、`quotedPid`）
2. 把 `dom_mvp/bin/full_parse.dart` 中的解析类内容迁移为 `lib/data/parsers/nga_thread_dom_parser.dart`
3. 在 repository 里：
   - 请求 API 得到 `rawHtml`
   - `final map = await parseThreadMapInIsolate(rawHtml)`（主 isolate 再 `ThreadData.fromJson(map)`）
   - 更新列表与 `postByPidCacheByTid`
4. 在 UI 里：
   - `ListView.builder` 渲染 `ThreadPost.content`
   - 如果有 `quote`，渲染一个“引用卡片”（quote.content 或缓存补齐）

---

## 7. 验证与排错建议

### 7.1 对比工具输出

当前仓库已经能把样例 HTML 输出完整 JSON：

- 解析脚本：`dom_mvp/bin/full_parse.dart`
- 输出文件：`outputs/thread_dom_full.json`

你可以用这个 JSON 作为 Flutter 侧的“金数据”，对照 UI 展示是否符合预期（尤其是引用回填）。

### 7.2 常见坑

- **编码**：服务端可能不是 UTF-8；如遇乱码，优先在 HTTP 响应头/HTML meta 决定解码方式。
- **跨页引用**：`quotedPid` 不在当前页时，quote.content 合理为空；用缓存补齐或展示占位。
- **清洗规则**：UBB/表情等替换要和 UI 的展示策略一致（例如 `[图片]`、`[链接]`）。
- **删帖/缺楼**：某些楼层可能缺失或被隐藏；不要依赖 `floor` 连续，索引用 `pid` 更可靠。
- **重复数据**：分页请求重试或并发加载会导致重复楼；合并列表时做 `pid` 去重。

---

## 8. 下一步（如果你希望我继续帮你做）

如果你贴一下 Flutter 项目的目录结构（或给我一个 `lib/` 片段），我可以：

- 直接把 `NgaThreadDomParser` 迁移成 Flutter 里的 `lib/data/parsers/nga_thread_dom_parser.dart`
- 同时提供一个 `NgaThreadRepository` + isolate 调用封装
- 给一个最简的 `ThreadPage` 列表 UI（含引用卡片）
