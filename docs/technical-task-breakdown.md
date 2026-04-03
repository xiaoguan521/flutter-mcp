# Flutter MCP AI App Builder 技术任务拆解

## 1. 文档目标

本文件用于把“通过 AI 调用 MCP 实现页面、App 或应用构建”的目标拆成可执行的技术工作流。

拆解方式按 5 条主线展开：

- MCP Tools / Resources
- DSL / Schema
- Studio
- Runtime
- Build / Delivery

每条主线都按照：

- 目标
- 任务项
- 完成标准
- 依赖关系

来定义，便于分阶段推进。

## 2. 总体技术架构目标

最终技术架构建议如下：

1. `MCP Server`
   - 暴露工具和资源
   - 管理页面、应用、版本、构建任务

2. `Schema Layer`
   - 页面 DSL
   - 应用 Schema
   - 数据源与动作 Schema

3. `Studio`
   - 页面 / 应用可视化编辑
   - AI 生成结果承接
   - 人工修订与固化

4. `Runtime`
   - 渲染页面和应用
   - 处理状态、动作、数据绑定

5. `Build Layer`
   - 导出 Web / Android / Desktop
   - 把构建结果返回给 AI / Studio

## 3. 主线一：MCP Tools / Resources

## 3.1 目标

让 AI 能通过 MCP 完成“读、改、校验、保存、装配、构建”全链路操作。

## 3.2 当前已有基础

当前已存在的服务能力包括：

- 页面列表
- 页面读取
- 页面版本保存
- 模板页生成
- 资源 URI 解析

下一阶段需要把它从“页面演示工具”升级为“应用构建工具”。

## 3.3 第一批需要新增的 Tool

### A. 页面生成与修改

- `generate_page_from_prompt`
  - 输入：prompt、页面类型、约束条件
  - 输出：页面 DSL 草稿

- `update_page_by_instruction`
  - 输入：现有页面 DSL、修改指令
  - 输出：更新后的页面 DSL

- `validate_page`
  - 输入：页面 DSL
  - 输出：校验结果、错误位置、修复建议

- `explain_page`
  - 输入：页面 DSL
  - 输出：结构说明、组件说明、动作说明

- `list_components`
  - 输入：无或分类条件
  - 输出：当前允许使用的组件列表与属性协议

### B. 应用生成与装配

- `create_app`
  - 输入：应用名、业务目标、初始页面集合
  - 输出：应用 manifest

- `load_app`
  - 输入：appId 或 slug
  - 输出：完整应用结构

- `save_app_version`
  - 输入：应用结构
  - 输出：新应用版本

- `list_app_pages`
  - 输入：appId
  - 输出：应用内页面列表

- `add_page_to_app`
  - 输入：appId、pageId、路由信息
  - 输出：更新后的应用结构

- `update_app_navigation`
  - 输入：导航定义
  - 输出：更新后的导航结构

### C. 数据与动作

- `create_data_source`
  - 输入：接口定义或 mock 配置
  - 输出：数据源配置

- `bind_component_data`
  - 输入：组件路径、数据源配置
  - 输出：绑定结果

- `bind_form_submit`
  - 输入：表单定义、提交动作
  - 输出：表单动作配置

- `test_action`
  - 输入：动作定义
  - 输出：执行结果与调试信息

### D. 构建与导出

- `build_web`
  - 输入：appId / pageId / version
  - 输出：构建结果与产物路径

- `build_android_debug`
  - 输入：应用版本、构建参数
  - 输出：APK 路径与构建日志摘要

- `build_android_release`
  - 输入：签名配置、应用版本
  - 输出：release 包结果

- `export_app_bundle`
  - 输入：应用版本
  - 输出：导出包路径与元信息

## 3.4 需要新增的 Resource

- `mcpui://apps/{slug}/stable`
- `mcpui://apps/{slug}/versions/{version}`
- `mcpui://components/catalog/stable`
- `mcpui://schemas/page/stable`
- `mcpui://schemas/app/stable`

这些资源的价值：

- 让 AI 能读取应用结构而不是盲生成
- 让 AI 读取组件协议和 Schema 约束
- 降低生成结果漂移

## 3.5 完成标准

- AI 能读取组件能力、页面资源、应用资源
- AI 能生成和修改页面
- AI 能组装多页应用
- AI 能触发构建任务

