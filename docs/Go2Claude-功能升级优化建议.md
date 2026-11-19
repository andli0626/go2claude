# Go2Claude 功能升级优化建议

- 文档版本：v1.0
- 编写日期：2026-03-26
- 适用范围：`go2claude` 工程（不含 `go2codex` 实施）
- 目标读者：产品、研发、测试、发布维护

---

## 1. 工程现状总览

### 1.1 当前工程基线

| 维度 | 现状 |
|---|---|
| 构建系统 | Swift Package Manager（`swift-tools-version: 6.2`） |
| 目标平台 | macOS 13.0+ |
| 模块结构 | `Go2ClaudeCore`（核心库） + `Go2Claude`（主应用） + `Go2ClaudeToolbar`（Finder 工具栏 Helper） |
| 源码与测试规模 | 约 2245 行（`Sources + Tests`） |
| 测试基线 | `swift test` 全量通过（45/45） |
| 打包能力 | `scripts/package_app.sh` 可生成 `Go2Claude.app`、`Go2Claude Toolbar.app`、`.pkg`（可选 `.zip`） |
| 外部依赖 | 无第三方依赖（纯 Apple 框架） |

### 1.2 模块边界与关键职责

| 模块 | 核心职责 | 关键文件 |
|---|---|---|
| `Go2ClaudeCore` | Finder 路径解析、模板渲染、Terminal 拉起、启动流程编排 | `Sources/Go2ClaudeCore/AppCoordinator.swift`<br>`Sources/Go2ClaudeCore/FinderPathResolver.swift`<br>`Sources/Go2ClaudeCore/CommandTemplateRenderer.swift`<br>`Sources/Go2ClaudeCore/TerminalLauncher.swift` |
| `Go2Claude` | 主界面、菜单、启动事件处理、设置窗口与反馈 | `Sources/Go2Claude/AppDelegate.swift`<br>`Sources/Go2Claude/SettingsView.swift`<br>`Sources/Go2Claude/SettingsWindowController.swift` |
| `Go2ClaudeToolbar` | Finder 工具栏点击后快速执行，失败时回退主界面 | `Sources/Go2ClaudeToolbar/ToolbarLaunchController.swift` |

### 1.3 启动链路（现状）

1. 用户点击 Finder 工具栏按钮或打开主应用。
2. `AppDelegate` / `ToolbarLaunchController` 触发启动流程。
3. `LaunchRequestRouter` 处理首启与 Finder 事件去重。
4. `AppCoordinator` 调用 `FinderPathResolver` 获取路径（或使用显式路径）。
5. `CommandTemplateRenderer` 替换 `%PATH%` 并进行 shell quote。
6. `TerminalLauncher` 通过 AppleScript 在 `Terminal.app` 执行命令。

### 1.4 已知约束与问题识别

| 约束/问题 | 现状说明 | 影响 |
|---|---|---|
| 默认命令安全性 | 默认模板仍为 `cd %PATH% && claude --dangerously-skip-permissions` | 首次使用风险较高，安全策略不够稳健 |
| 自动化权限可诊断性 | Finder/Terminal 权限失败时仅返回错误文案，缺少分级错误码与具体引导 | 用户自助修复效率一般 |
| 模板校验能力 | 当前仅校验 `%PATH%` 是否存在 | 非法模板在运行时才暴露错误 |
| 终端扩展能力 | 仅支持 `Terminal.app` | 无法覆盖 iTerm2/Warp 用户偏好 |
| 配置可扩展性 | `AppSettings` 当前仅维护 `commandTemplate` 单 key | 后续新增配置会面临迁移与兼容压力 |
| 发布工程化 | 本地脚本已可打包，但未形成签名/公证/版本注入的标准流水线 | 外部分发与可追踪性不足 |

---

## 2. 风险与机会矩阵

评分规则：1 = 弱，5 = 强。当前分表示现状能力，目标分为本次升级后建议目标。

| 维度 | 当前分 | 目标分 | 主要风险 | 主要机会 |
|---|---:|---:|---|---|
| 安全性 | 2 | 4 | 默认危险参数、权限异常不可分级 | 安全默认值 + 显式危险模式可显著降低误用 |
| 可用性 | 3 | 4 | 权限失败引导不完整、错误语义不统一 | 增加预检查/引导后，首次成功率可提升 |
| 扩展性 | 2 | 4 | 终端实现单一、配置模型未版本化 | 终端适配层与配置迁移可支撑持续演进 |
| 可维护性 | 3 | 4 | 日志字段不统一、跨模块演进接口尚未抽象 | 统一上下文对象和验证模型可降低回归成本 |
| 发布可靠性 | 2 | 4 | 缺少标准签名/公证/制品校验流程 | 形成 CI/CD 发布规范后可提升交付质量 |

