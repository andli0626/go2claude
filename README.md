# Go2Claude

Go2Claude 是一款轻量级 macOS 实用工具，灵感来自 Go2Shell。`Go2Claude.app` 用于打开主界面；`Go2Claude Toolbar.app` 用于拖到 Finder 工具栏，点击后会在当前 Finder 文件夹中直接启动 Claude CLI。

![Go2Claude 截图](截图.png)

<br />

## 功能特点

- 使用 AppleScript 读取当前 Finder 窗口路径
- 启动 `Terminal.app` 并执行可配置的 命令模板
- 默认命令：`cd %PATH% && claude --dangerously-skip-permissions`
- 双击应用或执行 `open -a Go2Claude` 打开主界面
- 保留 `open -a Go2Claude --args config` 兼容配置入口
- 首次打开自动检查本机是否已安装 Claude CLI，未安装时弹窗并在设置页持续提示
- 打包为两个未签名的 `.app` 包、一个 `.zip` 压缩包和一个 `.pkg` 安装包
- 零外部依赖 — 纯 Apple 框架

## 系统要求

- macOS 13.0 或更高版本
- Xcode 15.0 或更高版本
- Claude CLI 已安装并可在 shell 环境中作为 `claude` 调用

## 免责声明

- Go2Claude 是一个非官方第三方效率工具，仅用于帮助用户从 Finder 快速定位目录并启动本机已安装的 Claude CLI 或相关命令行环境。
- 本项目与 Anthropic、Claude 官方客户端及其关联产品不存在任何隶属、代理、担保、赞助、背书或认证关系；`Claude` 及相关名称、商标与产品权益归其各自权利方所有。
- 当前发布的 `.app`、`.zip`、`.pkg` 为未签名分发版本，安装、打开或运行过程中可能触发 macOS 的 Gatekeeper、安全验证、自动化权限或其他系统限制。是否继续安装、放行和使用，应由使用者自行判断并承担相应风险。
- 本工具的核心行为是在本机 `Terminal.app` 中执行用户配置的命令模板。命令模板可能涉及目录切换、CLI 调用、环境变量继承、脚本执行、权限调用或其他系统操作。使用者应自行确认命令内容的真实性、安全性、合法性及适用性。
- 作者不保证本工具在所有 macOS 版本、芯片架构、Shell 环境、权限配置、终端设置、Finder 状态、第三方 CLI 版本或网络条件下均可正常工作，也不保证与未来版本的 Claude CLI、macOS 或相关第三方组件持续兼容。
- 对于因使用、误用、无法使用、安装失败、系统拦截、权限拒绝、命令执行异常、环境污染、工作目录错误、脚本副作用、数据丢失、配置损坏、开发环境异常、生产事故、中断损失或任何直接、间接、附带、特殊、惩罚性后果所引发的问题，作者在适用法律允许的范围内不承担责任。
- 若你计划将本工具用于公司设备、受管终端、团队环境、生产主机或包含敏感数据的工作目录，请在使用前自行完成内部安全评估、命令审查、权限校验与备份措施。
- 下载、安装、分发或使用本项目，即视为你已理解并接受上述全部说明，并同意自行承担由此产生的相关风险与责任。

## 快速上手

### 在 Xcode 中打开

这是一个 Swift Package，可直接用 Xcode 打开：

```bash
cd /Users/lilin/Downloads/Go2Claude
xed .
```

然后在 Xcode 中运行 `Go2Claude` 可执行目标。

### 运行测试

```bash
cd /Users/lilin/Downloads/Go2Claude
swift test
```

### 打包应用

