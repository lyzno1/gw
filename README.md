# Gw (Git Workflow) - 您的下一代 Git 命令行助手

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Gw (Git Workflow)** 是一款精心设计的 Shell 脚本工具，旨在大幅简化和增强您日常的 Git 操作体验。它不仅仅是 Git 命令的简单别名集合，更是一套经过实战优化的工作流引擎，通过提供一系列直观、高效、连贯的命令，帮助开发者更专注于编码本身，而不是繁琐的 Git 指令。

## ✨ Gw 的设计理念与核心价值

在快节奏的软件开发中，高效的源码管理是成功的关键。然而，原生 Git 命令虽然强大，但其学习曲线陡峭，且日常操作中往往需要组合多个命令来完成一个逻辑单元，容易出错且效率不高。Gw 正是为了解决这些痛点而生。

*   **工作流驱动 (Workflow-Driven)**：Gw 的核心命令（如 `gw new`, `gw save`, `gw sync`, `gw finish`）直接映射了开发中的典型阶段，使得开发者可以像执行自然语言一样完成版本控制。
*   **用户体验至上 (User-Centric)**：通过彩色的输出、清晰的提示信息、交互式的选择以及对常见错误的预判和友好引导，Gw 致力于提供流畅且愉悦的使用体验。
*   **效率提升 (Efficiency Boost)**：将多步 Git 操作封装为单一 Gw 命令，减少记忆负担和重复劳动。例如，`gw new <branch>` 会自动完成基于主干拉取最新代码、创建并切换到新分支的全套动作。
*   **最佳实践内建 (Best Practices Embedded)**：Gw 在设计中融入了诸多 Git 使用的最佳实践，例如：
    *   **Rebase 优先**：默认使用 `rebase` 策略进行代码集成，保持提交历史的整洁与线性。
    *   **提交前检查**：在关键操作（如 `push`, `new`）前检查未提交的变更，并提供处理选项。
    *   **原子化提交引导**：`gw save` 命令鼓励原子化提交，并提供便捷的提交信息编辑方式。
    *   **网络操作重试**：内置推送和拉取重试机制，应对不稳定的网络环境。
*   **安全性与容错性 (Safety & Fault Tolerance)**：对于可能产生破坏性后果的操作（如 `reset`, 分支删除），Gw 会提供额外的确认环节或警告。同时，它也努力处理各种边缘情况，提供清晰的错误反馈。
*   **可扩展与可配置 (Extensible & Configurable)**：
    *   模块化的命令设计（`actions/` 目录），方便添加新的自定义命令。
    *   核心配置（如默认主分支名、远程名、重试次数）可通过环境变量或配置文件 (`core_utils/config_vars.sh`) 进行调整。
    *   新增 `gw config set remote.default <name>` 允许用户动态更新脚本对默认远程的认知。
*   **渐进式学习 (Progressive Learning)**：对于 Git 新手，Gw 提供了一层简化的抽象；对于有经验的用户，Gw 依然允许他们通过参数透传的方式使用原生 Git 的高级功能，并从中受益于 Gw 增强的流程和反馈。

## 🚀 主要功能特性

Gw 提供了一系列精心设计的命令来覆盖您开发周期的方方面面：

### 仓库初始化与配置
*   `gw init [...]`: 快速初始化 Git 仓库，可附加原生 `git init` 参数。
*   `gw config <user> <email>`: 一键设置本地仓库的用户名和邮箱。
*   `gw config set remote.default <name>`: **[新]** 更新 Gw 脚本内部配置的默认远程仓库名称。
*   `gw config [...]`: 无缝透传至原生 `git config`，支持所有原生配置操作。
*   `gw remote [...]`: 原生 `git remote` 包装器，方便管理远程仓库。
*   `gw gh-create [repo] [...]`: **[增强]** 在 GitHub 上创建新仓库，并自动关联到本地，支持设置可见性、描述、自定义本地远程名，并处理远程名已存在的情况。

### 核心开发工作流
*   `gw new <branch> [--base <base>] [--local]`:\
    *   基于指定的基础分支（默认主分支）创建并切换到新的开发分支。\
    *   自动从远程拉取基础分支的最新代码（使用 rebase）。\
    *   **[增强]** 如果当前有未提交更改，会提示用户暂存 (stash) 并可在新分支创建后尝试恢复。\
    *   `--local`: 跳过拉取，基于本地基础分支状态创建。
*   `gw save [-m "msg"] [-e] [files...]`:\
    *   快速添加指定文件（默认全部已修改/新增文件）并提交。\
    *   无 `-m` 或 `-e` (强制编辑器) 时，进入交互式提交信息编辑模式（打开 `$EDITOR` 或命令行提示）。
*   `gw sync`:\
    *   **[增强]** 智能同步当前分支：\
        *   若在特性分支：自动切换到主分支，拉取最新（使用 rebase），切换回特性分支，然后将特性分支 rebase 到最新的主分支上。\
        *   若在主分支：直接拉取远程主分支的最新代码（使用 rebase）。\
        *   **[增强]** 操作前检查未提交更改，并提示用户暂存。
*   `gw finish [--no-switch] [--pr]`:\
    *   完成当前分支的开发周期。\
    *   **[增强]** 自动检查并提示处理未提交的变更（通过 `gw save` 逻辑）。\
    *   推送当前分支到远程（自动处理 `-u`）。\
    *   `--pr`: 推送后尝试使用 `gh` CLI 创建 GitHub Pull Request。\
    *   `--no-switch`: 完成后不自动切换回主分支。
*   `gw main` / `gw master [...]`: 快速推送主分支到远程（可附加原生 `git push` 参数）。

