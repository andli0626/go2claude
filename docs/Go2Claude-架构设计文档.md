# Go2Claude 架构设计文档

## 一、项目概述

### 1.1 项目基本信息

| 属性 | 说明 |
|------|------|
| 项目名称 | Go2Claude |
| 项目类型 | macOS 桌面工具（Swift Package + App Bundle） |
| 核心功能 | 一键从 Finder 工具栏按钮启动 Claude CLI 到当前文件夹 |
| 灵感来源 | Go2Shell（经典 macOS 工具） |
| 最低系统要求 | macOS 13.0+ |
| Swift 版本 | Swift 6.2 |

### 1.2 技术栈

| 层级 | 技术/框架 |
|------|----------|
| UI 框架 | SwiftUI + AppKit（混合使用） |
| 核心语言 | Swift 6.2 |
| 包管理 | Swift Package Manager |
| 系统集成 | AppleScript |
| 测试框架 | XCTest |
| 应用打包 | 脚本打包为 .app + .zip |

---

## 二、项目结构

```
Go2Claude/
├── Sources/
│   ├── Go2Claude/                    # 应用入口层（UI + 协调）
│   │   ├── main.swift               # NSApplication 手动启动入口
│   │   ├── AppDelegate.swift        # 应用生命周期、菜单、窗口协调
│   │   ├── SettingsView.swift       # SwiftUI 设置界面
│   │   ├── SettingsWindowController.swift  # NSWindowController
│   │   ├── SettingsWindowState.swift       # 设置窗口状态
│   │   └── AppBundleLocator.swift           # 应用包路径工具
│   │
│   └── Go2ClaudeCore/               # 核心业务逻辑层（可测试）
│       ├── AppCoordinator.swift           # 核心协调器
│       ├── AppSettings.swift              # 用户设置（UserDefaults）
│       ├── LaunchMode.swift               # 启动模式解析
│       ├── CommandTemplateRenderer.swift   # 命令模板渲染
│       ├── FinderPathResolver.swift       # AppleScript 获取 Finder 路径
│       ├── TerminalLauncher.swift         # AppleScript 启动 Terminal
│       └── AppleScriptRunner.swift        # AppleScript 执行器
│
├── Tests/
│   └── Go2ClaudeCoreTests/          # 单元测试
│       ├── AppCoordinatorTests.swift
│       ├── AppSettingsTests.swift
│       ├── LaunchModeTests.swift
│       ├── CommandTemplateRendererTests.swift
│       └── TerminalLauncherTests.swift
│
├── Resources/
│   ├── Info.plist                  # 应用配置
│   └── AppIcon.appiconset/         # 应用图标集
│
├── scripts/
│   └── package_app.sh              # 打包脚本
│
├── design-assets/                   # 设计资源
│
├── Package.swift                    # SPM 配置
├── README.md                        # 项目说明
└── .gitignore
```

---

## 三、架构设计

### 3.1 整体架构：分层清晰，依赖反转

```
┌─────────────────────────────────────────────────────────────┐
│                      Go2Claude App                          │
│  (main.swift → AppDelegate → SettingsWindowController)     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     AppCoordinator                          │
│        (编排: LaunchMode + Settings + 核心组件)            │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│FinderPathResolver│  │CommandTemplate │   │TerminalLauncher│
│  (协议+实现)   │    │   Renderer    │    │  (协议+实现)   │
└───────────────┘    └───────────────┘    └───────────────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              ▼
                    ┌───────────────┐
                    │AppleScriptRunner│
                    │  (基础工具)    │
                    └───────────────┘
```

### 3.2 核心设计模式

| 模式 | 应用位置 | 说明 |
|------|---------|------|
| **依赖注入** | AppCoordinator 构造器 | 便于单元测试时注入 Stub |
| **协议抽象** | FinderPathResolving, TerminalLaunching | 核心逻辑与实现解耦 |
| **Observable** | AppSettings, SettingsWindowState | SwiftUI 数据绑定 |
| **协调器模式** | AppCoordinator | 封装启动流程编排 |
| **手动入口** | main.swift | 不使用 @main，保持控制权 |

