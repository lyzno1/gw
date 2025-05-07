#!/bin/bash
# 脚本/actions/cmd_rm_branch.sh
#
# Implements the 'rm' (remove branch) command logic.
# Dependencies:
# - colors.sh (for YELLOW, BLUE, RED, GREEN, NC)
# - utils.sh (for check_in_git_repo, get_current_branch_name, confirm_action)
# - config_vars.sh (for MAIN_BRANCH, REMOTE_NAME)
# - utils_print.sh (for print_step, print_success, print_error, print_warning, print_info)

# 删除本地分支 (新命令 gw rm)
cmd_rm_branch() {
    if ! check_in_git_repo; then return 1; fi

    local target="$1"
    local force=false
    local delete_all_remotes_too=false # 新增标志，用于 all 模式下是否删除远程
    
    if [ -z "$target" ]; then
        print_error "错误: 请指定要删除的分支名称或 'all'。"
        print_info "用法: gw rm <分支名|all> [-f] [--delete-remotes]"
        return 1
    fi
    shift # 移除 target 参数
    
    # 解析剩余参数
    # local other_args_for_single_delete=() # 不再需要，因为 git branch -d/-D 不接受额外参数
    for arg in "$@"; do
        case "$arg" in
            -f|--force)
                force=true
                ;;
            --delete-remotes) 
                delete_all_remotes_too=true
                ;;
            *)
                # 对于 'gw rm all' 和 'gw rm <branch>'，除了 -f 和 --delete-remotes，其他参数通常不适用
                print_warning "未知参数 '$arg' 在 'gw rm $target' 命令中将被忽略。"
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

        print_step "正在查找可清理的分支 (已合并到 '$MAIN_BRANCH')..."
        
        local local_branches_to_delete=()
        local remote_branches_to_delete=()
        local candidate_branches=()

        # 获取所有不是 MAIN_BRANCH 也不是当前分支的本地分支
        # 同时检查它们是否已合并到 MAIN_BRANCH
        while IFS= read -r line; do
            candidate_branches+=("$line")
        done < <(git branch --merged "$MAIN_BRANCH" --format="%(refname:short)" | grep -v -E "^(\* )?$MAIN_BRANCH$")

        if [ ${#candidate_branches[@]} -eq 0 ]; then
            print_info "没有找到已合并到 '$MAIN_BRANCH' 的其他本地分支可供清理。"
            return 0
        fi

        print_info "以下已合并到 '$MAIN_BRANCH' 的本地分支将被考虑删除:"
        for b in "${candidate_branches[@]}"; do 
            echo "  - 本地: $b"
            local_branches_to_delete+=("$b")
            # 检查对应的远程分支是否存在
            if $delete_all_remotes_too && git ls-remote --exit-code --heads "$REMOTE_NAME" "$b" > /dev/null 2>&1; then
                echo "    - 远程: $REMOTE_NAME/$b"
                remote_branches_to_delete+=("$REMOTE_NAME/$b") # 存储格式为 remote/branch
            fi
        done
        echo ""

        if [ ${#local_branches_to_delete[@]} -eq 0 ] && [ ${#remote_branches_to_delete[@]} -eq 0 ]; then
            print_info "没有可删除的分支。" 
            if ! $delete_all_remotes_too; then print_info "(提示: 使用 --delete-remotes 选项可同时考虑删除匹配的远程分支)"; fi
            return 0
        fi

        local num_local_to_delete=${#local_branches_to_delete[@]}
        local num_remote_to_delete=${#remote_branches_to_delete[@]}
        local confirm_msg="确认要删除这 ${num_local_to_delete} 个本地分支"
        if [ "$num_remote_to_delete" -gt 0 ]; then
            confirm_msg+=" 和 ${num_remote_to_delete} 个远程分支"
        fi
        confirm_msg+="吗？此操作不可逆！"

        if $force; then
            print_warning "强制删除模式 (-f) 将用于本地分支删除。"
        fi
        if $delete_all_remotes_too; then
             print_info "远程分支也将被删除 (--delete-remotes)。"
        fi

        if ! confirm_action "$confirm_msg" "N"; then
            echo "已取消批量删除操作。"
            return 1
        fi
        
        local local_delete_flag="-d"
        if $force; then local_delete_flag="-D"; fi
        local success_local_count=0; local fail_local_count=0
        local success_remote_count=0; local fail_remote_count=0
        
        print_step "开始批量删除本地分支..."
        for branch_name in "${local_branches_to_delete[@]}"; do
            echo -n "  删除本地分支 '$branch_name'... "
            if git branch "$local_delete_flag" "$branch_name"; then
                echo -e "${GREEN}成功${NC}"
                success_local_count=$((success_local_count + 1))
            else
                echo -e "${RED}失败${NC}"
                fail_local_count=$((fail_local_count + 1))
            fi
        done

        if [ ${#remote_branches_to_delete[@]} -gt 0 ]; then
            print_step "开始批量删除远程分支..."
            for remote_branch_ref in "${remote_branches_to_delete[@]}"; do
                # remote_branch_ref 格式是 remote/branch, 例如 origin/feature-x
                # 我们需要从中提取远程名和纯分支名
                local remote_part=$(dirname "$remote_branch_ref")
                local branch_part=$(basename "$remote_branch_ref")
                echo -n "  删除远程分支 '$remote_part/$branch_part'... "
                if git push "$remote_part" --delete "$branch_part"; then
                    echo -e "${GREEN}成功${NC}"
                    success_remote_count=$((success_remote_count + 1))
                else
                    echo -e "${RED}失败${NC}"
                    fail_remote_count=$((fail_remote_count + 1))
                fi
            done
        fi
        
        echo -e "${GREEN}--- 批量删除总结 ---${NC}"
        echo -e "本地分支: 成功 ${GREEN}$success_local_count${NC}, 失败 ${RED}$fail_local_count${NC}"
        if $delete_all_remotes_too || [ ${#remote_branches_to_delete[@]} -gt 0 ]; then # 只有当尝试过删除远程时才显示远程统计
            echo -e "远程分支: 成功 ${GREEN}$success_remote_count${NC}, 失败 ${RED}$fail_remote_count${NC}"
        fi

        if [ $fail_local_count -gt 0 ] || [ $fail_remote_count -gt 0 ]; then
             print_warning "提示: 删除失败的分支可能包含未合并的更改 (若本地未使用 -f) 或其他问题。"
             return 1
        fi
        return 0
    else # 单个分支删除逻辑
        local branch_to_del="$target"
        
        if [ "$branch_to_del" = "$current_branch" ]; then
            print_error "错误：不能删除当前所在的分支。请先切换到其他分支。"
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

        local local_delete_flag="-d"
        # 确定删除标志前，先获取上游信息，因为强制删除的确认逻辑可能先于本地删除执行
        
        local upstream_info=""
        local actual_remote_for_deletion="$REMOTE_NAME" # 默认为配置的远程
        local actual_remote_branch_for_deletion="$branch_to_del" # 默认为本地分支名
        local upstream_found_and_parsed=false

        # 尝试获取上游信息
        # 这个检查必须在分支实际删除前，但分支有效性检查已在前头完成
        upstream_info=$(git for-each-ref --format='%(upstream:short)' "refs/heads/$branch_to_del" 2>/dev/null)
        if [ -n "$upstream_info" ] && [[ "$upstream_info" == */* ]]; then
            actual_remote_for_deletion=$(dirname "$upstream_info")
            actual_remote_branch_for_deletion=$(basename "$upstream_info")
            upstream_found_and_parsed=true
            print_info "本地分支 '$branch_to_del' 当前跟踪远程分支 '${actual_remote_for_deletion}/${actual_remote_branch_for_deletion}'。"
        else
            print_info "本地分支 '$branch_to_del' 没有配置有效的上游跟踪信息或无法解析。"
            print_info "如果需要删除远程分支，将尝试 '$REMOTE_NAME/$branch_to_del'。"
        fi

        if $force; then
            local_delete_flag="-D"
            print_warning "将强制删除本地分支 '$branch_to_del'。"
        else
            # 检查是否已合并到当前分支 (或者主分支更合适？对于单个删除，通常是当前分支)
            # 注意: 这个合并检查可能与一些用户期望不同，例如，如果用户想删除未合并到当前但已合并到主分支的特性分支
            # 但为了与 git branch -d 的默认行为（检查合并状态）保持某种一致性，这里保留。
            # 如果分支未合并，会触发下面的确认逻辑。
            if ! git branch --merged | grep -qw "$branch_to_del"; then 
                 print_warning "分支 '$branch_to_del' 包含未合并到当前分支 ('$current_branch') 的更改。"
                 if confirm_action "是否要强制删除此本地分支 '$branch_to_del'？" "N"; then
                     local_delete_flag="-D"
                 else
                     print_info "已取消分支删除操作。"
                     return 1
                 fi
            fi
        fi
        
        print_step "正在删除本地分支 '$branch_to_del' (使用 $local_delete_flag)..."
        if git branch "$local_delete_flag" "$branch_to_del"; then
            print_success "成功删除本地分支 '$branch_to_del'"
            
            local remote_branch_display_name="${actual_remote_for_deletion}/${actual_remote_branch_for_deletion}"
            
            # 检查对应的远程分支是否存在，并根据 --delete-remotes 或单独确认
            if git ls-remote --exit-code --heads "$actual_remote_for_deletion" "$actual_remote_branch_for_deletion" > /dev/null 2>&1; then
                local should_delete_this_remote=false
                if $delete_all_remotes_too; then # 如果 gw rm <branch> --delete-remotes
                    should_delete_this_remote=true
                    if $upstream_found_and_parsed && ( [ "$branch_to_del" != "$actual_remote_branch_for_deletion" ] || [ "$REMOTE_NAME" != "$actual_remote_for_deletion" ] ); then
                         print_info "根据跟踪信息，将尝试删除远程分支 '$remote_branch_display_name' (由于指定了 --delete-remotes)。"
                    elif $upstream_found_and_parsed; then
                         print_info "将尝试删除远程分支 '$remote_branch_display_name' (由于指定了 --delete-remotes)。"
                    else # 没有上游信息，但 --delete-remotes 指定
                         print_info "将尝试删除远程分支 '$REMOTE_NAME/$branch_to_del' (由于指定了 --delete-remotes)。"
                    fi
                else # 如果是 gw rm <branch> (没有 --delete-remotes)
                    local confirm_remote_delete_msg="是否同时删除远程分支 '$remote_branch_display_name'？"
                    if $upstream_found_and_parsed && ( [ "$branch_to_del" != "$actual_remote_branch_for_deletion" ] || [ "$REMOTE_NAME" != "$actual_remote_for_deletion" ] ); then
                         # 表明上游与默认猜测不同
                        confirm_remote_delete_msg="本地分支 '$branch_to_del' 跟踪 '$remote_branch_display_name'。是否删除该远程分支？"
                    elif ! $upstream_found_and_parsed; then
                        # 没有上游，提示删除默认远程的同名分支
                        confirm_remote_delete_msg="是否同时删除远程分支 '$REMOTE_NAME/$branch_to_del'？"
                    fi
                    # 如果 $upstream_found_and_parsed is true AND 远程与本地同名且与默认远程同名，则confirm_remote_delete_msg保持默认
                    
                    if confirm_action "$confirm_remote_delete_msg" "N"; then
                        should_delete_this_remote=true
                    fi
                fi

                if $should_delete_this_remote; then
                    print_step "正在删除远程分支 '$remote_branch_display_name'..."
                    if git push "$actual_remote_for_deletion" --delete "$actual_remote_branch_for_deletion"; then
                        print_success "成功删除远程分支 '$remote_branch_display_name'"
                    else
                        print_error "删除远程分支 '$remote_branch_display_name' 失败。"
                        # 即使远程删除失败，本地也已删除，所以整体结果可能是部分成功
                        # 可以考虑返回一个特定错误码或信息
                    fi
                fi
            elif $delete_all_remotes_too; then # 如果 --delete-remotes 指定了，但目标远程分支未找到
                if $upstream_found_and_parsed; then
                    print_info "选项 --delete-remotes 已指定，但未找到要删除的已跟踪远程分支 '$remote_branch_display_name'。"
                else
                    print_info "选项 --delete-remotes 已指定，但未找到要删除的远程分支 '$REMOTE_NAME/$branch_to_del'。"
                fi
            fi
            return 0
        else
            print_error "删除本地分支 '$branch_to_del' 失败。"
            return 1
        fi
    fi
} 