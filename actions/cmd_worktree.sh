#!/bin/bash
# 脚本/actions/cmd_worktree.sh
#
# 实现 'worktree' 主命令逻辑，作为所有worktree子命令的入口。
# 依赖:
# - core_utils/colors.sh (颜色定义)
# - core_utils/utils_print.sh (打印函数)
# - core_utils/utils.sh (通用工具函数)
# - core_utils/config_vars.sh (配置变量)
# - actions/worktree/cmd_wt_*.sh (各个子命令)

# 导入worktree子命令
source_worktree_commands() {
    local worktree_dir="${SCRIPT_DIR}/actions/worktree"
    
    if [ ! -d "$worktree_dir" ]; then
        print_error "Worktree命令目录不存在: $worktree_dir"
        return 1
    fi
    
    # 导入所有worktree子命令
    for cmd_file in "$worktree_dir"/cmd_wt_*.sh; do
        if [ -f "$cmd_file" ]; then
            source "$cmd_file"
        fi
    done
}

# 显示worktree帮助信息
show_worktree_help() {
    echo -e "${BOLD}Git Worktree 管理命令${NC}"
    echo "用法: gw <worktree-command> [参数...]"
    echo ""
    echo -e "${CYAN}⭐ Worktree 命令 ⭐${NC}"
    printf "  ${YELLOW}%-18s${NC} %s\n" "wt-init" "初始化worktree环境，设置目录结构"
    printf "  ${YELLOW}%-18s${NC} %s\n" "wt-start <branch>" "创建新的worktree分支并开始工作"
    printf "  %-18s  ${GRAY}支持 --base <base>（指定基础分支）、--local（本地模式）${NC}\n" ""
    printf "  ${YELLOW}%-18s${NC} %s\n" "wt-list" "列出所有worktree及其状态"
    printf "  %-18s  ${GRAY}支持 --detailed/-d（详细信息）、--simple/-s（简单模式）${NC}\n" ""
    printf "  ${YELLOW}%-18s${NC} %s\n" "wt-switch <branch>" "切换到指定的worktree"
    printf "  ${YELLOW}%-18s${NC} %s\n" "wt-clean <branch>" "清理指定的worktree和分支"
    printf "  %-18s  ${GRAY}支持 --force/-f（强制清理）、--keep-branch/-k（保留分支）${NC}\n" ""
    printf "  ${YELLOW}%-18s${NC} %s\n" "wt-update" "在当前worktree中同步主分支"
    printf "  ${YELLOW}%-18s${NC} %s\n" "wt-submit" "提交当前worktree的工作"
    printf "  ${YELLOW}%-18s${NC} %s\n" "wt-prune" "清理所有无效的worktree"
    printf "  ${YELLOW}%-18s${NC} %s\n" "wt-config" "配置worktree设置"
    echo ""
    echo -e "${CYAN}💡 典型工作流：${NC}"
    echo -e "  ${GRAY}1. 初始化环境:${NC}        gw wt-init"
    echo -e "  ${GRAY}2. 开始新功能:${NC}        gw wt-start feature-login"
    echo -e "  ${GRAY}3. 日常开发:${NC}          cd dev/feature-login && gw save \"add login\""
    echo -e "  ${GRAY}4. 同步主分支:${NC}        gw wt-update"
    echo -e "  ${GRAY}5. 提交工作:${NC}          gw wt-submit --pr"
    echo -e "  ${GRAY}6. 清理分支:${NC}          gw wt-clean feature-login"
    echo ""
    echo -e "${CYAN}📖 更多信息：${NC}"
    echo -e "  使用 'gw help <command>' 查看特定命令的详细说明"
}

# 主worktree命令处理器
cmd_worktree() {
    local subcommand="$1"
    
    if [ -z "$subcommand" ]; then
        show_worktree_help
        return 0
    fi
    
    shift
    
    case "$subcommand" in
        help|--help|-h)
            show_worktree_help
            ;;
        *)
            print_error "未知的worktree子命令: $subcommand"
            echo ""
            show_worktree_help
            return 1
            ;;
    esac
}

# 初始化时导入worktree命令
source_worktree_commands 