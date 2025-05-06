#!/bin/bash
# 脚本/actions/gw_new.sh
#
# 实现 'new' (创建新分支) 命令逻辑。
# 依赖:
# - colors.sh (颜色定义)
# - utils_print.sh (打印函数)
# - utils.sh (通用工具函数)
# - config_vars.sh (配置变量, MAIN_BRANCH, REMOTE_NAME)
# - git_network_ops.sh (do_pull_with_retry)
# - help.sh (show_help - 如果解析参数失败)

# 创建并切换到新分支
gw_new() {
    if ! check_in_git_repo; then return 1; fi

    local new_branch_name
    local base_branch_param=""
    local local_flag=false

    # 使用 getopt 进行更健壮的参数解析
    # 定义短选项和长选项
    # -o 表示短选项，后面是可接受的短选项字符
    # --long 表示长选项，后面是逗号分隔的长选项名
    # n: 表示选项后面需要参数 (例如 -b <branch>)
    # 如果 getopt 不可用，可以退回到简单的参数解析
    if ! command -v getopt >/dev/null 2>&1; then
        print_warning "getopt 命令未找到，使用基础参数解析。这可能不支持所有高级选项。"
        # 基础参数解析 (仅支持 gw new <branch> [base] --local)
        if [ -z "$1" ]; then
            print_error "错误：需要提供新分支名称。"
            show_help # 假设 show_help 可用
            return 1
        fi
        new_branch_name="$1"
        shift
        if [[ "$1" != "--local" && -n "$1" ]]; then
            base_branch_param="$1"
            shift
        fi
        if [[ "$1" == "--local" ]]; then
            local_flag=true
            shift
        fi
        if [ $# -gt 0 ]; then
            print_warning "忽略了额外的参数: $@"
        fi
    else
        parsed_args=$(getopt -o l --long local,base: -n 'gw new' -- "$@")
        if [ $? != 0 ]; then
            # show_help # getopt 错误时显示帮助
            echo "用法: gw new <new_branch_name> [--local] [--base <base_branch>]"
            return 1
        fi 
        eval set -- "$parsed_args"
        while true; do
            case "$1" in
                --local|-l)
                    local_flag=true
                    shift
                    ;;
                --base)
                    base_branch_param="$2"
                    shift 2
                    ;;
                --)
                    shift
                    break
                    ;;
                *)
                    # 应为 getopt 处理了未知选项
                    break
                    ;;
            esac
        done
        # 第一个非选项参数是 new_branch_name
        if [ -z "$1" ]; then
            print_error "错误：需要提供新分支名称。"
            # show_help
            echo "用法: gw new <new_branch_name> [--local] [--base <base_branch>]"
            return 1
        fi
        new_branch_name="$1"
        shift
        if [ $# -gt 0 ]; then # 剩下的应该是base_branch (如果未使用--base) 或无效参数
             if [ -z "$base_branch_param" ] && [[ ! "$1" =~ ^- ]]; then # 如果未使用 --base 且不是选项
                 base_branch_param="$1"
                 shift
             fi
             if [ $# -gt 0 ]; then
                print_warning "忽略了 'new' 命令无法识别的额外参数: $@"
             fi
        fi
    fi

    # 验证分支名是否有效
    if ! git check-ref-format --branch "$new_branch_name"; then
        print_error "错误：无效的分支名称 '$new_branch_name'。"
        return 1
    fi

    # 确定基础分支
    local base_branch=${base_branch_param:-$MAIN_BRANCH} # 如果未指定，则默认为 MAIN_BRANCH
    print_info "将基于分支 '${base_branch}' 创建新分支 '${new_branch_name}'。"

    # 检查基础分支是否存在本地或远程
    local base_branch_exists_locally=false
    if git rev-parse --verify --quiet "refs/heads/$base_branch" > /dev/null 2>&1; then
        base_branch_exists_locally=true
    fi

    if ! $base_branch_exists_locally && ! $local_flag; then
        # 本地不存在且不是 local 模式, 尝试从远程获取
        if git rev-parse --verify --quiet "refs/remotes/$REMOTE_NAME/$base_branch" > /dev/null 2>&1; then
            print_warning "本地不存在基础分支 '${base_branch}'，但远程存在。尝试从远程获取..."
            if ! git fetch "$REMOTE_NAME" "$base_branch:refs/remotes/$REMOTE_NAME/$base_branch"; then # 只 fetch 这个分支
                 print_error "无法从远程 '${REMOTE_NAME}' 获取基础分支 '${base_branch}' 的引用。"
                 return 1
            fi
            # 创建本地跟踪分支，但不切换
             if ! git branch "$base_branch" "refs/remotes/$REMOTE_NAME/$base_branch"; then 
                 print_error "创建本地跟踪分支 '${base_branch}' 失败。"
                 return 1
             fi
            print_success "成功获取并创建本地基础分支 '${base_branch}'。"
            base_branch_exists_locally=true # 现在本地存在了
        else
            print_error "错误：基础分支 '${base_branch}' 在本地和远程 '${REMOTE_NAME}' 都不存在。"
            return 1
        fi
    elif ! $base_branch_exists_locally && $local_flag; then
         print_error "错误：--local 模式要求基础分支 '${base_branch}' 必须在本地存在。"
         return 1
    fi # 如果 base_branch_exists_locally 为 true，则什么都不做，直接用本地的

    # 1. 切换到基础分支 (现在它应该在本地存在了)
    print_step "1/3: 切换到基础分支 '${base_branch}'..."
    if ! git checkout "$base_branch"; then
        print_error "切换到基础分支 '${base_branch}' 失败。"
        return 1
    fi
    print_success "已切换到基础分支 '${base_branch}'。"

    # 2. 如果不是 --local 模式，则拉取基础分支的最新代码
    if ! $local_flag; then
        print_step "2/3: 拉取基础分支 '${base_branch}' 的最新代码 (使用 rebase)..."
        if ! do_pull_with_retry --rebase "$REMOTE_NAME" "$base_branch"; then # 使用带重试的 pull 并 rebase
            print_error "从 '${REMOTE_NAME}/${base_branch}' 拉取代码 (rebase) 失败。"
            print_warning "请检查网络连接或手动解决冲突后重试。当前停留在 '${base_branch}'。"
            return 1
        fi
        print_success "基础分支 '${base_branch}' 已更新至最新。"
    else
        print_step "2/3: 跳过拉取最新代码 (--local 模式)。基础分支状态为本地当前状态。"
    fi

    # 3. 创建并切换到新分支
    print_step "3/3: 创建并切换到新分支 '${new_branch_name}'..."
    if git rev-parse --verify --quiet "refs/heads/$new_branch_name" > /dev/null 2>&1; then
         print_warning "分支 '${new_branch_name}' 已存在。将直接切换到该分支。"
         if ! git checkout "$new_branch_name"; then
             print_error "切换到已存在的分支 '${new_branch_name}' 失败。"
             return 1
         fi
    else
        if ! git checkout -b "$new_branch_name"; then
            print_error "创建并切换到新分支 '${new_branch_name}' 失败。"
            # 尝试切换回基础分支以保持状态一致性
            print_info "尝试切换回基础分支 '${base_branch}'..."
            git checkout "$base_branch"
            return 1
        fi
    fi

    print_success "操作完成！已创建并切换到新分支 '${new_branch_name}'。"
    print_info "现在可以开始在新分支上进行开发了。"
} 