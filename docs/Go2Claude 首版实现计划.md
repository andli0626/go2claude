# Go2Claude 首版实现计划

## Summary

基于原生 macOS App 做一个 `Go2Claude`，形态参考 Go2Shell，但首版聚焦在单一能力：把当前 Finder 窗口目录一键交给 `Claude CLI`。首版不做 Finder Extension，也不做多终端支持；交付为可本机编译运行、并可导出未签名 `.app/.zip` 的安装包。

核心行为定为：

- 用户把 `Go2Claude.app` 手动拖到 Finder 工具栏
- 点击工具栏图标时，应用读取当前 Finder 目录
- 在 `Terminal.app` 中执行用户配置的命令模板
- 默认模板为 `cd %PATH% && claude --dangerously-skip-permissions`
- “开发方式”不做单独预设，直接通过编辑模板实现，例如改成 `cd %PATH% && claude`

## Key Changes

### 1. 工程与运行形态

- 建一个原生 macOS Xcode App 工程，技术栈用 `SwiftUI + 少量 AppKit`
- 保留一个常规主入口，支持两种启动模式：
  - 普通启动：执行“打开当前 Finder 目录到 Claude”
  - `config` 启动：直接打开设置窗口，兼容 `open -a Go2Claude --args config`
- 增加一个简单的打包脚本，产出 `dist/Go2Claude.app` 与 `dist/Go2Claude.zip`

### 2. 核心链路

- 实现 `FinderPathResolver`
  - 通过 AppleScript 读取前台 Finder 窗口目标目录
  - 失败时不静默退出，改为打开设置/帮助窗口并展示错误提示
- 实现 `CommandTemplateRenderer`
  - 模板必须包含 `%PATH%`
  - 渲染时将 `%PATH%` 替换为安全转义后的 POSIX 路径
  - 必须覆盖空格、中文、括号、引号、`&` 等特殊字符路径
- 实现 `TerminalLauncher`
  - 首版只支持 `Terminal.app`
  - 用 AppleScript/系统调用拉起 Terminal 并执行渲染后的完整命令
  - Terminal 已打开和未打开两种情况都要可用

### 3. 设置窗口

- 做一个简洁的 Go2Shell 风格设置页，首版只保留真正需要的项：
  - `Command to execute in terminal` 文本框
  - `Reset to default` 按钮
  - `Open configuration`/帮助说明
  - `Add Go2Claude button to Finder Toolbar` 按钮
- “添加到 Finder 工具栏”按钮不尝试自动安装，而是：
  - 在 Finder 中定位当前 `.app`
  - 弹出说明，引导用户按住 `Command` 拖到 Finder 工具栏
- 配置存储到 `UserDefaults`
  - 至少包含 `commandTemplate`
  - 首次启动若无配置，自动写入默认模板

### 4. 文档与安装

- 提供 README，明确说明：
  - 如何编译
  - 如何打开设置窗口
  - 如何把 `.app` 拖到 Finder 工具栏
  - 如何切换为“开发方式”模板
  - 未签名应用首次打开的系统提示如何处理
- 打包脚本默认走 Release 构建，不做签名、公证、DMG

## Public Interfaces / Contracts

- 启动参数约定：
  - `open -a Go2Claude --args config`
- 命令模板约定：
  - 使用 `%PATH%` 作为 Finder 当前目录占位符
  - 默认值：`cd %PATH% && claude --dangerously-skip-permissions`
- 关键内部类型建议固定为：
  - `LaunchMode`
  - `AppSettings`
  - `FinderPathResolver`
  - `CommandTemplateRenderer`
  - `TerminalLauncher`

## Test Plan

- 单元测试
  - `%PATH%` 校验与替换
  - 路径转义与特殊字符处理
  - 启动参数解析
  - 默认配置回填逻辑
- 组件级测试
  - Finder 路径获取失败时的错误分支
  - Terminal 拉起失败时的提示分支
- 手工验收
  - Finder 普通目录点击后可正确打开 Claude
  - 路径含空格、中文、特殊符号时仍可工作
  - 修改模板为 `cd %PATH% && claude` 后可作为“开发方式”使用
  - 通过 `open -a Go2Claude --args config` 能直接进入设置页
  - Release 打包产物可在另一位置解压并运行

## Assumptions

- 首版只支持 `Terminal.app`，不做 iTerm2/Ghostty，也不做“新窗口/新标签”选择
- 首版不做 Finder Extension、右键菜单、签名、公证
- “开发方式”通过可编辑模板实现，不额外做多 profile 管理
- 当前本机环境以 `Xcode 26.3`、`Swift 6.2.4` 为基线
- Finder 工具栏按钮采用“手动拖拽安装”方案，这与 [Go2Shell 官方页](https://zipzapmac.com/go2shell) 和 [Go2Shell App Store 说明](https://apps.apple.com/ca/app/go2shell/id445770608?mt=12) 的使用方式一致
