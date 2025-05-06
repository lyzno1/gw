#!/bin/bash
# 脚本/actions/cmd_add_all.sh
#
# Implements the 'add_all' (aa) command logic.
# Dependencies:
# - colors.sh (for BLUE, GREEN, RED)
# - utils.sh (for check_in_git_repo)

# 添加所有修改到暂存区 (快捷方式 aa)
cmd_add_all() {
    if ! check_in_git_repo; then
        return 1
    fi

    echo -e "${BLUE}正在添加所有修改到暂存区 (git add .)...${NC}"
    git add .
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}成功添加所有修改。${NC}"
        return 0
    else
        echo -e "${RED}添加所有修改失败。${NC}"
        return 1
    fi
} 