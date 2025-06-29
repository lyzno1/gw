#!/bin/bash
# 脚本/actions/cmd_update.sh # Renamed from cmd_sync.sh
#
# 实现 'update' 命令逻辑。 # Renamed from 'sync'
# 依赖:
# - colors.sh (颜色定义)
# - utils_print.sh (打印函数)
# - utils.sh (通用工具函数)
# - config_vars.sh (配置变量)
# - git_network_ops.sh (do_pull_with_retry)

# 同步当前分支 (拉取主分支最新代码并 rebase 或 merge)
cmd_update() { # Renamed from cmd_sync
    if ! check_in_git_repo; then return 1; fi

    # 解析参数
    local use_merge=false
    local args=()
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --merge|-m)
                use_merge=true
                shift
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done
    
    # 如果有未识别的参数，报错
    if [ ${#args[@]} -gt 0 ]; then
        print_error "未识别的参数: ${args[*]}"
        echo "用法: gw update [--merge|-m]"
        echo "  --merge, -m    使用 merge 而不是 rebase 来整合主分支变更"
        return 1
    fi

    local original_branch
    original_branch=$(get_current_branch_name)
    if [ $? -ne 0 ]; then return 1; fi

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
                print_step "正在暂存当前变更 (cmd_stash push)..."
                if cmd_stash push -m "在同步 $original_branch 前自动暂存"; then
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

    if [ "$original_branch" = "$MAIN_BRANCH" ]; then
        print_info "您已在主分支 ($MAIN_BRANCH)。正在尝试拉取最新代码 (使用 rebase)..."
        if ! do_pull_with_retry --rebase "$REMOTE_NAME" "$MAIN_BRANCH"; then # 明确使用 --rebase 策略
            print_error "从远程 '$REMOTE_NAME' 拉取并 rebase 主分支 '$MAIN_BRANCH' 失败。"
            # 如果因拉取失败而退出，也尝试恢复stash
            if $stash_needed; then
                print_warning "正在尝试恢复之前暂存的变更 (cmd_stash pop)..."
                if ! cmd_stash pop; then
                    print_warning "恢复暂存失败。您可能需要手动使用 'cmd_stash pop'。当前暂存列表:"
                    cmd_stash list
                else
                    print_success "之前暂存的变更已成功恢复。"
                fi
            fi
            return 1
        fi
        print_success "主分支 '$MAIN_BRANCH' 已成功更新。"
    else # 非主分支的同步逻辑
        echo -e "${CYAN}=== 同步当前分支 ('$original_branch') ===${NC}"
        
        # 1. 获取远程主分支最新代码
        print_step "1/2: 获取远程主分支 ($REMOTE_NAME/$MAIN_BRANCH) 的最新代码..."
        if ! git fetch "$REMOTE_NAME" "$MAIN_BRANCH"; then
            print_error "获取远程主分支更新失败。"
            if $stash_needed; then
                print_warning "正在尝试恢复之前暂存的变更..."
                if ! cmd_stash pop; then
                    print_warning "恢复暂存失败。手动处理: cmd_stash list / pop"
                else
                    print_success "暂存已恢复。"
                fi
            fi
            return 1
        fi
        print_success "远程主分支已获取。"

        # 2. 基于远程主分支进行 rebase 或 merge
        if $use_merge; then
            print_step "2/2: 将远程主分支 '$REMOTE_NAME/$MAIN_BRANCH' Merge 到当前分支 '$original_branch'..."
            if git merge "$REMOTE_NAME/$MAIN_BRANCH"; then
                print_success "成功将 '$REMOTE_NAME/$MAIN_BRANCH' Merge 到 '$original_branch'。"
            else
                print_error "Merge 操作失败或遇到冲突。"
                echo -e "请解决 Merge 冲突。"
                echo -e "解决冲突后，运行 'gw add <冲突文件>' 然后 'git commit'。"
                echo -e "如果想中止 Merge，可以运行 'git merge --abort'。"
                # Merge 失败时，stash 的恢复需要用户在 merge 完成后手动操作
                if $stash_needed; then
                    print_warning "请注意：您之前暂存的变更在 Merge 成功并结束后需要手动恢复 (git stash pop)。"
                fi
                return 1 # Merge 失败，脚本不应尝试自动 pop stash
            fi
        else
            print_step "2/2: 将当前分支 '$original_branch' Rebase 到最新的 '$REMOTE_NAME/$MAIN_BRANCH'..."
            if git rebase "$REMOTE_NAME/$MAIN_BRANCH"; then
                print_success "成功将 '$original_branch' Rebase 到 '$REMOTE_NAME/$MAIN_BRANCH'。"
            else
                print_error "Rebase 操作失败或遇到冲突。"
                echo -e "请解决 Rebase 冲突。"
                echo -e "解决冲突后，运行 'gw add <冲突文件>' 然后 'git rebase --continue'。"
                echo -e "如果想中止 Rebase，可以运行 'git rebase --abort'。"
                # Rebase 失败时，stash 的恢复需要用户在 rebase 完成后手动操作
                if $stash_needed; then
                    print_warning "请注意：您之前暂存的变更在 Rebase 成功并结束后需要手动恢复 (git stash pop)。"
                fi
                return 1 # Rebase 失败，脚本不应尝试自动 pop stash
            fi
        fi
    fi # 结束非主分支的同步逻辑

    # 6. 如果之前暂存了，尝试恢复 (现在这个逻辑对主分支和非主分支都适用，在各自成功路径后执行)
    if $stash_needed; then
        print_step "正在尝试恢复之前暂存的变更 (cmd_stash pop)..."
        if cmd_stash pop; then
            print_success "成功恢复暂存的变更。"
        else
            print_error "自动恢复暂存失败。可能存在冲突。"
            print_info "请运行 'git status' 查看详情，并手动解决冲突。未恢复的暂存在 'cmd_stash list' 中。"
        fi
    fi

    echo -e "${GREEN}=== 同步操作完成 ('$original_branch') ===${NC}"
    return 0
} 