# Flutter MCP AI App Builder 第一期 Sprint 任务清单

## 1. 文档目标

本文件用于把 [product-roadmap.md](./product-roadmap.md) 与 [technical-task-breakdown.md](./technical-task-breakdown.md) 中的“阶段 1：AI 单页生成 MVP”细化为一份可执行的 Sprint 清单。

默认按 `2 周 Sprint` 组织，若团队节奏不同，可在不改变范围边界的前提下调整排期。

## 2. Sprint 主题

`AI 单页生成 MVP`

一句话目标：

`让用户输入一句页面需求，系统通过 AI + MCP 生成一张可运行页面，并能在 Studio 中预览、微调、校验和固化保存。`

## 3. Sprint 目标

本期 Sprint 只聚焦单页面闭环，不进入多页应用、正式发布和复杂数据接入。

本期结束时，团队应完成以下 5 个结果：

1. AI 可以通过 MCP 生成页面 DSL 草稿
2. 服务端可以校验页面 DSL 并返回结构化错误
3. Studio 中有 Prompt 输入区，可触发生成并加载结果
4. Runtime 能稳定渲染本期生成的页面类型
5. 用户可以把 AI 生成结果继续编辑并保存为新版本

## 4. Sprint 范围

## 4.1 In Scope

- 单页生成
- 单页修改
- 页面 DSL 校验
- 组件目录读取
- Studio 中承接 AI 结果
- 页面预览、修订、固化
- `dashboard / form / table-list` 三类页面的基础生成能力

## 4.2 Out of Scope

- 多页应用生成
- App Schema 落地
- 真正的业务 API 接入
- Android release 发版
- Electron / WebView 完整交付验证
- 复杂权限系统
- 页面 diff / 回滚功能

## 5. Sprint 成功标准

本期 Sprint 完成时，应满足以下验收条件：

1. 输入一个自然语言 Prompt 后，服务端能返回合法页面 DSL
2. 返回结果能在 Studio 中直接加载
3. Runtime 能渲染生成结果，不出现致命错误
4. 当 DSL 不合法时，Studio 能看到明确校验错误
5. 用户能在生成结果上继续手工修改并固化保存
6. 至少验证 3 类页面：
   - dashboard
   - form
   - table/list

### 5.1 当前达成情况（2026-04-03）

- [x] 自然语言 Prompt 已可生成合法页面 DSL，并返回摘要、警告、组件使用清单与假设说明
- [x] Studio 已可直接加载生成结果，并同步到 JSON 编辑区与预览区
- [x] Runtime 已可稳定渲染当前 Sprint 覆盖的 dashboard / form / table-list 页面
- [x] 非法 DSL 已可返回结构化错误，Studio 中可直接查看错误路径与警告
- [x] 用户已可在 AI 生成结果上继续手工编辑、AI 二次修改并固化保存
- [x] 三类页面样例与服务端自动化测试已补齐，作为当前回归基线

## 6. 用户故事

### US-01 生成页面

作为一个产品或运营用户，我希望输入一句自然语言需求，让系统自动生成一张页面草稿，这样我不需要先手写 JSON DSL。

### US-02 预览页面

作为一个设计或前端用户，我希望生成结果能立刻显示在 Studio 预览区，这样我能快速判断结果是否可用。

### US-03 修改页面

作为一个人工编辑者，我希望继续修改 AI 生成的页面 DSL，这样我可以对 AI 结果进行精修。

### US-04 校验页面

作为一个开发者，我希望在页面结构不合法时看到具体错误信息，这样我可以快速修正问题。

### US-05 固化页面

作为一个使用者，我希望把 AI 生成并人工微调后的页面保存为版本资源，这样后续可以继续复用和追踪。

## 7. 本期交付物

本期 Sprint 结束时建议至少交付以下内容：

### 产品与协议

- 页面生成输入输出协议初版
- 页面校验返回结构初版
- 组件目录协议初版

### MCP Server

- `generate_page_from_prompt`
- `update_page_by_instruction`
- `validate_page`
- `list_components`

### Studio

- Prompt 输入区
- “生成页面”按钮
- 生成结果加载到编辑器 / 预览区
- 校验错误展示区

