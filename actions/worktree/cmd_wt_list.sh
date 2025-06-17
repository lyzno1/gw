#!/bin/bash
# 脚本/actions/worktree/cmd_wt_list.sh
#
# 实现 'wt-list' 命令逻辑。
# 依赖:
# - core_utils/colors.sh (颜色定义)
# - core_utils/utils_print.sh (打印函数)
# - core_utils/utils.sh (通用工具函数)
# - core_utils/config_vars.sh (配置变量)

# 列出所有worktree
cmd_wt_list() {
    if ! check_in_git_repo; then return 1; fi

    # 检查是否在worktree环境中
    if [ ! -f ".gw/worktree-config" ]; then
        print_error "当前不在worktree环境中。请先运行 'gw wt-init' 初始化worktree环境。"
        return 1
    fi

    local show_detailed=false
    local show_stats=true

    # 参数解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --detailed|-d)
                show_detailed=true
                shift
                ;;
            --simple|-s)
                show_stats=false
                shift
                ;;
            *)
                print_warning "忽略未知参数: $1"
                shift
                ;;
        esac
    done

    echo -e "${BOLD}📋 当前Worktree状态:${NC}"
    echo ""

    # 获取当前工作目录，用于标识当前所在的worktree
    local current_dir=$(pwd)
    local worktree_root
    if [ -f ".gw/worktree-config" ]; then
        source .gw/worktree-config
    fi
    worktree_root=${WORKTREE_ROOT:-$(git rev-parse --show-toplevel)}

    # 获取所有worktree信息
    local worktree_count=0
    local active_count=0
    local total_size=0

    # 使用git worktree list获取准确信息
    while IFS= read -r line; do
        local wt_path=$(echo "$line" | awk '{print $1}')
        local wt_commit=$(echo "$line" | awk '{print $2}' | tr -d '[]')
        local wt_branch=$(echo "$line" | awk '{$1=$2=""; print $0}' | sed 's/^\s*\[//' | sed 's/\]\s*$//' | xargs)

        # 标准化路径
        if [[ "$wt_path" == /* ]]; then
            # 绝对路径
            local display_path="$wt_path"
        else
            # 相对路径
            local display_path="$wt_path"
        fi

        # 判断是否是当前目录
        local is_current=false
        if [[ "$current_dir" == "$wt_path"* ]]; then
            is_current=true
        fi

        # 获取worktree状态信息
        local status_info=""
        local status_color="$NC"
        local activity_info=""

        if [ -d "$wt_path" ]; then
            worktree_count=$((worktree_count + 1))
            
            # 检查是否有未提交的变更
            local has_changes=false
            if [ -d "$wt_path/.git" ] || [ -f "$wt_path/.git" ]; then
                # 进入worktree目录检查状态
                local old_pwd=$(pwd)
                cd "$wt_path" 2>/dev/null
                if [ $? -eq 0 ]; then
                    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null || [ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then
                        has_changes=true
                    fi
                    
                    # 获取最后提交时间
                    local last_commit_time
                    last_commit_time=$(git log -1 --format="%cr" 2>/dev/null || echo "未知")
                    activity_info="最后提交: $last_commit_time"
                    
                    cd "$old_pwd"
                fi
            fi

            if $has_changes; then
                status_info="有变更"
                status_color="$YELLOW"
            else
                status_info="干净"
                status_color="$GREEN"
                active_count=$((active_count + 1))
            fi

            # 计算目录大小（如果需要详细信息）
            if $show_detailed; then
                local dir_size
                if command -v du >/dev/null 2>&1; then
                    dir_size=$(du -sh "$wt_path" 2>/dev/null | awk '{print $1}' || echo "未知")
                else
                    dir_size="未知"
                fi
            fi
        else
            status_info="目录不存在"
            status_color="$RED"
        fi

        # 判断worktree类型和显示图标
        local wt_icon="🚧"
        local wt_type=""
        if [[ "$wt_branch" == "$MAIN_BRANCH" ]]; then
            wt_icon="🏠"
            wt_type="主分支"
        elif [[ "$display_path" == *"/dev/"* ]]; then
            wt_icon="🚧"
            wt_type="开发分支"
        fi

        # 显示当前worktree标识
        local current_marker=""
        if $is_current; then
            current_marker=" ${BOLD}${GREEN}← 当前${NC}"
        fi

        # 基本信息显示
        echo -e "${wt_icon} ${BOLD}${display_path}${NC}${current_marker}"
        echo -e "   分支: ${CYAN}${wt_branch}${NC} | 状态: ${status_color}${status_info}${NC}"
        
        if [ -n "$activity_info" ]; then
            echo -e "   ${GRAY}${activity_info}${NC}"
        fi

        if $show_detailed && [ -n "$dir_size" ]; then
            echo -e "   ${GRAY}大小: ${dir_size}${NC}"
        fi

        echo ""

    done < <(git worktree list 2>/dev/null)

    # 显示统计信息
    if $show_stats; then
        echo -e "${CYAN}📊 统计信息:${NC}"
        echo -e "  总Worktree数: ${BOLD}${worktree_count}${NC}"
        echo -e "  干净状态: ${BOLD}${active_count}${NC}"
        echo -e "  需要处理: ${BOLD}$((worktree_count - active_count))${NC}"
        
        if $show_detailed && command -v du >/dev/null 2>&1; then
            local total_size_info
            total_size_info=$(du -sh . 2>/dev/null | awk '{print $1}' || echo "未知")
            echo -e "  总占用空间: ${BOLD}${total_size_info}${NC}"
        fi
        echo ""
    fi

    # 显示建议操作
    if [ $worktree_count -gt 1 ]; then
        echo -e "${CYAN}💡 快速操作:${NC}"
        
        # 检查是否有可清理的worktree
        local cleanup_suggestions=()
        while IFS= read -r line; do
            local wt_path=$(echo "$line" | awk '{print $1}')
            local wt_branch=$(echo "$line" | awk '{$1=$2=""; print $0}' | sed 's/^\s*\[//' | sed 's/\]\s*$//' | xargs)
            
            if [[ "$wt_branch" != "$MAIN_BRANCH" ]] && [ -d "$wt_path" ]; then
                # 检查分支是否已合并到主分支
                local old_pwd=$(pwd)
                cd "$wt_path" 2>/dev/null
                if [ $? -eq 0 ]; then
                    # 检查是否已推送且可能已合并
                    if git rev-parse --verify "refs/remotes/$REMOTE_NAME/$wt_branch" >/dev/null 2>&1; then
                        # 检查最后活动时间（简单检查：超过3天没有新提交）
                        local last_commit_days
                        last_commit_days=$(git log -1 --format="%ct" 2>/dev/null)
                        if [ -n "$last_commit_days" ]; then
                            local current_time=$(date +%s)
                            local days_diff=$(( (current_time - last_commit_days) / 86400 ))
                            if [ $days_diff -gt 3 ]; then
                                cleanup_suggestions+=("$wt_branch")
                            fi
                        fi
                    fi
                    cd "$old_pwd"
                fi
            fi
        done < <(git worktree list 2>/dev/null)

        # 显示切换建议
        local other_worktrees=()
        while IFS= read -r line; do
            local wt_path=$(echo "$line" | awk '{print $1}')
            local wt_branch=$(echo "$line" | awk '{$1=$2=""; print $0}' | sed 's/^\s*\[//' | sed 's/\]\s*$//' | xargs)
            
            if [[ "$current_dir" != "$wt_path"* ]] && [ -d "$wt_path" ]; then
                other_worktrees+=("$wt_branch")
            fi
        done < <(git worktree list 2>/dev/null)

        if [ ${#other_worktrees[@]} -gt 0 ]; then
            echo -e "  ${YELLOW}gw wt-switch ${other_worktrees[0]}${NC}    # 切换到其他worktree"
        fi
        
        if [ ${#cleanup_suggestions[@]} -gt 0 ]; then
            echo -e "  ${YELLOW}gw wt-clean ${cleanup_suggestions[0]}${NC}     # 清理旧的worktree"
        fi
        
        echo -e "  ${YELLOW}gw wt-prune${NC}                    # 清理所有无效worktree"
    fi

    return 0
} 