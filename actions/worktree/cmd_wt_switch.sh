#!/bin/bash
# 脚本/actions/worktree/cmd_wt_switch.sh
#
# 实现 'wt-switch' 命令逻辑。
# 依赖:
# - core_utils/colors.sh (颜色定义)
# - core_utils/utils_print.sh (打印函数)
# - core_utils/utils.sh (通用工具函数)
# - core_utils/config_vars.sh (配置变量)

# 切换到指定worktree
cmd_wt_switch() {
    if ! check_in_git_repo; then return 1; fi

    # 检查是否在worktree环境中
    if [ ! -f ".gw/worktree-config" ]; then
        print_error "当前不在worktree环境中。请先运行 'gw wt-init' 初始化worktree环境。"
        return 1
    fi

    local target_branch="$1"
    
    if [ -z "$target_branch" ]; then
        print_error "错误：需要指定要切换到的分支名称。"
        echo "用法: gw wt-switch <branch_name>"
        echo ""
        echo "可用的worktree:"
        cmd_wt_list --simple
        return 1
    fi

    # 查找对应的worktree路径
    local target_path=""
    local found=false

    while IFS= read -r line; do
        local wt_path=$(echo "$line" | awk '{print $1}')
        local wt_branch=$(echo "$line" | grep -o '\[[^]]*\]' | tr -d '[]')
        
        if [ "$wt_branch" = "$target_branch" ]; then
            target_path="$wt_path"
            found=true
            break
        fi
    done < <(git worktree list 2>/dev/null)

    if ! $found; then
        print_error "错误：未找到分支 '$target_branch' 对应的worktree。"
        echo ""
        echo "可用的worktree:"
        cmd_wt_list --simple
        return 1
    fi

    # 检查目标目录是否存在
    if [ ! -d "$target_path" ]; then
        print_error "错误：worktree目录 '$target_path' 不存在。"
        echo "可能需要运行 'gw wt-prune' 清理无效的worktree。"
        return 1
    fi

    # 检查当前是否已经在目标worktree中
    local current_dir=$(pwd)
    if [[ "$current_dir" == "$target_path"* ]]; then
        print_info "您已经在worktree '$target_branch' 中。"
        return 0
    fi

    # 切换到目标目录
    print_step "🔄 切换到Worktree: $target_path"
    
    # 标准化路径处理
    local abs_target_path
    if [[ "$target_path" == /* ]]; then
        abs_target_path="$target_path"
    else
        abs_target_path="$(pwd)/$target_path"
    fi

    # 验证目标路径
    if ! cd "$abs_target_path" 2>/dev/null; then
        print_error "无法切换到目录 '$abs_target_path'。"
        return 1
    fi

    # 获取worktree状态信息
    local branch_status=""
    local status_color="$GREEN"
    local uncommitted_count=0
    local untracked_count=0

    # 检查git状态
    if git rev-parse --git-dir >/dev/null 2>&1; then
        # 检查未提交的变更
        if ! git diff --quiet 2>/dev/null; then
            uncommitted_count=$((uncommitted_count + 1))
        fi
        if ! git diff --cached --quiet 2>/dev/null; then
            uncommitted_count=$((uncommitted_count + 1))
        fi
        
        # 检查未追踪的文件
        local untracked_files
        untracked_files=$(git ls-files --others --exclude-standard 2>/dev/null)
        if [ -n "$untracked_files" ]; then
            untracked_count=$(echo "$untracked_files" | wc -l)
        fi

        if [ $uncommitted_count -gt 0 ] || [ $untracked_count -gt 0 ]; then
            branch_status="有变更"
            status_color="$YELLOW"
        else
            branch_status="干净"
            status_color="$GREEN"
        fi
    fi

    print_success "✅ 已切换到Worktree"
    echo ""
    echo -e "${CYAN}📂 当前Worktree信息：${NC}"
    echo -e "  工作目录: ${BOLD}$abs_target_path${NC}"
    echo -e "  当前分支: ${CYAN}$target_branch${NC}"
    echo -e "  状态: ${status_color}$branch_status${NC}"
    
    if [ $uncommitted_count -gt 0 ]; then
        echo -e "  未提交变更: ${YELLOW}$uncommitted_count 个文件${NC}"
    fi
    
    if [ $untracked_count -gt 0 ]; then
        echo -e "  未追踪文件: ${YELLOW}$untracked_count 个文件${NC}"
    fi

    # 显示最近的活动
    if git rev-parse --git-dir >/dev/null 2>&1; then
        echo ""
        echo -e "${CYAN}📝 最近活动:${NC}"
        local recent_commits
        recent_commits=$(git log --oneline -3 --format="  📝 %cr: %s" 2>/dev/null)
        if [ -n "$recent_commits" ]; then
            echo "$recent_commits"
        else
            echo "  暂无提交记录"
        fi
    fi

    # 检查是否有其他用户在此分支上工作的迹象
    if git rev-parse --git-dir >/dev/null 2>&1; then
        local branch_author
        branch_author=$(git log -1 --format="%an" 2>/dev/null)
        local current_user
        current_user=$(git config user.name 2>/dev/null)
        
        if [ -n "$branch_author" ] && [ -n "$current_user" ] && [ "$branch_author" != "$current_user" ]; then
            echo ""
            echo -e "${YELLOW}⚠️  注意: 此分支最后由 '$branch_author' 提交，请小心不要冲突${NC}"
        fi
    fi

    echo ""
    echo -e "${CYAN}💡 在此Worktree中你可以：${NC}"
    echo -e "  ${YELLOW}gw save \"commit message\"${NC}   # 保存变更"
    echo -e "  ${YELLOW}gw wt-update${NC}                 # 同步主分支"
    echo -e "  ${YELLOW}gw wt-submit${NC}                 # 提交工作"
    echo -e "  ${YELLOW}gw wt-list${NC}                   # 查看所有worktree"

    return 0
} 