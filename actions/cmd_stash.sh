#!/bin/bash
# 脚本/actions/cmd_stash.sh
#
# 实现 'stash' 命令逻辑，封装 git stash 常用操作，统一输出与交互。
# 依赖:
# - core_utils/colors.sh (颜色定义)
# - core_utils/utils_print.sh (打印函数)
# - core_utils/utils.sh (通用工具函数)
# - core_utils/config_vars.sh (配置变量)
#

# gw stash 主命令入口
# @param $1 子命令（push/pop/apply/list/show/drop/clear）
# @param $2... 其余参数
cmd_stash() {
    local subcmd="$1"
    shift
    case "$subcmd" in
        push|save|"" )
            # push 支持 -m/--message
            local msg=""
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    -m|--message)
                        msg="$2"
                        shift 2
                        ;;
                    *)
                        break
                        ;;
                esac
            done
            if [ -n "$msg" ]; then
                git stash push -u -m "$msg"
            else
                git stash push -u
            fi
            if [ $? -eq 0 ]; then
                print_success "已保存当前工作区更改到 stash。"
            else
                print_error "stash 保存失败。"
                return 1
            fi
            ;;
        pop)
            git stash pop "$@"
            if [ $? -eq 0 ]; then
                print_success "已恢复最近的 stash 更改。"
            else
                print_error "stash pop 失败。请检查冲突。"
                return 1
            fi
            ;;
        apply)
            git stash apply "$@"
            if [ $? -eq 0 ]; then
                print_success "已应用 stash 更改（未删除 stash 条目）。"
            else
                print_error "stash apply 失败。请检查冲突。"
                return 1
            fi
            ;;
        list|ls)
            print_info "当前 stash 列表："
            git stash list
            ;;
        show)
            git stash show "$@"
            ;;
        drop)
            git stash drop "$@"
            if [ $? -eq 0 ]; then
                print_success "已删除指定 stash 条目。"
            else
                print_error "stash drop 失败。"
                return 1
            fi
            ;;
        clear)
            read -p "⚠️ 你确定要清空所有 stash 吗？此操作不可恢复！[y/N]: " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                git stash clear
                if [ $? -eq 0 ]; then
                    print_success "已清空所有 stash。"
                else
                    print_error "stash clear 失败。"
                    return 1
                fi
            else
                print_info "已取消清空 stash。"
            fi
            ;;
        help|-h|--help)
            echo "用法: gw stash [push|pop|apply|list|show|drop|clear] [参数]"
            echo "  push [-m <msg>]   保存当前更改到 stash (默认)"
            echo "  pop [<stash@{n}>] 弹出最近或指定 stash"
            echo "  apply [<stash@{n}>] 应用 stash（不删除）"
            echo "  list              列出所有 stash"
            echo "  show [<stash@{n}>] 显示 stash 详情"
            echo "  drop <stash@{n}>  删除指定 stash"
            echo "  clear             清空所有 stash（需确认）"
            ;;
        *)
            print_error "未知子命令: $subcmd"
            echo "用法: gw stash [push|pop|apply|list|show|drop|clear] [参数]"
            return 1
            ;;
    esac
}
