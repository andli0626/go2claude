# Command Reference Terminal Actions Design

**Background**

设置页右侧“配置说明”已经展示了四类常用命令，但当前只能阅读或手动复制，无法直接用于快速打开。

**Goal**

为每条配置说明增加终端小图标，点击后直接打开 Terminal 并执行对应命令，形成真正可用的快捷入口。

**Approved Direction**

采用单击直接执行方案：

- 每条配置说明右上角增加一个终端图标按钮。
- 含 `%PATH%` 的说明项在执行前先解析当前 Finder 路径，再渲染成真实命令。
- 不含 `%PATH%` 的说明项按字面命令直接执行。
- 执行失败时继续复用设置页现有的橙色错误提示条。

**Interaction Design**

- 图标按钮位于每条说明项的标题行右侧。
- 按钮使用轻量圆角胶囊/圆形样式，hover 时有背景高亮。
- 按钮命中区域不小于 44x44，便于点击。
- 为按钮增加 tooltip 和无障碍标签，说明“在终端中运行”。

**Architecture**

- `SettingsView` 负责展示说明项和发出“执行该命令”的回调。
- `AppDelegate` 负责区分“模板命令”和“字面命令”，并统一处理执行失败后的消息反馈。
- `AppCoordinator` 扩展为可执行任意模板命令和任意字面 Shell 命令，继续复用 `FinderPathResolver`、`CommandTemplateRenderer`、`TerminalLauncher`。

**Testing**

- 为 `AppCoordinator` 增加模板命令和字面命令执行测试。
- 为 `AppDelegate` 增加说明项点击后的命令分发测试。
- 跑完整 `swift test` 与 `swift build` 作为最终验证。
