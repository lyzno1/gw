#!/bin/bash
# 脚本/actions/cmd_rm_branch.sh
#
# Implements the 'rm' (remove branch) command logic.
# Dependencies:
# - colors.sh (for YELLOW, BLUE, RED, GREEN, NC)
# - utils.sh (for check_in_git_repo, get_current_branch_name, confirm_action)
# - config_vars.sh (for MAIN_BRANCH, REMOTE_NAME)

# 删除本地分支 (新命令 gw rm)
cmd_rm_branch() {
    if ! check_in_git_repo; then return 1; fi

    local target="$1"
    local force=false
    # local delete_remote=false # Not currently used for prompting, kept for clarity
    
    if [ -z "$target" ]; then
        echo -e "${RED}错误: 请指定要删除的分支名称或 'all'。${NC}"
        echo "用法: gw rm <分支名|all> [-f]"
        return 1
    fi
    shift # 移除 target 参数
    
    for arg in "$@"; do
        if [ "$arg" = "-f" ] || [ "$arg" = "--force" ]; then
            force=true
            break
        fi
    done

    local current_branch
    current_branch=$(get_current_branch_name)
    if [ $? -ne 0 ]; then return 1; fi
 
    if [ "$target" = "all" ]; then
        if [ "$current_branch" != "$MAIN_BRANCH" ]; then
            echo -e "${RED}错误: 'gw rm all' 只能在主分支 ($MAIN_BRANCH) 上执行以确保安全。${NC}"
            echo "您当前在分支 '$current_branch'。"
            return 1
        fi
        
        echo -e "${YELLOW}⚠️ 警告：即将删除除了 '$MAIN_BRANCH' 之外的所有本地分支！${NC}"
        
        local branches_to_delete=()
        while IFS= read -r branch_name; do
            if [ -n "$branch_name" ]; then
                branches_to_delete+=("$branch_name")
            fi
        done < <(git branch --format="%(refname:short)" | grep -v -e "^${MAIN_BRANCH}$" -e "^\* ${MAIN_BRANCH}$")
        
        if [ ${#branches_to_delete[@]} -eq 0 ]; then
            echo "没有其他可删除的本地分支。"
            return 0
        fi
        
        echo "将要删除以下分支:"
        for b in "${branches_to_delete[@]}"; do echo " - $b"; done
        echo ""
        
        local confirm_msg="确认要删除这 ${#branches_to_delete[@]} 个本地分支吗？此操作不可逆！"
        if $force; then
            confirm_msg="强制删除模式 (-f): ${confirm_msg}"
        fi

        if ! confirm_action "$confirm_msg" "N"; then
            echo "已取消批量删除操作。"
            return 1
        fi
        
        local delete_flag="-d"
        if $force; then delete_flag="-D"; fi
        local success_count=0
        local fail_count=0
        
        echo -e "${BLUE}开始批量删除分支...${NC}"
        for branch_to_del in "${branches_to_delete[@]}"; do # Renamed variable to avoid conflict
            echo -n "删除分支 '$branch_to_del'... "
            if git branch $delete_flag "$branch_to_del"; then
                echo -e "${GREEN}成功${NC}"
                success_count=$((success_count + 1))
            else
                echo -e "${RED}失败${NC}"
                fail_count=$((fail_count + 1))
            fi
        done
        
        echo -e "${GREEN}批量删除完成。成功: $success_count, 失败: $fail_count ${NC}"
        if [ $fail_count -gt 0 ]; then
             echo -e "${YELLOW}提示: 删除失败的分支可能包含未合并的更改 (若未使用 -f) 或其他问题。${NC}"
             return 1
        fi
        return 0
    else
        local branch_to_del="$target" # Renamed variable
        
        if [ "$branch_to_del" = "$current_branch" ]; then
            echo -e "${RED}错误：不能删除当前所在的分支。请先切换到其他分支。${NC}"
            return 1
        fi
        
        if [ "$branch_to_del" = "$MAIN_BRANCH" ]; then
            echo -e "${RED}错误：不能删除主分支 ($MAIN_BRANCH)。${NC}"
            return 1
        fi
        
        if ! git rev-parse --verify --quiet "refs/heads/$branch_to_del"; then
             echo -e "${RED}错误：本地分支 '$branch_to_del' 不存在。${NC}"
             return 1
        fi

        local delete_flag="-d"
        if $force; then
            delete_flag="-D"
            echo -e "${YELLOW}⚠️ 警告：将强制删除分支 '$branch_to_del'，即使它包含未合并的更改。${NC}"
        else
            if ! git branch --merged | grep -q -E "(^|\s)${branch_to_del}$"; then # Check against branch_to_del
                 echo -e "${YELLOW}⚠️ 警告：分支 '$branch_to_del' 包含未合并到当前分支 ('$current_branch') 的更改。${NC}"
                 if confirm_action "是否要强制删除此分支？" "N"; then
                     delete_flag="-D"
                 else
                     echo "已取消分支删除操作。"
                     return 1
                 fi
            fi
        fi
        
        echo -e "${BLUE}正在删除本地分支 '$branch_to_del'...${NC}"
        if git branch $delete_flag "$branch_to_del"; then
            echo -e "${GREEN}成功删除本地分支 '$branch_to_del'${NC}"
            
            if git ls-remote --heads "$REMOTE_NAME" "$branch_to_del" | grep -q "$branch_to_del"; then
                if confirm_action "是否同时删除远程分支 '$REMOTE_NAME/$branch_to_del'？" "N"; then
                    echo -e "${BLUE}正在删除远程分支...${NC}"
                    if git push "$REMOTE_NAME" --delete "$branch_to_del"; then
                        echo -e "${GREEN}成功删除远程分支 '$REMOTE_NAME/$branch_to_del'${NC}"
                    else
                        echo -e "${RED}删除远程分支失败。${NC}"
                    fi
                fi
            fi
            return 0
        else
            echo -e "${RED}删除本地分支失败。${NC}"
            return 1
        fi
    fi
} 