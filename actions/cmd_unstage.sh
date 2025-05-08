#!/bin/bash
# 脚本/actions/cmd_unstage.sh

# 实现 'unstage' 命令逻辑，用于将暂存区的更改移回工作目录。
#
# 依赖:
# - core_utils/colors.sh (颜色定义)
# - core_utils/utils_print.sh (打印函数)
# - core_utils/utils.sh (通用工具函数)

# Source SCRIPT_DIR if not already sourced
if [ -z "$SCRIPT_DIR" ]; then
  export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

source "$SCRIPT_DIR/core_utils/utils.sh"
source "$SCRIPT_DIR/core_utils/utils_print.sh"

cmd_unstage() {
    if ! check_in_git_repo; then
        return 1
    fi

    local interactive_mode=false
    local files_to_unstage=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i | --interactive)
                interactive_mode=true
                shift
                ;;
            --)
                shift # Consume '--' separator
                files_to_unstage+=("$@") # Add all remaining arguments as files
                break # Stop parsing options
                ;;
            -*)
                print_error "未知选项: $1"
                show_help_for_command "unstage"
                return 1
                ;;
            *)
                files_to_unstage+=("$1")
                shift
                ;;
        esac
    done

    if ! git diff --cached --quiet --exit-code; then # Checks if there is anything staged
        # There are staged changes
        if $interactive_mode; then
            if [ ${#files_to_unstage[@]} -gt 0 ]; then
                print_warning "交互模式下指定文件将被忽略。将对所有暂存的更改进行交互式取消暂存。"
            fi
            print_step "进入交互式取消暂存模式..."
            if git reset -p; then # or git reset --patch
                print_success "交互式取消暂存完成。"
            else
                print_error "交互式取消暂存失败或被中止。"
                return 1
            fi
        elif [ ${#files_to_unstage[@]} -gt 0 ]; then
            print_step "正在取消暂存指定文件: ${files_to_unstage[*]}..."
            if git restore --staged -- "${files_to_unstage[@]}"; then
                print_success "指定文件已取消暂存。"
            else
                print_error "取消暂存指定文件失败。请检查文件是否已暂存。"
                return 1
            fi
        else
            print_step "正在取消暂存所有文件..."
            if git reset HEAD; then # or git restore --staged .
                print_success "所有文件已取消暂存。"
            else
                print_error "取消暂存所有文件失败。"
                return 1
            fi
        fi
    else
        print_info "暂存区为空，无需取消暂存。"
    fi

    return 0
} 