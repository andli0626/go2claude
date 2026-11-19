# Settings Layout Refresh Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 修复设置页顶部标题被遮挡的问题，突出显示“立即打开 Claude”主按钮，并优化整体页面信息分组与布局层级。

**Architecture:** 保留现有单窗口 SwiftUI 页面结构，在 `SettingsView` 中重组为欢迎区、命令编辑区、主次操作区和说明卡片区四个层级；同时调高窗口默认高度并加入更稳妥的顶部留白，避免内容被标题栏挤压。

**Tech Stack:** Swift 6.2, SwiftUI, AppKit, XCTest

---

### Task 1: 为设置窗口高度与内容适配补失败测试

**Files:**
- Modify: `Tests/Go2ClaudeAppTests/FinderLaunchPathResolverTests.swift`
- Create: `Tests/Go2ClaudeAppTests/SettingsWindowControllerTests.swift`

**Step 1: Write the failing test**

- 创建 `SettingsWindowControllerTests`，验证设置窗口默认内容高度足够容纳设置页内容，并为后续布局调整留出顶部安全空间。

**Step 2: Run test to verify it fails**

Run: `swift test --filter SettingsWindowControllerTests`
Expected: FAIL，当前窗口高度不足或未满足新的布局要求。

**Step 3: Write minimal implementation**

- 在设置窗口控制器和设置页中引入新的内容高度、顶部留白与滚动容器配置。

**Step 4: Run test to verify it passes**

Run: `swift test --filter SettingsWindowControllerTests`
Expected: PASS

### Task 2: 重排设置页结构并突出主按钮

**Files:**
- Modify: `Sources/Go2Claude/SettingsView.swift`

**Step 1: Write the failing test**

- 复用任务 1 的失败测试作为布局回归门禁，并在需要时补充针对信息分组或视图配置的单元测试。

**Step 2: Run test to verify it fails**

Run: `swift test --filter SettingsWindowControllerTests`
Expected: FAIL

**Step 3: Write minimal implementation**

- 将页面重构为：
  - 欢迎区：标题、副标题、Finder 工具栏引导按钮
  - 命令编辑卡片：标题、输入框、校验提示
  - 操作区：突出“立即打开 Claude”主按钮，其他按钮作为次级操作
  - 说明区：用更清晰的卡片式分组展示命令示例

**Step 4: Run test to verify it passes**

Run: `swift test --filter SettingsWindowControllerTests`
Expected: PASS

### Task 3: 完整回归验证

**Files:**
- Modify: `Sources/Go2Claude/SettingsView.swift`
- Modify: `Sources/Go2Claude/SettingsWindowController.swift`
- Create: `Tests/Go2ClaudeAppTests/SettingsWindowControllerTests.swift`

**Step 1: Run focused tests**

Run: `swift test --filter SettingsWindowControllerTests`

**Step 2: Run full test suite**

Run: `swift test`

**Step 3: Run build verification**

Run: `swift build`
