#!/bin/bash
# 脚本/actions/cmd_log.sh
#
# Implements the 'log' command logic.
# Dependencies:
# - utils.sh (for check_in_git_repo)

# 显示提交历史
cmd_log() {
    if ! check_in_git_repo; then return 1; fi
    
    # 直接将所有参数传递给 git log
    # 为了更好的分页体验，检测是否在 TTY 环境，如果是，则使用 less
    if [ -t 1 ]; then # 检查 stdout 是否连接到终端
        git log --color=always "$@" | less -R
    else
        git log "$@"
    fi
    # git log 的退出码我们不视为脚本错误
    return 0
} 