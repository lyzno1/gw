#!/bin/bash
# 脚本/actions/show_help.sh
#
# 实现 'help' 命令逻辑。
# 依赖:
# - colors.sh (颜色定义)
# - config_vars.sh (配置变量, 用于显示 MAIN_BRANCH, REMOTE_NAME 等默认值)

# 显示帮助信息
cmd_help() { # Renamed from show_help
    echo -e "${BOLD}Git 工作流助手 (gw) v3.0 使用说明${NC}"
    echo "用法: gw <命令> [参数...]"
    echo ""
    
    # --- 核心工作流命令 ---
    echo -e "${CYAN}⭐ 核心工作流命令 (Core Workflow) ⭐${NC}"
    printf "  ${YELLOW}%-22s${NC} %s\n" "start <branch>" "- 从基础分支 (默认: ${MAIN_BRANCH}) 创建新分支并开始工作。"
    printf "  %-22s  ${GRAY}(自动处理 stash, 更新基础分支, 可用 --base/-b, --local/-l)${NC}\n" ""
    printf "  %-22s  ${GRAY}参数说明：\n" ""
    printf "  %-22s  ${GRAY}  --base, -b <base_branch>  指定基础分支（默认: ${MAIN_BRANCH}）\n" ""
    printf "  %-22s  ${GRAY}  --local, -l             仅基于本地分支创建，不拉取远程\n" ""
    printf "  %-22s  ${GRAY}典型用法：\n" ""
    printf "  %-22s  ${GRAY}  gw start feat/xxx             # 基于主分支创建新分支\n" ""
    printf "  %-22s  ${GRAY}  gw start feat/xxx --base dev  # 基于本地dev分支创建新分支\n" ""
    printf "  %-22s  ${GRAY}  gw start feat/xxx -b dev      # 同上，简写\n" ""
    printf "  %-22s  ${GRAY}  gw start feat/xxx --local     # 只用本地分支，不拉取远程\n" ""
    printf "  %-22s  ${GRAY}  gw start feat/xxx -l          # 同上，简写\n" ""
    printf "  %-22s  ${GRAY}  gw start feat/xxx -b dev -l   # 基于本地dev分支，不拉取远程\n" ""
    printf "  %-22s  ${GRAY}注意：如需保留本地未提交内容，建议使用 --local/-l 模式，避免远程拉取覆盖本地。\n" ""
    printf "  ${YELLOW}%-22s${NC} %s\n" "save [-m msg] [-e] [f...]" "- 快速保存变更 (add+commit)。默认添加全部变更。"
    printf "  %-22s  ${GRAY}(无 -m/-e 时使用 'gw ide' 配置的编辑器或VISUAL/EDITOR)${NC}\n" ""
    printf "  ${YELLOW}%-22s${NC} %s\n" "sp [-m msg] [-e] [f...]" "- 快速保存所有变更并推送到远程 (save && push)。"
    printf "  ${YELLOW}%-22s${NC} %s\n" "update" "- 更新当前分支: 若为特性分支则与主干同步, 若为主干则拉取。"
    printf "  %-22s  ${GRAY}(自动处理 stash, 默认拉取策略通常为 rebase)${NC}\n" ""
    printf "  ${YELLOW}%-22s${NC} %s\n" "submit [...]" "- 提交分支工作成果: 保存/推送, 可选创建 PR (-p), 可选不切换 (-n)。"
    printf "  %-22s  ${GRAY}(-p: 创建 PR; -a: 创建 PR 并 rebase 合并; -s: 创建 PR 并 squash 合并; -m: 创建 PR 并 merge 合并)${NC}\n" ""
    printf "  %-22s  ${GRAY}(--rebase/--squash/--merge: 对应长选项; --merge-strategy <策略>: 显式指定)${NC}\n" ""
    printf "  %-22s  ${GRAY}(--delete-branch-after-merge: 自动合并后删除源分支)${NC}\n" ""
    printf "  ${YELLOW}%-22s${NC} %s\n" "rm <branch|all> [-f]" "- 删除本地分支, 并询问是否删除远程同名分支。"
    printf "  %-22s  ${GRAY}(all 模式分阶段处理自动识别和剩余分支, 支持交互式/强制批量)${NC}\n" ""
    printf "  ${YELLOW}%-22s${NC} %s\n" "clean <branch>" "- 清理分支: 切换到主分支, 更新, 然后调用 'gw rm' 删除指定分支。"
    echo ""

    # --- 常用 Git 操作 (增强封装) ---
    echo -e "${CYAN}🛠️ 常用 Git 操作 (Enhanced Wrappers) 🛠️${NC}"
    printf "  ${GREEN}%-22s${NC} %s\n" "status [-r] [-l]" "- 显示工作区状态 (增强版: 含远程对比, 可选日志)。"
    printf "  ${GREEN}%-22s${NC} %s\n" "add [文件...]" "- 添加文件到暂存区 (无参数则交互式选择)。"
    printf "  ${GREEN}%-22s${NC} %s\n" "add-all" "- 添加所有变更到暂存区 (git add -A)。"
    printf "  ${GREEN}%-22s${NC} %s\n" "commit [...]" "- 提交暂存区 (封装原生 commit, 无 -m/-F 时行为依赖原生)。"
    printf "  ${GREEN}%-22s${NC} %s\n" "push [...]" "- 推送本地提交 (带重试, 自动处理 -u, 远程检查)。"
    printf "  ${GREEN}%-22s${NC} %s\n" "pull [...]" "- 拉取更新 (带重试, 默认使用 --rebase)。"
    printf "  ${GREEN}%-22s${NC} %s\n" "fetch [...]" "- 获取远程更新，不合并 (原生 fetch 包装器)。"
    printf "  ${GREEN}%-22s${NC} %s\n" "branch [...]" "- (无参数) 显示本地分支; (带参数) 原生 'git branch' 操作。"
    printf "  %-22s  ${GRAY}(推荐: 创建用 'gw start', 删除用 'gw rm')${NC}\n" ""
    printf "  ${GREEN}%-22s${NC} %s\n" "checkout <分支>" "- 切换分支 (检查未提交变更, 无参数可交互选择)。"
    printf "  ${GREEN}%-22s${NC} %s\n" "merge <来源> [...]" "- 合并指定分支到当前 (检查未提交变更)。"
    printf "  ${GREEN}%-22s${NC} %s\n" "log [...]" "- 显示提交历史 (自动分页, 支持原生 log 参数)。"
    printf "  ${GREEN}%-22s${NC} %s\n" "diff [...]" "- 显示变更差异 (原生 diff 包装器)。"
    printf "  ${GREEN}%-22s${NC} - ${RED}危险:${NC} %s\n" "reset <目标> [...]" "重置 HEAD (对 --hard 有强确认)。"
    printf "  ${GREEN}%-22s${NC} %s\n" "stash [子命令] [...]" "- 暂存工作区变更 (封装常用 stash 子命令, 对 clear 有确认)。"
    printf "  ${GREEN}%-22s${NC} %s\n" "rebase <目标> [...]" "- Rebase 当前分支 (增强版: 自动更新目标, 处理 stash)。"
    printf "  %-22s  ${GRAY}(支持 -i, --continue, --abort, --skip)${NC}\n" ""
    printf "  ${GREEN}%-22s${NC} %s\n" "undo [--soft|--hard]" "- 撤销上一次提交。默认放回工作区, --soft 保留暂存, --hard 丢弃。"
    printf "  ${GREEN}%-22s${NC} %s\n" "unstage [-i] [文件...]" "- 将暂存区更改移回工作区。默认全部, -i 交互, 可指定文件。"
    echo ""

    # --- 仓库管理与配置 ---
    echo -e "${CYAN}🚀 仓库管理与配置 (Repository & Config) 🚀${NC}"
    printf "  ${BLUE}%-22s${NC} %s\n" "init [...]" "- 初始化 Git 仓库 (原生 init 包装器)。"
    printf "  ${BLUE}%-22s${NC} %s\n" "config set-url <url>" "- 设置 'origin' 的 URL (若不存在则添加)。"
    printf "  ${BLUE}%-22s${NC} %s\n" "config set-url <name> <url>" "- 设置指定远程的 URL (若不存在则添加)。"
    printf "  ${BLUE}%-22s${NC} %s\n" "config add-remote <name> <url>" "- 添加新的远程仓库。"
    printf "  ${BLUE}%-22s${NC} %s\n" "config list | show" "- 显示 'gw' 脚本配置和部分Git用户配置。"
    printf "  ${BLUE}%-22s${NC} %s\n" "config <usr> <eml> [--global|-g]" "- 快速设置本地(默认)或全局(--global或-g)用户名/邮箱。"
    printf "  ${BLUE}%-22s${NC} %s\n" "config [...]" "- 其他参数将透传给原生 'git config' (例如 'gw config user.name ...')。"
    printf "  ${BLUE}%-22s${NC} %s\n" "remote [...]" "- 管理远程仓库 (原生 remote 包装器)。"
    printf "  ${BLUE}%-22s${NC} %s\n" "gh-create [repo] [...]" "- 在 GitHub 创建仓库并关联 (需 'gh' CLI)。"
    printf "  ${BLUE}%-22s${NC} %s\n" "ide [name|cmd]" "- 设置或显示 'gw save' 编辑提交信息时默认使用的编辑器。"
    printf "  %-22s  ${GRAY}(无参数则显示当前设置; <name>: vscode等短名称; <cmd>: \"完整命令\")${NC}\n" ""
    printf "  %-22s  ${GRAY}(配置保存在 ~/.gw_editor_pref 文件中)${NC}\n" ""
    echo ""

    # --- 兼容旧版推送命令 ---
    echo -e "${CYAN}📠 兼容旧版推送命令 (Old Push Aliases) 📠${NC}"
    printf "  ${PURPLE}%-22s${NC} %s\n" "1 | first <分支>" "- 首次推送指定分支 (带 -u)。"
    printf "  ${PURPLE}%-22s${NC} %s\n" "2" "- 推送主分支 ('${MAIN_BRANCH}')。"
    printf "  ${PURPLE}%-22s${NC} %s\n" "3 | other <分支>" "- 推送已存在的指定分支。"
    printf "  ${PURPLE}%-22s${NC} %s\n" "4 | current" "- 推送当前分支 (自动处理 -u)。"
    echo ""

    # --- 其他 ---
    echo -e "${CYAN}💡 其他 (Other) 💡${NC}"
    printf "  ${BOLD}%-22s${NC} %s\n" "help, --help, -h" "- 显示此帮助信息。"
    echo ""

    # --- 环境变量与提示 ---
    echo -e "${YELLOW}📌 提示 (Tips):${NC}"
    echo -e "  - 大部分常用 Git 操作命令都支持原生 Git 参数。"
    echo -e "  - 核心工作流命令提供了更高级别的抽象和自动化。"
    echo -e "${YELLOW}🔧 环境变量 (部分):${NC}"
    echo -e "  ${GRAY}MAIN_BRANCH (当前: ${YELLOW}${MAIN_BRANCH}${GRAY}), REMOTE_NAME (当前: ${YELLOW}${REMOTE_NAME}${GRAY}) - 定义默认分支/远程。${NC}"
    echo -e "  ${GRAY}MAX_ATTEMPTS (当前: ${YELLOW}${MAX_ATTEMPTS}${GRAY}), DELAY_SECONDS (当前: ${YELLOW}${DELAY_SECONDS}${GRAY}) - 控制网络重试。${NC}"
}
