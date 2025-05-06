#!/bin/bash
# 脚本/actions/cmd_sync.sh
#
# 实现 'sync' 命令逻辑。
# 依赖:
# - colors.sh (颜色定义)
# - utils_print.sh (打印函数)
# - utils.sh (通用工具函数)
# - config_vars.sh (配置变量)
# - git_network_ops.sh (do_pull_with_retry)

# 同步当前分支 (拉取主分支最新代码并 rebase)
cmd_sync() {
    if ! check_in_git_repo; then return 1; fi

    local original_branch
    original_branch=$(get_current_branch_name)
    if [ $? -ne 0 ]; then return 1; fi

    if [ "$original_branch" = "$MAIN_BRANCH" ]; then
        echo -e "${YELLOW}您已在主分支 ($MAIN_BRANCH)。正在尝试拉取最新代码...${NC}"
        # 直接使用 do_pull_with_retry 保证一致性
        if do_pull_with_retry "$REMOTE_NAME" "$MAIN_BRANCH"; then
            echo -e "${GREEN}主分支已更新。${NC}"
            return 0
        else
            echo -e "${RED}拉取主分支更新失败。${NC}"
            return 1
        fi
    fi

    echo -e "${CYAN}=== 同步当前分支 ('$original_branch') ===${NC}"

    # 1. 检查未提交的变更
    local stash_needed=false
    if check_uncommitted_changes || check_untracked_files; then
        echo -e "${YELLOW}检测到未提交的变更或未追踪的文件。${NC}"
        echo "在同步操作前，建议先处理这些变更。"
        echo "1) 暂存 (stash) 变更并在同步后尝试恢复"
        echo "2) 提交变更"
        echo "3) 取消同步"
        echo -n "请选择操作 [1-3]: "
        read -r choice
        
        case "$choice" in
            1)
                echo -e "${BLUE}正在暂存当前变更...${NC}"
                if git stash save "Auto-stash before sync on $original_branch"; then
                    stash_needed=true
                else
                    echo -e "${RED}暂存失败，同步已取消。${NC}"
                    return 1
                fi
                ;;
            2)
                echo -e "${BLUE}请提交您的变更。${NC}"
                # 这里不直接调用 cmd_commit, 避免循环依赖或复杂参数处理
                # 提示用户手动提交或脚本调用者应确保 cmd_commit 已被 source
                echo "请运行 'gw commit' 或相关命令提交您的变更，然后重新运行 'gw sync'。"
                return 1 # 或者根据设计决定是否调用 cmd_commit
                ;;
            3|*)
                echo "同步操作已取消。"
                return 1
                ;;
        esac
    fi

    # 2. 切换到主分支
    echo -e "${BLUE}切换到主分支 ($MAIN_BRANCH)...${NC}"
    if ! git checkout "$MAIN_BRANCH"; then
        echo -e "${RED}切换到主分支失败。请检查您的工作区状态。${NC}"
        if $stash_needed; then
            echo -e "${YELLOW}正在尝试恢复之前暂存的变更...${NC}"
            git stash pop
        fi
        return 1
    fi

    # 3. 拉取主分支最新代码
    echo -e "${BLUE}正在从远程 '$REMOTE_NAME' 拉取主分支 ($MAIN_BRANCH) 的最新代码...${NC}"
    if ! do_pull_with_retry "$REMOTE_NAME" "$MAIN_BRANCH"; then
        echo -e "${RED}拉取主分支更新失败。${NC}"
        echo -e "${BLUE}正在切换回原分支 '$original_branch'...${NC}"
        git checkout "$original_branch"
        if $stash_needed; then
            echo -e "${YELLOW}正在尝试恢复之前暂存的变更...${NC}"
            git stash pop
        fi
        return 1
    fi
    echo -e "${GREEN}主分支已更新。${NC}"

    # 4. 切换回原分支
    echo -e "${BLUE}切换回原分支 '$original_branch'...${NC}"
    if ! git checkout "$original_branch"; then
        echo -e "${RED}切换回原分支 '$original_branch' 失败。${NC}"
        echo -e "${YELLOW}您的代码仍在最新的主分支上。请手动切换。${NC}"
        if $stash_needed; then
            echo -e "${YELLOW}请注意：您之前暂存的变更需要手动恢复 (git stash pop)。${NC}"
        fi
        return 1
    fi

    # 5. Rebase 当前分支到主分支
    echo -e "${BLUE}正在将当前分支 '$original_branch' Rebase 到最新的 '$MAIN_BRANCH'...${NC}"
    if git rebase "$MAIN_BRANCH"; then
        echo -e "${GREEN}成功将 '$original_branch' Rebase 到 '$MAIN_BRANCH'。${NC}"
    else
        echo -e "${RED}Rebase 操作失败或遇到冲突。${NC}"
        echo -e "请解决 Rebase 冲突。"
        echo -e "解决冲突后，运行 'gw add <冲突文件>' 然后 'git rebase --continue'。"
        echo -e "如果想中止 Rebase，可以运行 'git rebase --abort'。"
        if $stash_needed; then
             echo -e "${YELLOW}请注意：您之前暂存的变更在 Rebase 成功后需要手动恢复 (git stash pop)。${NC}"
        fi
        return 1
    fi

    # 6. 如果之前暂存了，尝试恢复
    if $stash_needed; then
        echo -e "${BLUE}正在尝试恢复之前暂存的变更...${NC}"
        if git stash pop; then
            echo -e "${GREEN}成功恢复暂存的变更。${NC}"
        else
            echo -e "${RED}自动恢复暂存失败。可能存在冲突。${NC}"
            echo -e "请运行 'git status' 查看详情，并手动解决冲突。未恢复的暂存在 'git stash list' 中。"
        fi
    fi

    echo -e "${GREEN}=== 分支 '$original_branch' 同步完成 ===${NC}"
    return 0
} 