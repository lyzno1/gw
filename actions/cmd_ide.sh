#!/bin/bash
# 脚本/actions/cmd_ide.sh
#
# 实现 'ide' 命令逻辑，用于设置 gw save 使用的默认编辑器。
# 依赖:
# - colors.sh
# - utils_print.sh

# 定义 gw 编辑器偏好文件的路径
GW_EDITOR_PREF_FILE="$HOME/.gw_editor_pref"

# 预定义的编辑器短名称到完整命令的映射
# 使用函数替代关联数组以提高兼容性
get_editor_command_from_short_name() {
    local lower_short_name
    lower_short_name=$(echo "$1" | tr '[:upper:]' '[:lower:]') # 转换为小写以实现大小写不敏感匹配
    
    case "$lower_short_name" in
        vscode|code) echo "code --wait";;
        cursor) echo "cursor --wait";; # cursor 命令存在且支持 --wait
        sublime|subl) echo "subl --wait";;
        windsurf) echo "windsurf --wait";; # 根据用户文件内容保留
        trae) echo "trae --wait";;       # 根据用户文件内容保留
        vim) echo "vim";;
        nvim) echo "nvim";;
        nano) echo "nano";;
        emacs) echo "emacs";;
        *) echo "";; # 返回空字符串表示未找到映射
    esac
}

# 获取支持的短名称列表的函数 (用于帮助信息)
get_supported_short_names() {
    # 从 get_editor_command_from_short_name 函数的 case 语句中提取
    # 这是一种间接的方式，更健壮的方式可能是硬编码一个列表或从注释解析
    # 为简单起见，暂时硬编码或依赖用户查看函数体
    echo "vscode, code, cursor, sublime, subl, windsurf, trae, vim, nvim, nano, emacs"
}

cmd_ide() {
    if [ -z "$1" ]; then
        print_info "用法: gw ide <editor_short_name | \"full_editor_command_with_args\">"
        print_info "此命令用于设置 'gw save' 在编辑提交信息时默认尝试打开的编辑器。"
        echo -e "当前设置的编辑器命令为: ${CYAN}$(cat "$GW_EDITOR_PREF_FILE" 2>/dev/null || echo "未设置 (将尝试 code/VISUAL/EDITOR)")${NC}"
        echo "支持的短名称包括: $(get_supported_short_names)" # 使用新函数
        echo "示例:"
        echo "  gw ide vscode"
        echo "  gw ide vim"
        echo "  gw ide \"myeditor --custom-flag --wait\""
        return 1
    fi

    local user_input="$1"
    local editor_command_to_set=""

    # 检查用户输入是否是预定义的短名称
    editor_command_to_set=$(get_editor_command_from_short_name "$user_input")

    if [ -n "$editor_command_to_set" ]; then
        print_info "识别到预定义短名称 '$user_input', 将使用命令: '$editor_command_to_set'"
    else
        # 如果不是短名称，则将用户输入视为完整命令
        editor_command_to_set="$user_input"
        print_info "未识别为预定义短名称，将直接尝试使用用户提供的命令: '$editor_command_to_set'"
    fi

    # (可选) 简单验证命令头是否存在
    local cmd_head
    cmd_head=$(echo "$editor_command_to_set" | awk '{print $1}')
    if ! command -v "$cmd_head" >/dev/null 2>&1; then
        print_warning "警告: 命令 '$cmd_head' (从您输入的 '$editor_command_to_set' 中提取) 似乎在您的 PATH 环境变量中找不到。"
        echo -e "${YELLOW}这可能意味着："
        echo -e "  1. 您输入的命令名称有误。"
        echo -e "  2. 如果您输入的是一个应用程序的显示名称 (例如 \"Visual Studio Code\")，请注意这通常不是一个可直接在命令行执行的命令。"
        echo -e "     您应该提供该编辑器在命令行中的实际调用名称，并附带必要的参数 (例如 \"code --wait\" 或 \"/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code --wait\")。"
        echo -e "  3. 或者，该命令确实存在，但其所在目录不在您的 PATH 环境变量中。${NC}"
        if ! confirm_action "是否仍要将 '$editor_command_to_set' 设置为这个可能无效的编辑器命令？"; then
            print_info "设置已取消。"
            return 1
        fi
    fi

    # 将命令写入偏好文件
    # 创建目录以防万一（虽然 $HOME 通常存在）
    mkdir -p "$(dirname "$GW_EDITOR_PREF_FILE")"
    if echo "$editor_command_to_set" > "$GW_EDITOR_PREF_FILE"; then
        print_success "gw 的默认编辑器已成功设置为: ${GREEN}$editor_command_to_set${NC}"
        print_info "此设置将保存在: $GW_EDITOR_PREF_FILE"
        print_info "下次运行 'gw save' (不带 -m 或 -e) 时将尝试使用此编辑器。"
    else
        print_error "错误: 无法将编辑器偏好写入到 $GW_EDITOR_PREF_FILE。"
        return 1
    fi

    return 0
}
