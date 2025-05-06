#!/bin/bash
# 脚本/actions/cmd_remote.sh
#
# 实现 'remote' 命令逻辑。
# 依赖:
# - colors.sh (颜色定义)
# - utils_print.sh (打印函数)
# - utils.sh (check_in_git_repo)

cmd_remote() {
    if ! check_in_git_repo; then
        print_error "此命令需要在 Git 仓库中运行。"
        return 1
    fi

    # 如果没有参数，或者第一个参数是 -v/--verbose，则默认显示远程列表
    if [ "$#" -eq 0 ] || [ "$1" = "-v" ] || [ "$1" = "--verbose" ]; then
        print_info "当前配置的远程仓库列表 (git remote -v):"
        git remote -v
        return $?
    fi
    
    # 对于 add, remove, rename, set-url 等常见操作，可以考虑简化，但目前先直接包装
    # 例如: gw remote add <name> <url>
    # 例如: gw remote remove <name>
    # 其他所有情况，直接将参数传递给 git remote

    print_info "执行: git remote $@"
    if git remote "$@"; then
        # git remote 的输出和成功/失败提示依赖其自身行为
        # 如果是添加或删除成功，可以额外打印一个 gw 的成功消息
        if [[ "$1" == "add" && $# -eq 3 ]]; then
            print_success "远程仓库 '$2' 添加操作已尝试执行。请用 'gw remote -v' 确认。"
        elif [[ "$1" == "remove" || "$1" == "rm" ]] && [ $# -eq 2 ]; then
            print_success "远程仓库 '$2' 删除操作已尝试执行。请用 'gw remote -v' 确认。"
        fi
        return 0
    else
        # git remote 失败时通常会打印错误信息
        # print_error "git remote 命令执行失败。" # 可能重复
        return 1
    fi
} 