### 3.3 模块职责

#### Go2Claude 层（UI 层）
负责应用 UI 和生命周期管理，不包含核心业务逻辑。

| 文件 | 职责 |
|------|------|
| main.swift | NSApplication 手动启动入口 |
| AppDelegate.swift | 应用生命周期、菜单配置、窗口协调 |
| SettingsView.swift | SwiftUI 设置界面 |
| SettingsWindowController.swift | 设置窗口控制器 |
| SettingsWindowState.swift | 设置窗口状态（@Published） |
| AppBundleLocator.swift | 应用包路径工具 |

#### Go2ClaudeCore 层（核心层）
包含纯业务逻辑，可独立测试，不依赖 UI 框架。

| 文件 | 职责 |
|------|------|
| AppCoordinator.swift | 核心业务协调，编排启动流程 |
| AppSettings.swift | 用户设置持久化（UserDefaults） |
| LaunchMode.swift | 启动模式解析（无参数/config） |
| CommandTemplateRenderer.swift | 命令模板渲染（%PATH% 替换） |
| FinderPathResolver.swift | AppleScript 获取 Finder 当前路径 |
| TerminalLauncher.swift | AppleScript 在 Terminal 执行命令 |
| AppleScriptRunner.swift | AppleScript 执行封装 |

---

## 四、启动流程

### 4.1 应用启动流程

```
用户点击 Finder 工具栏按钮
        │
        ▼
   main.swift
   (手动创建 NSApplication)
        │
        ▼
   AppDelegate.applicationDidFinishLaunching(_:)
        │
        ▼
   LaunchMode(arguments: ProcessInfo.arguments)
   (解析启动参数)
        │
        ├─ "config" → .configuration
        └─ 无参数   → .openCurrentFinderPath
        │
        ▼
   AppCoordinator.handleLaunch(mode:)
        │
        ├─ .configuration → 打开设置窗口
        │
        └─ .openCurrentFinderPath
              │
              ▼
         尝试执行命令
              │
              ├─ 成功 → terminate（退出，只启动 Terminal）
              └─ 失败 → 打开设置窗口（显示错误信息）
```

### 4.2 命令执行流程

```
1. 获取 Finder 当前路径
   └→ FinderPathResolver.resolveCurrentFinderPath()
      └→ AppleScript: "tell application Finder... POSIX path of target"

2. 渲染命令模板
   └→ CommandTemplateRenderer.render(template, finderPath)
      └→ 替换 %PATH% 为 shell 转义后的路径

3. 在 Terminal 执行命令
   └→ TerminalLauncher.launch(command)
      └→ AppleScript: "tell application Terminal... do script"
```

---

## 五、关键实现

### 5.1 main.swift - 手动应用入口

```swift
import AppKit

let application = NSApplication.shared
let appDelegate = AppDelegate()

application.setActivationPolicy(.accessory)  // 菜单栏工具，不显示 Dock 图标
application.delegate = appDelegate
application.run()
```

**设计考虑**：不使用 `@main`，将应用启动控制权完全交给手动代码。

### 5.2 LaunchMode - 启动模式解析

```swift
public enum LaunchMode: Equatable {
    case openCurrentFinderPath   // 直接执行命令
    case configuration            // 打开设置窗口

    public init(arguments: [String]) {
        if arguments.dropFirst().contains(where: { $0.caseInsensitiveCompare("config") == .orderedSame }) {
            self = .configuration
        } else {
            self = .openCurrentFinderPath
        }
    }
}
```

**使用方式**：
- `open -a Go2Claude` → `.openCurrentFinderPath`
- `open -a Go2Claude --args config` → `.configuration`

### 5.3 CommandTemplateRenderer - 命令模板渲染