## 4. 主线二：DSL / Schema

## 4.1 目标

建立一套稳定、可校验、可扩展的结构化协议，承接 AI 生成结果。

## 4.2 页面 DSL 任务

### 当前已具备的能力

- page
- linear layout
- button
- select
- 自定义 `antdSection`
- 自定义 `antdStat`
- 自定义 `antdTable`

### 下一步需要补齐的组件协议

- `form`
- `input`
- `textarea`
- `numberInput`
- `datePicker`
- `switch`
- `radioGroup`
- `checkboxGroup`
- `tabs`
- `modal`
- `drawer`
- `descriptions`
- `chart`
- `pagination`
- `searchBar`
- `filterPanel`
- `sidebarNav`
- `topNav`

### 页面 DSL 必须补的结构能力

- 组件唯一标识
- 页面级 metadata
- 页面级 permissions
- 动作定义标准化
- 数据绑定定义标准化
- 条件显示 / 条件禁用
- 校验规则
- 错误态和空态

## 4.3 应用 Schema 任务

这是当前最关键的新增工作。

### 建议新增应用模型

- `appId`
- `slug`
- `name`
- `description`
- `theme`
- `layoutShell`
- `routes`
- `navigation`
- `pages`
- `homePage`
- `auth`
- `globalState`
- `dataSources`
- `buildProfiles`

### 建议新增页面与应用关系

- 页面引用方式
  - 内嵌
  - 资源引用
- 路由绑定方式
- 导航节点绑定方式
- 页面权限绑定方式

## 4.4 Schema 校验任务

- 定义 Page Schema
- 定义 App Schema
- 定义 Action Schema
- 定义 DataSource Schema
- 定义 BuildTask Schema

### 校验要求

- 可在服务端校验
- 可在 Studio 实时校验
- 能返回结构化错误信息
- 能给 AI 提供修复建议

## 4.5 完成标准

- AI 生成的页面和应用都有明确 schema
- schema 能独立校验
- runtime 不再依赖“尽量容错”的方式运行

## 5. 主线三：Studio

## 5.1 目标

让 Studio 成为 AI 生成与人工修订的主承接界面。

## 5.2 页面级任务

- 页面列表与版本列表继续保留
- 页面 DSL 编辑器增强
- 结构树视图
- 组件属性面板
- schema 校验错误面板
- 页面 diff 视图
- 回滚操作

## 5.3 应用级任务

- 新增应用列表
- 新增应用详情页
- 新增页面编排面板
- 新增导航编辑器
- 新增主题配置面板
- 新增路由配置面板

## 5.4 AI 协同任务

- 新增 Prompt 输入区
- 支持“生成页面”
- 支持“修改当前页面”
- 支持“生成应用骨架”
- 支持“根据指令追加页面”
- 支持显示 AI 变更摘要
- 支持 AI 结果与当前版本 diff

## 5.5 调试任务

- 动作调试面板
- 数据绑定调试面板
- schema 校验结果面板
- MCP 调用日志面板
- 构建任务状态面板

## 5.6 完成标准

- 用户可以在 Studio 内完成主要操作闭环
- 不需要频繁跳出 Studio 做人工修订
- AI 生成结果可视、可比、可改、可保存

## 6. 主线四：Runtime

## 6.1 目标

让 runtime 稳定承接页面和应用的渲染与动作执行。

## 6.2 页面渲染任务

- 扩展更多组件工厂
- 支持复杂布局
- 支持嵌套容器
- 支持条件渲染
- 支持统一的事件模型

## 6.3 应用运行任务

- 应用级路由容器
- 导航壳
- 页面切换
- 应用主题注入
- 全局状态管理

## 6.4 数据与动作任务

- 标准化 state action
- 标准化 tool action
- 标准化 resource action
- 新增 data action
- 新增 navigation action
- 新增 submit action

## 6.5 可靠性任务

- 初始化失败兜底
- 组件渲染失败隔离
- 动作执行失败反馈
- 非法 schema 的错误展示
- 性能监控与慢操作提示

## 6.6 完成标准

- 生成页面可稳定渲染
- 多页应用可稳定运行
- 数据与动作可以调试和回放

## 7. 主线五：Build / Delivery

## 7.1 目标

把“生成 DSL”升级为“生成可验证产物”。

