## 项目 `gw` (Git Workflow) 架构文档

### 1. 项目概述

`gw` (Git Workflow) 是一个基于 Bash Shell 的命令行工具，旨在通过封装和增强原生 Git 命令，为开发者提供一套更流畅、规范、健壮和智能的 Git 工作流。它将常见的 Git 操作序列（如创建分支、同步代码、完成特性、清理分支等）集成为单一、直观的命令，并加入了自动重试、交互式提示、安全检查等特性，以提升开发效率、减少错误并促进团队协作中的代码库健康。

### 2. 核心设计理念

*   **流程驱动**: 将开发生命周期中的典型步骤抽象为高级命令。
*   **用户体验**: 通过彩色输出、清晰提示和交互式确认优化用户交互。
*   **健壮可靠**: 内建网络操作重试和操作前安全检查。
*   **规范协作**: 鼓励使用 `rebase` 保持历史整洁，提供标准命令集。
*   **可扩展性**: 模块化的命令设计，易于添加新功能。

### 3. 整体架构

项目采用分层和模块化的 Bash脚本架构：

```
gw (git_workflow.sh) -- 主入口脚本
|
|-- core_utils/        -- 核心工具和共享函数库
|   |-- colors.sh          # ANSI 颜色代码定义
|   |-- config_vars.sh     # 全局配置变量 (如 REMOTE_NAME, MAIN_BRANCH, MAX_ATTEMPTS)
|   |-- utils_print.sh     # 标准化打印函数 (info, error, success, warning, step)
|   |-- utils.sh           # 通用辅助函数 (Git状态检查, 交互, 确认等)
|   |-- git_network_ops.sh # 封装带重试逻辑的 Git 网络操作 (push, pull)
|
|-- actions/             -- 各个子命令的具体实现脚本
    |-- cmd_*.sh           # 实现具体命令逻辑 (如 cmd_new.sh, cmd_sync.sh)
    |-- gw_*.sh            # (在本项目中，cmd_*.sh 是主要模式，gw_*.sh 似乎不突出)
    |-- show_help.sh       # 实现 'help' 命令，显示帮助信息
```

**执行流程**:

1.  用户在终端执行 `gw <command> [options...]`。
2.  `git_workflow.sh` (主入口) 被调用。
3.  `git_workflow.sh` 首先获取自身路径，然后 `source` (导入) `core_utils/` 下的所有核心脚本，使其中的函数和变量在全局可用。
4.  接着，它动态 `source` `actions/` 目录下的所有 `cmd_*.sh` 和 `gw_*.sh` 脚本 (以及 `show_help.sh`)，加载所有子命令的实现函数。
5.  主脚本的 `main()` 函数解析全局选项 (如 `--verbose`, `--dry-run`)，并进行初步的 Git 仓库检查（某些命令允许在仓库外执行）。
6.  根据用户提供的第一个参数 (`<command>`)，`main()` 函数中的 `case` 语句将执行流分发到 `actions/` 目录中对应脚本定义的函数 (例如，`gw new ...` 会调用 `actions/cmd_new.sh` 中的 `cmd_new()` 函数)。
7.  对应的 `cmd_*()` 函数执行具体逻辑，它可能会调用 `core_utils/` 中的辅助函数（如打印、状态检查、网络操作）以及其他 Git 命令。
8.  `cmd_*()` 函数执行完毕后，将其退出状态码返回给 `main()` 函数，主脚本随后退出。

### 4. 关键模块与组件

#### 4.1. `git_workflow.sh` (主入口)