### 常用 Git 操作便捷封装
*   `gw status [-r] [-l]`: 增强版 `git status` (未来可集成更多信息)。
*   `gw add [files...]`: 交互式文件选择（无参数时）或直接 `git add`。
*   `gw add-all`: 执行 `git add -A`。
*   `gw commit [...]`: 原生 `git commit` 包装器，保留其所有参数功能，并与 `gw save` 的提交信息处理逻辑一致。
*   `gw pull [remote] [branch] [...]`:\
    *   **[核心增强]** 默认使用 `--rebase` 策略拉取远程更新，保持历史线性。\
    *   用户可通过 `--no-rebase` 或 `--ff-only` 等参数覆盖默认行为。\
    *   内置网络重试机制。
*   `gw push [remote] [branch] [...]`:\
    *   增强版 `git push`，自动处理首次推送时的 `-u` (set-upstream)。\
    *   内置网络重试机制。\
    *   **[增强]** 推送前检查未提交变更，并引导用户处理。
*   `gw fetch [...]`: 原生 `git fetch` 包装器，带重试。

### 分支管理
*   `gw branch`:\
    *   **[增强]** 无参数时，显示美化过的本地和远程分支列表，包含最新提交信息、作者、相对时间，当前分支高亮。
*   `gw branch [...]`:\
    *   带参数时，作为原生 `git branch` 的智能包装器，支持 `-a`, `-r`, `-d <name>`, `-D <name>`, `-m <old> <new>` 等操作，并对删除/重命名操作提供额外上下文提示。
*   `gw checkout <branch>` / `gw switch <branch>` / `gw co <branch>`: 切换分支，操作前检查未提交变更。
*   `gw merge <source> [...]`: 原生 `git merge` 包装器。
*   `gw rm <branch|all> [-f]`: 更安全和强大的分支删除命令，支持删除远程分支，`all` 选项可用于清理所有已合并到主干的非保护分支。

### 历史与差异
*   `gw log [...]`: 原生 `git log` 包装器，带分页。
*   `gw diff [...]`: 原生 `git diff` 包装器。
*   `gw reset <target> [...]`: **[安全增强]** 对 `git reset` 的包装，特别是对 `--hard` 等危险操作提供额外确认。

### 兼容旧版 (gp) 推送命令
*   `gw 1 <branch>` / `gw first <branch>`: 首次推送指定分支 (带 `-u`)。
*   `gw 2`: 推送主分支。
*   `gw 3 <branch>` / `gw other <branch>`: 推送已存在的指定分支 (不带 `-u`)。
*   `gw 4` / `gw current`: 推送当前分支 (自动处理 `-u`)。

### 其他
*   `gw help`: 显示详细的帮助信息。

## 🛠️ 安装与使用

1.  **克隆仓库或下载脚本**:\
    ```bash
    git clone <gw_repository_url> # 替换为实际的仓库 URL
    cd gw_repository_directory/脚本
    ```
    或者直接下载 `git_workflow.sh` 和整个 `core_utils`、`actions` 目录。

2.  **给予执行权限**:\
    ```bash
    chmod +x git_workflow.sh
    chmod +x actions/*.sh
    chmod +x core_utils/*.sh 
    ```
    (注意: `core_utils` 下的文件主要是被 source，不直接执行，但赋予权限无害)

3.  **添加到 PATH 或创建别名 (推荐)**:\
    *   **添加到 PATH**: 将包含 `git_workflow.sh` 的目录（例如 `/path/to/your/gw_repository_directory/脚本`）添加到您的 `$PATH` 环境变量中。\
        ```bash
        # 例如，在 ~/.bashrc 或 ~/.zshrc 中添加:
        export PATH="/path/to/your/gw_repository_directory/脚本:$PATH"
        ```
    *   **创建别名**: 在您的 shell 配置文件中（如 `~/.bashrc`, `~/.zshrc`）添加一个别名：\
        ```bash
        alias gw="/path/to/your/gw_repository_directory/脚本/git_workflow.sh"
        ```
    修改配置文件后，记得运行 `source ~/.bashrc` (或对应的文件) 或重启终端。

4.  **验证安装**:\
    ```bash
    gw help
    ```
    如果看到帮助信息，说明安装成功！

5.  **（可选）安装依赖**:\
    *   `gh` (GitHub CLI): `gw gh-create` 和 `gw finish --pr` 功能需要。请参考 [GitHub CLI 安装文档](https://cli.github.com/)。\
    *   `GNU getopt`: 在 macOS 等使用 BSD getopt 的系统上，为了获得 `gw new` 等命令的完整长选项支持（如 `--base`），建议安装 GNU getopt。\
        ```bash
        brew install gnu-getopt 
        # 可能需要将其添加到 PATH，或者脚本会提示使用基础参数解析
        ```

## 💡 如何贡献

我们欢迎各种形式的贡献！无论是 bug 修复、功能增强、文档改进还是新的想法，请随时通过以下方式参与：

1.  **提交 Issue**: 发现 bug 或有功能建议？请在项目的 Issue 跟踪系统中提交。
2.  **发起 Pull Request**:\
    *   Fork 本仓库。\
    *   创建您的特性分支 (`gw new feat/amazing-feature`)。\
    *   遵循项目的 [Git 提交信息规范](COMMIT_CONVENTION.md) 进行提交。\
    *   确保您的更改通过了所有测试（如果有）。\
    *   推送您的分支 (`gw push origin feat/amazing-feature`)。\
    *   发起 Pull Request。

## 📜 许可证

本项目采用 [MIT 许可证](LICENSE.txt)授权。 (如果还没有 LICENSE.txt，后续可以添加一个标准的 MIT 许可证文本)

---

**Gw - 让 Git 更简单，让开发更专注！**
我们相信 Gw 能成为您 Git 工具箱中不可或缺的一员。立即体验，感受高效 Git 工作流的魅力！ 