```swift
public struct CommandTemplateRenderer {
    public static let pathPlaceholder = "%PATH%"

    public func render(template: String, finderPath: String) throws -> String {
        guard template.contains(Self.pathPlaceholder) else {
            throw Error.missingPathPlaceholder
        }

        return template.replacingOccurrences(
            of: Self.pathPlaceholder,
            with: shellQuote(path: finderPath)
        )
    }

    private func shellQuote(path: String) -> String {
        let escaped = path.replacingOccurrences(of: "'", with: "'\"'\"'")
        return "'\(escaped)'"
    }
}
```

**shell 转义逻辑**：将路径中的单引号替换为 `'"'"'`，确保路径被正确引用。

### 5.4 FinderPathResolver - Finder 路径解析

```swift
public func resolveCurrentFinderPath() throws -> String {
    let script = """
    activate application "System Events"
    tell application "Finder"
        activate
        if (count of Finder windows) is 0 then
            error "No Finder window is open."
        end if
        try
            set targetAlias to (target of front Finder window) as alias
            return POSIX path of targetAlias
        on error
            return POSIX path of ((insertion location) as alias)
        end try
    end tell
    """
    // ...
}
```

**逻辑**：优先取前台窗口的 target，如果失败则取 insertion location。

### 5.5 TerminalLauncher - Terminal 执行

```swift
public struct TerminalLauncher: TerminalLaunching {
    private let shellPathProvider: () -> String

    public init(shellPathProvider: @escaping () -> String = { UserShell.currentShellPath() }) {
        self.shellPathProvider = shellPathProvider
    }

    func wrappedCommand(_ command: String) -> String {
        "\(shellPathProvider()) -lc \(shellQuote(command))"
    }

    func appleScript(for command: String) -> String {
        let appleScriptCommand = wrappedCommand(command)
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")

        return """
        tell application "Terminal"
            activate
            do script "\(appleScriptCommand)"
        end tell
        """
    }
}
```

**关键点**：使用 `-lc` 以 login shell 执行命令，确保环境变量正确加载。

---

## 六、Info.plist 配置

```xml
<key>LSUIElement</key>
<true/>                    <!-- 作为后台工具，不显示 Dock 图标 -->
<key>NSAppleEventsUsageDescription</key>
<string>Go2Claude 需要自动化权限来读取 Finder 当前目录并在 Terminal 中打开 Claude。</string>
<key>LSMinimumSystemVersion</key>
<string>13.0</string>
```

---

## 七、依赖关系图

```
┌─────────────────────────────────────────────────────────────────┐
│                         Go2Claude (App)                         │
│  main.swift → AppDelegate → SettingsWindowController → SwiftUI │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                         AppCoordinator
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
  AppSettings          CommandTemplate        TerminalLauncher
  (UserDefaults)        Renderer              (依赖 AppleScriptRunner)
        │                     │                         │
        └─────────────────────┼─────────────────────────┘
                              ▼
                    ┌───────────────┐
                    │  FinderPathResolver │
                    │  (依赖 AppleScriptRunner) │
                    └───────────────┘
                              │
                              ▼
                    ┌───────────────┐
                    │AppleScriptRunner│
                    └───────────────┘
```

---

## 八、设计亮点

1. **清晰的二层架构**：UI 层与核心逻辑分离，核心逻辑可独立测试
2. **依赖注入**：AppCoordinator 接受协议参数，便于测试时注入 Stub
3. **协议抽象**：FinderPathResolver、TerminalLauncher 可替换实现
4. **路径 shell 转义**：正确处理空格、特殊字符、中文路径
5. **错误本地化**：所有 Error 实现 LocalizedError，提供中文错误信息
6. **手动 @main**：保持对应用启动的完全控制

---

## 九、待改进点

1. **FinderPathResolver 同步阻塞**：AppleScript 调用是同步的
2. **未使用 async/await**：AppleScript 部分是传统回调风格
3. **缺少 UI 层测试**：目前只有 Core 层有单元测试
4. **TerminalLauncher.launch 未使用 AppleScript**：实际使用 Process.open 实现