### Runtime

- 支持本期生成页面所需组件
- 生成结果错误兜底

### 文档与验证

- 3 个典型 Prompt 示例
- 3 类页面验收记录

## 8. 任务拆解

## 8.1 Track A：产品协议与 Prompt 设计

### S1-A1 页面生成输入协议

- 优先级：P0
- 目标：定义 `generate_page_from_prompt` 的输入字段
- 输出：
  - `prompt`
  - `pageType`
  - `constraints`
  - `seedTemplate`
  - `locale`
- 完成标准：
  - 文档明确字段说明
  - 后端与 Studio 对字段含义一致

### S1-A2 页面生成输出协议

- 优先级：P0
- 目标：定义页面生成结果的统一返回结构
- 输出：
  - `definition`
  - `summary`
  - `warnings`
  - `usedComponents`
  - `assumptions`
- 完成标准：
  - 生成接口不再只返回裸 DSL
  - Studio 可使用返回摘要和警告信息

### S1-A3 Prompt 模板与示例库

- 优先级：P1
- 目标：建立 3 到 5 组高质量 Prompt 示例
- 建议至少包含：
  - dashboard
  - form
  - table/list
- 当前共享示例：
  - `帮我生成一个销售 dashboard，包含营收、转化率、重点商机和负责人表格`
  - `帮我生成一个客户录入表单，包含客户名称、负责人、优先级、预算和备注`
  - `帮我生成一个订单列表页，包含状态筛选、搜索框、负责人和状态列`
- 完成标准：
  - 团队有统一示例可回归测试

## 8.2 Track B：MCP Server 能力

### S1-B1 实现 `generate_page_from_prompt`

- 优先级：P0
- 目标：新增页面生成工具
- 建议落点：
  - `server/mcp-ui-server/src/tool-service.ts`
  - `server/mcp-ui-server/src/http-server.ts`
  - `server/mcp-ui-server/src/mcp-server.ts`
- 完成标准：
  - HTTP API 可调用
  - MCP tool 可调用
  - 支持至少 3 类页面生成

### S1-B2 实现 `validate_page`

- 优先级：P0
- 目标：新增页面 DSL 校验工具
- 返回格式建议：
  - `valid`
  - `errors`
  - `warnings`
  - `normalizedDefinition`
- 完成标准：
  - 非法 DSL 能返回结构化错误
  - 合法 DSL 可返回标准化结果

### S1-B3 实现 `list_components`

- 优先级：P0
- 目标：让 AI 和 Studio 都能读取当前可用组件目录
- 返回内容建议：
  - 组件名
  - 分类
  - 关键属性
  - 示例片段
  - 是否推荐给 AI 使用
- 完成标准：
  - 组件目录能被 AI 读取
  - 组件目录能被 Studio 展示

### S1-B4 实现 `update_page_by_instruction`

- 优先级：P1
- 目标：支持基于当前页面进行二次修改
- 完成标准：
  - 能接受现有 DSL 和修改指令
  - 返回更新后的 DSL 与变更摘要

### S1-B5 生成接口测试用例

- 优先级：P1
- 目标：覆盖至少 3 类页面生成与校验场景
- 完成标准：
  - 工具调用至少有基础自动化验证

## 8.3 Track C：DSL / Schema

### S1-C1 页面 Schema 初版

- 优先级：P0
- 目标：确定本期支持的页面 DSL 最小结构
- 本期至少覆盖：
  - page
  - linear
  - button
  - select
  - text
  - antdSection
  - antdStat
  - antdTable
- 完成标准：
  - 页面结构有明确 schema 约束
  - 服务端可执行校验

### S1-C2 组件目录元数据

- 优先级：P0
- 目标：给每个组件补元数据供 AI 与 Studio 使用
- 元数据建议包括：
  - `name`
  - `category`
  - `description`
  - `props`
  - `sample`
- 完成标准：
  - 组件不再依赖“靠代码猜能力”

### S1-C3 生成约束规则

- 优先级：P1
- 目标：明确 AI 生成时的限制条件
- 规则示例：
  - 只允许白名单组件
  - 必须生成合法根节点
  - 表格列结构必须完整
  - 动作类型必须属于受支持集合
