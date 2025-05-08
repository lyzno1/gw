#!/bin/bash
# 脚本/actions/cmd_undo.sh

# 实现 'undo' 命令逻辑，用于撤销上一次提交。
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

cmd_undo() {
    if ! check_in_git_repo; then
        return 1
    fi

    local mode="mixed" # default
    local confirm_needed=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --soft)
                mode="soft"
                shift
                ;;
            --hard)
                mode="hard"
                confirm_needed=true
                shift
                ;;
            *)
                print_error "未知选项: $1"
                show_help_for_command "undo"
                return 1
                ;;
        esac
    done

    # 检查是否有父提交
    if ! git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
        print_error "无法撤销：HEAD 没有父提交 (可能是初始提交或仓库为空)。"
        return 1
    fi

    if $confirm_needed; then
        if ! utils_confirm "$(print_warning "警告:") 您确定要永久丢弃上一次提交及其所有更改吗？此操作无法恢复。"; then
            print_info "操作已取消。"
            return 0
        fi
    fi

    print_step "正在撤销上一次提交 (模式: ${mode})..."
    case "$mode" in
        soft)
            if git reset --soft HEAD~1; then
                print_success "上一次提交已撤销。更改保留在暂存区。"
            else
                print_error "撤销提交失败 (soft reset)。"
                return 1
            fi
            ;;
        hard)
            if git reset --hard HEAD~1; then
                print_success "上一次提交已撤销，相关更改已被永久丢弃。"
            else
                print_error "撤销提交失败 (hard reset)。"
                return 1
            fi
            ;;
        mixed) # default
            if git reset HEAD~1; then # --mixed is default
                print_success "上一次提交已撤销。更改已移至您的工作目录 (未暂存)。"
            else
                print_error "撤销提交失败 (mixed reset)。"
                return 1
            fi
            ;;
    esac
    return 0
} 