优先级结论：短期优先解决安全性与可诊断性（P0），中期完善终端和模板体验（P1），后期完成架构与发布治理（P2）。

---

## 3. P0（1-2 周）快速收益项

### P0-1 默认模板安全化

| 项目 | 建议 |
|---|---|
| 业务价值 | 降低默认高权限模式带来的误操作风险，改善首次使用安全基线 |
| 实施复杂度 | 低 |
| 风险 | 低（主要是默认行为变化，需要文案同步） |
| 预估工时 | 1-2 人日 |
| 影响文件 | `Sources/Go2ClaudeCore/AppSettings.swift`<br>`Sources/Go2Claude/SettingsView.swift`<br>`Sources/Go2Claude/AppDelegate.swift`<br>`README.md`<br>`docs/*` |
| 验收标准 | 新装/重置后默认模板不包含 `--dangerously-skip-permissions`；危险模式仅在用户显式选择后生效；相关文档与 UI 提示一致 |

### P0-2 权限与失败可诊断

| 项目 | 建议 |
|---|---|
| 业务价值 | 缩短用户定位权限问题的时间，减少“不可用但无从修复”体验 |
| 实施复杂度 | 中 |
| 风险 | 中（需覆盖不同系统权限状态分支） |
| 预估工时 | 3-4 人日 |
| 影响文件 | `Sources/Go2ClaudeCore/FinderPathResolver.swift`<br>`Sources/Go2ClaudeCore/TerminalLauncher.swift`<br>`Sources/Go2Claude/AppDelegate.swift`<br>`Sources/Go2Claude/SettingsWindowState.swift` |
| 验收标准 | Finder/Terminal 权限拒绝、无 Finder 窗口、AppleScript 执行失败能区分错误码；UI 给出分场景引导文案 |

### P0-3 模板校验增强（保存前校验）

| 项目 | 建议 |
|---|---|
| 业务价值 | 将运行时失败前移到配置时发现，减少用户试错成本 |
| 实施复杂度 | 中 |
| 风险 | 低（主要是规则边界定义） |
| 预估工时 | 2-3 人日 |
| 影响文件 | `Sources/Go2ClaudeCore/CommandTemplateRenderer.swift`<br>`Sources/Go2Claude/SettingsView.swift`<br>`Tests/Go2ClaudeCoreTests/CommandTemplateRendererTests.swift` |
| 验收标准 | 模板保存前可展示校验结果；缺少 `%PATH%`、包含明显非法片段、转义风险输入均有明确提示；合法模板无误报 |

### P0-4 启动日志可观测（结构化字段）

| 项目 | 建议 |
|---|---|
| 业务价值 | 提升问题复盘与回归定位效率，为后续发布监控打底 |
| 实施复杂度 | 低-中 |
| 风险 | 低 |
| 预估工时 | 2 人日 |
| 影响文件 | `Sources/Go2Claude/AppDelegate.swift`<br>`Sources/Go2ClaudeCore/AppCoordinator.swift`<br>`Sources/Go2ClaudeCore/TerminalLauncher.swift` |
| 验收标准 | 启动主流程日志包含统一字段：`mode`、`path_source`、`trigger_source`、`error_stage`、`error_code`；关键异常链路可通过日志串联 |

---

## 4. P1（2-4 周）产品能力升级项

### P1-1 多模板预设（工作流模板库）

| 项目 | 建议 |
|---|---|
| 业务价值 | 满足“不同项目/不同模型参数”快速切换，减少手工改模板 |
| 实施复杂度 | 中 |
| 风险 | 中（涉及配置存储结构变更） |
| 预估工时 | 4-6 人日 |
| 影响文件 | `Sources/Go2ClaudeCore/AppSettings.swift`<br>`Sources/Go2Claude/SettingsView.swift`<br>`Tests/Go2ClaudeCoreTests/AppSettingsTests.swift` |
| 验收标准 | 支持模板列表、默认模板切换、模板新增/重命名/删除（至少一条保留）；历史单模板配置可自动迁移 |

### P1-2 多终端支持抽象（Terminal/iTerm2/Warp）

| 项目 | 建议 |
|---|---|
| 业务价值 | 覆盖更多开发者终端偏好，提高实际采用率 |
| 实施复杂度 | 中-高 |
| 风险 | 中（不同终端 AppleScript/URI 协议存在差异） |
| 预估工时 | 5-8 人日 |
| 影响文件 | `Sources/Go2ClaudeCore/TerminalLauncher.swift`（重构）<br>`Sources/Go2ClaudeCore/AppCoordinator.swift`<br>`Sources/Go2ClaudeCore/AppSettings.swift` |
| 验收标准 | 可在设置中选择终端 profile；至少支持 Terminal + iTerm2；不支持终端可回退并提示 |

