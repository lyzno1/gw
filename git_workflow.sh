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

declare -a action_files=(
    "${SCRIPT_DIR}/actions/cmd_add.sh"
    "${SCRIPT_DIR}/actions/cmd_add_all.sh"
    "${SCRIPT_DIR}/actions/cmd_branches.sh"
    "${SCRIPT_DIR}/actions/cmd_checkout.sh"
    "${SCRIPT_DIR}/actions/cmd_clean_branch.sh"
    "${SCRIPT_DIR}/actions/cmd_commit.sh"
    "${SCRIPT_DIR}/actions/cmd_config.sh"
    "${SCRIPT_DIR}/actions/cmd_delete_branch.sh"
    "${SCRIPT_DIR}/actions/cmd_diff.sh"
    "${SCRIPT_DIR}/actions/cmd_fetch.sh"
    "${SCRIPT_DIR}/actions/cmd_finish.sh"
    "${SCRIPT_DIR}/actions/cmd_gh_create.sh"
    "${SCRIPT_DIR}/actions/cmd_init.sh"
    "${SCRIPT_DIR}/actions/cmd_log.sh"
    "${SCRIPT_DIR}/actions/cmd_merge.sh"
    "${SCRIPT_DIR}/actions/cmd_pull.sh"
    "${SCRIPT_DIR}/actions/cmd_push.sh"
    "${SCRIPT_DIR}/actions/cmd_remote.sh"
    "${SCRIPT_DIR}/actions/cmd_rm_branch.sh"
    "${SCRIPT_DIR}/actions/cmd_reset.sh"
    "${SCRIPT_DIR}/actions/cmd_save.sh"
    "${SCRIPT_DIR}/actions/cmd_status.sh"
    "${SCRIPT_DIR}/actions/cmd_sync.sh"
    "${SCRIPT_DIR}/actions/gw_new.sh"
    "${SCRIPT_DIR}/actions/show_help.sh"
)

# 导入核心文件
for file in "${core_files[@]}"; do
    import_file "$file"
done

# 记录最后一次命令的执行状态
LAST_COMMAND_STATUS=0

# 设置中断处理
trap "echo -e '\n${YELLOW}脚本被用户中断，退出.${NC}'; exit 130" INT

# 导入命令实现文件
for file in "${action_files[@]}"; do
    import_file "$file"
done

# 主函数
main() {
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
            cmd_add_all
            LAST_COMMAND_STATUS=$?
            ;;
        commit)
            cmd_commit "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        save)
            cmd_save "$@"
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
             cmd_sync
             LAST_COMMAND_STATUS=$?
             ;;
        branch)
            case "$1" in
                 ""|-a|-r|--list|--show-current) 
                    git branch "$@"
                    LAST_COMMAND_STATUS=$?
                    ;;
                 -d|-D)
                     local branch_to_delete="$2"
                     if [ -z "$branch_to_delete" ]; then
                        echo -e "${RED}错误: 请提供要删除的分支名称。${NC}"
                        LAST_COMMAND_STATUS=1
                     else
                        echo -e "${BLUE}正在使用 'git branch $@' 删除分支...${NC}"
                        git branch "$@"
                        LAST_COMMAND_STATUS=$?
                     fi
                     ;;
                 *)
                     echo -e "${RED}错误: 未知的 'branch' 子命令或选项 '$1'。${NC}"
                     echo "创建分支请使用 'gw new <分支名>'。"
                     echo "删除分支请使用 'gw rm <分支名>' 或 'git branch -d/-D <分支名>'。"
                     echo "查看分支请使用 'gw branch' 或 'git branch'。"
                     LAST_COMMAND_STATUS=1
                     ;;
            esac
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
            gw_new "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        finish)
            cmd_finish "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        main|master)
            echo -e "${BLUE}准备推送主分支 ($MAIN_BRANCH)...${NC}"
            do_push_with_retry "$REMOTE_NAME" "$MAIN_BRANCH" "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        1|first)
            local branch_arg="$1"
            if [ -z "$branch_arg" ]; then
                echo -e "${RED}错误: 命令 '1' 或 'first' 需要指定分支名称。${NC}"
                echo "用法: gw 1 <分支名> [...]"
                LAST_COMMAND_STATUS=1
            else
                echo -e "${BLUE}执行首次推送 (模式 1) 分支 '$branch_arg' (带 -u)...${NC}"
                shift
                do_push_with_retry "-u" "$REMOTE_NAME" "$branch_arg" "$@"
                LAST_COMMAND_STATUS=$?
            fi
            ;;
        2)
            echo -e "${BLUE}执行推送主分支 (模式 2)...${NC}"
            do_push_with_retry "$REMOTE_NAME" "$MAIN_BRANCH" "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        3|other)
            local branch_arg="$1"
            if [ -z "$branch_arg" ]; then
                echo -e "${RED}错误: 命令 '3' 或 'other' 需要指定分支名称。${NC}"
                echo "用法: gw 3 <分支名> [...]"
                LAST_COMMAND_STATUS=1
            else
                echo -e "${BLUE}执行推送指定分支 (模式 3) '$branch_arg'...${NC}"
                shift
                do_push_with_retry "$REMOTE_NAME" "$branch_arg" "$@"
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
                do_push_with_retry "$REMOTE_NAME" "$current_branch" "$@"
                LAST_COMMAND_STATUS=$?
            fi
            ;;
        reset)
            cmd_reset "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        clean)
            cmd_clean_branch "$@"
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

