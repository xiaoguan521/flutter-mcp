# Flutter MCP Configurable UI Studio

一个面向“人工可定制 + AI 可通过 MCP 返回交互式 UI + 页面可版本化固化”的基础框架仓库。

当前仓库已经包含：

- 一个自托管、开源、可本地运行的 MCP UI Server
- 一个 Flutter Studio 骨架，使用 `flutter_mcp_ui_runtime` 渲染 JSON DSL
- 一组 Ant Design 风格自定义 Widget 注册示例
- 页面固化保存、版本管理、稳定资源 URI 约定
- Electron 桌面壳示例
- Android 原生 WebView 壳示例
- 三个样例页面：`dashboard`、`form`、`table`

## 目标能力

- 人工定制：
  - 在 Studio 中通过拖拽排序顶层区块
  - 通过右侧 JSON 编辑器直接修改页面 DSL
  - 自动保存本地草稿
- AI / MCP：
  - MCP Server 提供 tool 和 resource
  - AI 可读取稳定页面 URI 或指定版本 URI
  - Flutter 端 runtime 可执行 tool action，并把结果回写到页面
- 固化与版本：
  - 每次保存都会创建新的不可变版本
  - 稳定 URI 永远指向当前 curated 版本
  - 支持历史版本列表查看和加载

## 仓库结构

```text
.
├─ apps
│  ├─ flutter_mcp_studio
│  │  ├─ assets/samples
│  │  └─ lib
│  ├─ electron_shell
│  └─ android_webview_shell
├─ server
│  └─ mcp-ui-server
└─ docs
```

### 关键目录

- `apps/flutter_mcp_studio`
  - Flutter Studio 主应用
  - `assets/samples/*.page.json` 是样例页面与服务端种子页的单一来源
- `server/mcp-ui-server`
  - 默认使用 SQLite 的 MCP 服务
  - 可切换到 Valkey
- `apps/electron_shell`
  - Electron 容器，加载 Flutter Web 构建产物或 dev URL
- `apps/android_webview_shell`
  - Android 原生 WebView 壳，默认加载本机开发地址

## JSON DSL 约定

当前样例采用 `flutter_mcp_ui_runtime` 的 page v1 结构：

```json
{
  "type": "page",
  "title": "Dashboard Demo",
  "state": {
    "initial": {
      "selectedRegion": "north"
    }
  },
  "content": {
    "type": "linear",
    "direction": "vertical",
    "children": []
  }
}
```

### 已注册的 Antd 风格自定义组件

- `antdSection`
  - 白底卡片区块，带标题和副标题
- `antdStat`
  - KPI 统计卡
- `antdTable`
  - DataTable 风格的表格，内置状态标签渲染
- `input`
  - 单行输入别名组件，落到 runtime 的 `textInput`
- `textarea`
  - 多行备注输入别名组件
- `form`
  - 面向表单页的结构化容器
- `searchBar`
  - 面向列表页的搜索与筛选容器

### 动作示例

- State action

```json
{
  "type": "state",
  "action": "increment",
  "binding": "app.kpiDelta",
  "value": 1
}
```

- Tool action

```json
{
  "type": "tool",
  "tool": "persistPage",
  "params": {
    "slug": "dashboard",
    "title": "Dashboard Demo"
  }
}
```

## MCP 约定

### Tools

- `list_pages`
- `load_page`
- `save_page_version`
- `generate_page`
- `generate_page_from_prompt`
- `update_page_by_instruction`
- `validate_page`
- `list_components`
- `resolve_resource_uri`

### Resource URI

- 稳定资源：
  - `mcpui://pages/<slug>/stable`
- 指定版本：
  - `mcpui://pages/<slug>/versions/<version>`

## 存储策略

### 默认

- SQLite-based KV
- 文件位置：
  - `server/mcp-ui-server/data/mcp-ui-pages.sqlite`

### 可选切换到 Valkey

```powershell
$env:PAGE_STORE='valkey'
$env:VALKEY_URL='redis://127.0.0.1:6379'
npm --workspace server/mcp-ui-server run dev
```

## 本地运行

### macOS 快速启动

如果你在 macOS 上本地开发，推荐先安装：

```bash
brew install openjdk@17
brew install --cask flutter
```

仓库已经提供了可直接复用的启动脚本：

```bash
cd /Users/xiaochen/Downloads/flutter-mcp
./scripts/run-server.sh
```

另开一个终端：

```bash
cd /Users/xiaochen/Downloads/flutter-mcp
./scripts/run-studio-web.sh
```

如需仅验证 Web 构建：

```bash
cd /Users/xiaochen/Downloads/flutter-mcp
./scripts/build-studio-web.sh
```

这些脚本会自动尝试注入 Homebrew 安装的 `openjdk@17`，默认把 Flutter Studio 指向 `http://127.0.0.1:8787`。其中 `build-studio-web.sh` 会为当前依赖组合关闭 web icon tree shaking 以避免构建失败。

### 1. 启动 MCP UI Server

```powershell
cd M:\flutter-mcp
npm --workspace server/mcp-ui-server run dev
```

默认地址：

