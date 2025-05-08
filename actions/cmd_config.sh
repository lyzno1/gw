#!/bin/bash
# 脚本/actions/cmd_config.sh
#
# 实现 'config' 命令逻辑。
# 依赖:
# - colors.sh (颜色定义)
# - utils_print.sh (打印函数)
# - utils.sh (check_in_git_repo)
# - config_vars.sh (SCRIPT_DIR -间接依赖，用于定位 config_vars.sh)

cmd_config() {
    local config_file_path="${SCRIPT_DIR}/core_utils/config_vars.sh"

    # Handler 1: gw config set remote.default <name>
    if [[ "$1" == "set" && "$2" == "remote.default" && -n "$3" ]]; then
        if ! check_in_git_repo; then
            print_error "设置默认远程仓库名称的操作需要在 Git 仓库中执行。"
            return 1
        fi
        local new_remote_name="$3"
        shift 3 # 消耗 set remote.default <name>

        if [ $# -gt 0 ]; then
            print_warning "忽略了 'config set remote.default' 之后的多余参数: $@"
        fi

        print_step "尝试将默认远程仓库名称设置为: '$new_remote_name'"

        if ! git remote get-url "$new_remote_name" > /dev/null 2>&1; then
            print_error "错误: 远程仓库 '$new_remote_name' 不存在或未配置 URL。"
            print_info "请使用 'git remote add $new_remote_name <url>' 添加，或检查名称是否正确。"
            return 1
        fi
        print_success "远程仓库 '$new_remote_name' 验证通过。"

        if [ ! -f "$config_file_path" ]; then
            print_error "配置文件 '$config_file_path' 未找到。"
            return 1
        fi
        
        local temp_config_file
        temp_config_file=$(mktemp)
        if [ -z "$temp_config_file" ]; then
            print_error "创建临时文件失败。"
            return 1
        fi

        awk -v new_val="\\\"${new_remote_name}\\\"" '
            /^REMOTE_NAME=/ {
                if (sub(/REMOTE_NAME=\${REMOTE_NAME:-[^}]+}/, "REMOTE_NAME=\\${REMOTE_NAME:-" new_val "}")) {
                    print $0
                } else if (sub(/REMOTE_NAME=[^ ]+/, "REMOTE_NAME=" new_val)) { # Ensure a quote if not using ${}
                    print $0
                } else {
                    print $0
                    print "# [GW_CONFIG_WARNING] Failed to automatically update REMOTE_NAME line above." > "/dev/stderr"
                }
            }
            !/^REMOTE_NAME=/ { print $0 }
        ' "$config_file_path" > "$temp_config_file"

        if [ $? -ne 0 ]; then
            print_error "使用 awk 修改配置文件失败。"
            rm -f "$temp_config_file"
            return 1
        fi
        
        local updated_remote_name_check
        updated_remote_name_check=$(grep '^REMOTE_NAME=' "$temp_config_file" | sed -n "s/.*REMOTE_NAME=\(.\\{0,1\\}\)\(ัน์\\(\\${REMOTE_NAME:-\\|\\)\\([^\"} ]*\\).*/\\3/p")
        
        if [[ "$updated_remote_name_check" == "$new_remote_name" ]]; then
            cp "$temp_config_file" "$config_file_path"
            rm -f "$temp_config_file"
            print_success "配置文件 '$config_file_path' 中的 REMOTE_NAME 已更新为 '$new_remote_name'。"
            print_info "请注意：此更改将在下次加载脚本时完全生效 (例如，打开新的终端或重新 source git_workflow.sh)。"
            return 0
        else
            print_error "尝试更新配置文件中的 REMOTE_NAME 失败。预期值 '$new_remote_name'，实际检测值 '$updated_remote_name_check'。"
            print_info "临时文件 '$temp_config_file' 保留供检查。原配置文件未修改。"
            return 1
        fi
    fi

    # Handler 2: gw config <name> <email> --global (GLOBAL shortcut)
    if [ "$#" -eq 3 ] && [[ ! "$1" =~ ^- && ! "$2" =~ ^- && "$3" == "--global" ]]; then
        local username="$1"
        local email="$2"
        
        print_step "正在配置全局的 user.name 和 user.email..."
        
        local success=true
        if git config --global user.name "$username"; then
            print_success "全局 user.name 已设置为: $username"
        else
            print_error "设置全局 user.name 失败。"
            success=false
        fi
        
        if $success; then # Only proceed if name setting was successful
            if git config --global user.email "$email"; then
                print_success "全局 user.email 已设置为: $email"
            else
                print_error "设置全局 user.email 失败。"
                success=false
            fi
        fi
        
        if $success; then
            return 0
        else
            return 1
        fi
    fi

    # Handler 3: gw config <name> <email> (LOCAL shortcut)
    if [ "$#" -eq 2 ] && [[ ! "$1" =~ ^- && ! "$2" =~ ^- ]]; then
        # This specific shortcut requires being in a repo.
        if ! check_in_git_repo; then
            print_error "快速设置本地用户名/邮箱的操作应在 Git 仓库中运行。"
            return 1
        fi
        local username="$1"
        local email="$2"
        
        print_step "正在配置本地仓库的 user.name 和 user.email..."
        local op_success=true # Renamed to avoid conflict with success from global block if script structure changes
        if git config user.name "$username"; then # Implicitly local
            print_success "本地 user.name 已设置为: $username"
        else
            print_error "设置本地 user.name 失败。"
            op_success=false
        fi

        if $op_success; then # Only proceed if name setting was successful
            if git config user.email "$email"; then # Implicitly local
                print_success "本地 user.email 已设置为: $email"
            else
                print_error "设置本地 user.email 失败。"
                op_success=false
            fi
        fi
        
        if $op_success; then
            echo -e "${CYAN}提示: 如果需要全局配置，请使用:${NC}"
            echo "  gw config \"$username\" \"$email\" --global" # Updated hint
            echo "  (或 gw config --global user.name \"$username\" 及 user.email)"
            return 0
        else
            return 1
        fi
    fi

    # Handler 4: Default - pass all arguments to git config
    # The check for whether this can run outside a repo (e.g., for --global, --system, --list)
    # is primarily handled by git_workflow.sh before cmd_config is called.
    print_info "执行: git config $@"
    if git config "$@"; then
        return 0
    else
        # git config itself will print errors for invalid syntax or context
        return 1 
    fi
}