## 7.2 Web 构建任务

- 固定 Web 构建入口
- 统一构建参数
- 构建结果目录规范化
- 构建日志摘要化
- MCP 返回构建状态

## 7.3 Android 构建任务

### 当前已有基础

- `debug` APK 构建脚本已存在

### 下一步任务

- 构建脚本参数标准化
- 构建日志结构化
- 构建失败错误码归类
- `release` 签名配置
- 构建结果归档

## 7.4 Electron / WebView 任务

- Electron 加载 Flutter Web 构建产物验证
- Android WebView 壳安装验证
- 多环境地址注入标准化
- 容器启动状态回传

## 7.5 MCP 化任务

构建流程最终要被 MCP 调用，而不是只能人工执行命令。

建议分两步：

1. 先包装现有命令行脚本
2. 再抽象为标准 build task

## 7.6 完成标准

- AI 能触发构建
- 构建成功和失败都能结构化回传
- 用户能直接拿到产物路径

## 8. 推荐执行顺序

建议按下面顺序推进，避免同时开太多战线：

1. `App Schema` 设计
2. 页面生成 / 修改 / 校验类 MCP tools
3. Studio 的 AI Prompt 工作流
4. Runtime 补组件与动作模型
5. 应用级导航与路由
6. 数据绑定能力
7. Build MCP 化
8. 测试、回滚、治理

## 9. 阶段性任务清单

## 阶段 A：AI 单页生成

### MCP

- 新增 `generate_page_from_prompt`
- 新增 `update_page_by_instruction`
- 新增 `validate_page`
- 新增 `list_components`

### DSL

- 补页面 schema
- 补组件元数据
- 补校验规则

### Studio

- 新增 Prompt 输入
- 新增生成结果加载入口
- 新增校验结果展示

### Runtime

- 确保生成页面可稳定渲染
- 增强错误提示

### Build

- 暂不作为主重点

## 阶段 B：AI 多页应用

### MCP

- 新增 `create_app`
- 新增 `load_app`
- 新增 `save_app_version`
- 新增 `add_page_to_app`
- 新增 `update_app_navigation`

### DSL

- 落地 App Schema
- 落地应用资源 URI

### Studio

- 新增应用视图
- 新增页面编排
- 新增路由编辑

### Runtime

- 新增应用壳与导航

### Build

- 确定应用构建入口

## 阶段 C：数据与业务动作

### MCP

- 新增 `create_data_source`
- 新增 `bind_component_data`
- 新增 `bind_form_submit`
- 新增 `test_action`

### DSL

- 标准化 data source schema
- 标准化 submit / query / navigation action schema

### Studio

- 新增数据源配置面板
- 新增动作调试

### Runtime

- 支持 data action
- 支持 submit action

### Build

- 非主优先级

## 阶段 D：AI 构建导出

### MCP

- 新增 `build_web`
- 新增 `build_android_debug`
- 新增 `export_app_bundle`

### DSL

- 新增 build profile schema

### Studio

- 新增构建面板
- 新增构建日志摘要

### Runtime

- 无主改动

### Build

- 包装 Web / Android 构建流程
- 回传构建结果

## 阶段 E：发布与治理

### MCP

- 新增版本 diff / rollback 工具
- 新增审计查询工具

### DSL

- schema 冻结与版本化

### Studio

- diff、回滚、审计入口

### Runtime

- 稳定性与监控增强

### Build

- `release` 流程
- 多端验收

## 10. 验收标准

当以下条件满足时，可以认为平台已经接近目标状态：

- AI 可生成单页并保存
- AI 可组装多页应用
- 页面和应用都具备结构化 schema
- 生成结果可在 Studio 中人工修订
- runtime 可稳定渲染与执行动作
- AI 可触发构建并获得产物
- 系统具备版本化、回滚、校验和测试能力

## 11. 当前最推荐立刻启动的任务

如果只启动一批任务，建议就是下面这组：

1. 设计 `App Schema` 初版
2. 实现 `generate_page_from_prompt`
3. 实现 `validate_page`
4. 在 Studio 新增 AI Prompt 输入区
5. 为 runtime 扩展表单与导航类组件
6. 设计 `build_web` / `build_android_debug` 的 MCP 接口

这组任务能最快把项目从“可编辑 Demo”推进到“AI 构建平台”的下一阶段。
