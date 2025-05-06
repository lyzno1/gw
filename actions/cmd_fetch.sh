#!/bin/bash
# 脚本/actions/cmd_fetch.sh
#
# Implements the 'fetch' command logic.
# Dependencies:
# - colors.sh (for BLUE, GREEN, RED, NC)
# - utils.sh (for check_in_git_repo)
# - config_vars.sh (for REMOTE_NAME)

# 从远程获取更新 (不合并)
cmd_fetch() {
    if ! check_in_git_repo; then return 1; fi
    
    local remote=${1:-$REMOTE_NAME} # 默认使用 origin
    local fetch_args=()
    
    # 如果指定了远程名，则从参数中移除它
    if [ "$1" = "$remote" ]; then
        shift
    fi
    
    fetch_args=("$remote" "$@") # 包含远程名和所有其他 git fetch 参数
    
    echo -e "${BLUE}正在从远程仓库 '$remote' 获取最新信息...${NC}"
    if git fetch "${fetch_args[@]}"; then
        echo -e "${GREEN}成功从 '$remote' 获取更新。${NC}"
        # 可以考虑在这里显示一些 fetch 的摘要信息
        # git fetch --verbose "${fetch_args[@]}"
        return 0
    else
        echo -e "${RED}从 '$remote' 获取更新失败。${NC}"
        return 1
    fi
} 