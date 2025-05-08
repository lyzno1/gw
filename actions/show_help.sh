#!/bin/bash
# 脚本/actions/show_help.sh
#
# 实现 'help' 命令逻辑。
# 依赖:
# - colors.sh (颜色定义)
# - config_vars.sh (配置变量, 用于显示 MAIN_BRANCH, REMOTE_NAME 等默认值)

# 显示帮助信息
show_help() {
    echo -e "${BOLD}Git 工作流助手 (gw) v3.0 使用说明${NC}"
    echo "用法: gw <命令> [参数...]"
    echo ""
    
    # --- 核心工作流命令 ---
    echo -e "${CYAN}⭐ 核心工作流命令 (Core Workflow) ⭐${NC}"
    printf "  ${YELLOW}%-22s${NC} %s\n" "new <branch>" "- 从基础分支 (默认: ${MAIN_BRANCH}) 创建并切换新分支。"
    printf "  %-22s  ${GRAY}(自动处理 stash, 更新基础分支, 可用 --base, --local)${NC}\n" ""
    printf "  ${YELLOW}%-22s${NC} %s\n" "save [-m msg] [-e] [f...]" "- 快速保存变更 (add+commit)。默认添加全部变更。"
    printf "  %-22s  ${GRAY}(无 -m/-e 时优先尝试 'code --wait' 或提示编辑 COMMIT_EDITMSG)${NC}\n" ""
    printf "  ${YELLOW}%-22s${NC} %s\n" "sp [-m msg] [-e] [f...]" "- 快速保存所有变更并推送到远程 (save && push)。"
    printf "  ${YELLOW}%-22s${NC} %s\n" "sync" "- 同步当前分支: 拉取主分支 ('${MAIN_BRANCH}') 最新并 rebase 当前分支。"
    printf "  %-22s  ${GRAY}(自动处理 stash, 在主分支上仅 pull --rebase)${NC}\n" ""
    printf "  ${YELLOW}%-22s${NC} %s\n" "finish [-n] [-p]" "- 完成分支: 保存/推送当前分支, 可选创建 PR (-p), 可选不切换 (-n)。"
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
    printf "  %-22s  ${GRAY}(推荐: 创建用 'gw new', 删除用 'gw rm')${NC}\n" ""
    printf "  ${GREEN}%-22s${NC} %s\n" "checkout <分支>" "- 切换分支 (检查未提交变更, 无参数可交互选择)。"
    printf "  ${GREEN}%-22s${NC} %s\n" "merge <来源> [...]" "- 合并指定分支到当前 (检查未提交变更)。"
    printf "  ${GREEN}%-22s${NC} %s\n" "log [...]" "- 显示提交历史 (自动分页, 支持原生 log 参数)。"
    printf "  ${GREEN}%-22s${NC} %s\n" "diff [...]" "- 显示变更差异 (原生 diff 包装器)。"
    printf "  ${GREEN}%-22s${NC} %s\n" "reset <目标> [...]" "- ${RED}危险:${NC} 重置 HEAD (对 --hard 有强确认)。"
    printf "  ${GREEN}%-22s${NC} %s\n" "stash [子命令] [...]" "- 暂存工作区变更 (封装常用 stash 子命令, 对 clear 有确认)。"
    printf "  ${GREEN}%-22s${NC} %s\n" "rebase <目标> [...]" "- Rebase 当前分支 (增强版: 自动更新目标, 处理 stash)。"
    printf "  %-22s  ${GRAY}(支持 -i, --continue, --abort, --skip)${NC}\n" ""
    printf "  ${GREEN}%-22s${NC} %s\n" "undo [--soft|--hard]" "- 撤销上一次提交。默认放回工作区, --soft 保留暂存, --hard 丢弃。"
    printf "  ${GREEN}%-22s${NC} %s\n" "unstage [-i] [文件...]" "- 将暂存区更改移回工作区。默认全部, -i 交互, 可指定文件。"
    echo ""

    # --- 仓库管理与配置 ---
    echo -e "${CYAN}🚀 仓库管理与配置 (Repository & Config) 🚀${NC}"
    printf "  ${BLUE}%-22s${NC} %s\n" "init [...]" "- 初始化 Git 仓库 (原生 init 包装器)。"
    printf "  ${BLUE}%-22s${NC} %s\n" "config <usr> <eml> [--g]" "- 快速设置本地(默认)或全局(--g)用户名/邮箱。"
    printf "  ${BLUE}%-22s${NC} %s\n" "config [...]" "- 执行原生 git config 命令。"
    printf "  ${BLUE}%-22s${NC} %s\n" "config set remote.default <name>" "- 设置 'gw' 默认远程名 (修改脚本配置)。"
    printf "  ${BLUE}%-22s${NC} %s\n" "remote [...]" "- 管理远程仓库 (原生 remote 包装器)。"
    printf "  ${BLUE}%-22s${NC} %s\n" "gh-create [repo] [...]" "- 在 GitHub 创建仓库并关联 (需 'gh' CLI)。"
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