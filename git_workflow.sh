#!/bin/bash
# --- 获取脚本自身所在目录 ---
_SCRIPT_PATH_="${BASH_SOURCE[0]}"
_SCRIPT_DIR_COMPONENT_="$(dirname -- "$_SCRIPT_PATH_")"

if ! SCRIPT_DIR="$(cd -- "$_SCRIPT_DIR_COMPONENT_" &> /dev/null && pwd -P)"; then
    echo "错误：无法解析脚本自身的目录 (cd '$_SCRIPT_DIR_COMPONENT_' failed)." >&2
    exit 1
fi

if [ -z "$SCRIPT_DIR" ]; then
    echo "错误：脚本自身目录解析为空 (BASH_SOURCE='$_SCRIPT_PATH_', dirname='$_SCRIPT_DIR_COMPONENT_')." >&2
    exit 1
fi

# 脚本：增强版 Git 工作流助手 (Git Workflow - gw)
# 描述：根据实际工作流程优化的 Git 操作集合，提供便捷的一站式命令
# 版本：3.0
# 定义导入文件的函数
import_file() {
    local file_path="$1"
    local file_name=$(basename "$file_path")
    
    if [ -f "$file_path" ]; then
        source "$file_path"
    else
        echo "错误：文件 $file_name 未找到 (路径: $file_path)。" >&2
        exit 1 # Critical dependency
    fi
}

# 定义需要导入的文件列表
declare -a core_files=(
    "${SCRIPT_DIR}/core_utils/colors.sh"
    "${SCRIPT_DIR}/core_utils/config_vars.sh"
    "${SCRIPT_DIR}/core_utils/utils_print.sh"
    "${SCRIPT_DIR}/core_utils/utils.sh"
    "${SCRIPT_DIR}/core_utils/git_network_ops.sh"
)

shopt -s nullglob
declare -a action_files=(
    "${SCRIPT_DIR}/actions/cmd_"*.sh
    "${SCRIPT_DIR}/actions/gw_"*.sh
)
if [ -f "${SCRIPT_DIR}/actions/show_help.sh" ]; then
    action_files+=("${SCRIPT_DIR}/actions/show_help.sh")
fi
shopt -u nullglob

# 导入核心文件
for file in "${core_files[@]}"; do
    import_file "$file"
done

# 记录最后一次命令的执行状态
LAST_COMMAND_STATUS=0

# 设置中断处理
trap "echo -e '\n${YELLOW}脚本被用户中断，退出.${NC}'; exit 130" INT

# 辅助函数：报告参数错误
_report_arg_error() {
    local command_name="$1"
    local error_message="$2"
    print_error "参数错误: ${error_message}"
    echo -e "${CYAN}请使用 'gw help ${command_name}' 查看正确用法。${NC}"
    LAST_COMMAND_STATUS=1 # 设置错误状态，以便主函数退出时使用
}

# 导入命令实现文件
for file in "${action_files[@]}"; do
    import_file "$file"
done

