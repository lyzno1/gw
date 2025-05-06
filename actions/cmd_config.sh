#!/bin/bash
# 脚本/actions/cmd_config.sh
#
# 实现 'config' 命令逻辑。
# 依赖:
# - colors.sh (颜色定义)
# - utils_print.sh (打印函数)
# - utils.sh (check_in_git_repo)

cmd_config() {
    if ! check_in_git_repo; then
        # 允许在非git仓库设置全局--global或系统--system配置
        local is_global_or_system=false
        for arg in "$@"; do
            if [[ "$arg" == "--global" || "$arg" == "--system" ]]; then
                is_global_or_system=true
                break
            fi
        done
        if ! $is_global_or_system && [[ "$1" != "--list" && "$1" != "-l" ]] ; then # --list 允许在任何地方执行
             print_error "此命令通常应在 Git 仓库中运行，除非您正在使用 --global 或 --system 选项。"
             return 1
        fi
    fi

    # 特殊处理：gw config <用户名> <邮箱>
    # 条件：正好有两个参数，且都不是以 '-' 开头的选项
    if [ "$#" -eq 2 ] && [[ ! "$1" =~ ^- && ! "$2" =~ ^- ]]; then
        local username="$1"
        local email="$2"
        
        print_step "正在配置本地仓库的 user.name 和 user.email..."
        
        if git config user.name "$username"; then
            print_success "本地 user.name 已设置为: $username"
        else
            print_error "设置本地 user.name 失败。"
            return 1
        fi
        
        if git config user.email "$email"; then
            print_success "本地 user.email 已设置为: $email"
        else
            print_error "设置本地 user.email 失败。"
            return 1
        fi
        
        echo -e "${CYAN}提示: 如果需要全局配置，请使用:${NC}"
        echo "  gw config --global user.name \"$username\""
        echo "  gw config --global user.email \"$email\""
        return 0
    fi

    # 其他情况：直接将所有参数传递给 git config
    print_info "执行: git config $@"
    if git config "$@"; then
        # 对于读取操作 (如 git config user.name)，git config 成功时会打印到stdout，我们不需要额外打印
        # 对于写入/修改操作，如果成功，git config 通常不输出，我们给一个通用成功提示
        # 但难以区分读写，所以如果 git config 命令本身没有输出，可以给一个通用成功提示
        # 为了简化，这里依赖 git config 自身的输出和退出码
        return 0
    else
        # git config 失败时通常会打印错误信息到 stderr
        # print_error "git config 命令执行失败。" # 这可能会重复git自身的错误输出
        return 1
    fi
} 