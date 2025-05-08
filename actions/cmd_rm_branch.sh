#!/bin/bash
# 脚本/actions/cmd_rm_branch.sh
#
# Implements the 'rm' (remove branch) command logic.
# Dependencies:
# - colors.sh (for YELLOW, BLUE, RED, GREEN, NC)
# - utils.sh (for check_in_git_repo, get_current_branch_name, confirm_action)
# - config_vars.sh (for MAIN_BRANCH, REMOTE_NAME)
# - utils_print.sh (for print_step, print_success, print_error, print_warning, print_info)

# 检查分支是否已完全合并到主分支 (针对rebase工作流优化)
is_branch_merged_to_main() {
    local branch_to_check="$1"
    local commits_ahead
    commits_ahead=$(git rev-list --count "$MAIN_BRANCH..$branch_to_check" 2>/dev/null)
    
    if [ -z "$commits_ahead" ]; then
        return 1 # 保守起见，视为未合并或检查失败
    fi

    if [ "$commits_ahead" -eq 0 ]; then
        return 0 # 已合并 (没有新提交)
    else
        return 1 # 未合并 (有新提交)
    fi
}

# 删除本地分支 (新命令 gw rm)
cmd_rm_branch() {
    if ! check_in_git_repo; then return 1; fi

    local target="$1"
    local global_force=false # -f 参数现在是全局的，影响所有删除操作
    # global_delete_remotes 标志不再需要
    
    if [ -z "$target" ]; then
        print_error "错误: 请指定要删除的分支名称或 'all'。"
        print_info "用法: gw rm <分支名|all> [-f]"
        return 1
    fi
    shift # 移除 target 参数
    
    # 解析剩余的全局参数 -f
    for arg_in_loop in "$@"; do # Use a different variable name for the loop
        case "$arg_in_loop" in
            -f|--force)
                global_force=true
                ;;
            # 移除 --delete-remotes 解析
            *)
                print_warning "未知参数 '$arg_in_loop' 在 'gw rm $target' 命令中将被忽略。 (-f 是唯一支持的选项)"
                ;;
        esac
    done

    local current_branch
    current_branch=$(get_current_branch_name)
    if [ $? -ne 0 ]; then return 1; fi
 
    if [ "$target" = "all" ]; then
        if [ "$current_branch" != "$MAIN_BRANCH" ]; then
            print_error "错误: 'gw rm all' 只能在主分支 ($MAIN_BRANCH) 上执行以确保安全。"
            print_info "您当前在分支 '$current_branch'。"
            return 1
        fi

        print_step "阶段 1: 查找并处理自动识别为已合并到 '$MAIN_BRANCH' 的分支..."
        local auto_merged_branches=()
        local remaining_non_main_branches=()

        while IFS= read -r branch; do
            if [ "$branch" = "$MAIN_BRANCH" ] || [ "$branch" = "$current_branch" ]; then
                continue
            fi
            
            if is_branch_merged_to_main "$branch"; then
                auto_merged_branches+=("$branch")
            else
                remaining_non_main_branches+=("$branch")
            fi
        done < <(git for-each-ref --format='%(refname:short)' refs/heads/)

        local overall_success=true

        if [ ${#auto_merged_branches[@]} -gt 0 ]; then
            print_info "以下分支被自动识别为已合并到 '$MAIN_BRANCH':"
            for b in "${auto_merged_branches[@]}"; do echo "  - $b"; done
            echo ""
            local confirm_msg="确认要删除这 ${#auto_merged_branches[@]} 个自动识别的本地分支吗？"
            # 不再需要检查 global_delete_remotes
            
            if confirm_action "$confirm_msg" "N"; then
                if $global_force; then print_warning "将对自动识别的分支使用强制删除 (-f)。"; fi
                
                for branch_name in "${auto_merged_branches[@]}"; do
                    print_info "处理自动识别分支: '$branch_name'"
                    # 调用单个分支删除逻辑，传递全局的 force 标志
                    if ! _delete_single_branch_internal "$branch_name" "$global_force" "$current_branch"; then
                        overall_success=false
                        print_warning "删除自动识别的分支 '$branch_name' 失败或被跳过。"
                    fi
                done
            else
                print_info "跳过了删除自动识别的已合并分支。"
            fi
        else
            print_info "没有找到可被自动识别为已合并到 '$MAIN_BRANCH' 的其他本地分支。"
        fi
        echo ""

        # --- 阶段 2: 处理剩余的非主分支 ---
        if [ ${#remaining_non_main_branches[@]} -gt 0 ]; then
            print_step "阶段 2: 处理剩余的其他本地非主分支..."
            echo -e "${YELLOW}以下本地分支未被自动识别为已合并，或在阶段1中被跳过:${NC}"
            for b in "${remaining_non_main_branches[@]}"; do echo "  - $b"; done
            echo ""
            echo "请选择如何处理这些剩余分支:"
            echo "  [M] 手动逐个审核并选择操作 (Manually review and act on each)"
            echo "  [F] 全部强制删除这些列出的分支 (Force delete ALL listed - DANGEROUS!)"
            echo "  [S] 全部跳过并完成 (Skip all and finish)"
            local choice_remaining
            read -r -p "您的选择 [M/F/S]: " choice_remaining

            case "$(echo "$choice_remaining" | tr '[:lower:]' '[:upper:]')" in
                M)
                    print_info "开始手动逐个审核剩余分支..."
                    for branch_name in "${remaining_non_main_branches[@]}"; do
                        echo ""
                        print_info "审核分支: '$branch_name'"
                        echo "  选择操作: (d) 安全删除 (delete) / (D) 强制删除 (FORCE delete) / (s) 跳过 (skip) / (q) 退出审核 (quit)"
                        local choice_manual
                        read -r -p "对 '$branch_name' 的操作 [d/D/s/q]: " choice_manual
                        case "$(echo "$choice_manual" | tr '[:lower:]' '[:upper:]')" in
                            D)
                                # 调用时不再传递 remote 标志
                                if ! _delete_single_branch_internal "$branch_name" true "$current_branch"; then overall_success=false; fi
                                ;;
                            d)
                                if ! _delete_single_branch_internal "$branch_name" false "$current_branch"; then overall_success=false; fi
                                ;;
                            S)
                                print_info "已跳过分支 '$branch_name'。"
                                ;;
                            Q)
                                print_info "已退出手动审核。"
                                break
                                ;;
                            *)
                                print_warning "无效选择，已跳过分支 '$branch_name'。"
                                ;;
                        esac
                    done
                    ;;
                F)
                    print_warning "${BOLD}${RED}警告：您选择了全部强制删除所有 ${#remaining_non_main_branches[@]} 个列出的剩余非主分支！${NC}"
                    print_warning "${RED}此操作将无视这些分支的合并状态，直接使用 'git branch -D'。${NC}"
                    # 不再需要检查 global_delete_remotes
                    print_warning "${RED}这是一个非常危险的操作，可能导致未推送或未完成的工作永久丢失！${NC}"
                    
                    if confirm_action "您确定要强制删除所有 ${#remaining_non_main_branches[@]} 个列出的剩余分支吗？请再次确认此危险操作！" "N"; then
                        print_info "确认通过。开始强制删除所有列出的剩余分支..."
                        for branch_name in "${remaining_non_main_branches[@]}"; do
                            # 调用时强制标志为 true，不传 remote 标志
                            if ! _delete_single_branch_internal "$branch_name" true "$current_branch"; then 
                                overall_success=false;
                            fi
                        done
                    else
                        print_error "确认未通过。已取消强制批量删除操作。"
                        overall_success=false
                    fi
                    ;;
                S)
                    print_info "已选择跳过所有剩余的非主分支。"
                    ;;
                *)
                    print_warning "无效选择。未对剩余分支执行任何操作。"
                    overall_success=false
                    ;;
            esac
        elif [ ${#auto_merged_branches[@]} -eq 0 ]; then
             print_info "没有其他本地分支可供清理 (除了 '$MAIN_BRANCH')。"
        fi 
        
        if $overall_success; then
            print_success "'gw rm all' 操作处理完毕。"
            return 0
        else
            print_warning "'gw rm all' 操作已处理，但可能部分分支未按预期删除或被跳过。请检查输出。"
            return 1
        fi
        
    else # 单个分支删除逻辑 (gw rm <branch_name> [-f])
        # 调用内部函数，只传递 force 标志
        if _delete_single_branch_internal "$target" "$global_force" "$current_branch"; then
            return 0
        else
             return 1
        fi
    fi
}

# 内部函数，用于删除单个分支，由 cmd_rm_branch 的 'all' 模式和单一模式调用
# 参数: $1: branch_to_del, $2: force_flag (true/false string), $3: current_branch_name_when_called
_delete_single_branch_internal() {
    local branch_to_del="$1"
    local force_delete=$2 # Expects "true" or "false"
    local caller_current_branch="$3"
    # 不再需要 delete_remotes 参数

    if [ "$branch_to_del" = "$caller_current_branch" ]; then
        print_error "错误：不能删除当前所在的分支 ('$caller_current_branch')。请先切换。"
            return 1
        fi
        
        if [ "$branch_to_del" = "$MAIN_BRANCH" ]; then
            print_error "错误：不能删除主分支 ($MAIN_BRANCH)。"
            return 1
        fi
        
        if ! git rev-parse --verify --quiet "refs/heads/$branch_to_del"; then
             print_error "错误：本地分支 '$branch_to_del' 不存在。"
             return 1
        fi

    local local_delete_git_flag="-d"
    local perform_force_delete_check=true

    if [ "$force_delete" = true ]; then
        local_delete_git_flag="-D"
        perform_force_delete_check=false
        print_info "将强制删除本地分支 '$branch_to_del' (使用 -D)。"
    fi

    if $perform_force_delete_check; then
        if ! git branch --merged "$caller_current_branch" | grep -qE "(^\* |^[[:space:]]+)$branch_to_del$"; then
            print_warning "分支 '$branch_to_del' 包含未合并到 '$caller_current_branch' 的更改。"
            if confirm_action "是否要强制删除此分支 '$branch_to_del'？" "N"; then
                local_delete_git_flag="-D"
                print_info "将强制删除本地分支 '$branch_to_del' (用户确认)。"
            else
                print_info "已取消删除分支 '$branch_to_del'。"
                return 1
            fi
        fi
    fi
    
    local local_branch_deleted_successfully=false
    print_step "尝试删除本地分支 '$branch_to_del' (使用 git branch $local_delete_git_flag $branch_to_del)..."
    if git branch "$local_delete_git_flag" "$branch_to_del"; then
        print_success "本地分支 '$branch_to_del' 删除成功。"
        local_branch_deleted_successfully=true
    else
        print_error "删除本地分支 '$branch_to_del' 失败。"
        return 1 # 本地删除失败，直接返回错误
    fi

    # 总是检查远程分支 (如果本地删除成功)
    if $local_branch_deleted_successfully; then
        local remote_to_try="$REMOTE_NAME"
        local remote_branch_to_try="$branch_to_del"
        
        print_info "正在检查远程 '$remote_to_try' 上是否存在同名分支 '$remote_branch_to_try'..."
        if git ls-remote --exit-code --heads "$remote_to_try" "$remote_branch_to_try" > /dev/null 2>&1; then
            print_warning "检测到远程分支 '$remote_to_try/$remote_branch_to_try'。"
            if confirm_action "是否要删除此远程分支 '$remote_to_try/$remote_branch_to_try'？" "N"; then
                print_step "尝试删除远程分支 '$remote_to_try/$remote_branch_to_try'..."
                if git push "$remote_to_try" --delete "$remote_branch_to_try"; then
                    print_success "远程分支 '$remote_to_try/$remote_branch_to_try' 删除成功。"
                    # 即使远程删除成功，整体仍然是成功
                else
                    print_error "删除远程分支 '$remote_to_try/$remote_branch_to_try' 失败。"
                    return 1 # 远程删除失败，将此次操作标记为失败
                fi
            else
                print_info "已跳过删除远程分支 '$remote_to_try/$remote_branch_to_try'。"
            fi
        else
            print_info "在远程 '$remote_to_try' 上未找到同名分支 '$remote_branch_to_try'。"
        fi
    fi

    return 0 # 本地删除成功，远程处理完成（或跳过）
} 