- HTTP API: [http://127.0.0.1:8787](http://127.0.0.1:8787)
- MCP endpoint: [http://127.0.0.1:8787/mcp](http://127.0.0.1:8787/mcp)

### 2. 启动 Flutter Studio

在 Flutter SDK 已安装的前提下：

```powershell
cd M:\flutter-mcp\apps\flutter_mcp_studio
flutter pub get
flutter run -d chrome --dart-define=MCP_UI_SERVER_URL=http://127.0.0.1:8787
```

### 3. 如需补全 Flutter 原生平台目录

这个仓库目前保留了轻量骨架；如果你要直接打 Android/iOS/Desktop 原生包，建议在 Flutter app 目录里执行一次：

```powershell
cd M:\flutter-mcp\apps\flutter_mcp_studio
flutter create . --platforms=web,android,ios,windows,macos,linux
```

这会补齐 Flutter 官方平台壳，而不会覆盖我们现有的 `lib/`、`assets/`、`web/` 主体代码。

### 4. 一键打包 Android APK

Flutter Studio 已提供 Windows PowerShell 一键打包脚本：

- `apps/flutter_mcp_studio/build-android-apk.ps1`

默认配置使用当前机器已经验证通过的环境：

- `JAVA_HOME=C:\Users\xiaochen\.sdkman\candidates\java\17.0.9-tem`
- `FLUTTER_HOME=E:\flutter`
- `PUB_CACHE=E:\pub-cache`
- `ANDROID_HOME=E:\Android\sdk`
- `ANDROID_SDK_ROOT=E:\Android\sdk`
- `GRADLE_USER_HOME=D:\program\Java\repository\gradle-flutter-mcp-studio`
- 构建模式：`debug`
- 目标 ABI：`android-arm64`

默认打包：

```powershell
cd M:\flutter-mcp\apps\flutter_mcp_studio
.\build-android-apk.ps1
```

常用参数：

```powershell
.\build-android-apk.ps1 -BuildMode release
.\build-android-apk.ps1 -TargetPlatform android-x64
.\build-android-apk.ps1 -SkipClean
.\build-android-apk.ps1 -SkipPubGet
```

如果你本机路径不同，可以通过参数覆盖默认路径：

```powershell
cd M:\flutter-mcp\apps\flutter_mcp_studio
.\build-android-apk.ps1 `
  -JavaHome 'C:\path\to\jdk17' `
  -FlutterHome 'E:\flutter' `
  -AndroidSdkRoot 'E:\Android\sdk' `
  -AndroidHome 'E:\Android\sdk' `
  -PubCache 'E:\pub-cache' `
  -GradleUserHome 'D:\program\Java\repository\gradle-flutter-mcp-studio'
```

脚本会自动：

- 切到 `apps/flutter_mcp_studio`
- 清理残留的 Flutter / Gradle / Dart 构建进程
- 执行 `flutter clean`
- 执行 `flutter pub get`
- 执行 `flutter build apk`

默认产物路径：

- `apps/flutter_mcp_studio/build/app/outputs/flutter-apk/app-debug.apk`
- `apps/flutter_mcp_studio/build/app/outputs/apk/debug/app-debug.apk`

## Electron 嵌入

### 方式 A：加载 Flutter dev server

```powershell
$env:FLUTTER_WEB_URL='http://127.0.0.1:8088'
npm --workspace apps/electron_shell run dev
```

### 方式 B：加载 Flutter Web 构建产物

```powershell
cd M:\flutter-mcp\apps\flutter_mcp_studio
flutter build web

cd M:\flutter-mcp
npm --workspace apps/electron_shell run dev
```

Electron 默认会寻找：

- `apps/flutter_mcp_studio/build/web/index.html`

## Android WebView 壳

默认加载地址是：

- `http://10.0.2.2:8088`

如果你的 Flutter Web dev server 不在这个地址，可以通过 Gradle 属性覆盖：

```powershell
cd M:\flutter-mcp\apps\android_webview_shell
gradlew installDebug -PflutterWebUrl=http://10.0.2.2:8088
```

## 已完成的核心链路

- `assets/samples/*.page.json` 作为页面模板与服务端种子页来源
- MCP UI Server 在启动时自动导入样例页
- `POST /api/pages/:slug/save` 会创建新版本并刷新稳定 URI
- Flutter Studio 支持：
  - 页面列表读取
  - 版本列表读取
  - 顶层区块拖拽排序
  - JSON 直接编辑
  - 本地草稿保存/恢复
  - 页面“固化”保存
  - 自定义 Antd 风格组件渲染

## 当前实现上的取舍

- `flutter_mcp` 已接入初始化和 streamable HTTP client 建连逻辑
- 为了提高 Demo 可跑通性，runtime 内部的 tool action 目前优先走 HTTP API bridge
- 人工“拖拽”目前实现为顶层区块重排，不是任意像素级画布编辑
- Android WebView 壳是独立原生示例，不是 Flutter app 的官方 Android 平台目录

## 已验证内容

以下内容已在当前机器验证通过：

- 样例 JSON 可正常解析
- `server/mcp-ui-server` TypeScript 类型检查通过
- `GET /health` 返回正常
- `GET /api/pages` 能读到三张样例页
- `POST /api/pages/dashboard/save` 能创建新版本并写入版本历史
- Flutter Studio `debug` APK 打包成功
- `app-debug.apk` 已可安装到 Android 手机

## 当前机器未验证内容

- Flutter Web / iOS / Desktop 编译
- Electron 运行时实际加载 Flutter Web 页面
- Android WebView 壳编译安装
- Android `release` 正式签名 / 发版流程

原因：

- 当前机器已经验证了 Flutter Android `debug` 打包链路；其余平台和正式发版流程尚未逐项验证

## 后续建议

下一步比较推荐继续做这三件事之一：

1. 补齐 Flutter 平台目录并跑起 Web 预览
2. 把 `persistPage` / `generatePage` 完全切到 `flutter_mcp` 原生 MCP client 调用
3. 扩展更多 Antd 组件映射，例如 `antdForm`, `antdTabs`, `antdModal`, `antdDescriptions`
