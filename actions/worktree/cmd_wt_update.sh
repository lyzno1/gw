#!/bin/bash
# 脚本/actions/worktree/cmd_wt_update.sh
#
# 实现 'wt-update' 命令逻辑。
# 依赖:
# - core_utils/colors.sh (颜色定义)
# - core_utils/utils_print.sh (打印函数)
# - core_utils/utils.sh (通用工具函数)
# - core_utils/config_vars.sh (配置变量)
# - core_utils/git_network_ops.sh (网络操作函数)

# 在当前worktree中同步主分支
cmd_wt_update() {
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

    # 获取当前分支和worktree信息
    local current_branch
    current_branch=$(get_current_branch_name)
    if [ $? -ne 0 ]; then return 1; fi

    local current_worktree_path
    current_worktree_path=$(git rev-parse --show-toplevel)

    echo -e "${CYAN}=== 同步Worktree '$current_branch' ===${NC}"

    # 检查是否在主分支
    if [ "$current_branch" = "$MAIN_BRANCH" ]; then
        print_info "您在主分支 ($MAIN_BRANCH)。正在尝试拉取最新代码..."
        if ! do_pull_with_retry --rebase "$REMOTE_NAME" "$MAIN_BRANCH"; then
            print_error "从远程 '$REMOTE_NAME' 拉取并 rebase 主分支 '$MAIN_BRANCH' 失败。"
            return 1
        fi
        print_success "主分支 '$MAIN_BRANCH' 已成功更新。"
        return 0
    fi

    # 处理未提交的变更
    local stash_needed=false
    if check_uncommitted_changes || check_untracked_files; then
        print_warning "检测到未提交的变更或未追踪的文件。"
        print_info "在同步操作前，建议先处理这些变更。"
        echo -e "1) \033[32m暂存 (Stash) 变更并在同步后尝试恢复\033[0m"
        echo -e "2) \033[31m取消同步操作\033[0m"
        local choice_stash
        read -r -p "请选择操作 [1-2]: " choice_stash
        case "$choice_stash" in
            1)
                print_step "正在暂存当前变更..."
                if git stash push -m "在同步 $current_branch 前自动暂存"; then
                    stash_needed=true
                else
                    print_error "stash 保存失败，同步已取消。"
                    return 1
                fi
                ;;
            2|*)
                print_info "同步操作已取消。"
                return 1
                ;;
        esac
        echo ""
    fi

    # 获取当前目录，最后要返回这里
    local original_pwd="$(pwd)"

    # 1. 切换到主分支worktree并更新
    print_step "1/3: 更新主分支 ($MAIN_BRANCH)..."
    local main_worktree_path="$worktree_root"
    
    if [ ! -d "$main_worktree_path" ]; then
        print_error "主分支worktree目录不存在: $main_worktree_path"
        if $stash_needed; then
            print_warning "正在尝试恢复之前暂存的变更..."
            git stash pop
        fi
        return 1
    fi

    cd "$main_worktree_path"
    if [ $? -ne 0 ]; then
        print_error "无法切换到主分支worktree目录。"
        cd "$original_pwd"
        if $stash_needed; then
            print_warning "正在尝试恢复之前暂存的变更..."
            git stash pop
        fi
        return 1
    fi

    # 确保在主分支上
    if ! git checkout "$MAIN_BRANCH" 2>/dev/null; then
        print_warning "主分支checkout失败，但继续尝试更新..."
    fi

    # 拉取主分支最新代码
    if ! do_pull_with_retry --rebase "$REMOTE_NAME" "$MAIN_BRANCH"; then
        print_error "拉取主分支更新失败。"
        cd "$original_pwd"
        if $stash_needed; then
            print_warning "正在尝试恢复之前暂存的变更..."
            git stash pop
        fi
        return 1
    fi
    print_success "主分支已更新。"

    # 2. 返回到原来的worktree
    print_step "2/3: 返回到worktree '$current_branch'..."
    cd "$original_pwd"
    if [ $? -ne 0 ]; then
        print_error "返回到原worktree失败。"
        return 1
    fi

    # 确保在正确的分支上
    if ! git checkout "$current_branch" 2>/dev/null; then
        print_warning "切换到分支 '$current_branch' 失败，但继续尝试rebase..."
    fi

    # 3. Rebase 当前分支到最新的主分支
    print_step "3/3: 将当前分支 '$current_branch' Rebase 到最新的 '$MAIN_BRANCH'..."
    if git rebase "$MAIN_BRANCH"; then
        print_success "成功将 '$current_branch' Rebase 到 '$MAIN_BRANCH'。"
    else
        print_error "Rebase 操作失败或遇到冲突。"
        echo -e "请解决 Rebase 冲突。"
        echo -e "解决冲突后，运行 'git add <冲突文件>' 然后 'git rebase --continue'。"
        echo -e "如果想中止 Rebase，可以运行 'git rebase --abort'。"
        # Rebase 失败时，stash 的恢复需要用户在 rebase 完成后手动操作
        if $stash_needed; then
            print_warning "请注意：您之前暂存的变更在 Rebase 成功并结束后需要手动恢复 (git stash pop)。"
        fi
        return 1
    fi

    # 4. 如果之前暂存了，尝试恢复
    if $stash_needed; then
        print_step "正在尝试恢复之前暂存的变更..."
        if git stash pop; then
            print_success "成功恢复暂存的变更。"
        else
            print_error "自动恢复暂存失败。可能存在冲突。"
            print_info "请运行 'git status' 查看详情，并手动解决冲突。未恢复的暂存在 'git stash list' 中。"
        fi
    fi

    print_success "=== Worktree同步操作完成 ('$current_branch') ==="
    
    # 显示当前状态
    echo ""
    echo -e "${CYAN}📊 同步后状态：${NC}"
    echo -e "  当前分支: ${BOLD}$current_branch${NC}"
    echo -e "  基于主分支: ${BOLD}$MAIN_BRANCH${NC} (最新)"
    
    # 检查是否有新的提交可以推送
    if git rev-parse --verify "refs/remotes/$REMOTE_NAME/$current_branch" >/dev/null 2>&1; then
        local commits_ahead
        commits_ahead=$(git rev-list --count "refs/remotes/$REMOTE_NAME/$current_branch..HEAD" 2>/dev/null || echo "0")
        if [ "$commits_ahead" -gt 0 ]; then
            echo -e "  未推送提交: ${YELLOW}$commits_ahead 个${NC}"
            echo ""
            echo -e "${CYAN}💡 建议下一步：${NC}"
            echo -e "  ${YELLOW}gw push${NC}        # 推送最新变更"
        fi
    fi

    return 0
} 