*   **职责**:
    *   环境设置（脚本路径）。
    *   依赖导入 (`core_utils/` 和 `actions/` 中的脚本）。
    *   全局中断处理 (`trap INT`)。
    *   全局选项解析 (`--verbose`, `--dry-run`)。
    *   命令分发（`case` 语句将控制权交给相应的 `cmd_*` 函数）。
    *   维护 `LAST_COMMAND_STATUS`。
*   **特点**: 作为项目的调度中心，本身不包含复杂的业务逻辑，保持了较高的内聚性。

#### 4.2. `core_utils/` (核心工具库)

*   **`colors.sh`**: 定义终端输出的颜色代码，增强可读性。
*   **`config_vars.sh`**:
    *   定义可配置的全局变量（`MAX_ATTEMPTS`, `DELAY_SECONDS`, `REMOTE_NAME`, `DEFAULT_MAIN_BRANCH`），允许通过环境变量覆盖。
    *   包含 `get_main_branch_name()` 动态确定实际主分支 (master/main)，并设置 `MAIN_BRANCH` 变量。
*   **`utils_print.sh`**: 提供一组标准化的打印函数 (`print_info`, `print_step`, `print_success`, `print_warning`, `print_error`)，统一了用户反馈的风格。
*   **`utils.sh`**:
    *   包含大量通用的 Git 和 Shell 辅助函数：
        *   `get_current_branch_name()`
        *   `check_in_git_repo()`
        *   `check_uncommitted_changes()`, `check_untracked_files()`
        *   `interactive_select_files()`
        *   `confirm_action()` (Y/n 提示)
        *   `get_commit_msg_file()`
*   **`git_network_ops.sh`**:
    *   **核心功能**: 实现带重试逻辑的 Git 网络操作。
    *   `do_push_with_retry()`: 封装 `git push`，包含未提交变更检查 (提示 `gw save`)、自动 `-u` 设置、远程仓库URL有效性检查、以及基于 `MAX_ATTEMPTS` 和 `DELAY_SECONDS` 的重试机制。
    *   `do_pull_with_retry()`: 封装 `git pull`，包含重试机制，并倾向于使用 `--rebase` 策略。
    *   *(推测应有 `do_fetch_with_retry`，但未在当前 `cmd_fetch.sh` 中明确使用)*

#### 4.3. `actions/` (子命令实现)

此目录包含每个 `gw` 子命令的具体实现脚本。每个 `cmd_*.sh` 文件通常：

1.  在文件头部包含 `#!/bin/bash` 和注释块（说明路径、用途、依赖）。
2.  定义一个与命令同名的主函数，例如 `cmd_new()`。
3.  在函数开始处进行必要的检查（如 `check_in_git_repo`）。
4.  解析该命令特有的参数。
5.  实现命令的核心逻辑，调用原生 Git 命令、`core_utils` 中的函数，以及可能的其他 `cmd_*` 函数。
6.  使用 `utils_print.sh` 中的函数提供用户反馈。
7.  返回适当的退出码。

**主要工作流命令及其特点**:

*   **`cmd_new.sh` (`gw new`)**:
    *   复杂工作流：处理未提交变更 (stash)、解析参数 (包括 `--local`, `--base`)、确保基础分支存在 (本地或远程获取)、更新基础分支 (除非 `--local`)、创建并切换到新分支、最后尝试恢复 stash。
    *   健壮性：参数解析尝试使用 GNU `getopt`。
*   **`cmd_save.sh` (`gw save`)**:
    *   组合 `git add` 和 `git commit`。
    *   智能提交信息处理：若无 `-m` 或 `-e`，则准备 `COMMIT_EDITMSG` (包含暂存文件列表)，提示用户编辑，然后提交清理后的信息。
*   **`cmd_sync.sh` (`gw sync`)**:
    *   核心同步逻辑：处理未提交变更 (stash)；若在主分支则 `pull --rebase`；若在特性分支，则切换到主分支、`pull --rebase` 主分支、切回特性分支、`rebase` 特性分支到主分支；最后尝试恢复 stash。
    *   强调 `rebase` 策略。
*   **`cmd_finish.sh` (`gw finish`)**:
    *   完成分支工作流：处理未提交变更 (调用 `cmd_save`)、推送当前分支 (调用 `do_push_with_retry`)、可选创建 GitHub PR (调用 `gh pr create`)、可选切换回主分支并更新。
*   **`cmd_rm_branch.sh` (`gw rm`)**:
    *   增强的分支删除：支持删除单个分支或 `all` (已合并到主分支的)；`is_branch_merged_to_main` 用于更准确的合并检测 (对 rebase 友好)；集成远程分支删除 (`--delete-remotes` 或提示)；安全确认。
*   **`cmd_gh_create.sh` (`gw gh-create`)**: 集成 GitHub CLI (`gh`) 在 GitHub 创建仓库并与本地关联，支持多种选项。
*   **`cmd_push.sh`, `cmd_pull.sh`**: 主要作为 `do_push_with_retry` 和 `do_pull_with_retry` 的入口，`cmd_push` 还增加了远程不存在时的交互式添加逻辑。
*   **`cmd_status.sh` (`gw status`)**: 提供比 `git status` 更丰富的概览，包括与远程的同步状态 (ahead/behind)、可选的最近日志和标签。
*   **`cmd_reset.sh` (`gw reset`)**: 对 `git reset --hard` 增加严格的确认步骤。
*   **`cmd_stash.sh` (`gw stash`)**: 封装常用 `git stash` 子命令，统一交互和反馈，对 `clear` 操作有确认。
*   **`cmd_rebase.sh` (`gw rebase`) (新增)**:
    *   封装 `git rebase`，提供更完善的工作流程。
    *   支持 rebase 到指定的上游分支 (如 `gw rebase main`)，会自动更新上游分支。
    *   支持原生 rebase 操作，如交互式 rebase (`gw rebase -i HEAD~3`)。
    *   支持 rebase 管理命令 (`--continue`, `--abort`, `--skip`)。
    *   在执行 rebase 前，会自动处理未提交的变更 (提示stash)。
    *   Rebase 成功后，会尝试恢复之前自动暂存的变更。
*   **`show_help.sh`**: 生成详细的、分类的、带颜色的帮助信息。
*   **其他**: 多数是原生 Git 命令的简单包装器，增加了仓库检查和统一的 `gw` 命令入口，部分有细微增强 (如 `cmd_log` 自动分页)。
*   **已弃用/重定向**: 如 `cmd_new_branch.sh` 重定向到 `cmd_new.sh`。`cmd_delete_branch.sh` 的功能很大程度上被 `cmd_rm_branch.sh` 覆盖和增强。

### 5. 数据流与状态管理

*   **环境变量**: `core_utils/config_vars.sh` 定义的变量（如 `MAIN_BRANCH`, `REMOTE_NAME`）在所有 `source` 了该文件的脚本中全局可用。这些变量可以通过外部环境变量覆盖。
*   **函数参数与返回值**: 命令逻辑主要通过函数参数传递数据，通过退出状态码 (`$?`) 返回结果。
*   **Git 状态**: 脚本严重依赖 Git 仓库的当前状态（当前分支、工作区是否干净、暂存区内容等）。
*   **临时文件**: `cmd_save` 在其默认提交流程中会使用 `.git/COMMIT_EDITMSG` 及一个 `.gw_cleaned` 临时文件。

### 6. 错误处理与用户反馈

*   **退出码**: `LAST_COMMAND_STATUS` 在 `git_workflow.sh` 中记录最后一个 `cmd_*` 函数的退出状态，主脚本最终会以这个状态退出。单个 `cmd_*` 函数也应返回 `0` 表示成功，非零表示失败。
*   **标准打印函数**: `utils_print.sh` 中的函数（`print_error`, `print_warning`, `print_success`, `print_info`, `print_step`）用于向用户提供一致且带颜色的反馈。错误和警告信息通常输出到 `stderr`。
*   **安全确认**: 对于危险操作（如 `reset --hard`, `stash clear`, `rm all`），使用 `confirm_action` 或特定提示要求用户明确确认。
*   **未提交变更处理**: 多个工作流命令（`new`, `sync`, `finish`, `checkout`, `clean`）在执行敏感操作前会检查未提交变更，并提供处理选项（通常是 stash 或取消）。

### 7. 扩展性

*   **添加新命令**:
    1.  在 `actions/` 目录下创建新的 `cmd_newcmd.sh` 文件。
    2.  遵循头部注释规范，定义 `cmd_newcmd()` 函数。
    3.  在 `git_workflow.sh` 的 `action_files` 数组中确保新文件能被加载 (如果遵循 `cmd_*.sh` 命名会自动加载)。
    4.  在 `git_workflow.sh` 的 `main()` 函数的 `case` 语句中为新命令添加一个分支，调用 `cmd_newcmd "$@"`。
    5.  在 `actions/show_help.sh` 中为新命令添加帮助信息。
*   **修改现有命令**: 直接修改 `actions/` 目录下对应的脚本。
*   **修改核心工具**: 修改 `core_utils/` 下的脚本，但需注意这可能影响所有依赖它们的命令。

### 8. 潜在问题与改进点 (基于代码阅读)

*   **`cmd_branch` 功能不符**: `gw branch` (无参数) 的实现 (`git branch`) 与 `README.md` 描述的 "美化版分支列表" 功能不符。
*   **`cmd_fetch` 缺失重试**: `cmd_fetch.sh` 直接调用 `git fetch`，未集成 `git_network_ops.sh` 中的重试逻辑，与 `README.md` "带重试" 的描述不一致。
*   **`cmd_checkout` 中的 `cmd_commit_all` 未定义**: 这是一个bug，导致 `gw checkout` 时选择 "提交变更" 选项会失败。应替换为调用 `cmd_save` 或类似功能。
*   **`cmd_checkout` Stash 消息问题**: Stash 消息中使用未定义的 `$target_branch` 且消息内容不完全匹配场景。
*   **`cmd_add_all` 实现**: `README.md` 和帮助信息称其为 `git add -A` 的包装，但 `cmd_add_all.sh` 中实际执行的是 `git add .`。行为上可能存在细微差别。
*   **硬编码的PR Base**: `cmd_finish --pr` 中创建 PR 的基础分支硬编码为 `$MAIN_BRANCH`，缺乏灵活性。
*   **`getopt` 依赖**: 虽然有 fallback，但完全依赖 GNU `getopt` 的高级参数解析在某些系统上可能需要用户额外安装。

### 9. 总结

`gw` 项目是一个精心设计且功能丰富的 Git 工作流辅助工具。其架构清晰，通过模块化的 Bash 脚本实现了对原生 Git 命令的有效封装和功能增强。核心优势在于其流程驱动的设计、用户友好的交互、对网络操作的健壮性处理以及对危险操作的安全防护。通过 `core_utils` 提供共享基础能力，`actions` 目录实现具体命令逻辑，使得项目易于理解、维护和扩展。尽管存在一些代码实现与文档描述不一致的小问题，但整体而言，这是一个高质量的 Shell 工具项目。 