### P1-3 Finder 启动增强（选中文件优先 + 无窗口回退）

| 项目 | 建议 |
|---|---|
| 业务价值 | 降低 Finder 场景差异导致的失败率，提升直觉行为一致性 |
| 实施复杂度 | 中 |
| 风险 | 中（不同 Finder 状态组合较多） |
| 预估工时 | 3-5 人日 |
| 影响文件 | `Sources/Go2Claude/FinderLaunchPathResolver.swift`<br>`Sources/Go2ClaudeCore/FinderPathResolver.swift`<br>`Sources/Go2Claude/AppDelegate.swift` |
| 验收标准 | 选中文件时优先取文件所在目录；无窗口场景支持可配置回退（最近路径或提示打开窗口） |

### P1-4 命令引用区能力升级（收藏/最近使用/一键恢复）

| 项目 | 建议 |
|---|---|
| 业务价值 | 将“说明区”升级为“高频操作区”，减少重复输入和切换 |
| 实施复杂度 | 中 |
| 风险 | 低-中 |
| 预估工时 | 3-4 人日 |
| 影响文件 | `Sources/Go2Claude/SettingsView.swift`<br>`Sources/Go2Claude/CommandReferenceActionHandler.swift`<br>`Sources/Go2ClaudeCore/AppSettings.swift` |
| 验收标准 | 支持收藏常用命令、展示最近执行记录、支持一键恢复上次生效模板；执行反馈和失败提示保持一致 |

---

## 5. P2（4-8 周）架构与交付治理项

### P2-1 配置模型版本化与迁移机制

| 项目 | 建议 |
|---|---|
| 业务价值 | 降低未来新增字段或结构调整造成的兼容成本 |
| 实施复杂度 | 中 |
| 风险 | 中（需要处理旧用户数据升级路径） |
| 预估工时 | 4-6 人日 |
| 影响文件 | `Sources/Go2ClaudeCore/AppSettings.swift`<br>`Tests/Go2ClaudeCoreTests/AppSettingsTests.swift` |
| 验收标准 | 引入配置版本号；支持从 v1（单模板）自动迁移到新结构；迁移失败可回退默认并保留告警日志 |

### P2-2 发布流水线升级（签名/公证/版本注入/制品校验）

| 项目 | 建议 |
|---|---|
| 业务价值 | 提升外部分发可信度、安装体验和可追踪性 |
| 实施复杂度 | 中-高 |
| 风险 | 中（证书与 CI 环境配置复杂） |
| 预估工时 | 5-8 人日 |
| 影响文件 | `scripts/package_app.sh`<br>新增 CI 配置（如 `.github/workflows/*`）<br>`Resources/Info.plist` |
| 验收标准 | 自动注入版本号；产物包含签名/公证状态（如启用）；制品哈希与 plist 关键字段校验自动执行 |

### P2-3 与兄弟工程同构能力抽象（方案级，不在本轮实现）

| 项目 | 建议 |
|---|---|
| 业务价值 | 减少 `go2claude` 与 `go2codex` 平行维护成本，提升一致性 |
| 实施复杂度 | 高 |
| 风险 | 中-高（重构范围大） |
| 预估工时 | 方案评估 2-3 人日，实施另行排期 |
| 影响文件 | 方案文档级，暂不改代码 |
| 验收标准 | 形成共享内核抽象草案（品牌配置、命令品牌化、资源替换策略、测试复用策略）；本轮仅输出评估，不执行大重构 |

---

## 6. 接口级调整建议（Public APIs / Interfaces / Types）

本章用于指导后续实现，当前仅为设计建议，不直接修改现有接口。

### 6.1 `AppSettings` 扩展

建议新增字段：

- `launchPresetId: String`
- `terminalProfile: TerminalProfile`
- `safetyMode: SafetyMode`

建议类型：

```swift
public enum SafetyMode: String, Codable {
    case safeDefault
    case allowDangerousSkipPermissions
}

public enum TerminalProfile: String, Codable {
    case terminal
    case iterm2
    case warp
}

public struct LaunchPreset: Codable, Equatable {
    public let id: String
    public var name: String
    public var commandTemplate: String
    public var isDefault: Bool
}
```

兼容策略：

- 保留旧 key `commandTemplate` 读取能力。
- 首次升级时将旧值迁移为默认 preset。
- 新老结构并存一段版本周期后再移除旧 key（至少一个小版本缓冲）。

### 6.2 `TerminalLaunching` 抽象为策略接口

现状：`TerminalLauncher` 单一实现。

建议：

