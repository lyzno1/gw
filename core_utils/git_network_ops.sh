#!/bin/bash

# 脚本/git_network_ops.sh
#
# 此文件定义了与 Git 网络操作（如 push 和 pull）相关且包含重试逻辑的核心函数。
# 旨在被其他脚本 source。
# 注意：此文件依赖于 colors.sh, config_vars.sh, utils_print.sh, 和 utils.sh。

# 执行带重试的 Git 推送
do_push_with_retry() {
    local push_args=()
    local remote="$REMOTE_NAME"
    local branch_to_push=""
    local current_branch
    current_branch=$(get_current_branch_name)
    if [ $? -ne 0 ]; then return 1; fi

    # --- 前置检查：未提交的变更 ---
    if check_uncommitted_changes || check_untracked_files; then
        echo -e "${YELLOW}检测到未提交的变更或未追踪的文件。${NC}"
        # 列出具体文件
        echo "变更详情:"
        git status -s
        echo ""
        if confirm_action "是否要将所有变更添加到暂存区并提交，然后再推送？"; then
            echo -e "${BLUE}正在暂存所有变更...${NC}"
            # 注意：这里假设 cmd_add_all 和 cmd_commit 仍然在主脚本中或将被正确加载
            # 在完全模块化后，可能需要通过主脚本调用或将它们也移到合适模块
            if ! cmd_add_all; then # 依赖主脚本中的 cmd_add_all
                echo -e "${RED}暂存变更失败，推送已取消。${NC}"
                return 1
            fi
            
            echo -e "${BLUE}正在提交变更...${NC}"
            if ! cmd_commit; then # 依赖主脚本中的 cmd_commit
                echo -e "${RED}提交失败或被取消，推送已取消。${NC}"
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

    for (( i=0; i<$arg_count; i++ )); do
        local arg="${args_array[i]}"
        case "$arg" in
            -u|--set-upstream)
                set_upstream=true
                other_args+=("$arg")
                ;;
            -f|--force|--force-with-lease)
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
    branch_to_push=${potential_branch:-$current_branch} 

    push_args=("$remote" "$branch_to_push")
    push_args+=("${other_args[@]}") 

    if ! git rev-parse --verify --quiet "refs/remotes/$remote/$current_branch" > /dev/null 2>&1 && \
       [ "$branch_to_push" == "$current_branch" ] && \
       ! $set_upstream; then
        if ! printf '%s\n' "${other_args[@]}" | grep -q -e '-u' -e '--set-upstream'; then
           echo -e "${BLUE}检测到是首次推送分支 '$current_branch' 到 '$remote'，将自动设置上游跟踪 (-u)。${NC}"
           push_args+=("--set-upstream")
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