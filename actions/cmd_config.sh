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
    # Handler for: gw config set-url <url> OR gw config set-url <remote_name> <url>
    if [[ "$1" == "set-url" ]]; then
        if ! check_in_git_repo; then
            print_error "配置远程 URL 的操作需要在 Git 仓库中执行。"
            return 1
        fi
        shift # consume "set-url"
        local remote_name_to_set_url="origin" # Default to origin
        local url_to_set=""

        if [ "$#" -eq 1 ]; then # gw config set-url <url>
            url_to_set="$1"
        elif [ "$#" -eq 2 ]; then # gw config set-url <remote_name> <url>
            remote_name_to_set_url="$1"
            url_to_set="$2"
        else
            print_error "用法错误: gw config set-url [<remote_name>] <url>"
            print_info "示例: gw config set-url https://github.com/user/repo.git"
            print_info "      gw config set-url upstream https://github.com/other/repo.git"
            return 1
        fi

        if [ -z "$url_to_set" ]; then
            print_error "错误: 未提供 URL。"
            return 1
        fi

        if git remote get-url "$remote_name_to_set_url" > /dev/null 2>&1; then
            print_step "远程仓库 '$remote_name_to_set_url' 已存在，正在更新其 URL 为 '$url_to_set'..."
            if git remote set-url "$remote_name_to_set_url" "$url_to_set"; then
                print_success "远程仓库 '$remote_name_to_set_url' 的 URL 已更新为 '$url_to_set'。"
                git remote -v | grep --color=always "$remote_name_to_set_url"
            else
                print_error "更新远程仓库 '$remote_name_to_set_url' 的 URL 失败。"
                return 1
            fi
        else
            print_step "远程仓库 '$remote_name_to_set_url' 不存在，正在添加并设置 URL 为 '$url_to_set'..."
            if git remote add "$remote_name_to_set_url" "$url_to_set"; then
                print_success "远程仓库 '$remote_name_to_set_url' 已添加，URL 为 '$url_to_set'。"
                git remote -v | grep --color=always "$remote_name_to_set_url"
            else
                print_error "添加远程仓库 '$remote_name_to_set_url' 失败。"
                return 1
            fi
        fi
        return 0
    fi

    # Handler for: gw config add-remote <name> <url>
    if [[ "$1" == "add-remote" ]]; then
        if ! check_in_git_repo; then
            print_error "添加远程仓库的操作需要在 Git 仓库中执行。"
            return 1
        fi
        shift # consume "add-remote"
        if [ "$#" -ne 2 ]; then
            print_error "用法错误: gw config add-remote <name> <url>"
            return 1
        fi
        local remote_name_to_add="$1"
        local url_to_add="$2"

        if git remote get-url "$remote_name_to_add" > /dev/null 2>&1; then
            print_error "错误: 远程仓库 '$remote_name_to_add' 已存在。"
            print_info "如需修改 URL，请使用 'gw config set-url $remote_name_to_add <new_url>'。"
            return 1
        fi

        print_step "正在添加远程仓库 '$remote_name_to_add' URL 为 '$url_to_add'..."
        if git remote add "$remote_name_to_add" "$url_to_add"; then
            print_success "远程仓库 '$remote_name_to_add' 已添加。"
            git remote -v | grep --color=always "$remote_name_to_add"
        else
            print_error "添加远程仓库 '$remote_name_to_add' 失败。"
            return 1
        fi
        return 0
    fi

    # Handler for: gw config list / gw config show
    if [[ "$1" == "list" || "$1" == "show" ]]; then
        print_info "=== gw Script Configuration & Effective Values ==="
        
        # Default Editor (from ~/.gw_editor_pref via gw ide)
        # GW_EDITOR_PREF_FILE and get_short_name_from_editor_command would need to be available
        # if cmd_ide.sh is sourced globally or those definitions are moved to a common utils file.
        # For now, we assume cmd_ide.sh handles its own display when `gw ide` is called.
        # We can show the path to the pref file if it exists.
        local ide_pref_file_path="$HOME/.gw_editor_pref" # Duplicating definition for clarity here
        echo -n "default-editor (set by 'gw ide'): "
        if [ -s "$ide_pref_file_path" ]; then
            local editor_cmd
            editor_cmd=$(cat "$ide_pref_file_path")
            echo -e "${CYAN}${editor_cmd}${NC} (from ${ide_pref_file_path})"
        else
            echo -e "${GRAY}Not set via 'gw ide' (gw save uses VISUAL/EDITOR fallback)${NC}"
        fi

        # Script variables from config_vars.sh (these are the effective, sourced values)
        print_info "default-main (Configured Fallback): ${CYAN}${DEFAULT_MAIN_BRANCH}${NC}"
        print_info "default-main (Effective, auto-detected): ${CYAN}${MAIN_BRANCH}${NC}"
        print_info "remote-name (Default for operations): ${CYAN}${REMOTE_NAME}${NC}"
        print_info "max-attempts (For network ops): ${CYAN}${MAX_ATTEMPTS}${NC}"
        print_info "delay-seconds (Between network retries): ${CYAN}${DELAY_SECONDS}${NC}"
        
        echo ""
        print_info "--- Git User Configuration (effective) ---"
        print_info "To see all Git settings, use 'gw config --list [--global|--local]'"
        local local_user_name local_user_email
        local_user_name=$(git config user.name 2>/dev/null)
        local_user_email=$(git config user.email 2>/dev/null)

        if [ -n "$local_user_name" ]; then
            print_info "user.name (effective for this repo): ${CYAN}$local_user_name${NC}"
        else
            print_info "user.name (effective for this repo): ${CYAN}$(git config --global user.name 2>/dev/null || echo "<Not Set Globally>")${NC} ${GRAY}(from global)${NC}"
        fi
        if [ -n "$local_user_email" ]; then
            print_info "user.email (effective for this repo): ${CYAN}$local_user_email${NC}"
        else
            print_info "user.email (effective for this repo): ${CYAN}$(git config --global user.email 2>/dev/null || echo "<Not Set Globally>")${NC} ${GRAY}(from global)${NC}"
        fi
        return 0
    fi

    # Handler for: gw config <name> <email> --global (GLOBAL shortcut)
    if [ "$#" -eq 3 ] && [[ ! "$1" =~ ^- && ! "$2" =~ ^- && ( "$3" == "--global" || "$3" == "-g" ) ]]; then
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

    # Handler for: gw config <name> <email> (LOCAL shortcut)
    if [ "$#" -eq 2 ] && [[ ! "$1" =~ ^- && ! "$2" =~ ^- ]]; then
        # This specific shortcut requires being in a repo.
        if ! check_in_git_repo; then
            print_error "快速设置本地用户名/邮箱的操作应在 Git 仓库中运行。"
            return 1
        fi
        local username="$1"
        local email="$2"
        
        print_step "正在配置本地仓库的 user.name 和 user.email..."
        local op_success=true
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
            echo "  gw config \"$username\" \"$email\" --global"
            echo "  (或直接使用 'gw config --global user.name \"$username\"' 等原生命令)"
            return 0
        else
            return 1
        fi
    fi

    # Fallback: Pass all other arguments to git config
    # This will now also handle `gw config user.name "Name"` etc.
    print_info "执行: git config $@"
    if git config "$@"; then
        return 0
    else
        # git config itself will print errors for invalid syntax or context
        return 1
    fi
}