#!/bin/bash
# 脚本/actions/cmd_delete_branch.sh
#
# Implements the (older) 'delete_branch' command logic.
# Dependencies:
# - colors.sh (for YELLOW, BLUE, RED, GREEN, CYAN, NC)
# - utils.sh (for check_in_git_repo, get_current_branch_name, confirm_action)
# - config_vars.sh (for MAIN_BRANCH, REMOTE_NAME)

# 删除分支
cmd_delete_branch() {
    if ! check_in_git_repo; then
        return 1
    fi

    local branch="$1"
    local force="$2"  # 是否强制删除
    
    if [ -z "$branch" ]; then
        # 没有提供分支名，显示所有可选分支并交互式选择
        current_branch=$(get_current_branch_name)
        echo -e "${CYAN}可删除的分支:${NC}"
        branches=($(git branch --format="%(refname:short)" | grep -v "^$current_branch$" | sort))
        
        if [ ${#branches[@]} -eq 0 ]; then
            echo "没有可删除的分支。"
            return 1
        fi
        
        PS3="选择要删除的分支 (输入数字): "
        select branch_name in "${branches[@]}" "取消"; do
            if [ "$branch_name" = "取消" ]; then
                echo "已取消分支删除操作。"
                return 0
            elif [ -n "$branch_name" ]; then
                branch="$branch_name"
                break
            else
                echo "无效选择，请重试。"
            fi
        done
    fi
    
    # 检查不能删除当前分支
    current_branch=$(get_current_branch_name)
    if [ "$branch" = "$current_branch" ]; then
        echo -e "${RED}错误：不能删除当前所在的分支。请先切换到其他分支。${NC}"
        return 1
    fi
    
    # 检查是否为主分支
    if [ "$branch" = "$MAIN_BRANCH" ]; then
        echo -e "${RED}错误：不能删除主分支。${NC}"
        return 1
    fi
    
    # 检查分支是否已合并
    is_merged=false
    if git branch --merged | grep -q "^..\?$branch$"; then
        is_merged=true
    fi
    
    # 根据是否已合并选择删除方式
    delete_flag="-d"  # 默认安全删除
    if [ "$force" = "force" ] || [ "$force" = "-f" ]; then
        delete_flag="-D"  # 强制删除
        echo -e "${YELLOW}⚠️ 警告：将强制删除分支 '$branch'，即使它包含未合并的更改。${NC}"
    elif [ "$is_merged" = false ]; then
        echo -e "${YELLOW}⚠️ 警告：分支 '$branch' 包含未合并到 '$current_branch' 的更改。${NC}"
        if confirm_action "是否要强制删除此分支？" "N"; then
            delete_flag="-D"  # 强制删除
        else
            echo "已取消分支删除操作。"
            return 1
        fi
    fi
    
    # 执行分支删除
    echo -e "${BLUE}正在删除分支 '$branch'...${NC}"
    git branch $delete_flag "$branch"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}成功删除分支 '$branch'${NC}"
        
        # 询问是否也删除远程分支
        if git ls-remote --heads "$REMOTE_NAME" "$branch" | grep -q "$branch"; then
            if confirm_action "是否同时删除远程分支 '$REMOTE_NAME/$branch'？" "N"; then
                echo -e "${BLUE}正在删除远程分支...${NC}"
                git push "$REMOTE_NAME" --delete "$branch"
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}成功删除远程分支 '$REMOTE_NAME/$branch'${NC}"
                else
                    echo -e "${RED}删除远程分支失败。${NC}"
                    return 1
                fi
            fi
        fi
        
        return 0
    else
        echo -e "${RED}删除分支失败。${NC}"
        return 1
    fi
} 