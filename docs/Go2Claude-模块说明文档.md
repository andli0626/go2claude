# Go2Claude 模块说明文档

## 一、Go2Claude 层（应用层）

### 1.1 main.swift

**路径**：`Sources/Go2Claude/main.swift`

**功能**：手动启动 NSApplication，作为应用入口点。

**代码**：
```swift
import AppKit

let application = NSApplication.shared
let appDelegate = AppDelegate()

application.setActivationPolicy(.accessory)
application.delegate = appDelegate
application.run()
```

**说明**：
- 不使用 `@main`，完全手动控制应用启动
- `setActivationPolicy(.accessory)` 使应用作为菜单栏工具运行，不显示 Dock 图标
- `appDelegate` 处理应用生命周期

---

### 1.2 AppDelegate.swift

**路径**：`Sources/Go2Claude/AppDelegate.swift`

**功能**：应用生命周期管理、菜单配置、窗口协调。

**主要属性**：
| 属性 | 类型 | 说明 |
|------|------|------|
| settings | AppSettings | 应用设置（UserDefaults） |
| windowState | SettingsWindowState | 设置窗口状态 |
| coordinator | AppCoordinator | 核心协调器 |
| settingsWindowController | SettingsWindowController? | 设置窗口控制器 |

**主要方法**：

| 方法 | 说明 |
|------|------|
| `applicationDidFinishLaunching(_:)` | 应用启动完成，处理启动模式 |
| `applicationShouldHandleReopen(_:hasVisibleWindows:)` | 处理 dock 图标点击 |
| `openSettingsWindowFromMenu(_:)` | 从菜单打开设置窗口 |
| `showUsageTips(_:)` | 显示使用提示 |
| `handleLaunch()` | 根据 LaunchMode 处理启动 |
| `openSettingsWindow()` | 创建并显示设置窗口 |
| `revealAppInFinder()` | 在 Finder 中显示应用，引导添加到工具栏 |
| `launchClaudeFromSettings()` | 从设置窗口启动 Claude |
| `presentUsageTips()` | 显示使用提示弹窗 |
| `configureApplicationMenu()` | 配置应用菜单 |

---

### 1.3 SettingsView.swift

**路径**：`Sources/Go2Claude/SettingsView.swift`

**功能**：SwiftUI 设置界面。

**属性**：
| 属性 | 类型 | 说明 |
|------|------|------|
| settings | AppSettings | 应用设置（@ObservedObject） |
| state | SettingsWindowState | 窗口状态（@ObservedObject） |
| onRevealAppInFinder | () -> Void | 回调：显示应用在 Finder |
| onLaunchClaude | () -> Void | 回调：启动 Claude |
| onShowUsageTips | () -> Void | 回调：显示使用提示 |

**界面布局**：
1. 标题区域：应用名称 + 副标题
2. 消息区域：显示启动错误信息（如有）
3. 命令模板区域：TextField 编辑命令模板
4. 按钮区域：重置、启动、提示按钮
5. 配置信息区域：GroupBox 显示配置示例
6. 添加到 Finder 工具栏按钮

---

### 1.4 SettingsWindowController.swift

**路径**：`Sources/Go2Claude/SettingsWindowController.swift`

**功能**：NSWindowController，管理设置窗口。

**构造参数**：
| 参数 | 类型 | 说明 |
|------|------|------|
| rootView | SettingsView | SwiftUI 根视图 |

**窗口配置**：
- 标题：Go2Claude
- StyleMask：titled, closable, miniaturizable
- Size：700 x 440
- 窗口居中，不释放关闭时

---

### 1.5 SettingsWindowState.swift

**路径**：`Sources/Go2Claude/SettingsWindowState.swift`

**功能**：设置窗口状态管理（@Observable）

**属性**：
| 属性 | 类型 | 说明 |
|------|------|------|
| launchMessage | String? | 启动错误消息（@Published） |

---

### 1.6 AppBundleLocator.swift

**路径**：`Sources/Go2Claude/AppBundleLocator.swift`

**功能**：应用包路径工具。

**方法**：
```swift
static func revealableURL(from bundleURL: URL) -> URL
```

**逻辑**：
- 如果路径以 `.app` 结尾，返回 bundle URL
- 否则返回父目录

---

