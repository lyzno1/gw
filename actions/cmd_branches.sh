#!/bin/bash
# 脚本/actions/cmd_branches.sh
#
# Implements the 'branches' command logic.
# Dependencies:
# - colors.sh (for BOLD, CYAN, GREEN, NC, YELLOW)
# - utils.sh (for check_in_git_repo, get_current_branch_name)

# 显示仓库的所有分支
cmd_branches() {
    if ! check_in_git_repo; then
        return 1
    fi
    
    echo -e "${CYAN}=== 本地分支列表 ===${NC}"
    
    # 获取当前分支名
    current_branch=$(get_current_branch_name)
    
    # 本地分支
    echo -e "${BOLD}本地分支:${NC}"
    git for-each-ref --sort=committerdate refs/heads/ --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))' | 
    while read -r branch; do
        if [[ $branch == "*"* ]]; then
            # 如果是当前分支，用绿色标记
            echo -e "${GREEN}$branch${NC}"
        else
            echo "$branch"
        fi
    done

    # 远程分支
    echo -e "\n${BOLD}远程分支:${NC}"
    git for-each-ref --sort=committerdate refs/remotes/ --format='%(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))' |
    grep -v "HEAD"
    
    return 0
} 