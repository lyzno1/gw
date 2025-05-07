#!/bin/bash
# 脚本/actions/cmd_checkout.sh
#
# Implements the 'checkout' command logic.
# Dependencies:
# - colors.sh (for YELLOW, BLUE, RED, GREEN, CYAN, NC)
# - utils.sh (for check_in_git_repo, check_uncommitted_changes, check_untracked_files, confirm_action)
# - Potentially cmd_commit_all (Note: cmd_commit_all is not defined in the original script and might be an issue)

# 切换分支
cmd_checkout() {
    if ! check_in_git_repo; then
        return 1
    fi

    local branch="$1"
    
    if [ -z "$branch" ]; then
        # 没有提供分支名，显示所有可选分支并交互式选择
        echo -e "${CYAN}可用分支:${NC}"
        branches=($(git branch --format="%(refname:short)" | sort))
        
        PS3="选择要切换的分支 (输入数字): "
        select branch_name in "${branches[@]}" "取消"; do
            if [ "$branch_name" = "取消" ]; then
                echo "已取消分支切换。"
                return 0
            elif [ -n "$branch_name" ]; then
                branch="$branch_name"
                break
            else
                echo "无效选择，请重试。"
            fi
        done
    fi
    
    # 检查是否有未提交的变更
    if check_uncommitted_changes || check_untracked_files; then
        echo -e "${YELLOW}⚠️ 警告：您有未提交的变更或未追踪的文件。${NC}"
        echo "1) 提交变更"
        echo "2) 暂存变更"
        echo "3) 放弃变更"
        echo "4) 保持变更并切换分支"
        echo "5) 取消操作"
        echo -n "请选择操作 [1-5]: "
        read -r choice
        
        case "$choice" in
            1)
                # 提交变更
                cmd_commit_all # This function is not defined in the script.
                ;;
            2)
                # 暂存变更
                echo -e "${BLUE}正在暂存当前变更...${NC}"
                if ! cmd_stash push -m "Auto-stashed before checkout to $branch"; then
                    echo -e "${RED}暂存变更失败，请检查操作。${NC}"
                    return 1
                fi
                ;;
            3)
                # 放弃变更
                if confirm_action "确定要放弃所有未提交的变更吗？这个操作不可逆！" "N"; then
                    echo -e "${BLUE}正在放弃变更...${NC}"
                    git reset --hard HEAD
                    git clean -fd
                else
                    echo "已取消。"
                    return 1
                fi
                ;;
            4)
                # 继续保持变更
                echo -e "${YELLOW}保持变更并尝试切换分支，如果有冲突可能会失败。${NC}"
                ;;
            5|*)
                echo "已取消分支切换。"
                return 1
                ;;
        esac
    fi
    
    # 执行分支切换
    echo -e "${BLUE}正在切换到分支 '$branch'...${NC}"
    git checkout "$branch"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}成功切换到分支 '$branch'${NC}"
        return 0
    else
        echo -e "${RED}切换分支失败，请检查分支名称或解决冲突。${NC}"
        return 1
    fi
} 