## 二、Go2ClaudeCore 层（核心层）

### 2.1 AppCoordinator.swift

**路径**：`Sources/Go2ClaudeCore/AppCoordinator.swift`

**功能**：核心业务协调器，编排启动流程。

**LaunchResult**：
```swift
public enum LaunchResult: Equatable {
    case terminate           // 终止应用
    case openSettings(message: String?)  // 打开设置窗口
}
```

**构造参数**：
| 参数 | 类型 | 说明 |
|------|------|------|
| settings | AppSettings | 应用设置 |
| finderPathResolver | FinderPathResolving | Finder 路径解析器 |
| commandRenderer | CommandTemplateRenderer | 命令模板渲染器 |
| terminalLauncher | TerminalLaunching | Terminal 启动器 |

**主要方法**：

| 方法 | 说明 |
|------|------|
| `launchCurrentFinderPath(explicitFinderPath:)` | 使用用户模板启动命令 |
| `launchClaudeCurrentFinderPath(explicitFinderPath:)` | 使用硬编码模板启动 Claude |
| `handleLaunch(mode:explicitFinderPath:)` | 根据启动模式处理 |
| `resolveFinderPath(_:)` | 解析 Finder 路径 |

**内部硬编码命令**：`cd %PATH% && claude`

---

### 2.2 AppSettings.swift

**路径**：`Sources/Go2ClaudeCore/AppSettings.swift`

**功能**：用户设置持久化（ObservableObject）

**常量**：
| 常量 | 值 | 说明 |
|------|-----|------|
| commandTemplateKey | "commandTemplate" | UserDefaults key |
| defaultCommandTemplate | "cd %PATH% && claude --dangerously-skip-permissions" | 默认命令模板 |

**属性**：
| 属性 | 类型 | 说明 |
|------|------|------|
| commandTemplate | String (@Published) | 用户命令模板 |

**方法**：
| 方法 | 说明 |
|------|------|
| `init(userDefaults:)` | 初始化，从 UserDefaults 加载或使用默认值 |
| `resetToDefault()` | 重置为默认模板 |

---

### 2.3 LaunchMode.swift

**路径**：`Sources/Go2ClaudeCore/LaunchMode.swift`

**功能**：启动模式解析。

**枚举**：
```swift
public enum LaunchMode: Equatable {
    case openCurrentFinderPath  // 执行命令并退出
    case configuration          // 打开设置窗口
}
```

**构造**：
```swift
public init(arguments: [String])
```
- 如果参数包含 "config"（大小写不敏感），则为 `.configuration`
- 否则为 `.openCurrentFinderPath`

---

### 2.4 CommandTemplateRenderer.swift

**路径**：`Sources/Go2ClaudeCore/CommandTemplateRenderer.swift`

**功能**：命令模板渲染，将 `%PATH%` 替换为 Finder 路径。

**常量**：
```swift
public static let pathPlaceholder = "%PATH%"
```

**Error**：
```swift
public enum Error: Swift.Error, LocalizedError, Equatable {
    case missingPathPlaceholder  // 模板缺少 %PATH%
}
```

**方法**：
```swift
public func render(template: String, finderPath: String) throws -> String
```

**shell 转义逻辑**：
- 将 `'` 替换为 `'"'"'`
- 用单引号包裹路径

**示例**：
```
输入：template = "cd %PATH% && claude --dangerously-skip-permissions"
     finderPath = "/Users/lilin/中文 & Demo/O'Reilly (Test)"

输出："cd '/Users/lilin/中文 & Demo/O'\"'\"'Reilly (Test)' && claude --dangerously-skip-permissions"
```

---

### 2.5 FinderPathResolver.swift

**路径**：`Sources/Go2ClaudeCore/FinderPathResolver.swift`

**功能**：AppleScript 获取 Finder 当前路径。

**协议**：
```swift
public protocol FinderPathResolving {
    func resolveCurrentFinderPath() throws -> String
}
```

**Error**：
```swift
public enum Error: Swift.Error, LocalizedError, Equatable {
    case noOpenFinderWindow           // 没有打开的 Finder 窗口
    case appleScriptFailed(String)    // AppleScript 执行失败
}
```

**方法**：
```swift
public func resolveCurrentFinderPath() throws -> String
```

