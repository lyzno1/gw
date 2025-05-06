[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

***`gw` (Git Workflow) v3.0：告别繁琐，拥抱流畅——您的智能 Git 工作流引擎***

**您是否还在经历这些 Git "痛点"？**

- **命令冗长难记？** 每天敲打大量相似的 Git 命令序列？
- **流程易错不规范？** 团队成员 Git 操作五花八门，主干历史混乱不堪？
- **网络波动心惊胆战？** 一次 `push` 或 `pull` 失败就得手动重试，打断心流？
- **重复劳动效率低？** 创建分支、同步代码、完成合并前准备... 每次都是一套固定却繁琐的动作？

**现在，是时候升级您的 Git 体验了！隆重推出 `gw` v3.0 —— 为现代开发流程量身打造的增强版 Git 工作流助手！**

**【设计初衷：化繁为简，聚焦价值】**

`gw` 的诞生源于一个简单的信念：**Git 应当是开发的助力，而非阻力。** 我们观察到开发者在日常版本控制中耗费了大量精力在重复、易错的底层命令上。`gw` 旨在将行业内的 **Git 最佳实践** 与 **高效工作流** 相结合，通过一层智能封装，让开发者能将更多时间投入到真正创造价值的编码工作中。

**【核心设计理念：流畅、规范、健壮、智能】**

1.  **流程驱动，一键直达 (Workflow-Centric Automation):**
    `gw` 不仅仅是命令别名，它**内嵌了一套推荐的开发生命周期**。从 `gw new`（智能创建并同步分支）到 `gw sync`（一键保持与主干同步并采用 rebase 保持历史整洁），再到 `gw finish`（自动化完成、推送、准备PR），`gw` 将多步操作融合成**单一、符合直觉的命令**，引导您顺畅地完成开发循环。
2.  **体验至上，交互友好 (User Experience First):**
    告别冰冷的黑白终端！`gw` 采用**丰富的彩色高亮**，清晰标示操作状态。
    在关键节点（如切换分支有未提交变更、删除分支等）提供**智能交互提示与确认**，有效防止误操作。
    创新的 `gw commit`/`gw save` 默认提交流程，在便捷与规范间取得平衡，同时也**兼容标准的 `m` 和编辑器模式**，满足不同习惯。
3.  **健壮可靠，无惧干扰 (Robust & Reliable):**
    内置强大的 `push`/`pull` **自动重试机制**，显著提高在不稳定网络环境下的操作成功率，让您不再为此分心。
    操作前的**安全检查**（如未提交检查）进一步保障代码和仓库的稳定。所有核心推送操作（包括旧版别名）均享有此保障。
4.  **规范协作，整洁历史 (Standardization & Clean History):**
    通过 `gw sync` 默认采用 `rebase` 策略，`gw` 鼓励团队成员在合并前整理提交，最终**汇聚成清晰、线性的主干历史**，极大提升代码库的可维护性和可读性。
    为团队提供一套**标准、易学的命令集**，降低沟通成本，加速新成员融入。
5.  **可扩展与可配置 (Extensible & Configurable)**：
    *   模块化的命令设计（`actions/` 目录），方便添加新的自定义命令。
    *   核心配置（如默认主分支名、远程名、重试次数）可通过环境变量或配置文件 (`core_utils/config_vars.sh`) 进行调整。
    *   新增 `gw config set remote.default <name>` 允许用户动态更新脚本对默认远程的认知。
6.  **渐进式学习 (Progressive Learning)**：对于 Git 新手，Gw 提供了一层简化的抽象；对于有经验的用户，Gw 依然允许他们通过参数透传的方式使用原生 Git 的高级功能，并从中受益于 Gw 增强的流程和反馈。


**【选择 `gw`，您将获得：】**

- **效率倍增**：大幅减少敲打 Git 命令的时间和心智负担。
- **错误骤减**：智能提示和检查，让常见 Git 错误成为过去。
- **团队协同升级**：统一工作流程，提升团队整体战斗力。
- **代码库更健康**：拥有易于理解和追溯的高质量提交历史。
- **更自信、流畅的 Git 使用体验**！

**`gw` 是为谁设计的？**

- 追求极致效率的**每一位开发者**。
- 希望规范团队 Git 使用、提升协作水平的**技术负责人与团队**（尤其适合中小型团队快速落地标准化流程）。
- 渴望简化 Git 操作，专注于业务逻辑实现的**工程师**。

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
*   `gw new <branch> [--base <base>] [--local]`:
    *   基于指定的基础分支（默认主分支）创建并切换到新的开发分支。
    *   自动从远程拉取基础分支的最新代码（使用 rebase）。
    *   **[增强]** 如果当前有未提交更改，会提示用户暂存 (stash) 并可在新分支创建后尝试恢复。
    *   `--local`: 跳过拉取，基于本地基础分支状态创建。
*   `gw save [-m "msg"] [-e] [files...]`:
    *   快速添加指定文件（默认全部已修改/新增文件）并提交。
    *   无 `-m` 或 `-e` (强制编辑器) 时，进入交互式提交信息编辑模式（打开 `$EDITOR` 或命令行提示）。
*   `gw sync`:
    *   **[增强]** 智能同步当前分支：
        *   若在特性分支：自动切换到主分支，拉取最新（使用 rebase），切换回特性分支，然后将特性分支 rebase 到最新的主分支上。
        *   若在主分支：直接拉取远程主分支的最新代码（使用 rebase）。
        *   **[增强]** 操作前检查未提交更改，并提示用户暂存。
*   `gw finish [--no-switch] [--pr]`:
    *   完成当前分支的开发周期。
    *   **[增强]** 自动检查并提示处理未提交的变更（通过 `gw save` 逻辑）。
    *   推送当前分支到远程（自动处理 `-u`）。
    *   `--pr`: 推送后尝试使用 `gh` CLI 创建 GitHub Pull Request。
    *   `--no-switch`: 完成后不自动切换回主分支。
*   `gw main` / `gw master [...]`: 快速推送主分支到远程（可附加原生 `git push` 参数）。

### 常用 Git 操作便捷封装
*   `gw status [-r] [-l]`: 增强版 `git status` (未来可集成更多信息)。
*   `gw add [files...]`: 交互式文件选择（无参数时）或直接 `git add`。
*   `gw add-all`: 执行 `git add -A`。
*   `gw commit [...]`: 原生 `git commit` 包装器，保留其所有参数功能，并与 `gw save` 的提交信息处理逻辑一致。
*   `gw pull [remote] [branch] [...]`:
    *   **[核心增强]** 默认使用 `--rebase` 策略拉取远程更新，保持历史线性。
    *   用户可通过 `--no-rebase` 或 `--ff-only` 等参数覆盖默认行为。
    *   内置网络重试机制。
*   `gw push [remote] [branch] [...]`:
    *   增强版 `git push`，自动处理首次推送时的 `-u` (set-upstream)。
    *   内置网络重试机制。
    *   **[增强]** 推送前检查未提交变更，并引导用户处理。
*   `gw fetch [...]`: 原生 `git fetch` 包装器，带重试。

### 分支管理
*   `gw branch`:
    *   **[增强]** 无参数时，显示美化过的本地和远程分支列表，包含最新提交信息、作者、相对时间，当前分支高亮。
*   `gw branch [...]`:
    *   带参数时，作为原生 `git branch` 的智能包装器，支持 `-a`, `-r`, `-d <name>`, `-D <name>`, `-m <old> <new>` 等操作，并对删除/重命名操作提供额外上下文提示。
*   `gw checkout <branch>` / `gw switch <branch>` / `gw co <branch>`: 切换分支，操作前检查未提交变更。
*   `gw merge <source> [...]`: 原生 `git merge` 包装器。
*   `gw rm <branch|all> [-f] [--delete-remotes]`:
    *   **[增强]** 更安全和强大的分支删除。
    *   `gw rm <branch_name> [-f] [--delete-remotes]`: 删除指定的本地分支。
        *   `-f`: 强制删除本地分支。
        *   `--delete-remotes`: 自动删除对应的远程分支。优先删除已跟踪的远程分支；若无跟踪信息，则尝试删除 `$REMOTE_NAME/<branch_name>`。
        *   若不指定 `--delete-remotes`，但在删除本地分支后检测到远程分支存在，会提示用户确认是否删除（使用与上相同的远程分支查找逻辑）。
    *   `gw rm all [-f] [--delete-remotes]`: 清理所有已合并到主分支的本地分支（需在主分支运行）。
        *   `--delete-remotes`: 同时删除所有匹配的远程分支。
    *   在所有模式下，无法识别的参数将被警告并忽略。

### 历史与差异
*   `gw log [...]`: 原生 `git log` 包装器，带分页。
*   `gw diff [...]`: 原生 `git diff` 包装器。
*   `gw reset <target> [...]`: **[安全增强]** 对 `git reset` 的包装，特别是对 `--hard` 等危险操作提供额外确认。

### 兼容旧版 (gp) 推送命令
*   `gw 1 <branch>` / `gw first <branch>`: 首次推送指定分支 (带 `-u`)。
*   `gw 2`: 推送主分支。
*   `gw 3 <branch>` / `gw other <branch>`: 推送已存在的指定分支 (不带 `-u`)。
*   `gw 4` / `gw current`: 推送当前分支 (自动处理 `-u`)。
*   (所有这些推送别名现在都经过统一的 `cmd_push` 逻辑，包括未提交变更检查等。)

### 其他
*   `gw help`: 显示详细的帮助信息。

## 🛠️ 安装与使用

1.  **克隆仓库或下载脚本**:
    ```bash
    git clone https://github.com/lyzno1/gw.git
    cd gw/脚本 
    # 注意：如果您的项目结构中脚本确实在 'gw/脚本' 而不是 'gw_repository_directory/脚本'，请以此为准
    ```
    或者直接下载 `git_workflow.sh` 和整个 `core_utils`、`actions` 目录到您的 `脚本` 文件夹中。

2.  **给予执行权限**:
    ```bash
    chmod +x git_workflow.sh
    chmod +x actions/*.sh
    # core_utils/*.sh 主要被 source，通常不需要执行权限，但添加也无妨
    # chmod +x core_utils/*.sh 
    ```

3.  **添加到 PATH 或创建别名 (推荐)**:
    *   **添加到 PATH**: 将包含 `git_workflow.sh` 的 `脚本` 目录（例如 `/path/to/your/gw/脚本`）添加到您的 `$PATH` 环境变量中。
        ```bash
        # 例如，在 ~/.bashrc 或 ~/.zshrc 中添加:
        export PATH="/path/to/your/gw/脚本:$PATH"
        ```
    *   **创建别名**: 在您的 shell 配置文件中（如 `~/.bashrc`, `~/.zshrc`）添加一个别名：
        ```bash
        alias gw="/path/to/your/gw/脚本/git_workflow.sh"
        ```
    修改配置文件后，记得运行 `source ~/.bashrc` (或对应的文件) 或重启终端。

4.  **验证安装**:
    ```bash
    gw help
    ```
    如果看到帮助信息，说明安装成功！

5.  **（可选）安装依赖**:
    *   `gh` (GitHub CLI): `gw gh-create` 和 `gw finish --pr` 功能需要。请参考 [GitHub CLI 安装文档](https://cli.github.com/)。
    *   `GNU getopt`: 在 macOS 等使用 BSD getopt 的系统上，为了获得 `gw new` 等命令的完整长选项支持（如 `--base`），建议安装 GNU getopt。
        ```bash
        brew install gnu-getopt 
        # 可能需要将其添加到 PATH，或者脚本会提示使用基础参数解析
        ```

## 💡 如何贡献

我们欢迎各种形式的贡献！无论是 bug 修复、功能增强、文档改进还是新的想法，请随时通过以下方式参与：

1.  **提交 Issue**: 发现 bug 或有功能建议？请在项目的 Issue 跟踪系统中提交。
2.  **发起 Pull Request**:
    *   Fork 本仓库 (`https://github.com/lyzno1/gw.git`)。
    *   创建您的特性分支 (`gw new feat/amazing-feature`)。
    *   遵循项目的 [Git 提交信息规范](COMMIT_CONVENTION.md) 进行提交。
    *   确保您的更改通过了所有测试（如果有）。
    *   推送您的分支 (`gw push origin feat/amazing-feature`)。
    *   发起 Pull Request。

## 📜 许可证

本项目采用 [MIT 许可证](LICENSE)授权。

---

**Gw - 让 Git 更简单，让开发更专注！**
我们相信 Gw 能成为您 Git 工具箱中不可或缺的一员。立即体验，感受高效 Git 工作流的魅力！ 
