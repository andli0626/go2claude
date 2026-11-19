# Go2Claude 用户使用指南

## 产品概述

Go2Claude 是一款轻量级 macOS 实用工具，灵感来自 Go2Shell。它提供了一种快速从 Finder 工具栏启动 Claude CLI 的方法，让您可以在当前文件夹中直接进入 Claude 终端界面。

### 主要功能

- **快速启动**：在 Finder 工具栏添加按钮，一键进入 Claude CLI
- **智能路径检测**：自动获取当前 Finder 窗口路径
- **可配置命令**：支持自定义命令模板，满足不同需求
- **安装检测**：首次启动自动检查 Claude CLI 是否已安装
- **安全提示**：提供详细的安装和使用指导

## 系统要求

- macOS 13.0 或更高版本
- Claude CLI 已安装并可在 shell 环境中调用
- 终端应用程序（Terminal.app）

## 安装方法

### 方法一：使用 .pkg 安装包（推荐）

1. 下载 Go2Claude.pkg 安装包
2. 双击打开安装包，按照向导完成安装
3. 安装完成后，应用程序将位于 `/Applications` 文件夹中

### 方法二：使用 .zip 压缩包

1. 下载 Go2Claude-macOS-universal-<version>.zip 压缩包
2. 解压文件
3. 将 `Go2Claude.app` 和 `Go2Claude Toolbar.app` 拖到 `/Applications` 文件夹

## 首次使用设置

### 1. 打开主应用程序

- 方法一：在 Finder 中导航到 `/Applications` 文件夹，双击 `Go2Claude.app`
- 方法二：使用 Spotlight 搜索 "Go2Claude" 并打开

### 2. 检查安装状态

首次打开应用程序时，会自动检查您的系统是否已安装 Claude CLI。如果未安装，会显示安装指引。

### 3. 配置命令模板

1. 在主界面中，您可以看到当前的命令模板
2. 默认模板：`cd %PATH% && claude --dangerously-skip-permissions`
3. 如果需要修改，可直接在文本框中编辑
4. 确保命令模板包含 `%PATH%` 占位符，它会被替换为当前 Finder 路径

### 4. 添加到 Finder 工具栏

1. 在主界面中点击「查看如何添加到 Finder 工具栏」按钮
2. 在 Finder 中，选择「显示 > 自定义工具栏...」
3. 找到 `Go2Claude Toolbar.app`（位于 `/Applications` 文件夹）
4. 按住 Command 键，将应用程序图标拖到 Finder 工具栏
5. 点击「完成」保存更改

## 基本使用方法

### 从 Finder 工具栏启动

1. 打开 Finder 窗口并导航到您想要工作的文件夹
2. 点击 Finder 工具栏上的 Go2Claude 按钮
3. Terminal.app 会自动打开，并在当前文件夹中启动 Claude CLI

### 从主应用程序启动

1. 打开 `Go2Claude.app`
2. 点击「打开 Claude 终端」按钮
3. Terminal.app 会在默认位置启动 Claude CLI

### 打开设置界面

- 方法一：直接双击 `Go2Claude.app`
- 方法二：使用命令 `open -a Go2Claude`
- 方法三：使用兼容的配置命令 `open -a Go2Claude --args config`

## 高级配置

### 命令模板定制

Go2Claude 支持自定义命令模板，您可以根据需要修改。

#### 默认模板

```bash
cd %PATH% && claude --dangerously-skip-permissions
```

#### 开发模式

```bash
cd %PATH% && claude
```

#### 自定义模板示例

```bash
cd %PATH% && clear && claude
```

### 重要提示

- `%PATH%` 是必需的占位符，会被替换为当前 Finder 路径
- 命令模板必须包含有效的 shell 命令
- 确保命令模板的语法正确，否则可能导致启动失败

## 故障排除

### 问题 1：应用程序无法打开

**症状**：双击应用程序时，系统提示无法打开或无法验证开发者。

**解决方法**：

1. 打开「系统设置 > 隐私与安全性」
2. 在页面下方找到与 Go2Claude 相关的安全提示
3. 点击「仍要打开」按钮
4. 再次尝试打开应用程序

### 问题 2：Finder 工具栏按钮不工作

**症状**：点击工具栏按钮没有反应。

**解决方法**：

1. 检查 `Go2Claude Toolbar.app` 是否正确安装在 `/Applications` 文件夹
2. 确保应用程序有足够的权限
3. 尝试删除并重新添加工具栏按钮
4. 检查自动化权限是否已授权

### 问题 3：Claude CLI 未找到

**症状**：终端提示 "claude: command not found"。

**解决方法**：

1. 确保已安装 Claude CLI
2. 检查 Claude CLI 是否已添加到系统 PATH 中
3. 在主界面中点击安装指引链接，按照说明安装

### 问题 4：权限不足

**症状**：无法读取 Finder 路径或启动终端。

**解决方法**：

1. 打开「系统设置 > 隐私与安全性 > 自动化」
2. 确保 Go2Claude 已被授权访问 Finder 和 Terminal
3. 如果没有权限，点击 "+" 按钮添加应用程序并授权

## 常见问题

### 问：Go2Claude 是否支持其他终端应用程序？

答：目前 Go2Claude 仅支持 Apple 的 Terminal.app。

### 问：命令模板中的 %PATH% 是如何工作的？

答：%PATH% 是一个占位符，会被当前 Finder 窗口的路径替换。例如，如果您在 `/Users/用户名/Documents/项目` 文件夹中，%PATH% 会被替换为该路径。

### 问：我可以自定义命令模板吗？

答：是的，您可以在主界面中直接编辑命令模板。请确保模板包含 %PATH% 占位符。

### 问：为什么需要 --dangerously-skip-permissions 参数？

答：这个参数允许 Claude CLI 在没有额外权限检查的情况下运行，简化了使用流程。如果您需要更严格的安全设置，可以使用开发模式。

## 安全注意事项

- Go2Claude 是一个非官方的第三方工具，与 Anthropic 或 Claude 官方没有任何关联
- 命令模板会在您的系统上执行 shell 命令，请确保您信任命令的安全性
- 如果您计划在敏感环境中使用，请自行评估风险并采取适当的安全措施

## 更新与支持

### 检查更新

- 定期查看项目发布页面获取最新版本
- 更新时，请先移除旧的工具栏按钮，再添加新版本

### 反馈与建议

如果您在使用过程中遇到问题或有改进建议，欢迎通过以下方式联系我们：

- 提交 GitHub 问题
- 发送邮件到开发者邮箱
- 参与项目讨论

## 许可证

Go2Claude 采用 MIT 许可证，您可以自由使用、修改和分发。
