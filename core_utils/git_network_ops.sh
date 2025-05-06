#!/bin/bash

# 脚本/git_network_ops.sh
#
# 此文件定义了与 Git 网络操作（如 push 和 pull）相关且包含重试逻辑的核心函数。
# 旨在被其他脚本 source。
# 注意：此文件依赖于 colors.sh, config_vars.sh, utils_print.sh, 和 utils.sh。

# 执行带重试的 Git 推送
do_push_with_retry() {
    local push_args=()
    local remote_to_check="$REMOTE_NAME" # 默认为配置的远程
    local branch_to_push=""
    local current_branch
    current_branch=$(get_current_branch_name)
    if [ $? -ne 0 ]; then return 1; fi

    # --- 前置检查：未提交的变更 ---
    if check_uncommitted_changes || check_untracked_files; then
        echo -e "${YELLOW}检测到未提交的变更或未追踪的文件。${NC}"
        echo "变更详情:"
        git status -s
        echo ""
        # 确保 cmd_add_all 和 cmd_commit 可用
        if ! command -v cmd_add_all >/dev/null 2>&1 || ! command -v cmd_commit >/dev/null 2>&1; then
            print_error "cmd_add_all 或 cmd_commit 命令未找到。请先处理变更或确保脚本完整。"
            return 1
        fi
        if confirm_action "是否要将所有变更添加到暂存区并提交，然后再推送？"; then
            echo -e "${BLUE}正在暂存所有变更...${NC}"
            if ! cmd_add_all; then
                print_error "暂存变更失败，推送已取消。"
                return 1
            fi
            
            echo -e "${BLUE}正在提交变更...${NC}"
            if ! cmd_commit; then
                print_error "提交失败或被取消，推送已取消。"
                return 1
            fi
            echo -e "${GREEN}变更已提交，继续推送...${NC}"
        else
            echo "推送已取消。请先处理未提交的变更。"
            return 1
        fi
    fi

    local other_args=()
    local arg_count=$#
    local args_array=("$@") 

    local potential_remote=""
    local potential_branch=""
    local set_upstream=false

    # 解析参数以确定实际的远程和分支
    for (( i=0; i<$arg_count; i++ )); do
        local arg="${args_array[i]}"
        case "$arg" in
            -u|--set-upstream)
                set_upstream=true
                other_args+=("$arg")
                ;;
            -f|--force|--force-with-lease|--tags|--all|--prune|--mirror|--delete|--thin|--receive-pack=*|--repository=*|--gpg-sign*)
                other_args+=("$arg")
                ;;
            # 考虑一个更通用的方式来捕获所有以 '-' 开头的选项
            # 或者明确列出所有 git push 支持的选项
            --dry-run|--porcelain|--progress|--quiet|--verbose|--ipv4|--ipv6|--atomic|--follow-tags|--no-signed|--no-verify|--signed|--verify)
                other_args+=("$arg")
                ;;
            -*) # 捕获其他短选项或组合选项
                # 注意：这可能不够完美，复杂的选项组合可能需要更高级的解析
                other_args+=("$arg") 
                ;;
            *) # 非选项参数
                if [ -z "$potential_remote" ]; then
                    # 第一个非选项参数，尝试判断它是远程还是分支
                    # 如果它匹配已知的远程名，则认为是远程
                    if git remote | grep -qw "^$arg$"; then
                        potential_remote="$arg"
                    # 否则，如果还没确定分支，就认为是分支
                    elif [ -z "$potential_branch" ]; then 
                        potential_branch="$arg"
                    # 如果远程和分支都已暂定，则认为是其他参数（例如 refspec）
                    else 
                        other_args+=("$arg") # 或将其视为 refspec 的一部分
                    fi
                elif [ -z "$potential_branch" ]; then
                    # 第二个非选项参数，认为是分支（或 refspec 的一部分）
                    potential_branch="$arg"
                else
                    # 更多的非选项参数，通常是 refspecs
                    other_args+=("$arg") 
                fi
                ;;
        esac
    done

    remote_to_check=${potential_remote:-$REMOTE_NAME} 
    branch_to_push=${potential_branch:-$current_branch} 

    # --- 新增：检查远程仓库是否存在且有 URL ---
    if ! git remote get-url "$remote_to_check" > /dev/null 2>&1; then
        print_error "远程仓库 '$remote_to_check' 未配置或没有有效的 URL。"
        echo -e "${CYAN}请使用 'gw remote add $remote_to_check <URL>' 或 'git remote add $remote_to_check <URL>' 添加远程仓库后再试。${NC}"
        return 1
    fi
    # --- 远程检查结束 ---

    push_args=("$remote_to_check") # 始终先添加远程

    # 如果 branch_to_push 包含 ':' (refspec)，则直接使用
    if [[ "$branch_to_push" == *":"* ]]; then
        push_args+=("$branch_to_push")
    else
        # 否则，如果 branch_to_push 非空，则添加它
        # 这也处理了用户可能只提供远程名的情况，此时 branch_to_push 会是当前分支
        [ -n "$branch_to_push" ] && push_args+=("$branch_to_push")
    fi
    
    push_args+=("${other_args[@]}")


    # 自动设置上游逻辑：仅当没有显式提供 -u，且推送目标是当前分支，且当前分支在指定远程上没有跟踪信息时
    local remote_for_upstream_check="$remote_to_check" # 使用实际确定的远程
    
    # 检查上游前，确保 branch_to_push 是一个单纯的分支名，而不是 refspec
    local simple_branch_to_push="$branch_to_push"
    if [[ "$simple_branch_to_push" == *":"* ]]; then
        simple_branch_to_push="$current_branch" # 如果是 refspec，以上游检查基于当前分支
    fi

    if [ "$simple_branch_to_push" == "$current_branch" ] && ! $set_upstream; then
      # 使用 git rev-parse --symbolic-full-name @{u} 更可靠地检查上游
      # 或者检查 git branch -vv 是否包含 [remote/branch]
      # 为了简化，我们这里保持之前的逻辑，但可以改进
      # 检查远程分支是否存在：git ls-remote --exit-code --heads $remote_for_upstream_check $current_branch
      # 如果上面的命令 exit code 2，表示远程分支不存在
      if ! git ls-remote --exit-code --heads "$remote_for_upstream_check" "$current_branch" > /dev/null 2>&1; then
          if ! printf '%s\\n' "${push_args[@]}" | grep -q -e '-u' -e '--set-upstream'; then
             echo -e "${BLUE}检测到分支 '$current_branch' 在远程 '$remote_for_upstream_check' 上可能尚不存在或未跟踪。将自动添加 --set-upstream (-u)。${NC}"
             # 确保 -u 不重复添加
             local u_already_present=false
             for arg_in_push in "${push_args[@]}"; do
                 if [[ "$arg_in_push" == "-u" || "$arg_in_push" == "--set-upstream" ]]; then
                     u_already_present=true
                     break
                 fi
             done
             if ! $u_already_present; then
                push_args+=("--set-upstream")
             fi
          fi
      fi
    fi
    
    local command_str="git push ${push_args[*]}"
    
    echo -e "${GREEN}--- Git 推送重试执行 ---${NC}"
    echo "执行命令: $command_str"
    echo "最大尝试次数: $MAX_ATTEMPTS"
    if [ "$DELAY_SECONDS" -gt 0 ]; then
        echo "每次尝试间隔: ${DELAY_SECONDS} 秒"
    fi
    echo "-----------------------------------------"

    for i in $(seq 1 $MAX_ATTEMPTS)
    do
       echo "--- 第 $i/$MAX_ATTEMPTS 次尝试 ---"
       git push "${push_args[@]}"
       EXIT_CODE=$?
       if [ $EXIT_CODE -eq 0 ]; then
          echo -e "${GREEN}--- 推送成功 (第 $i 次尝试). 操作完成. ---${NC}"
          return 0
       else
          echo -e "${RED}!!! 第 $i 次尝试失败 (退出码: $EXIT_CODE). 正在重试... !!!${NC}"
       fi

       if [ $i -eq $MAX_ATTEMPTS ]; then
           break
       fi

       if [ "$DELAY_SECONDS" -gt 0 ]; then
           sleep $DELAY_SECONDS
       fi
    done

    echo -e "${RED}=== 尝试 $MAX_ATTEMPTS 次后推送仍失败. 操作终止. ===${NC}"
    return 1
}

