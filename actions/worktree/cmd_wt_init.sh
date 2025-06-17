#!/bin/bash
# 脚本/actions/worktree/cmd_wt_init.sh
#
# 实现 'wt-init' 命令逻辑。
# 依赖:
# - core_utils/colors.sh (颜色定义)
# - core_utils/utils_print.sh (打印函数)
# - core_utils/utils.sh (通用工具函数)
# - core_utils/config_vars.sh (配置变量)

# 初始化worktree环境
cmd_wt_init() {
    if ! check_in_git_repo; then return 1; fi

    local current_branch
    current_branch=$(get_current_branch_name)
    if [ $? -ne 0 ]; then return 1; fi

    # 检查是否已经是worktree环境
    if [ -d ".gw" ] && [ -f ".gw/worktree-config" ]; then
        print_warning "当前目录已经是worktree环境。"
        if ! confirm_action "是否要重新初始化worktree环境？"; then
            echo "操作已取消。"
            return 1
        fi
    fi

    print_step "🔧 正在初始化Worktree环境..."

    # 检查工作目录是否干净
    if check_uncommitted_changes || check_untracked_files; then
        print_warning "检测到未提交的变更或未追踪的文件。"
        echo "变更详情:"
        git status -s
        echo ""
        echo "初始化worktree前需要处理这些变更:"
        echo "1) 提交所有变更"
        echo "2) 暂存变更 (stash)"
        echo "3) 取消初始化"
        echo -n "请选择操作 [1-3]: "
        read -r choice

        case "$choice" in
            1)
                print_step "准备提交所有变更..."
                if ! cmd_save; then
                    print_error "变更提交失败，初始化已取消。"
                    return 1
                fi
                ;;
            2)
                print_step "正在暂存变更..."
                if ! git stash push -m "worktree初始化前自动暂存"; then
                    print_error "暂存失败，初始化已取消。"
                    return 1
                fi
                print_info "变更已暂存，初始化完成后可使用 'git stash pop' 恢复。"
                ;;
            3|*)
                echo "初始化已取消。"
                return 1
                ;;
        esac
    fi

    # 创建.gw目录
    print_step "✅ 创建配置目录..."
    mkdir -p .gw

    # 创建worktree配置文件
    cat > .gw/worktree-config << EOF
# GW Worktree配置文件
# 创建时间: $(date)
# 主分支: $MAIN_BRANCH
# 当前分支: $current_branch

# Worktree根目录布局
WORKTREE_ROOT=$(pwd)
MAIN_WORKTREE_DIR=.
DEV_WORKTREE_DIR=dev
SHARED_DIR=dev/shared

# 用户配置
USER_PREFIX=
AUTO_CLEANUP=true
AUTO_SYNC_SHARED=true
EOF

    # 创建目录结构
    print_step "✅ 创建目录结构..."
    
    # 确保在主分支上
    if [ "$current_branch" != "$MAIN_BRANCH" ]; then
        print_info "当前在分支 '$current_branch'，切换到主分支 '$MAIN_BRANCH'..."
        if ! git checkout "$MAIN_BRANCH"; then
            print_error "切换到主分支失败。"
            return 1
        fi
    fi

    # 创建dev目录和shared目录
    mkdir -p dev/shared

    print_step "✅ 设置主分支worktree: 当前目录"
    print_info "当前目录已被设置为主分支工作目录。"

    # 更新.gitignore
    print_step "✅ 更新.gitignore配置..."
    local gitignore_updated=false
    
    if [ ! -f ".gitignore" ]; then
        touch .gitignore
    fi
    
    # 检查并添加.gw到.gitignore
    if ! grep -q "^\.gw$" .gitignore 2>/dev/null; then
        echo "" >> .gitignore
        echo "# GW Worktree配置目录" >> .gitignore
        echo ".gw" >> .gitignore
        gitignore_updated=true
    fi
    
    # 检查并添加dev到.gitignore
    if ! grep -q "^/dev$" .gitignore 2>/dev/null; then
        echo "" >> .gitignore
        echo "# GW Worktree开发目录" >> .gitignore
        echo "/dev" >> .gitignore
        gitignore_updated=true
    fi
    
    if $gitignore_updated; then
        print_success ".gitignore已更新，添加了.gw和/dev目录的忽略规则。"
    fi

    # 创建活跃worktree记录文件
    echo "$MAIN_BRANCH:$MAIN_BRANCH:$(date):active" > .gw/active-worktrees

    print_success "✅ Worktree环境初始化完成"
    echo ""
    echo -e "${CYAN}💡 Worktree环境已就绪：${NC}"
    echo -e "  - 主分支代码在: ${BOLD}当前目录${NC}"
    echo -e "  - 开发分支将创建在: ${BOLD}dev/${NC}"
    echo -e "  - 共享资源目录: ${BOLD}dev/shared/${NC}"
    echo ""
    echo -e "${CYAN}💡 使用提示：${NC}"
    echo -e "  ${YELLOW}gw wt-start <branch>${NC}     # 开始新功能开发"
    echo -e "  ${YELLOW}gw wt-list${NC}               # 查看所有worktree"
    echo -e "  ${YELLOW}gw wt-switch <branch>${NC}    # 切换到其他worktree"
    echo ""
    
    return 0
} 