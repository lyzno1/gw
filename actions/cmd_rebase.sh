#!/bin/bash
# 脚本/actions/cmd_rebase.sh
#
# 实现 'rebase' 命令逻辑。
# 依赖:
# - core_utils/colors.sh (颜色定义)
# - core_utils/utils_print.sh (打印函数)
# - core_utils/utils.sh (通用工具函数)
# - core_utils/config_vars.sh (配置变量)
# - core_utils/git_network_ops.sh (do_pull_with_retry)
# - actions/cmd_stash.sh (cmd_stash 函数)

cmd_rebase() {
    if ! check_in_git_repo; then return 1; fi

    local current_branch
    current_branch=$(get_current_branch_name)
    if [ $? -ne 0 ]; then return 1; fi

    # Handle rebase management options first
    if [[ "$1" == "--continue" || "$1" == "--abort" || "$1" == "--skip" || "$1" == "--edit-todo" || "$1" == "--show-current-patch" ]]; then
        print_info "执行: git rebase $1"
        git rebase "$1"
        local rebase_status=$?
        if [ $rebase_status -eq 0 ]; then
            print_success "git rebase $1 操作成功。"
        else
            print_error "git rebase $1 操作失败。"
        fi
        return $rebase_status
    fi

    # --- Stash uncommitted changes if any ---
    local stash_needed_by_rebase=false
    if check_uncommitted_changes || check_untracked_files; then
        print_warning "检测到未提交的变更或未追踪的文件。"
        echo "变更详情:"
        git status -s
        echo ""
        echo -e "${YELLOW}在执行 rebase 前，建议处理这些变更:${NC}"
        echo -e "1) ${GREEN}暂存 (Stash) 当前变更并继续${NC}"
        echo -e "2) ${RED}取消 'rebase' 操作${NC}"
        local choice_stash
        read -r -p "请选择操作 [1-2]: " choice_stash

        case "$choice_stash" in
            1)
                local stash_msg="WIP on $current_branch before rebase"
                print_step "正在暂存当前变更 (cmd_stash push -m \"$stash_msg\")..."
                if cmd_stash push -m "$stash_msg"; then
                    print_success "变更已成功暂存。"
                    stash_needed_by_rebase=true
                else
                    print_error "暂存变更失败。'rebase' 操作已取消。"
                    return 1
                fi
                ;;
            2|*)
                print_info "'rebase' 操作已取消。"
                return 1
                ;;
        esac
        echo "" # Add a newline for better readability
    fi

    # --- Main rebase logic ---
    local rebase_target_branch="$1" # Assume the first arg is the target branch for now
    local rebase_args=("$@") # All arguments

    if [ -z "$rebase_target_branch" ]; then
        print_error "错误: 请指定 rebase 的目标或选项。"
        print_info "用法: gw rebase <目标分支> [其他 git rebase 参数]"
        print_info "      gw rebase [-i|--interactive] <commit-ish>"
        print_info "      gw rebase --continue | --abort | --skip"
        if $stash_needed_by_rebase; then
            print_warning "之前暂存的变更尚未恢复。可使用 'gw stash pop' 手动恢复。"
        fi
        return 1
    fi

    # Scenario 1: Rebase onto a specific upstream branch
    # We'll consider it this scenario if the first argument doesn't start with '-' (is not an option)
    # and is a valid branch reference (local or remote).
    local is_rebase_onto_upstream=false
    if ! [[ "$rebase_target_branch" =~ ^- ]]; then # Not an option like -i
        # Check if it's a known local or remote branch. This is a simplified check.
        # A more robust check would involve `git rev-parse --verify`.
        if git show-ref --verify --quiet "refs/heads/$rebase_target_branch" || \
           git show-ref --verify --quiet "refs/remotes/$REMOTE_NAME/$rebase_target_branch"; then
            is_rebase_onto_upstream=true
        fi
    fi
    
    local final_rebase_status=0

    if $is_rebase_onto_upstream; then
        print_step "准备将当前分支 ('$current_branch') rebase 到 '$rebase_target_branch'..."
        shift # Remove rebase_target_branch from rebase_args
        local remaining_rebase_args=("$@")

        # Ensure base branch exists locally and is up-to-date
        local base_branch_exists_locally=false
        if git rev-parse --verify --quiet "refs/heads/$rebase_target_branch" > /dev/null 2>&1; then
            base_branch_exists_locally=true
        fi

        if ! $base_branch_exists_locally; then
            if git rev-parse --verify --quiet "refs/remotes/$REMOTE_NAME/$rebase_target_branch" > /dev/null 2>&1; then
                print_info "本地不存在分支 '$rebase_target_branch'，但远程 '$REMOTE_NAME/$rebase_target_branch' 存在。"
                print_step "正在从远程获取 '$rebase_target_branch'..."
                if ! git fetch "$REMOTE_NAME" "$rebase_target_branch:refs/remotes/$REMOTE_NAME/$rebase_target_branch"; then
                    print_error "从远程 '$REMOTE_NAME' 获取分支 '$rebase_target_branch' 失败。"
                    if $stash_needed_by_rebase; then cmd_stash pop; fi # Try to restore stash
                    return 1
                fi
                if ! git branch "$rebase_target_branch" "refs/remotes/$REMOTE_NAME/$rebase_target_branch"; then
                    print_error "创建本地跟踪分支 '$rebase_target_branch' 失败。"
                    if $stash_needed_by_rebase; then cmd_stash pop; fi
                    return 1
                fi
                print_success "成功获取并创建本地分支 '$rebase_target_branch'。"
            else
                print_error "错误: 目标分支 '$rebase_target_branch' 在本地和远程 '$REMOTE_NAME' 都不存在。"
                if $stash_needed_by_rebase; then cmd_stash pop; fi
                return 1
            fi
        fi

        # Update the base_branch
        local original_branch_for_pull="$current_branch"
        if [ "$current_branch" != "$rebase_target_branch" ]; then # Temporarily switch if not on base
            print_step "临时切换到 '$rebase_target_branch' 以更新它..."
            if ! git checkout "$rebase_target_branch"; then
                print_error "切换到 '$rebase_target_branch' 失败。无法更新。"
                if $stash_needed_by_rebase; then cmd_stash pop; fi
                return 1
            fi
        fi
        
        print_step "正在更新目标分支 '$rebase_target_branch' (拉取最新)..."
        if ! do_pull_with_retry --rebase "$REMOTE_NAME" "$rebase_target_branch"; then
            print_error "更新目标分支 '$rebase_target_branch' 失败。"
            if [ "$current_branch" != "$rebase_target_branch" ]; then # Switch back if we switched
                 git checkout "$original_branch_for_pull" >/dev/null 2>&1
            fi
            if $stash_needed_by_rebase; then cmd_stash pop; fi
            return 1
        fi
        print_success "目标分支 '$rebase_target_branch' 已更新。"

        if [ "$current_branch" != "$rebase_target_branch" ]; then # Switch back if we switched
            print_step "切换回原分支 '$original_branch_for_pull'..."
            if ! git checkout "$original_branch_for_pull"; then
                print_error "切换回原分支 '$original_branch_for_pull' 失败。"
                # Stash was on original_branch_for_pull, but we can't get back to it.
                print_warning "请注意：之前暂存的变更需要手动在分支 '$original_branch_for_pull' 上恢复。"
                return 1
            fi
        fi
        
        print_step "执行: git rebase $rebase_target_branch ${remaining_rebase_args[*]}"
        # shellcheck disable=SC2068 # We want word splitting for remaining_rebase_args
        git rebase "$rebase_target_branch" ${remaining_rebase_args[@]}
        final_rebase_status=$?

    else
        # Scenario 2: Interactive rebase or other git rebase options
        print_step "执行: git rebase ${rebase_args[*]}"
        # shellcheck disable=SC2068 # We want word splitting
        git rebase ${rebase_args[@]}
        final_rebase_status=$?
    fi

    # --- Feedback and Stash Pop ---
    if [ $final_rebase_status -eq 0 ]; then
        print_success "Rebase 操作成功完成。"
        if $stash_needed_by_rebase; then
            print_step "尝试恢复之前暂存的变更 (gw stash pop)..."
            if cmd_stash pop; then
                print_success "之前暂存的变更已成功恢复。"
            else
                print_error "恢复暂存失败 (可能存在冲突)。"
                print_info "请运行 'git status' 查看详情，并使用 'gw stash list' 和 'gw stash apply' 手动恢复。"
                git status -s # Show status after failed pop
            fi
        fi
    else
        print_error "Rebase 操作失败或遇到冲突。"
        print_info "请解决 Rebase 冲突。"
        print_info "  - 解决冲突后: gw add <文件> && gw rebase --continue"
        print_info "  - 跳过补丁: gw rebase --skip"
        print_info "  - 中止 Rebase: gw rebase --abort"
        if $stash_needed_by_rebase; then
            print_warning "请注意: 之前暂存的变更在 Rebase 成功并结束后需要手动恢复 (gw stash pop)。"
        fi
    fi
    return $final_rebase_status
} 