- 完成标准：
  - 生成结果错误率明显下降

## 8.4 Track D：Studio

### S1-D1 新增 Prompt 面板

- 优先级：P0
- 目标：在 Studio 中新增 AI Prompt 输入区域
- 建议包含：
  - Prompt 输入框
  - 页面类型选择
  - “生成页面”按钮
  - 生成状态提示
- 完成标准：
  - 用户可直接在 Studio 中触发页面生成

### S1-D2 生成结果加载流程

- 优先级：P0
- 目标：把 MCP 返回的 DSL 自动加载到编辑器和预览区
- 完成标准：
  - 用户生成后可立刻看到页面
  - 编辑区同步显示 JSON DSL

### S1-D3 校验错误展示

- 优先级：P0
- 目标：在 Studio 中可视化显示校验结果
- 建议展示：
  - 错误摘要
  - 错误路径
  - 警告信息
  - AI 生成假设说明
- 完成标准：
  - 用户知道为什么渲染失败或校验失败

### S1-D4 再编辑与固化串联

- 优先级：P0
- 目标：保证 AI 生成结果仍可继续使用现有编辑与固化流程
- 完成标准：
  - AI 生成页面可以继续拖拽、改 JSON、保存版本

### S1-D5 生成记录保留

- 优先级：P1
- 目标：保留本次生成的 Prompt 和摘要信息
- 完成标准：
  - 至少在当前会话中可见

## 8.5 Track E：Runtime

### S1-E1 生成页面兼容性补齐

- 优先级：P0
- 目标：确保本期 AI 生成页能被 runtime 稳定渲染
- 重点检查：
  - 布局容器
  - 基本文本
  - 按钮动作
  - 表格结构
  - 表单基础组件
- 完成标准：
  - 3 类页面都能稳定显示

### S1-E2 运行时错误兜底

- 优先级：P0
- 目标：当页面不合法时，不让预览区完全崩溃
- 完成标准：
  - 出错时有明确错误展示
  - 不影响 Studio 继续编辑

### S1-E3 组件补齐

- 优先级：P1
- 本期建议优先补：
  - `input`
  - `textarea`
  - `form`
  - `searchBar`
- 完成标准：
  - 能支撑 form / list 类型页面生成

## 8.6 Track F：测试与验收

### S1-F1 三类页面验收样例

- 优先级：P0
- 目标：整理 3 组固定验收用例
- 建议场景：
  - 销售 dashboard
  - 客户录入 form
  - 订单 table/list
- 当前验收样例：
  - 销售 dashboard
    Prompt：`帮我生成一个销售 dashboard，包含营收、转化率、重点商机和负责人表格`
    期望结构：`page -> linear -> antdSection + antdStat + antdTable + button/select`
    验收结论：通过，生成结果可直接预览并通过服务端校验
  - 客户录入 form
    Prompt：`帮我生成一个客户录入表单，包含客户名称、负责人、预算、优先级和备注`
    期望结构：`page -> linear -> antdSection + textInput + select + numberField + button`
    验收结论：通过，表单类页面可生成、可预览、可继续编辑
  - 订单 table/list
    Prompt：`帮我生成一个订单列表页，展示订单号、负责人、状态，并保留操作按钮`
    期望结构：`page -> linear -> antdSection + antdTable + button`
    验收结论：通过，列表类页面可生成并支持后续 AI 二次修改
- 完成标准：
  - 每组场景都有 Prompt、期望结构、验收结论

### S1-F2 服务端校验测试

- 优先级：P0
- 目标：为 `generate_page_from_prompt` / `validate_page` 补测试
- 当前覆盖：
  - `generate_page_from_prompt` 三类页面生成测试
  - `validate_page` 非线性根节点归一化回归测试
  - `update_page_by_instruction` 标题修改与区块追加测试
- 完成标准：
  - 核心链路至少有最小自动化覆盖

### S1-F3 Studio 冒烟验证

- 优先级：P1
- 目标：验证“输入 Prompt -> 生成 -> 预览 -> 固化”主链路
- 完成标准：
  - 至少 1 次完整手工冒烟通过

