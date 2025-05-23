# 在 macOS 上手动设置 `code` 命令指向 Visual Studio Code

本文档提供了一个简明指南，说明如何在 macOS 系统上手动创建或修复 `code` 命令的符号链接，以确保它正确指向您期望的 Visual Studio Code (VS Code) 应用程序。

## 为什么可能需要手动设置？

通常，Visual Studio Code 应用内部提供了通过命令面板（`Cmd+Shift+P` 或 `Ctrl+Shift+P`）运行 "Shell Command: Install 'code' command in PATH" 的功能来自动完成此设置。但有时，这个自动过程可能会因为以下原因失败或未按预期工作：

1.  **权限问题**：在 `/usr/local/bin`（`code` 命令通常安装在此）等系统目录下创建或修改文件需要管理员权限。如果 VS Code 未能成功获取这些权限（例如，用户取消了密码提示，或系统安全策略阻止），安装可能会失败，并可能提示 `EACCES: permission denied` 之类的错误。
2.  **与其他应用的冲突**：如果您安装了其他也尝试注册 `code` 命令的应用程序（例如某些 VS Code 的衍生版，如 Cursor），它们可能覆盖了官方 VS Code 的设置，或者在您的 `PATH` 环境变量中具有更高的优先级。
3.  **`PATH` 环境变量配置不当**。

当 `code` 命令没有正确指向您期望的 VS Code 应用时，从终端运行 `code` 或 `code --wait` 可能会启动错误的编辑器，或者根本找不到命令。这也会影响依赖此命令的工具（如 `gw save` 在使用 `vscode` 作为偏好编辑器时）。

## 手动设置步骤

以下步骤将引导您通过终端手动创建符号链接：

**1. 找到您的 Visual Studio Code 的 `code` CLI 工具的实际路径**

   对于标准的 Visual Studio Code 安装，此工具通常位于应用程序包内部。您可以通过以下路径找到它：
   `"/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"`

   *   **重要**：请务必将上述路径替换为您系统中 **实际的、您期望使用的 Visual Studio Code 应用程序** 的对应路径。
   *   如果您使用的是 VS Code Insiders 版本，其路径和命令名称可能会有所不同（例如，命令可能是 `code-insiders`，路径中可能是 `Visual Studio Code - Insiders.app`）。
   *   您可以通过在访达 (Finder) 中右键点击 VS Code 应用程序，选择"显示包内容"，然后导航到 `Contents/Resources/app/bin/` 目录来确认 `code` 脚本是否存在及其确切位置。

**2. 打开终端应用程序**

   您可以在"应用程序" -> "实用工具"中找到它，或通过 Spotlight 搜索（`Cmd+Space` 然后输入 `Terminal`）。

**3. (可选) 检查并移除 `/usr/local/bin/code` 的旧链接或文件**

   在创建新链接之前，最好检查一下 `/usr/local/bin/code` 是否已存在，以及它当前是什么状态。
   ```bash
   ls -l /usr/local/bin/code
   ```
   *   如果该文件存在并且是一个指向错误应用程序的符号链接（例如，指向 Cursor），或者是一个您不期望的文件，您应该先将其移除。
   *   **警告**：移除文件请务必小心。如果您不确定，可以先备份。
   *   要移除它，请使用 `sudo`（因为 `/usr/local/bin` 通常需要管理员权限）：
     ```bash
     sudo rm /usr/local/bin/code
     ```
     系统会提示您输入您的 macOS 用户密码。

**4. 创建新的符号链接**

   现在，使用 `ln -s` 命令创建一个新的符号链接，从 `/usr/local/bin/code` 指向您在步骤 1 中找到的 VS Code CLI 工具的实际路径。同样，这需要 `sudo`：
   ```bash
   sudo ln -s "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" /usr/local/bin/code
   ```
   *(再次提醒：请确保将引号中的路径替换为您的实际路径！)*

**5. 重启终端并验证**

   *   **非常重要**：为了使新的符号链接和 `PATH` 设置能够被当前终端会话识别，您需要**完全关闭当前的终端窗口/标签页，并重新打开一个新的终端会话**。
   *   在新的终端窗口中，运行以下命令进行验证：
     *   `which code`
       这应该输出 `/usr/local/bin/code`。
     *   `ls -l /usr/local/bin/code`
       这应该显示它是一个符号链接，并指向您在步骤 4 中指定的 VS Code 内部路径。
     *   `code --version`
       这应该显示您期望的 Visual Studio Code 的版本信息。
     *   尝试用 `code .` 或 `code --wait somefile.txt` 打开一个项目或文件，确认它是否启动了正确的 VS Code 应用。

完成这些步骤后，您系统中的 `code` 命令应该就能正确地指向并启动您期望的 Visual Studio Code 应用程序了。依赖此命令的工具（如 `gw`）也应该能按预期工作。

## 注意事项

*   **管理员权限**：执行 `sudo rm` 和 `sudo ln -s` 命令时，您需要提供您的 macOS 用户密码。
*   **路径准确性**：请务必确保您在 `ln -s` 命令中使用的 VS Code CLI 工具的源路径是完全正确的。错误的路径将导致链接无效。
*   **`PATH` 环境变量**：`/usr/local/bin` 目录通常应该在您的 `PATH` 环境变量中。如果不在，您可能还需要将其添加到您的 shell 配置文件（如 `~/.zshrc` 或 `~/.bashrc`）中，例如 `export PATH="/usr/local/bin:$PATH"`，然后重新加载配置文件或重启终端。但对于大多数 macOS 系统，`/usr/local/bin` 默认就在 `PATH` 中。

希望这份指南能帮助您解决问题！

## 如何为 Cursor 设置全局符号链接

如果你使用 [Cursor](https://www.cursor.so/) 编辑器，并希望像 VS Code 一样通过命令行全局调用 `cursor` 命令，可以按照以下步骤操作：

1. **找到 Cursor 的 CLI 工具路径**

   Cursor 的命令行工具通常位于：
   `/Applications/Cursor.app/Contents/Resources/app/bin/cursor`

   > 路径结构和 VS Code 完全一致，只是应用名称不同。

2. **创建全局符号链接**

   在终端中执行以下命令，将 `cursor` 命令链接到 `/usr/local/bin/`，这样你可以在任意终端窗口直接输入 `cursor` 调用 Cursor：

   ```bash
   sudo ln -s "/Applications/Cursor.app/Contents/Resources/app/bin/cursor" /usr/local/bin/cursor
   ```
   > 如有同名旧链接，建议先 `sudo rm /usr/local/bin/cursor` 再执行上述命令。

3. **验证**

   关闭并重新打开终端，执行：
   ```bash
   which cursor
   cursor --version
   ```
   应该分别输出 `/usr/local/bin/cursor` 和 Cursor 的版本号。

4. **用法示例**

   - 直接用 `cursor .` 打开当前目录
   - 用 `cursor --wait 文件名` 让命令行等待你编辑完成（适用于 git、gw save 等自动化脚本）

> 这样设置后，依赖 `cursor` 命令的工具和脚本都能全局调用 Cursor 编辑器。
