#!/bin/bash
# 脚本/actions/cmd_reset.sh
#
# 实现 'reset' 命令逻辑。
# 依赖:
# - colors.sh (颜色定义)
# - utils_print.sh (打印函数)
# - utils.sh (通用工具函数)

# 重置变更 (git reset)
cmd_reset() {
    if ! check_in_git_repo; then return 1; fi

    local args_string="$*"
    local confirm_needed=false

    # 检查参数中是否包含 --hard
    # 通过前后加空格确保精确匹配 --hard，避免匹配 --harder 等
    if [[ " $args_string " =~ " --hard " ]]; then 
        confirm_needed=true
    fi

    if $confirm_needed; then
        echo -e "${RED}${BOLD}警告：您正在尝试使用 'git reset --hard'！${NC}"
        echo -e "${RED}这将永久丢弃您工作目录和暂存区中所有未提交的变更，并重置到目标状态。${NC}"
        echo -e "${RED}这个操作是不可逆的！${NC}"
        echo -e -n "${YELLOW}如果您确实要执行此操作，请输入 'yes' (区分大小写): ${NC}"
        read -r confirmation
        if [ "$confirmation" != "yes" ]; then # 精确匹配 "yes"
            echo "操作已取消。"
            return 1
        fi
        echo -e "${BLUE}确认通过，继续执行 'git reset --hard'...${NC}"
    fi

    echo -e "${BLUE}正在执行: git reset $args_string${NC}"
    # 直接将所有参数传递给 git reset
    git reset "$@"
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}git reset 操作成功完成。${NC}"
    else
        echo -e "${RED}git reset 操作失败 (退出码: $exit_code)。${NC}"
    fi
    return $exit_code
} 