## 8.7 Track G：文档与团队协作

### S1-G1 Sprint 演示脚本

- 优先级：P1
- 目标：整理 Sprint Review 演示脚本
- 演示路径建议：
  - 输入 Prompt
  - 生成页面
  - 查看校验结果
  - 人工微调
  - 固化保存

### S1-G2 Prompt 编写规范

- 优先级：P1
- 目标：沉淀团队内部 Prompt 书写约定
- 完成标准：
  - 后续测试与产品沟通口径更稳定

## 9. Sprint 任务优先级清单

## 9.1 P0 必须完成

- [x] S1-A1 页面生成输入协议
- [x] S1-A2 页面生成输出协议
- [x] S1-B1 `generate_page_from_prompt`
- [x] S1-B2 `validate_page`
- [x] S1-B3 `list_components`
- [x] S1-C1 页面 Schema 初版
- [x] S1-C2 组件目录元数据
- [x] S1-D1 Prompt 面板
- [x] S1-D2 生成结果加载流程
- [x] S1-D3 校验错误展示
- [x] S1-D4 再编辑与固化串联
- [x] S1-E1 生成页面兼容性补齐
- [x] S1-E2 运行时错误兜底
- [x] S1-F1 三类页面验收样例
- [x] S1-F2 服务端校验测试

## 9.2 P1 建议完成

- [x] S1-A3 Prompt 模板与示例库
- [x] S1-B4 `update_page_by_instruction`
- [x] S1-B5 生成接口测试用例
- [x] S1-C3 生成约束规则
- [x] S1-D5 生成记录保留
- [x] S1-E3 组件补齐
- [ ] S1-F3 Studio 冒烟验证
- [ ] S1-G1 Sprint 演示脚本
- [ ] S1-G2 Prompt 编写规范

## 10. 建议执行顺序

建议按以下顺序推进，减少来回返工：

1. 先定义生成协议与 Page Schema
2. 同步补组件目录元数据
3. 实现服务端 `generate_page_from_prompt` 和 `validate_page`
4. Studio 接入 Prompt 面板与结果加载
5. Runtime 做兼容性补齐和错误兜底
6. 最后做三类页面验收与补测试

## 11. 建议排期

以 10 个工作日为例：

### 第 1-2 天

- 完成协议设计
- 完成 Page Schema 初版
- 完成组件目录元数据初版

### 第 3-5 天

- 实现 `generate_page_from_prompt`
- 实现 `validate_page`
- 实现 `list_components`

### 第 6-7 天

- Studio 接入 Prompt 面板
- Studio 接入生成结果加载和错误展示

### 第 8-9 天

- Runtime 兼容性补齐
- 三类页面联调

### 第 10 天

- 冒烟测试
- 补文档
- Sprint Review 演示准备

## 12. 风险与应对

### 风险 1：AI 生成结果不稳定

- 应对：
  - 先加白名单组件
  - 强制经过 `validate_page`
  - 保留 `warnings` 与 `assumptions`

### 风险 2：Runtime 与生成结果不匹配

- 应对：
  - Sprint 1 只支持有限组件集合
  - 先围绕 3 类页面做能力封闭

### 风险 3：Studio 接入后体验断裂

- 应对：
  - 生成结果必须复用现有编辑和固化流程
  - 不单独做一套旁路编辑体验

### 风险 4：任务面太大

- 应对：
  - 本期只做单页
  - App Schema、数据源、构建 MCP 化全部延后

## 13. Definition of Done

一个任务只有满足以下条件才算完成：

1. 功能代码已落地
2. 至少完成一次本地验证
3. 相关文档已更新
4. 对外输入输出协议已明确
5. 不阻断“Prompt -> 生成 -> 预览 -> 固化”主链路

## 14. Sprint 结束时应看到的效果

Sprint 1 结束时，团队应该已经具备下面这个演示闭环：

1. 在 Studio 输入一句页面需求
2. AI 通过 MCP 生成页面 DSL
3. Studio 加载结果并展示预览
4. 用户查看校验结果和警告
5. 用户手工微调页面
6. 用户固化保存页面版本

如果这个闭环可稳定完成，那么第一期 Sprint 就达标了。
