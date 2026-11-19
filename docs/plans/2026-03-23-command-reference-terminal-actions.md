# Command Reference Terminal Actions Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 为设置页每条“配置说明”增加终端图标按钮，点击后直接打开 Terminal 并执行对应命令。

**Architecture:** 在 `SettingsView` 的说明项模型中补上快捷执行入口，通过新的回调把命令交给 `AppDelegate`；`AppDelegate` 再根据命令是否包含 `%PATH%` 决定走模板渲染执行还是字面 Shell 执行，底层统一复用 `AppCoordinator` 和 `TerminalLauncher`。

**Tech Stack:** Swift 6.2, SwiftUI, AppKit, XCTest, AppleScript

---

### Task 1: 为命令执行分发补失败测试

**Files:**
- Modify: `Tests/Go2ClaudeCoreTests/AppCoordinatorTests.swift`
- Modify: `Tests/Go2ClaudeAppTests/AppDelegateTests.swift`

**Step 1: Write the failing test**

- 为 `AppCoordinator` 增加：
  - 模板命令会先解析 Finder 路径再执行
  - 字面命令会直接交给终端启动器执行
- 为 `AppDelegate` 增加：
  - 含 `%PATH%` 的说明项会走模板命令执行
  - 普通命令会走字面命令执行

**Step 2: Run test to verify it fails**

Run: `swift test --filter AppCoordinatorTests`
Run: `swift test --filter AppDelegateTests`
Expected: FAIL，因缺少新的命令执行 API 和分发逻辑。

**Step 3: Write minimal implementation**

- 扩展核心协调器与 `AppDelegate` 的说明项执行逻辑。

**Step 4: Run test to verify it passes**

Run: `swift test --filter AppCoordinatorTests`
Run: `swift test --filter AppDelegateTests`
Expected: PASS

### Task 2: 为说明项增加终端图标按钮

**Files:**
- Modify: `Sources/Go2Claude/SettingsView.swift`
- Modify: `Sources/Go2Claude/AppDelegate.swift`

**Step 1: Write the failing test**

- 使用任务 1 的失败测试作为行为门禁。

**Step 2: Run test to verify it fails**

Run: `swift test --filter AppDelegateTests`
Expected: FAIL

**Step 3: Write minimal implementation**

- 为说明项增加终端图标按钮、tooltip、无障碍标签和点击回调。

**Step 4: Run test to verify it passes**

Run: `swift test --filter AppDelegateTests`
Expected: PASS

### Task 3: 完整验证

**Files:**
- Modify: `Sources/Go2ClaudeCore/AppCoordinator.swift`
- Modify: `Sources/Go2Claude/AppDelegate.swift`
- Modify: `Sources/Go2Claude/SettingsView.swift`
- Modify: `Tests/Go2ClaudeCoreTests/AppCoordinatorTests.swift`
- Modify: `Tests/Go2ClaudeAppTests/AppDelegateTests.swift`

**Step 1: Run focused tests**

Run: `swift test --filter AppCoordinatorTests`
Run: `swift test --filter AppDelegateTests`

**Step 2: Run full suite**

Run: `swift test`

**Step 3: Run build verification**

Run: `swift build`
