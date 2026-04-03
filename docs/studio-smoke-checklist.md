# Studio 冒烟检查表

## 1. 目标

用于验证 Sprint 1 的主链路是否稳定：

`输入 Prompt -> 生成页面 -> 查看预览与校验 -> AI 二次修改 -> 固化保存`

## 2. 环境准备

- 启动服务端：
  - `npm --workspace server/mcp-ui-server run dev`
- 启动 Studio：
  - `cd apps/flutter_mcp_studio`
  - `flutter run -d chrome --dart-define=MCP_UI_SERVER_URL=http://127.0.0.1:8787`

## 3. 手工检查步骤

1. 打开 Studio，确认顶部显示 `MCP 已连接` 或可手动连接成功。
2. 在 AI Prompt 面板输入：
   - `帮我生成一个客户列表页，包含搜索、状态筛选和操作按钮`
3. 点击 `AI 生成页面`，确认：
   - 预览区出现页面
   - JSON 编辑区同步刷新
   - 校验区没有致命错误
4. 在 AI 二次修改输入框输入：
   - `把标题改成客户运营列表，并增加搜索筛选和操作按钮`
5. 点击 `应用 AI 修改`，确认：
   - 页面标题更新
   - 预览区出现搜索/筛选条
   - 变更摘要面板显示已应用修改
6. 点击 `固化当前页`，确认：
   - 状态栏显示固化成功
   - 左侧出现新版本号
   - 页面可重新加载

## 4. 通过标准

- 生成后能看到可渲染页面
- 校验结果清晰可见
- AI 二次修改能改变当前页面 DSL
- 固化后可看到新版本并重新加载
- 主链路无阻断性错误

## 5. 当前记录

- 2026-04-03：
  - 已完成自动化辅助验证：
    - `server/mcp-ui-server` 构建通过
    - `server/mcp-ui-server` 测试通过
    - `flutter analyze` 通过
    - `flutter test` 通过
    - `studio_controller_smoke_test.dart` 覆盖主链路控制层
  - 手工 UI 点击验证：待执行

## 6. 当前阻塞

- 当前仓库已具备冒烟脚本和自动化辅助验证，但尚未形成一次真实的人工 UI 点击记录。