**AppleScript 逻辑**：
1. 激活 System Events 和 Finder
2. 检查是否有打开的 Finder 窗口
3. 优先取 `target of front Finder window`
4. 兜底取 `insertion location`

---

### 2.6 TerminalLauncher.swift

**路径**：`Sources/Go2ClaudeCore/TerminalLauncher.swift`

**功能**：在 Terminal.app 执行命令。

**协议**：
```swift
public protocol TerminalLaunching {
    func launch(command: String) throws
}
```

**Error**：
```swift
public enum Error: Swift.Error, LocalizedError, Equatable {
    case appleScriptFailed(String)  // AppleScript 执行失败
}
```

**UserShell**：
```swift
public enum UserShell {
    public static func currentShellPath() -> String
}
```

**方法**：

| 方法 | 说明 |
|------|------|
| `init(shellPathProvider:)` | 构造，可指定 shell 路径 provider |
| `wrappedCommand(_:)` | 用 login shell 包装命令 |
| `appleScript(for:)` | 生成 AppleScript 字符串 |
| `launch(command:)` | 执行命令 |

**wrappedCommand 格式**：`{shellPath} -lc '{command}'`

**appleScript 格式**：
```applescript
tell application "Terminal"
    activate
    do script "{wrappedCommand}"
end tell
```

---

### 2.7 AppleScriptRunner.swift

**路径**：`Sources/Go2ClaudeCore/AppleScriptRunner.swift`

**功能**：AppleScript 执行封装。

**Error**：
```swift
struct Error: Swift.Error {
    let message: String
}
```

**方法**：

| 方法 | 说明 |
|------|------|
| `run(_:)` -> String | 执行 AppleScript，返回字符串结果 |
| `runOptional(_:)` -> NSAppleEventDescriptor? | 执行 AppleScript，不关心结果 |

**逻辑**：
1. 创建 NSAppleScript
2. 执行并捕获错误
3. 返回结果或抛出错误

---

## 三、测试文件

| 文件 | 测试内容 |
|------|---------|
| AppCoordinatorTests.swift | 协调器启动逻辑、错误处理 |
| AppSettingsTests.swift | 默认值初始化、持久化 |
| LaunchModeTests.swift | 参数解析 |
| CommandTemplateRendererTests.swift | 占位符替换、shell 转义 |
| TerminalLauncherTests.swift | 命令包装、AppleScript 生成 |

---

## 四、数据流示例

### 4.1 用户点击 Finder 工具栏按钮启动 Claude

```
1. LaunchMode(arguments: ["Go2Claude"])
   → .openCurrentFinderPath

2. AppCoordinator.handleLaunch(mode: .openCurrentFinderPath)
   ↓
3. FinderPathResolver.resolveCurrentFinderPath()
   → "/Users/lilin/Projects/MyApp"

4. CommandTemplateRenderer.render(
       template: "cd %PATH% && claude --dangerously-skip-permissions",
       finderPath: "/Users/lilin/Projects/MyApp"
   )
   → "cd '/Users/lilin/Projects/MyApp' && claude --dangerously-skip-permissions"

5. TerminalLauncher.launch(command: "cd '/Users/lilin/Projects/MyApp' && claude --dangerously-skip-permissions")
   → Terminal.app 打开新窗口，执行命令

6. AppCoordinator.handleLaunch() 返回 .terminate
   → 应用退出
```

### 4.2 用户打开设置窗口

```
1. LaunchMode(arguments: ["Go2Claude", "config"])
   → .configuration

2. AppCoordinator.handleLaunch(mode: .configuration)
   → .openSettings(message: nil)

3. AppDelegate 收到 .openSettings
   → 打开 SettingsWindowController
```

### 4.3 路径包含特殊字符

```
输入路径：/Users/lilin/中文 & Demo/O'Reilly (Test)

shellQuote 过程：
1. 原始路径：/Users/lilin/中文 & Demo/O'Reilly (Test)
2. 转义单引号：O'Reilly → O'"'"'Reilly
3. 包裹单引号：'/Users/lilin/中文 & Demo/O'"'"'Reilly (Test)'

最终命令：
cd '/Users/lilin/中文 & Demo/O'"'"'Reilly (Test)' && claude --dangerously-skip-permissions
```