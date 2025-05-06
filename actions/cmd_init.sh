#!/bin/bash
# 脚本/actions/cmd_init.sh
#
# 实现 'init' 命令逻辑。
# 依赖:
# - colors.sh (颜色定义)
# - utils_print.sh (打印函数)

cmd_init() {
    # 检查当前目录是否已经是 Git 仓库
    if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        print_warning "当前目录已经是一个 Git 仓库。"
        if ! confirm_action "是否仍要在此目录执行 'git init' (这通常是安全的，但可能会重新初始化部分配置)？" "N"; then
            echo "操作已取消。"
            return 1
        fi
        print_info "继续执行 'git init'..."
    fi

    # 将所有参数传递给 git init
    # 允许用户使用例如 gw init --bare 或者 gw init --initial-branch=main 等参数
    print_step "正在初始化 Git 仓库 (git init $@)..."
    if git init "$@"; then
        print_success "Git 仓库初始化成功。"
        
        # 提示用户进行下一步配置
        echo -e "${CYAN}提示: 仓库已初始化。您可能需要设置用户信息:${NC}"
        echo "  gw config "您的用户名" "您的邮箱地址""
        echo -e "${CYAN}以及添加远程仓库:${NC}"
        echo "  gw remote add origin <远程仓库URL>"
        return 0
    else
        print_error "Git 仓库初始化失败。"
        return 1
    fi
} 