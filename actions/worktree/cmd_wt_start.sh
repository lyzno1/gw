#!/bin/bash
# 脚本/actions/worktree/cmd_wt_start.sh
#
# 实现 'wt-start' 命令逻辑。
# 依赖:
# - core_utils/colors.sh (颜色定义)
# - core_utils/utils_print.sh (打印函数)
# - core_utils/utils.sh (通用工具函数)
# - core_utils/config_vars.sh (配置变量)

# 创建新的worktree分支
cmd_wt_start() {
    if ! check_in_git_repo; then return 1; fi

    # 检查是否在worktree环境中
    if [ ! -f ".gw/worktree-config" ]; then
        print_error "当前不在worktree环境中。请先运行 'gw wt-init' 初始化worktree环境。"
        return 1
    fi

    local new_branch_name
    local base_branch_param=""
    local local_flag=false
    local user_prefix=""

    # 读取用户配置
    if [ -f ".gw/worktree-config" ]; then
        source .gw/worktree-config
    fi

    # 检测 getopt 类型
    local use_gnu_getopt=false
    if command -v getopt >/dev/null 2>&1; then
        getopt --test > /dev/null 2>&1
        if [ $? -eq 4 ]; then
            use_gnu_getopt=true
        fi
    fi

    if $use_gnu_getopt; then
        # GNU getopt 逻辑，支持 -l/--local, -b/--base
        parsed_args=$(getopt -o lb: --long local,base: -n 'gw wt-start' -- "$@")
        if [ $? != 0 ]; then
            echo "用法: gw wt-start <new_branch_name> [--local|-l] [--base|-b <base_branch>]"
            return 1
        fi
        eval set -- "$parsed_args"
        while true; do
            case "$1" in
                --local|-l)
                    local_flag=true
                    shift
                    ;;
                --base|-b)
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
            echo "用法: gw wt-start <new_branch_name> [--local|-l] [--base|-b <base_branch>]"
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
                print_warning "忽略了 'wt-start' 命令无法识别的额外参数: $@"
             fi
        fi
    else
        # 基础参数解析
        if [ -z "$1" ]; then
            print_error "错误：需要提供新分支名称。"
            echo "用法: gw wt-start <branch_name> [base_branch] [--local|-l]"
            return 1
        fi
        new_branch_name="$1"
        shift
        # 解析所有参数，支持任意顺序
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --local|-l)
                    local_flag=true
                    shift
                    ;;
                --base|-b)
                    if [ -n "$2" ]; then
                        base_branch_param="$2"
                        shift 2
                    else
                        print_error "--base/-b 需要一个参数。"
                        return 1
                    fi
                    ;;
                *)
                    if [ -z "$base_branch_param" ]; then
                        base_branch_param="$1"
                        shift
                    else
                        print_warning "忽略了 'wt-start' 命令无法识别的额外参数: $1"
                        shift
                    fi
                    ;;
            esac
        done
    fi

    # 添加用户前缀（如果配置了）
    if [ -n "$USER_PREFIX" ] && [[ ! "$new_branch_name" =~ ^${USER_PREFIX}- ]]; then
        new_branch_name="${USER_PREFIX}-${new_branch_name}"
        print_info "自动添加用户前缀，分支名称: $new_branch_name"
    fi

    # 验证分支名是否有效
    if ! git check-ref-format --branch "$new_branch_name"; then
        print_error "错误：无效的分支名称 '$new_branch_name'。"
        return 1
    fi

    # 检查分支是否已存在
    if git rev-parse --verify --quiet "refs/heads/$new_branch_name" > /dev/null 2>&1; then
        print_error "错误：分支 '$new_branch_name' 已存在。"
        return 1
    fi

    # 生成worktree目录名（将斜杠转换为连字符避免嵌套目录）
    local worktree_dir_name=$(branch_to_worktree_dirname "$new_branch_name")
    local worktree_dir="dev/$worktree_dir_name"
    if [ -d "$worktree_dir" ]; then
        print_error "错误：worktree目录 '$worktree_dir' 已存在。"
        return 1
    fi

    # 确定基础分支
    local base_branch=${base_branch_param:-$MAIN_BRANCH}
    print_info "将基于分支 '${base_branch}' 创建新worktree '${new_branch_name}'。"

    # 检查基础分支是否存在
    local base_branch_exists_locally=false
    if git rev-parse --verify --quiet "refs/heads/$base_branch" > /dev/null 2>&1; then
        base_branch_exists_locally=true
    fi

    if ! $base_branch_exists_locally && ! $local_flag; then
        # 本地不存在且不是 local 模式, 尝试从远程获取
        if git rev-parse --verify --quiet "refs/remotes/$REMOTE_NAME/$base_branch" > /dev/null 2>&1; then
            print_warning "本地不存在基础分支 '${base_branch}'，但远程存在。尝试从远程获取..."
            if ! git fetch "$REMOTE_NAME" "$base_branch:refs/remotes/$REMOTE_NAME/$base_branch"; then
                 print_error "无法从远程 '${REMOTE_NAME}' 获取基础分支 '${base_branch}' 的引用。"
                 return 1
            fi
            # 创建本地跟踪分支，但不切换
             if ! git branch "$base_branch" "refs/remotes/$REMOTE_NAME/$base_branch"; then 
                 print_error "创建本地跟踪分支 '${base_branch}' 失败。"
                 return 1
             fi
            print_success "成功获取并创建本地基础分支 '${base_branch}'。"
            base_branch_exists_locally=true
        else
            print_error "错误：基础分支 '${base_branch}' 在本地和远程 '${REMOTE_NAME}' 都不存在。"
            return 1
        fi
    elif ! $base_branch_exists_locally && $local_flag; then
         print_error "错误：--local 模式要求基础分支 '${base_branch}' 必须在本地存在。"
         return 1
    fi

    # 更新基础分支（除非是local模式）
    if ! $local_flag && [ "$base_branch" = "$MAIN_BRANCH" ]; then
        print_step "1/3: 更新基础分支 '$base_branch'..."
        # 切换到main worktree并更新
        local current_dir=$(pwd)
        if [ -d "main" ]; then
            cd main
            if ! do_pull_with_retry --rebase "$REMOTE_NAME" "$base_branch"; then
                print_error "更新基础分支失败。"
                cd "$current_dir"
                return 1
            fi
            cd "$current_dir"
            print_success "基础分支已更新。"
        fi
    fi

    # 创建worktree
    print_step "2/3: 创建worktree '$worktree_dir'..."
    if ! git worktree add "$worktree_dir" -b "$new_branch_name" "$base_branch"; then
        print_error "创建worktree失败。"
        return 1
    fi

    # 同步共享资源
    print_step "3/3: 同步共享资源..."
    if [ "$AUTO_SYNC_SHARED" = "true" ] && [ -d "dev/shared" ]; then
        # 创建软链接到共享资源
        local shared_items=("node_modules" ".next" "dist" "build" ".cache")
        for item in "${shared_items[@]}"; do
            if [ -e "dev/shared/$item" ] && [ ! -e "$worktree_dir/$item" ]; then
                ln -sf "../../shared/$item" "$worktree_dir/$item"
                print_info "已链接共享资源: $item"
            fi
        done
    fi

    # 更新活跃worktree记录
    echo "$new_branch_name:$new_branch_name:$(date):active" >> .gw/active-worktrees

    print_success "🚀 Worktree创建完成"
    echo ""
    echo -e "${CYAN}📂 新的Worktree信息：${NC}"
    echo -e "  分支名称: ${BOLD}$new_branch_name${NC}"
    echo -e "  工作目录: ${BOLD}$worktree_dir/${NC}"
    if [ "$worktree_dir_name" != "$new_branch_name" ]; then
        echo -e "  ${GRAY}(注: 分支名包含'/', 目录名已转换为 '$worktree_dir_name')${NC}"
    fi
    echo -e "  基础分支: ${BOLD}$base_branch${NC}"
    echo ""
    echo -e "${CYAN}💡 接下来你可以：${NC}"
    echo -e "  ${YELLOW}cd $worktree_dir${NC}          # 进入工作目录"
    echo -e "  ${YELLOW}gw save \"first commit\"${NC}   # 保存变更"
    echo -e "  ${YELLOW}gw wt-update${NC}              # 同步主分支"
    echo -e "  ${YELLOW}gw wt-submit${NC}              # 提交工作"

    return 0
} 