# 主函数
main() {
    # --- 全局选项解析 ---
    GW_VERBOSE=false
    GW_DRY_RUN=false
    export GW_VERBOSE GW_DRY_RUN # 导出变量使其对子脚本可见
    local command_args=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v)
                GW_VERBOSE=true
                # print_info "(调试) 详细模式已启用" # 移至实际使用时打印
                shift
                ;;
            --dry-run|-n)
                GW_DRY_RUN=true
                # print_info "(调试) 预演模式已启用 (不会执行实际更改)" # 移至实际使用时打印
                shift
                ;;
            --)
                shift
                command_args+=( "$@" )
                break
                ;;
            -*)
                # 如果是像 -m "message" 这样的选项，它属于特定命令，这里不处理
                # 但如果是未知的全局选项，可以考虑报错或忽略
                # 为了简单起见，我们先假设所有其他选项都传递给命令
                command_args+=( "$1" )
    shift
                ;;
            *)
                command_args+=( "$1" )
                    shift
                ;;
        esac
    done
    # 将解析后的参数重新放回位置参数列表，或者直接使用 command_args 数组
    set -- "${command_args[@]}" # 重新设置位置参数，以便后续的 command=$1 和 shift 能正确工作
    # --- 全局选项解析结束 ---

    # 允许 help, init, config --global/--system 在非 git 仓库目录执行
    local allow_outside_repo=false
        case "$1" in
        help|--help|-h|init)
             allow_outside_repo=true
             ;;
        config)
             # 检查是否有 --global 或 --system
    for arg in "$@"; do
                 if [[ "$arg" == "--global" || "$arg" == "--system" ]]; then
                     allow_outside_repo=true
            break
        fi
    done
             # config --list 也允许
             if [[ "$2" == "--list" || "$2" == "-l" ]]; then
                 allow_outside_repo=true
             fi
                ;;
        esac

    if ! $allow_outside_repo && ! check_in_git_repo; then
           # check_in_git_repo 内部会打印错误
        return 1
    fi

    local command="$1"
    # 如果没有命令，提示使用 help
    if [ -z "$command" ]; then
        echo "请输入一个命令。运行 'gw help' 查看可用命令。"
        return 1
    fi
    shift
    
    case "$command" in
        gh-create)
            cmd_gh_create "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        init)
            cmd_init "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        config)
            cmd_config "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        remote)
            cmd_remote "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        status)
            cmd_status "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        add)
            cmd_add "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        add-all)
            if [ "$#" -ne 0 ]; then
                _report_arg_error "add-all" "命令 'add-all' 不需要参数。"
            else
            cmd_add_all
            LAST_COMMAND_STATUS=$?
            fi
            ;;
        commit)
            cmd_commit "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        save)
            cmd_save "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        sp)
            cmd_sp "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        push)
            cmd_push "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        pull)
            cmd_pull "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        fetch)
            cmd_fetch "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        sync)
            if [ "$#" -ne 0 ]; then
                _report_arg_error "sync" "命令 'sync' 当前不需要参数。"
            else
                cmd_sync # cmd_sync 内部不处理参数
                LAST_COMMAND_STATUS=$?
             fi
             ;;
        branch)
            cmd_branch "$@"
                    LAST_COMMAND_STATUS=$?
                    ;;
        rm)
            cmd_rm_branch "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        checkout|switch|co)
            cmd_checkout "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        merge)
            cmd_merge "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        diff)
            cmd_diff "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        log)
            cmd_log "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        new)
            cmd_new "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        finish)
            cmd_finish "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        main|master)
            echo -e "${BLUE}准备推送主分支 ($MAIN_BRANCH)...${NC}"
            cmd_push "$REMOTE_NAME" "$MAIN_BRANCH" "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        1|first)
            if [ "$#" -eq 0 ]; then
                _report_arg_error "1" "命令 '1' (或 'first') 需要至少一个分支名参数。"
            else
                local branch_arg="$1"
                echo -e "${BLUE}执行首次推送 (模式 1) 分支 '$branch_arg' (带 -u)...${NC}"
                shift
                cmd_push "-u" "$REMOTE_NAME" "$branch_arg" "$@"
                LAST_COMMAND_STATUS=$?
            fi
            ;;
        2)
            echo -e "${BLUE}执行推送主分支 (模式 2)...${NC}"
            cmd_push "$REMOTE_NAME" "$MAIN_BRANCH" "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        3|other)
            if [ "$#" -eq 0 ]; then
                _report_arg_error "3" "命令 '3' (或 'other') 需要至少一个分支名参数。"
            else
                local branch_arg="$1"
                echo -e "${BLUE}执行推送指定分支 (模式 3) '$branch_arg'...${NC}"
                shift
                cmd_push "$REMOTE_NAME" "$branch_arg" "$@"
                LAST_COMMAND_STATUS=$?
            fi
            ;;
        4|current)
            echo -e "${BLUE}执行推送当前分支 (模式 4)...${NC}"
            local current_branch
            current_branch=$(get_current_branch_name)
            if [ $? -ne 0 ]; then 
                LAST_COMMAND_STATUS=1
            else
                cmd_push "$REMOTE_NAME" "$current_branch" "$@"
                LAST_COMMAND_STATUS=$?
            fi
            ;;
        reset)
            cmd_reset "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        clean)
            if [ "$#" -ne 1 ]; then
                _report_arg_error "clean" "命令 'clean' 需要且仅需要一个分支名参数。"
            else
            cmd_clean_branch "$@"
            LAST_COMMAND_STATUS=$?
            fi
            ;;
        stash)
            cmd_stash "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        help|--help|-h)
            show_help
            LAST_COMMAND_STATUS=0
            ;;
        *)
            echo -e "${RED}错误: 未知命令 \"$command\"${NC}"
            echo "请运行 'gw help' 查看可用命令。"
            LAST_COMMAND_STATUS=1
            ;;
    esac

    exit $LAST_COMMAND_STATUS
}

# --- 脚本入口 ---

# 设置脚本在出错时退出 (可选，但推荐)
# set -e

# 执行主函数，并将所有参数传递给它
main "$@"