```swift
public protocol TerminalAdapter {
    var profile: TerminalProfile { get }
    func launch(command: String) throws
}

public struct TerminalDispatcher: TerminalLaunching {
    public init(adapters: [any TerminalAdapter], selected: TerminalProfile)
    public func launch(command: String) throws
}
```

收益：

- 保持 `AppCoordinator` 对外仍依赖 `TerminalLaunching`。
- 终端差异封装在 Adapter 层，降低主流程分支复杂度。

### 6.3 `CommandTemplateRenderer` 增加校验接口

建议新增：

```swift
public struct TemplateValidationResult: Equatable {
    public let isValid: Bool
    public let errors: [TemplateValidationError]
    public let warnings: [TemplateValidationWarning]
}

public enum TemplateValidationError: Equatable {
    case missingPathPlaceholder
    case emptyTemplate
    case unsupportedControlCharacter
}

public func validate(template: String) -> TemplateValidationResult
```

原则：

- `render` 继续负责“渲染 + 强约束”。
- `validate` 负责“预检查 + UI 提示友好化”。

### 6.4 `AppCoordinator` 引入启动上下文对象

建议新增：

```swift
public struct LaunchContext: Equatable {
    public let mode: LaunchMode
    public let triggerSource: TriggerSource
    public let pathSource: PathSource
    public let templateSource: TemplateSource
}
```

建议目标：

- 统一日志字段来源。
- 统一错误反馈语义（例如错误码 + 描述）。
- 降低 `AppDelegate` 侧分支判断复杂度。

### 6.5 `LaunchMode` 保持兼容并预留扩展

建议方向：

- 继续兼容 `config` 参数。
- 将参数解析抽象为可扩展解析器，后续支持 `--mode`、`--path`、`--terminal` 等参数，不破坏既有行为。

---

## 7. 交付里程碑与落地清单

### 7.1 里程碑划分

| 里程碑 | 周期建议 | 目标范围 |
|---|---|---|
| M1 | 第 1-2 周 | 完成 P0：安全默认、权限诊断、模板校验、结构化日志 |
| M2 | 第 3-6 周 | 完成 P1：多模板、多终端（至少 Terminal + iTerm2）、Finder 启动增强、命令引用区升级 |
| M3 | 第 7-10 周 | 完成 P2：配置版本化、发布流水线升级；兄弟工程同构仅完成方案评估 |

### 7.2 每里程碑可发布定义（DoD）

| 里程碑 | DoD |
|---|---|
| M1 DoD | 全量测试通过；默认安全策略生效；关键失败路径具备错误码和引导；日志字段统一 |
| M2 DoD | 新增能力有完整单元测试覆盖；UI 关键路径有回归用例；终端适配回退机制可用 |
| M3 DoD | 发布脚本/流水线可稳定产出可校验制品；配置迁移回归测试通过；运维文档更新完成 |

### 7.3 执行顺序建议

1. 先做 P0，尽快降低风险并提升可诊断性。
2. 再做 P1，优先用户感知强的能力扩展。
3. 最后做 P2，避免过早架构化影响近期交付。

---

## 8. 附录

### 8.1 当前基线命令与结果

```bash
# 全量测试
swift test
# 结果：45 tests, 0 failures

# 构建
swift build

# 打包
./scripts/package_app.sh
# 产物：Go2Claude.app / Go2Claude Toolbar.app / Go2Claude.pkg（可选 zip）
```

### 8.2 关键代码入口索引

| 场景 | 入口文件 |
|---|---|
| 主应用启动与事件编排 | `Sources/Go2Claude/AppDelegate.swift` |
| 启动模式解析 | `Sources/Go2ClaudeCore/LaunchMode.swift` |
| 首启与 Finder 事件路由 | `Sources/Go2ClaudeCore/LaunchRequestRouter.swift` |
| Finder 路径解析 | `Sources/Go2ClaudeCore/FinderPathResolver.swift` |
| 模板渲染与占位符替换 | `Sources/Go2ClaudeCore/CommandTemplateRenderer.swift` |
| 终端启动 | `Sources/Go2ClaudeCore/TerminalLauncher.swift` |
| 配置持久化 | `Sources/Go2ClaudeCore/AppSettings.swift` |
| Finder 工具栏 helper 启动控制 | `Sources/Go2ClaudeToolbar/ToolbarLaunchController.swift` |

### 8.3 本轮范围与非范围

- 本轮范围：`go2claude` 的升级规划与文档产出。
- 非范围：直接修改 `go2codex`；跨仓大规模同构重构实施。

### 8.4 复盘与维护触发条件

满足以下任一条件建议更新本文档：

- 新增终端适配目标（例如 Warp 深度支持）。
- 配置模型发生结构性变化。
- 发布流程引入签名/公证策略变更。
- `AppCoordinator` 或 `AppSettings` 发生公共接口调整。

