#!/bin/bash
# 脚本/actions/cmd_new_branch.sh
#
# Implements the deprecated 'cmd_new_branch' command (redirects to gw_new).
# Dependencies:
# - colors.sh (for YELLOW, NC)
# - actions/gw_new.sh (must be sourced for gw_new function)

# 创建并切换到新分支
cmd_new_branch() {
    # This function is now effectively replaced by gw_new().
    # Keep it here for now or remove it if cleanup is desired.
    # For safety, redirect calls to the new function or print a deprecation warning.
    echo -e "${YELLOW}警告: 'cmd_new_branch' 已被 'gw_new' 取代。请更新调用方式。${NC}"
    gw_new "$@" # Redirect to the new function (gw_new must be available)
    return $?
} 