\`\`\`bash
cd /Users/lilin/Downloads/Go2Claude

# 基本打包（不递增版本）
./scripts/package_app.sh

# 自动递增版本号并打包（patch +1）
AUTO_INCREMENT_VERSION=1 ./scripts/package_app.sh

# 包含 ZIP 压缩包
INCLUDE_ZIP=1 ./scripts/package_app.sh

# 递增版本 + 包含 ZIP
AUTO_INCREMENT_VERSION=1 INCLUDE_ZIP=1 ./scripts/package_app.sh
\`\`\`

脚本会创建：

- \`dist/Go2Claude.app\`
- \`dist/Go2Claude Toolbar.app\`
- \`dist/Go2Claude.pkg\`
- \`dist/Go2Claude-macOS-universal-<version>-<YYYYMMDD>.pkg\`
- \`dist/Go2Claude-macOS-universal-<version>-<YYYYMMDD>.zip\`（当 \`INCLUDE_ZIP=1\` 时）

### 版本管理

使用版本管理脚本查看或修改版本号：

\`\`\`bash
# 查看当前版本号
./scripts/version.sh

# 自动递增 patch 版本（1.2.0 -> 1.2.1）
./scripts/version.sh increment

# 设置指定版本
./scripts/version.sh set 1.3.0
\`\`\`

### 添加到 Finder 工具栏

1. 构建或打包应用，获得 `Go2Claude.app` 和 `Go2Claude Toolbar.app`
2. 运行一次应用，打开主界面
3. 点击「Add Go2Claude button to Finder Toolbar」按钮
4. 在 Finder 中，选择 `Go2Claude Toolbar.app`，按住 Command 键拖动到 Finder 工具栏

之后，在任何 Finder 窗口中点击该工具栏按钮，即会使用当前模板命令在当前文件夹启动 Claude。

## 命令模板

配置窗口将一个命令模板存储在 `UserDefaults` 中。

- `%PATH%` 是必需的，会被替换为当前 Finder 文件夹路径
- 默认模式：

```bash
cd %PATH% && claude --dangerously-skip-permissions
```

- 开发模式示例：

```bash
cd %PATH% && claude
```

## 打开主界面

```bash
open -a Go2Claude
```

## 兼容打开配置窗口

```bash
open -a Go2Claude --args config
```

## 首次启动说明

- macOS 可能会警告应用未签名。可在「系统设置 > 隐私与安全性」中允许运行。
- Go2Claude 首次打开会检测当前机器是否存在 `claude` 命令；若未检测到，会弹出安装指引，并在设置页显示安装提示与官方文档入口。
- 首次连接 Finder 或 Terminal 时，macOS 会请求自动化权限。请授权，以便应用读取当前 Finder 文件夹并启动 Terminal。

### 未签名安装包如何放行

当前发布的 `Go2Claude.pkg` 和 `.app` 为未签名产物，其他用户仍可安装使用，但首次安装/打开时可能会被 macOS 安全机制拦截。

可按下面步骤处理：

1. 双击安装包或应用后，如果看到“无法打开”或“无法验证开发者”提示，先关闭弹窗。
2. 打开「系统设置」→「隐私与安全性」。
3. 在页面下方找到与 `Go2Claude` 或安装包相关的安全提示，点击「仍要打开」或允许继续安装。
4. 再次双击 `.pkg` 或 `.app`，按提示完成安装。
5. 首次运行后，如系统请求 Finder / Terminal 自动化权限，请选择允许。

如果 Finder 工具栏按钮仍指向旧版本，请删除旧按钮，再将新的 `Go2Claude Toolbar.app` 重新拖入 Finder 工具栏。

## 架构设计

Go2Claude 采用清晰的双层架构：

```
┌─────────────────────────────────────────────────────────────┐
│                      Go2Claude 应用层                       │
│  (main.swift → AppDelegate → SettingsWindowController)     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     AppCoordinator 协调器                    │
│        (编排: LaunchMode + Settings + 核心组件)             │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│FinderPathResolver│  │CommandTemplate │   │TerminalLauncher│
│   Finder路径解析 │   │  命令模板渲染  │    │  Terminal启动  │
└───────────────┘    └───────────────┘    └───────────────┘
```

### 核心设计模式

| 模式         | 应用位置                                   | 用途               |
| ---------- | -------------------------------------- | ---------------- |
| 依赖注入       | AppCoordinator                         | 通过 Stub 注入实现可测试性 |
| 协议抽象       | FinderPathResolving, TerminalLaunching | 解耦实现             |
| Observable | AppSettings, SettingsWindowState       | SwiftUI 数据绑定     |
| 协调器        | AppCoordinator                         | 封装启动流程           |

## 项目结构

```
Go2Claude/
├── Sources/
│   ├── Go2ClaudeCore/          # 核心业务逻辑（可测试）
│   │   ├── AppCoordinator.swift           # 主协调器
│   │   ├── AppSettings.swift              # UserDefaults 封装
│   │   ├── LaunchMode.swift               # 启动模式枚举
│   │   ├── CommandTemplateRenderer.swift   # %PATH% 替换
│   │   ├── FinderPathResolver.swift        # AppleScript 获取 Finder 路径
│   │   ├── TerminalLauncher.swift          # Terminal 执行
│   │   └── AppleScriptRunner.swift         # AppleScript 执行器
│   │
│   └── Go2Claude/              # AppKit/SwiftUI 应用
│       ├── main.swift                   # 主应用入口点（手动 NSApplication）
│       ├── AppDelegate.swift             # 生命周期和菜单
│       ├── SettingsView.swift           # SwiftUI 设置界面
│       ├── SettingsWindowController.swift
│       ├── SettingsWindowState.swift
│       └── AppBundleLocator.swift
│
│   └── Go2ClaudeToolbar/       # Finder 工具栏专用 Helper
│       ├── main.swift
│       ├── ToolbarAppDelegate.swift
│       └── ToolbarLaunchController.swift
│
├── Tests/
│   └── Go2ClaudeCoreTests/     # 单元测试（14 个测试）
│       ├── AppCoordinatorTests.swift
│       ├── AppSettingsTests.swift
│       ├── LaunchModeTests.swift
│       ├── CommandTemplateRendererTests.swift
│       └── TerminalLauncherTests.swift
│
├── Resources/
│   ├── Info.plist
│   └── AppIcon.appiconset/
│
├── scripts/
│   └── package_app.sh          # 打包脚本
│
├── doc/                        # 文档
│   ├── Go2Claude-架构设计文档.md
│   ├── Go2Claude-模块说明文档.md
│   └── Go2Claude-测试报告.md
│
├── Package.swift               # Swift Package 配置
├── AGENTS.md                   # AI 代理开发指南
├── CLAUDE.md                   # 架构参考
└── README.md                   # 本文件
```

### 模块职责

**Go2Claude（UI 层）**

- `main.swift`：手动 NSApplication 入口点
- `AppDelegate.swift`：应用生命周期、菜单配置、窗口协调
- `SettingsView.swift`：SwiftUI 设置界面
- `SettingsWindowController.swift`：设置窗口管理
- `SettingsWindowState.swift`：响应式窗口状态（@Published）
- `AppBundleLocator.swift`：应用包路径工具

**Go2ClaudeCore（业务逻辑层）**

- `AppCoordinator.swift`：编排启动流程
- `AppSettings.swift`：持久化设置（UserDefaults）
- `LaunchMode.swift`：启动模式解析（config vs 普通）
- `CommandTemplateRenderer.swift`：命令模板渲染（%PATH% 替换）
- `FinderPathResolver.swift`：AppleScript 获取当前 Finder 路径
- `TerminalLauncher.swift`：在 Terminal.app 中执行命令
- `AppleScriptRunner.swift`：AppleScript 执行封装

## 启动流程

```
普通启动（双击 App / open -a Go2Claude）
        │
        ▼
   LaunchMode(arguments:) → .mainInterface
        │
        ▼
   LaunchRequestRouter.consumeInitialLaunch(...)
        │
        ▼
   打开设置窗口（主界面）

