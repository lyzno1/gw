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
cmd_new() {
    if ! check_in_git_repo; then return 1; fi

    local changes_were_stashed_by_cmd_new=false
    if check_uncommitted_changes || check_untracked_files; then
        print_warning "检测到未提交的变更或未追踪的文件。"
        echo "变更详情:"
        git status -s
        echo ""
        echo -e "${YELLOW}在创建新分支前，建议处理这些变更:${NC}"
        echo -e "1) ${GREEN}暂存 (Stash) 当前变更并继续${NC}"
        echo -e "2) ${RED}取消 'cmd new' 操作${NC}"
        local choice_stash
        read -r -p "请选择操作 [1-2]: " choice_stash

        case "$choice_stash" in
            1)
                local stash_branch_name
                stash_branch_name=$(get_current_branch_name)
                if [ -z "$stash_branch_name" ]; then stash_branch_name="unknown_branch"; fi
                print_step "正在暂存当前变更 (git stash save 'WIP on $stash_branch_name before cmd new')..."
                if git stash save "WIP on $stash_branch_name before cmd new"; then
                    print_success "变更已成功暂存。"
                    changes_were_stashed_by_cmd_new=true
                else
                    print_error "暂存变更失败。'cmd new' 操作已取消。"
                    return 1
                fi
                ;;
            2|*)
                echo "'cmd new' 操作已取消。"
                return 1
                ;;
        esac
        echo "" # Add a newline for better readability after stash prompt
    fi

    local new_branch_name
    local base_branch_param=""
    local local_flag=false

    # 检测 getopt 类型
    local use_gnu_getopt=false
    if command -v getopt >/dev/null 2>&1; then
        getopt --test > /dev/null 2>&1
        if [ $? -eq 4 ]; then
            use_gnu_getopt=true
        fi
    fi

    if $use_gnu_getopt; then
        # GNU getopt 逻辑
        parsed_args=$(getopt -o l --long local,base: -n 'cmd new' -- "$@")
        if [ $? != 0 ]; then
            echo "用法: cmd new <new_branch_name> [--local] [--base <base_branch>]"
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
                    break
                    ;;
            esac
        done
        if [ -z "$1" ]; then
            print_error "错误：需要提供新分支名称。"
            echo "用法: cmd new <new_branch_name> [--local] [--base <base_branch>]"
            return 1
        fi
        new_branch_name="$1"
        shift
        if [ $# -gt 0 ]; then
             if [ -z "$base_branch_param" ] && [[ ! "$1" =~ ^- ]]; then
                 base_branch_param="$1"
                 shift
             fi
             if [ $# -gt 0 ]; then
                print_warning "忽略了 'new' 命令无法识别的额外参数 (GNU getopt): $@"
             fi
        fi
    else
        # getopt 未找到或非 GNU getopt，使用基础参数解析
        if command -v getopt >/dev/null 2>&1; then
             print_warning "检测到非 GNU getopt，将使用基础参数解析。长选项如 --base 可能不受支持或需按 'cmd new <branch> [base] --local' 格式。建议安装 GNU getopt (如 macOS: brew install gnu-getopt)。"
        else
             print_warning "getopt 命令未找到，使用基础参数解析。这可能不支持所有高级选项。"
        fi
        
        if [ -z "$1" ]; then
            print_error "错误：需要提供新分支名称。"
            echo "用法 (基础解析): cmd new <branch_name> [base_branch] [--local]"
            return 1
        fi
        new_branch_name="$1"
        shift
        
        # 尝试解析基础分支 (作为第二个位置参数)
        if [[ "$1" != "--local" && -n "$1" ]]; then
            base_branch_param="$1"
            shift
        fi
        
        if [[ "$1" == "--local" ]]; then
            local_flag=true
            shift
        fi
        
        if [ $# -gt 0 ]; then
            print_warning "忽略了 'new' 命令无法识别的额外参数 (基础解析): $@"
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

    if $changes_were_stashed_by_cmd_new; then
        echo "" # Add a newline for better readability
        print_info "之前在此次 'cmd_new' 操作开始时，有一些变更被自动暂存了。"
        if confirm_action "是否尝试在新分支 '${new_branch_name}' 上应用 (git stash pop) 这些暂存的变更？"; then
            print_step "尝试应用暂存 (git stash pop)..."
            if git stash pop; then
                print_success "暂存已成功应用。"
            else
                print_error "应用暂存失败 (可能存在冲突)。"
                print_info "您可能需要手动解决冲突或使用 'git stash apply stash@{0}' (或对应的stash ID) 来应用。"
                git status -s # Show status after failed pop
            fi
        else
            print_info "暂存的变更未自动应用。您可以使用 'git stash list' 查看，并用 'git stash pop/apply' 手动恢复。"
        fi
    fi
    return 0
} 