# 执行带重试的 Git 拉取
do_pull_with_retry() {
    local pull_args=()
    local remote="$REMOTE_NAME"
    local branch_to_pull=""
    local current_branch
    current_branch=$(get_current_branch_name)
    if [ $? -ne 0 ]; then return 1; fi

    local other_args=()
    local potential_remote=""
    local potential_branch=""
    local args_array=("$@")
    local arg_count=$#

    for (( i=0; i<$arg_count; i++ )); do
        local arg="${args_array[i]}"
        case "$arg" in
            --rebase|--ff|--ff-only|--no-ff|--stat|--no-stat|-v|--verbose|-q|--quiet)
                other_args+=("$arg")
                ;;
            -*)
                other_args+=("$arg") 
                ;;
            *)
                if [ -z "$potential_remote" ]; then
                    if git remote | grep -q "^$arg$"; then
                        potential_remote="$arg"
                    elif [ -z "$potential_branch" ]; then
                        potential_branch="$arg"
                    else
                        other_args+=("$arg")
                    fi
                elif [ -z "$potential_branch" ]; then
                    potential_branch="$arg"
                else
                    other_args+=("$arg")
                fi
                ;;
        esac
    done

    remote=${potential_remote:-$REMOTE_NAME} 
    if [ -n "$potential_branch" ]; then
       branch_to_pull=$potential_branch
       pull_args=("$remote" "$branch_to_pull")
    else
        pull_args=("$remote")
    fi
    pull_args+=("${other_args[@]}")

    local command_str="git pull ${pull_args[*]}"
    
    echo -e "${GREEN}--- Git 拉取重试执行 ---${NC}"
    echo "将尝试执行命令: $command_str"
    echo "最大尝试次数: $MAX_ATTEMPTS"
    if [ "$DELAY_SECONDS" -gt 0 ]; then
        echo "每次尝试间隔: ${DELAY_SECONDS} 秒"
    fi
    echo "-----------------------------------------"

    for i in $(seq 1 $MAX_ATTEMPTS)
    do
       echo "--- 第 $i/$MAX_ATTEMPTS 次尝试: 执行 '$command_str' --- "
       git pull "${pull_args[@]}"
       EXIT_CODE=$?
       if [ $EXIT_CODE -eq 0 ]; then
          echo -e "${GREEN}--- 拉取成功 (第 $i 次尝试). 操作完成. ---${NC}"
          return 0
       else
          if git diff --name-only --diff-filter=U --relative | grep -q .; then
              echo -e "${RED}!!! 拉取失败：检测到合并冲突 (退出码: $EXIT_CODE)。请手动解决冲突后提交。!!!${NC}"
              echo -e "运行 'git status' 查看冲突文件。"
              echo -e "解决后运行 'gw add <冲突文件>' 和 'gw commit'。"
              return 1 
          fi
          echo -e "${RED}!!! 第 $i 次尝试拉取失败 (退出码: $EXIT_CODE)。可能是网络问题，正在重试... !!!${NC}"
       fi

       if [ $i -eq $MAX_ATTEMPTS ]; then
           break
       fi

       if [ "$DELAY_SECONDS" -gt 0 ]; then
           sleep $DELAY_SECONDS
       fi
    done

    echo -e "${RED}=== 尝试 $MAX_ATTEMPTS 次后拉取仍失败. 操作终止. 请检查网络连接或错误信息. ===${NC}"
    return 1
} 