Finder 工具栏启动（Go2Claude Toolbar.app）
        │
        ▼
   Helper 普通启动
        │
        ▼
   AppCoordinator.launchCurrentFinderPath()
        │
        ▼
   尝试执行命令
        │
        ├─ 成功 → terminate（退出，仅启动 Terminal）
        └─ 失败 → 弹出错误并可打开主界面
```

## 故障排除

### 测试无法运行

```bash
# 清理后重新构建
rm -rf .build && swift test
```

### AppleScript 错误

- 检查「系统设置 > 隐私与安全性 > 自动化」
- 确保应用有 Finder 和 Terminal 的权限
- 先在脚本编辑器中测试脚本

### 构建失败

```bash
# 验证 Swift 版本
swift --version  # 需要 6.0+

# 检查平台
# Package.swift 指定 .macOS(.v13)
```

### 应用未出现在 Finder 工具栏

1. 确保应用正在运行（即使没有显示窗口）
2. 在 Finder 中选择「显示 > 自定义工具栏...」
3. 按住 Command 将 Go2Claude Toolbar.app 拖到工具栏

## 相关文档

- [架构设计文档](doc/Go2Claude-架构设计文档.md) - 详细架构说明
- [模块说明文档](doc/Go2Claude-模块说明文档.md) - API 参考
- [测试报告](doc/Go2Claude-测试报告.md) - 测试覆盖报告
- [AGENTS.md](AGENTS.md) - AI 代理开发指南

## 依赖项

**零外部依赖** — 仅使用 Apple 框架：

- Foundation
- Combine
- AppKit
- SwiftUI
- NSAppleScript

## 开源许可

MIT
