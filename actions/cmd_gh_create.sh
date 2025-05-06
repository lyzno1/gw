#!/bin/bash
# 脚本/actions/cmd_gh_create.sh
#
# 实现 'gh-create' (在 GitHub 上创建新仓库并关联) 命令逻辑。
# 依赖:
# - colors.sh (颜色定义)
# - utils_print.sh (打印函数)
# - utils.sh (check_in_git_repo, confirm_action, get_current_branch_name)
# - config_vars.sh (REMOTE_NAME)
# - cmd_push.sh (间接依赖，如果需要推送)

cmd_gh_create() {
    if ! check_in_git_repo; then
        print_error "此命令需要在 Git 本地仓库中运行，以关联新建的远程仓库。"
        print_info "请先使用 'gw init' 初始化本地仓库。"
        return 1
    fi

    # 1. 检查 gh CLI 是否安装和认证
    if ! command -v gh >/dev/null 2>&1; then
        print_error "GitHub CLI (gh) 未安装。请先安装 gh: https://cli.github.com/"
        return 1
    fi
    if ! gh auth status >/dev/null 2>&1; then
        print_error "GitHub CLI (gh) 未认证。请运行 'gh auth login' 进行认证。"
        return 1
    fi
    print_success "GitHub CLI (gh) 已安装并认证。"

    # 2. 解析参数
    local repo_name=""
    local visibility="--private" # 默认私有
    local description=""
    local no_push_flag=false
    local remote_name_to_add="$REMOTE_NAME" # 默认远程名为 origin
    local current_dir_name=$(basename "$PWD")

    # 使用 getopt 进行更健壮的参数解析
    local parsed_args
    parsed_args=$(getopt -o d:r: --long public,private,description:,remote-name:,no-push -n 'gw gh-create' -- "$@")
    if [ $? != 0 ]; then
        echo "用法: gw gh-create [仓库名] [--public|--private] [--description \"描述\"] [--remote-name <name>] [--no-push]"
        return 1
    fi
    eval set -- "$parsed_args"

    while true; do
        case "$1" in
            --public)
                visibility="--public"
                shift
                ;;
            --private)
                visibility="--private"
                shift
                ;;
            -d|--description)
                description="$2"
                shift 2
                ;;
            -r|--remote-name)
                remote_name_to_add="$2"
                shift 2
                ;;
            --no-push)
                no_push_flag=true
                shift
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

    # 第一个非选项参数是 repo_name
    if [ -n "$1" ]; then
        repo_name="$1"
        shift
    else
        repo_name="$current_dir_name"
        print_info "未提供仓库名，将使用当前目录名: $repo_name"
    fi

    if [ $# -gt 0 ]; then
        print_warning "忽略了 'gh-create' 命令无法识别的额外参数: $@"
    fi

    # 3. 确认操作
    echo -e "${CYAN}--- GitHub 仓库创建计划 ---${NC}"
    echo -e "仓库名 (在 GitHub 上): ${BOLD}$repo_name${NC}"
    echo -e "可见性: ${BOLD}${visibility#--}${NC}"
    if [ -n "$description" ]; then
        echo -e "描述: ${BOLD}$description${NC}"
    fi
    echo -e "本地远程名称: ${BOLD}$remote_name_to_add${NC}"
    if $no_push_flag; then
        echo -e "初始推送: ${BOLD}否${NC}"
    else
        echo -e "初始推送: ${BOLD}是 (当前分支到 $remote_name_to_add/${current_branch}) ${NC}"
    fi
    echo "---------------------------------"
    if ! confirm_action "是否继续创建并关联 GitHub 仓库？"; then
        echo "操作已取消。"
        return 1
    fi

    # 4. 创建 GitHub 仓库
    local gh_repo_create_cmd="gh repo create $repo_name $visibility"
    if [ -n "$description" ]; then
        gh_repo_create_cmd+=", --description='$description'"
    fi
    
    print_step "正在通过 GitHub CLI 创建仓库: $gh_repo_create_cmd"
    # 捕获 gh repo create 的输出，它通常包含仓库 URL
    local gh_output
    if ! gh_output=$(eval "$gh_repo_create_cmd" 2>&1); then # 使用eval来正确处理带引号的描述
        print_error "GitHub 仓库创建失败。"
        echo -e "${RED}GitHub CLI 输出:${NC}
$gh_output"
        return 1
    fi
    print_success "GitHub 仓库 '$repo_name' 创建成功。"
    echo -e "${BLUE}GitHub CLI 输出:${NC}
$gh_output"

    # 从 gh repo view 获取 SSH URL (优先) 或 HTTPS URL
    local repo_full_name # 通常是 user/repo_name or org/repo_name
    repo_full_name=$(echo "$gh_output" | grep -oE 'https://github.com/([a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+)' | sed 's|https://github.com/||')
    if [ -z "$repo_full_name" ]; then # 如果从创建输出中没拿到，尝试用 view
        print_info "尝试从 gh repo view 获取仓库信息..."
        repo_full_name="$repo_name" # 如果创建时没指定owner, gh 会用当前用户
         # 如果 repo_name 本身不含 owner, gh repo view 需要 owner/repo
         # 我们先假设 gh repo create 返回的 URL 或名称可以直接用于 gh repo view
    fi
    
    local remote_url=""
    print_info "正在获取远程仓库 '$repo_full_name' 的 SSH URL..."
    remote_url=$(gh repo view "$repo_full_name" --json sshUrl -q '.sshUrl' 2>/dev/null)
    if [ -z "$remote_url" ]; then
        print_warning "未能获取 SSH URL，尝试获取 HTTPS URL..."
        remote_url=$(gh repo view "$repo_full_name" --json url -q '.url' 2>/dev/null)
    fi

    if [ -z "$remote_url" ]; then
        print_error "无法获取新创建仓库的 URL。请手动添加远程。"
        echo "您可以尝试：git remote add $remote_name_to_add <仓库的SSH或HTTPS_URL>"
        return 1
    fi
    print_success "获取到远程 URL: $remote_url"

    # 5. 添加为本地远程仓库
    # 检查是否已存在同名远程
    if git remote get-url "$remote_name_to_add" > /dev/null 2>&1; then
        print_warning "远程 '$remote_name_to_add' 已经存在。"
        if confirm_action "是否要覆盖远程 '$remote_name_to_add' 的 URL 为 '$remote_url'？"; then
            if ! git remote set-url "$remote_name_to_add" "$remote_url"; then
                print_error "设置远程 '$remote_name_to_add' URL 失败。"
                return 1
            fi
            print_success "远程 '$remote_name_to_add' URL 已更新。"
        else
            print_info "未修改现有远程 '$remote_name_to_add'。"
        fi
    else
        print_step "正在添加远程 '$remote_name_to_add' -> $remote_url ..."
        if ! git remote add "$remote_name_to_add" "$remote_url"; then
            print_error "添加远程 '$remote_name_to_add' 失败。"
            return 1
        fi
        print_success "远程 '$remote_name_to_add' 添加成功。"
    fi

    # 6. 初始推送 (如果需要)
    if ! $no_push_flag; then
        local current_branch_for_push
        current_branch_for_push=$(get_current_branch_name)
        if [ $? -ne 0 ]; then
            print_error "无法确定当前分支，跳过初始推送。"
            return 1 # 或者0，因为远程已创建
        fi
        
        print_step "准备执行初始推送: gw push -u $remote_name_to_add $current_branch_for_push"
        # 确保 cmd_push 可用
        if ! command -v cmd_push >/dev/null 2>&1; then
            print_error "命令 'cmd_push' 未找到或未导入。无法执行初始推送。"
            echo "请稍后手动运行: gw push -u $remote_name_to_add $current_branch_for_push"
            return 1
        fi

        if cmd_push -u "$remote_name_to_add" "$current_branch_for_push"; then
            print_success "初始推送成功。"
        else
            print_error "初始推送失败。请检查错误信息或稍后手动推送。"
            echo "您可以尝试：gw push -u $remote_name_to_add $current_branch_for_push"
            return 1
        fi
    else
        print_info "已跳过初始推送 (--no-push)。"
        echo "您可能需要稍后运行: gw push -u $remote_name_to_add <分支名>"
    fi

    print_success "GitHub 远程仓库创建和关联流程完成！"
    return 0
} 