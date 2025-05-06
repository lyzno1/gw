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

    # 新增：处理 gw config set remote.default <name>
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

        # 验证新的远程名称是否存在
        if ! git remote get-url "$new_remote_name" > /dev/null 2>&1; then
            print_error "错误: 远程仓库 '$new_remote_name' 不存在或未配置 URL。"
            print_info "请使用 'git remote add $new_remote_name <url>' 添加，或检查名称是否正确。"
            return 1
        fi
        print_success "远程仓库 '$new_remote_name' 验证通过。"

        # 修改 core_utils/config_vars.sh
        if [ ! -f "$config_file_path" ]; then
            print_error "配置文件 '$config_file_path' 未找到。"
            return 1
        fi

        # 使用 sed 进行替换
        # 注意: sed 的 -i 选项在 macOS 和 Linux 上行为不同。
        # macOS sed -i 需要一个备份文件扩展名，如 -i '.bak'。
        # GNU sed -i可以直接使用。
        # 我们先创建一个临时文件，然后覆盖原文件，以提高兼容性。
        
        local temp_config_file
        temp_config_file=$(mktemp)
        if [ -z "$temp_config_file" ]; then
            print_error "创建临时文件失败。"
            return 1
        fi

        # 读取当前的 REMOTE_NAME 值，以便更精确地替换
        local current_remote_name
        current_remote_name=$(grep '^REMOTE_NAME=' "$config_file_path" | cut -d'=' -f2 | cut -d'#' -f1 | xargs)
        # 移除可能存在的默认值部分如 :-origin
        current_remote_name=${current_remote_name/%\$\{REMOTE_NAME:-*\}/*} 
        current_remote_name=${current_remote_name/%:-[a-zA-Z0-9_]*} # 移除 :-some_value

        if [ -z "$current_remote_name" ]; then
             # 如果无法精确获取，就用一个更通用的模式，但风险稍高
             print_warning "无法精确获取当前的 REMOTE_NAME 值，将尝试通用替换模式。"
        fi


        # sed 's/^REMOTE_NAME=.*$/REMOTE_NAME="new_value"/' config_vars.sh
        # 为了更安全，我们只替换 REMOTE_NAME=... 这一行，并保留可能的注释
        # 使用 awk 更安全地处理，只修改 REMOTE_NAME=... 部分，保留环境变量默认值结构
        awk -v new_val="\\\"${new_remote_name}\\\"" '
            /^REMOTE_NAME=/ {
                # $0 ~ /REMOTE_NAME=\$\{REMOTE_NAME:-/ 这种默认值结构比较复杂，直接替换整个行
                # 或者更简单地，我们假设 REMOTE_NAME= 这行不会太复杂
                # 我们只替换 REMOTE_NAME=some_value 或 REMOTE_NAME=${REMOTE_NAME:-some_value} 中的 some_value
                # REMOTE_NAME=${REMOTE_NAME:-origin}       # 默认的远程仓库名称
                # 替换为: REMOTE_NAME=${REMOTE_NAME:-new_remote_name}
                # 或者如果是 REMOTE_NAME=old_value, 替换为 REMOTE_NAME=new_remote_name
                if (sub(/REMOTE_NAME=\${REMOTE_NAME:-[^}]+}/, "REMOTE_NAME=\\${REMOTE_NAME:-" new_val "}")) {
                    print $0
                } else if (sub(/REMOTE_NAME=[^ ]+/, "REMOTE_NAME=" new_val)) {
                    print $0
                } else {
                    # 如果上面两种常见模式都不匹配，则原样打印，避免破坏文件
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
        
        # 检查 awk 是否真的修改了这一行 (或者发出了警告)
        # 简单的检查方法：看新文件中 REMOTE_NAME 的值是否是期望的
        local updated_remote_name_check
        updated_remote_name_check=$(grep '^REMOTE_NAME=' "$temp_config_file" | sed -n "s/.*REMOTE_NAME=\\(.\\{0,1\\}\\)\\(\\${REMOTE_NAME:-\\|\\)\\([^\"} ]*\\).*/\\3/p")
        
        if [[ "$updated_remote_name_check" == "$new_remote_name" ]]; then
            cp "$temp_config_file" "$config_file_path"
            rm -f "$temp_config_file"
            print_success "配置文件 '$config_file_path' 中的 REMOTE_NAME 已更新为 '$new_remote_name'。"
            print_info "请注意：此更改将在下次加载脚本时完全生效 (例如，打开新的终端或重新 source git_workflow.sh)。"
            return 0
        else
            print_error "尝试更新配置文件中的 REMOTE_NAME 失败。预期值 '$new_remote_name'，实际检测值 '$updated_remote_name_check'。"
            print_info "临时文件 '$temp_config_file' 保留供检查。原配置文件未修改。"
            # rm -f "$temp_config_file" # 决定是否保留临时文件
            return 1
        fi

    # 保留原有的 config 逻辑
    else
        # 检查是否应在 Git 仓库外运行
        local allow_outside_repo_for_standard_config=false
        if [[ "$1" == "--global" || "$1" == "--system" || "$1" == "--list" || "$1" == "-l" ]]; then
            allow_outside_repo_for_standard_config=true
        elif [[ "$#" -ge 2 && ("$2" == "--global" || "$2" == "--system" || "$2" == "--list" || "$2" == "-l") ]]; then # e.g. git config section.key --global
             allow_outside_repo_for_standard_config=true
        fi
        
        # 对于 gw config user mail 这种快捷方式，还是要求在 repo 内
        if [[ "$#" -eq 2 && ! "$1" =~ ^- && ! "$2" =~ ^- ]]; then
             if ! check_in_git_repo; then
                 print_error "快速设置用户名/邮箱的操作应在 Git 仓库中运行。"
                 return 1
             fi
        elif ! $allow_outside_repo_for_standard_config && ! check_in_git_repo; then
             print_error "此命令通常应在 Git 仓库中运行，除非您正在使用 --global, --system 或 --list 选项。"
             return 1
        fi


        # 特殊处理：gw config <用户名> <邮箱>
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
            echo "  gw config --global user.name \\\"$username\\\""
            echo "  gw config --global user.email \\\"$email\\\""
            return 0
        fi

        # 其他情况：直接将所有参数传递给 git config
        print_info "执行: git config $@"
        if git config "$@"; then
            return 0
        else
            return 1
        fi
    fi
}