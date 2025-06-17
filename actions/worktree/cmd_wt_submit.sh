#!/bin/bash
# 脚本/actions/worktree/cmd_wt_submit.sh
#
# 实现 'wt-submit' 命令逻辑。
# 依赖:
# - core_utils/colors.sh (颜色定义)
# - core_utils/utils_print.sh (打印函数)
# - core_utils/utils.sh (通用工具函数)
# - core_utils/config_vars.sh (配置变量)
# - actions/cmd_submit.sh (依赖现有的submit函数)

# 提交当前worktree的工作
cmd_wt_submit() {
    if ! check_in_git_repo; then return 1; fi

    # 检查是否在worktree环境中
    local worktree_root
    if [ -f ".gw/worktree-config" ]; then
        worktree_root="$(pwd)"
    else
        # 检查是否在某个worktree子目录中
        local current_dir="$(pwd)"
        while [ "$current_dir" != "/" ]; do
            if [ -f "$current_dir/.gw/worktree-config" ]; then
                worktree_root="$current_dir"
                break
            fi
            current_dir="$(dirname "$current_dir")"
        done
        
        if [ -z "$worktree_root" ]; then
            print_error "当前不在worktree环境中。请先运行 'gw wt-init' 初始化worktree环境。"
            return 1
        fi
    fi

    # 读取配置
    source "$worktree_root/.gw/worktree-config"

    local current_branch
    current_branch=$(get_current_branch_name)
    if [ $? -ne 0 ]; then return 1; fi

    # 防止在主分支上提交
    if [ "$current_branch" = "$MAIN_BRANCH" ]; then
        print_warning "您当前在主分支 ($MAIN_BRANCH)。建议不要在主分支上直接提交工作。"
        if ! confirm_action "是否仍要继续在主分支上提交？"; then
            echo "操作已取消。"
            return 1
        fi
    fi

    local auto_clean=false
    local keep_worktree=false
    local submit_args=()

    # 参数解析 - 分离worktree特有参数和submit参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --auto-clean)
                auto_clean=true
                shift
                ;;
            --keep-worktree)
                keep_worktree=true
                shift
                ;;
            *)
                # 其他参数传递给原始的submit命令
                submit_args+=("$1")
                shift
                ;;
        esac
    done

    # 如果配置了自动清理，则设置标志
    if [ "$AUTO_CLEANUP" = "true" ] && ! $keep_worktree; then
        auto_clean=true
    fi

    echo -e "${CYAN}=== 提交Worktree '$current_branch' 工作 ===${NC}"

    # 调用原始的submit命令
    print_step "1/2: 执行提交流程..."
    if ! cmd_submit "${submit_args[@]}"; then
        print_error "提交失败。"
        return 1
    fi

    print_success "工作提交完成。"

    # 如果设置了自动清理
    if $auto_clean && [ "$current_branch" != "$MAIN_BRANCH" ]; then
        echo ""
        print_step "2/2: 自动清理worktree..."
        
        # 检查提交是否成功推送
        local push_successful=false
        if git rev-parse --verify "refs/remotes/$REMOTE_NAME/$current_branch" >/dev/null 2>&1; then
            # 检查是否有未推送的提交
            local local_commits
            local_commits=$(git rev-list "refs/remotes/$REMOTE_NAME/$current_branch..HEAD" 2>/dev/null)
            if [ -z "$local_commits" ]; then
                push_successful=true
            fi
        fi

        if $push_successful; then
            print_info "检测到分支已成功推送，开始自动清理..."
            
            # 切换到worktree根目录执行清理
            local original_pwd="$(pwd)"
            cd "$worktree_root"
            
            # 调用清理命令
            if gw wt-clean "$current_branch" --force; then
                print_success "Worktree自动清理完成。"
            else
                print_warning "自动清理失败，请手动清理：gw wt-clean $current_branch"
                cd "$original_pwd"
            fi
        else
            print_warning "检测到可能有未推送的提交或推送失败，跳过自动清理。"
            print_info "如需清理，请手动执行：gw wt-clean $current_branch"
        fi
    else
        print_info "2/2: 保留worktree环境。"
        echo ""
        echo -e "${CYAN}💡 后续操作：${NC}"
        echo -e "  ${YELLOW}gw wt-list${NC}                    # 查看所有worktree"
        echo -e "  ${YELLOW}gw wt-clean $current_branch${NC}    # 手动清理此worktree"
        echo -e "  ${YELLOW}gw wt-switch main${NC}             # 切换到主分支"
    fi

    return 0
} 