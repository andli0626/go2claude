# CLAUDE.md

本文档为 Claude Code (claude.ai/code) 提供本代码仓库的工作指导。

## 项目概述

Go2Claude 是一个 macOS 实用工具，可在 Finder 工具栏添加一个按钮，用于在当前文件夹中打开 Claude CLI。它灵感来源于 Go2Shell，以原生 macOS Swift Package 形式实现。

## 架构

项目采用分层架构，核心逻辑与 UI 之间有清晰的分离：

### 模块结构

```
Go2ClaudeCore/          # 库目标，包含可测试的核心逻辑
├── LaunchMode.swift           # 枚举：normal | config | error
├── AppSettings.swift          # UserDefaults 包装器，用于命令模板
├── CommandTemplateRenderer    # 渲染 %PATH% 占位符并进行 Shell 转义
├── FinderPathResolver       # AppleScript 获取当前 Finder 文件夹
├── TerminalLauncher         # AppleScript 启动 Terminal.app 并执行命令
└── AppCoordinator           # 编排主流程

Go2Claude/              # 可执行目标 (AppKit/SwiftUI)
├── main.swift               # 入口点，解析启动参数
├── AppDelegate.swift        # 应用生命周期，窗口管理
├── SettingsWindowController.swift   # 设置窗口宿主
├── SettingsWindowState.swift        # 设置视图模型
├── SettingsView.swift                # SwiftUI 设置界面
└── AppBundleLocator.swift           # 辅助定位 .app 包

Go2ClaudeToolbar/       # Finder 工具栏专用 Helper
├── main.swift
├── ToolbarAppDelegate.swift
└── ToolbarLaunchController.swift
```

### 关键数据流

1. **普通启动**：无参数启动默认打开 `SettingsWindowController` 和 `SettingsView`
2. **Finder 工具栏启动**：`Go2Claude Toolbar.app` 普通启动后直接调用 `AppCoordinator.launchCurrentFinderPath()`，读取当前 Finder 前台目录并启动 `Terminal.app`
3. **配置启动**：`--args config` 仍然兼容，行为与普通启动一致，都会打开主界面
4. **设置存储**：`AppSettings` 使用 `UserDefaults`，键名为 `commandTemplate`，默认值为 `cd %PATH% && claude --dangerously-skip-permissions`

## 构建命令

```bash
# 运行测试
swift test

# 构建调试版本可执行文件
swift build

# 打包应用（创建两个 .app、一个 .zip 和一个 .pkg）
./scripts/package_app.sh
```

## 开发说明

- **平台**：仅支持 macOS 13+（在 Package.swift 中设置）
- **Swift 版本**：6.2（swift-tools-version）
- **无外部依赖**：纯 Foundation/AppKit/SwiftUI
- **测试**：核心模块包含单元测试；UI 测试需要手动验证

## 启动参数

应用支持通过命令行参数指定特殊启动模式：

```bash
# 正常操作（打开主界面）
./Go2Claude

# 打开主界面
open -a Go2Claude

# 兼容打开配置窗口
open -a Go2Claude --args config
```

## AppleScript 集成

应用依赖 AppleScript 实现 macOS 集成：

- **FinderPathResolver**：`tell application "Finder" to get target of front window as alias`
- **TerminalLauncher**：`tell application "Terminal" to do script "..."`

这些功能需要自动化权限（在 系统设置 > 隐私与安全性 > 自动化 中授予）。
