#!/bin/bash
# 脚本/actions/worktree/cmd_wt_clean.sh
#
# 实现 'wt-clean' 命令逻辑。
# 依赖:
# - core_utils/colors.sh (颜色定义)
# - core_utils/utils_print.sh (打印函数)
# - core_utils/utils.sh (通用工具函数)
# - core_utils/config_vars.sh (配置变量)

# 清理指定的worktree
cmd_wt_clean() {
    if ! check_in_git_repo; then return 1; fi

    # 检查是否在worktree环境中
    local worktree_root
    worktree_root=$(find_worktree_root)
    if [ $? -ne 0 ]; then
        print_error "当前不在worktree环境中。请先运行 'gw wt-init' 初始化worktree环境。"
        return 1
    fi

    local target_branch="$1"
    local force_flag=false
    local keep_branch=false

    # 参数解析
    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force|-f)
                force_flag=true
                shift
                ;;
            --keep-branch|-k)
                keep_branch=true
                shift
                ;;
            *)
                print_warning "忽略未知参数: $1"
                shift
                ;;
        esac
    done
    
    if [ -z "$target_branch" ]; then
        print_error "错误：需要指定要清理的分支名称。"
        echo "用法: gw wt-clean <branch_name> [--force|-f] [--keep-branch|-k]"
        echo ""
        echo "可清理的worktree:"
        cmd_wt_list --simple
        return 1
    fi

    # 防止清理主分支
    if [ "$target_branch" = "$MAIN_BRANCH" ]; then
        print_error "错误：不能清理主分支 '$MAIN_BRANCH'。"
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
    done < <(cd "$worktree_root" && git worktree list 2>/dev/null)

    if ! $found; then
        print_error "错误：未找到分支 '$target_branch' 对应的worktree。"
        return 1
    fi

    # 检查当前是否在要清理的worktree中
    local current_dir=$(pwd)
    if [[ "$current_dir" == "$target_path"* ]]; then
        print_warning "您当前在要清理的worktree中，需要先切换到其他目录。"
        
        # 自动切换到worktree根目录
        print_step "自动切换到worktree根目录..."
        cd "$(git rev-parse --show-toplevel)" 2>/dev/null || {
            print_error "无法切换到worktree根目录，请手动切换到其他目录后重试。"
            return 1
        }
                 print_success "已切换到worktree根目录。"
    fi

    # 检查worktree状态
    local has_uncommitted=false
    local has_unpushed=false
    local remote_exists=false

    if [ -d "$target_path" ]; then
        local old_pwd=$(pwd)
        cd "$target_path" 2>/dev/null
        if [ $? -eq 0 ]; then
            # 检查未提交的变更
            if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null || [ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then
                has_uncommitted=true
            fi
            
            # 检查是否有远程分支
            if git rev-parse --verify "refs/remotes/$REMOTE_NAME/$target_branch" >/dev/null 2>&1; then
                remote_exists=true
                
                # 检查是否有未推送的提交
                local local_commits
                local_commits=$(git rev-list "refs/remotes/$REMOTE_NAME/$target_branch..HEAD" 2>/dev/null)
                if [ -n "$local_commits" ]; then
                    has_unpushed=true
                fi
            fi
            
            cd "$old_pwd"
        fi
    fi

    # 显示清理信息
    echo -e "${CYAN}🗑️  准备清理Worktree: $target_branch${NC}"
    echo ""
    echo -e "目标worktree: ${BOLD}$target_path${NC}"
    echo -e "远程分支: $([ $remote_exists = true ] && echo "${GREEN}存在${NC}" || echo "${GRAY}不存在${NC}")"
    echo -e "未提交变更: $([ $has_uncommitted = true ] && echo "${YELLOW}有${NC}" || echo "${GREEN}无${NC}")"
    echo -e "未推送提交: $([ $has_unpushed = true ] && echo "${YELLOW}有${NC}" || echo "${GREEN}无${NC}")"
    echo ""

    # 安全检查
    if ! $force_flag; then
        if $has_uncommitted; then
            print_error "检测到未提交的变更。"
            echo "请先提交或暂存变更，或使用 --force 强制清理。"
            return 1
        fi
        
        if $has_unpushed; then
            print_warning "检测到未推送的提交。"
            if ! confirm_action "这些提交将会丢失，是否继续清理？"; then
                echo "清理已取消。"
                return 1
            fi
        fi
    fi

    # 最终确认
    if ! $force_flag; then
        echo -e "${YELLOW}即将清理以下内容：${NC}"
        echo -e "  - Worktree目录: $target_path"
        if ! $keep_branch; then
            echo -e "  - 本地分支: $target_branch"
            if $remote_exists; then
                echo -e "  - 远程分支: $REMOTE_NAME/$target_branch (需要手动确认)"
            fi
        fi
        echo ""
        
        if ! confirm_action "确认要清理worktree '$target_branch' 吗？"; then
            echo "清理已取消。"
            return 1
        fi
    fi

    # 执行清理
    print_step "1/3: 移除worktree目录..."
    if ! git worktree remove "$target_path" --force 2>/dev/null; then
        # 如果git worktree remove失败，手动删除目录
        print_warning "git worktree remove失败，尝试手动删除目录..."
        if [ -d "$target_path" ]; then
            rm -rf "$target_path"
            if [ $? -eq 0 ]; then
                print_success "手动删除目录成功。"
            else
                print_error "删除目录失败。"
                return 1
            fi
        fi
    else
        print_success "worktree目录已移除。"
    fi

    # 删除本地分支（如果不保留）
    if ! $keep_branch; then
        print_step "2/3: 删除本地分支..."
        if git branch -D "$target_branch" 2>/dev/null; then
            print_success "本地分支 '$target_branch' 已删除。"
        else
            print_warning "删除本地分支失败，可能已经被删除。"
        fi
    else
        print_info "2/3: 保留本地分支 '$target_branch'。"
    fi

    # 处理远程分支
    if $remote_exists && ! $keep_branch; then
        print_step "3/3: 处理远程分支..."
        echo -e "${YELLOW}检测到远程分支 '$REMOTE_NAME/$target_branch'。${NC}"
        if confirm_action "是否要删除远程分支？"; then
            if git push "$REMOTE_NAME" --delete "$target_branch" 2>/dev/null; then
                print_success "远程分支 '$target_branch' 已删除。"
            else
                print_warning "删除远程分支失败，可能已经被删除或没有权限。"
            fi
        else
            print_info "远程分支已保留。"
        fi
    else
        print_info "3/3: 无需处理远程分支。"
    fi

    # 更新活跃worktree记录
    if [ -f ".gw/active-worktrees" ]; then
        grep -v "^$target_branch:" .gw/active-worktrees > .gw/active-worktrees.tmp 2>/dev/null || true
        mv .gw/active-worktrees.tmp .gw/active-worktrees 2>/dev/null || true
    fi

    print_success "✅ Worktree清理完成"
    echo ""
    echo -e "${CYAN}📊 清理总结：${NC}"
    echo -e "  - Worktree目录: ${GREEN}已删除${NC}"
    echo -e "  - 本地分支: $([ $keep_branch = true ] && echo "${YELLOW}已保留${NC}" || echo "${GREEN}已删除${NC}")"
    if $remote_exists; then
        echo -e "  - 远程分支: ${GRAY}需要手动确认${NC}"
    fi
    echo ""
    echo -e "${CYAN}💡 其他可用操作：${NC}"
    echo -e "  ${YELLOW}gw wt-list${NC}     # 查看剩余的worktree"
    echo -e "  ${YELLOW}gw wt-prune${NC}    # 清理所有无效worktree"

    return 0
} 