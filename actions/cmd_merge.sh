#!/bin/bash
# 脚本/actions/cmd_merge.sh
#
# Implements the 'merge' command logic.
# Dependencies:
# - colors.sh (for RED, YELLOW, BLUE, GREEN, NC)
# - utils.sh (for check_in_git_repo, get_current_branch_name, check_uncommitted_changes, check_untracked_files, confirm_action)
# - config_vars.sh (for REMOTE_NAME - though not directly used, relevant for context)

# 合并分支
cmd_merge() {
    if ! check_in_git_repo; then return 1; fi
    
    local source_branch="$1"
    local current_branch
    current_branch=$(get_current_branch_name)
    if [ $? -ne 0 ]; then return 1; fi
    
    if [ -z "$source_branch" ]; then
        echo -e "${RED}错误: 请指定要合并到 '$current_branch' 的来源分支。${NC}"
        echo "用法: gw merge <来源分支> [git merge 的其他参数...]"
        return 1
    fi
    
    # 检查是否有未提交的变更
    if check_uncommitted_changes || check_untracked_files; then
        echo -e "${YELLOW}警告: 检测到未提交的变更或未追踪的文件。${NC}"
        echo "合并前建议先提交或暂存变更。"
        if ! confirm_action "是否仍要继续合并？"; then
            echo "合并操作已取消。"
            return 1
        fi
    fi
    
    echo -e "${BLUE}准备将分支 '$source_branch' 合并到 '$current_branch'...${NC}"
    shift # 移除已处理的 source_branch 参数
    
    # 执行 git merge，并将剩余参数传递过去
    if git merge "$source_branch" "$@"; then
        echo -e "${GREEN}成功将 '$source_branch' 合并到 '$current_branch'。${NC}"
        return 0
    else
        echo -e "${RED}合并 '$source_branch' 时遇到冲突或失败。${NC}"
        echo -e "请解决冲突后手动提交。你可以使用 'git status' 查看冲突文件。"
        echo -e "解决冲突后，运行 'gw add <冲突文件>' 然后 'gw commit'。"
        echo -e "如果想中止合并，可以运行 'git merge --abort'。"
        return 1
    fi
} 