#!/bin/bash
# 脚本/actions/cmd_diff.sh
#
# Implements the 'diff' command logic.
# Dependencies:
# - utils.sh (for check_in_git_repo)

# 显示差异
cmd_diff() {
    if ! check_in_git_repo; then return 1; fi
    
    # 直接将所有参数传递给 git diff
    # 用户可以自行添加 --cached, 文件路径等
    git diff "$@"
    # git diff 的退出码通常为 0 (无差异) 或 1 (有差异)，我们不视为脚本错误
    return 0 
} 