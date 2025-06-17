#!/bin/bash
# 脚本/actions/worktree/cmd_wt_prune.sh
#
# 实现 'wt-prune' 命令逻辑。
# 依赖:
# - core_utils/colors.sh (颜色定义)
# - core_utils/utils_print.sh (打印函数)
# - core_utils/utils.sh (通用工具函数)
# - core_utils/config_vars.sh (配置变量)

# 清理所有无效的worktree
cmd_wt_prune() {
    if ! check_in_git_repo; then return 1; fi

    # 检查是否在worktree环境中
    if [ ! -f ".gw/worktree-config" ]; then
        print_error "当前不在worktree环境中。请先运行 'gw wt-init' 初始化worktree环境。"
        return 1
    fi

    local force_flag=false
    local dry_run=false

    # 参数解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force|-f)
                force_flag=true
                shift
                ;;
            --dry-run|-n)
                dry_run=true
                shift
                ;;
            *)
                print_warning "忽略未知参数: $1"
                shift
                ;;
        esac
    done

    echo -e "${CYAN}🧹 清理无效Worktree${NC}"
    echo ""

    if $dry_run; then
        print_info "预览模式 - 不会执行实际删除操作"
        echo ""
    fi

    # 执行git worktree prune的预检查
    print_step "1/3: 检查Git内部的无效worktree引用..."
    local git_prune_output
    git_prune_output=$(git worktree prune --dry-run 2>&1)
    
    if [ -n "$git_prune_output" ]; then
        echo -e "${YELLOW}发现需要清理的Git内部引用：${NC}"
        echo "$git_prune_output"
        echo ""
        
        if ! $dry_run; then
            if $force_flag || confirm_action "是否清理这些Git内部引用？"; then
                if git worktree prune; then
                    print_success "Git内部引用已清理。"
                else
                    print_error "清理Git内部引用失败。"
                    return 1
                fi
            else
                print_info "跳过Git内部引用清理。"
            fi
        fi
    else
        print_success "Git内部引用正常，无需清理。"
    fi

    # 检查目录结构中的孤立worktree目录
    print_step "2/3: 检查孤立的worktree目录..."
    local orphaned_dirs=()
    local active_worktrees=()

    # 获取当前所有活跃的worktree路径
    while IFS= read -r line; do
        local wt_path=$(echo "$line" | awk '{print $1}')
        # 标准化路径
        if [[ "$wt_path" == /* ]]; then
            active_worktrees+=("$wt_path")
        else
            active_worktrees+=("$(pwd)/$wt_path")
        fi
    done < <(git worktree list 2>/dev/null)

    # 检查dev目录下的所有子目录
    if [ -d "dev" ]; then
        for dir in dev/*/; do
            if [ -d "$dir" ]; then
                local abs_dir=$(realpath "$dir" 2>/dev/null || echo "$(pwd)/$dir")
                local is_active=false
                
                for active_dir in "${active_worktrees[@]}"; do
                    if [ "$abs_dir" = "$active_dir" ]; then
                        is_active=true
                        break
                    fi
                done
                
                if ! $is_active; then
                    orphaned_dirs+=("$dir")
                fi
            fi
        done
    fi

    if [ ${#orphaned_dirs[@]} -gt 0 ]; then
        echo -e "${YELLOW}发现孤立的worktree目录：${NC}"
        for dir in "${orphaned_dirs[@]}"; do
            echo -e "  📁 $dir"
            # 显示目录大小
            if command -v du >/dev/null 2>&1; then
                local dir_size
                dir_size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}' || echo "未知")
                echo -e "     ${GRAY}大小: $dir_size${NC}"
            fi
        done
        echo ""
        
        if ! $dry_run; then
            if $force_flag || confirm_action "是否删除这些孤立目录？"; then
                for dir in "${orphaned_dirs[@]}"; do
                    print_step "删除目录: $dir"
                    if rm -rf "$dir"; then
                        print_success "已删除: $dir"
                    else
                        print_error "删除失败: $dir"
                    fi
                done
            else
                print_info "跳过孤立目录清理。"
            fi
        fi
    else
        print_success "未发现孤立的worktree目录。"
    fi

    # 清理活跃worktree记录文件
    print_step "3/3: 清理worktree记录文件..."
    if [ -f ".gw/active-worktrees" ]; then
        local cleaned_records=()
        local total_records=0
        
        while IFS=: read -r branch_name branch_ref timestamp status; do
            total_records=$((total_records + 1))
            local branch_exists=false
            
            # 检查分支是否仍然存在于worktree列表中
            while IFS= read -r line; do
                local wt_branch=$(echo "$line" | awk '{$1=$2=""; print $0}' | sed 's/^\s*\[//' | sed 's/\]\s*$//' | xargs)
                if [ "$wt_branch" = "$branch_name" ]; then
                    branch_exists=true
                    break
                fi
            done < <(git worktree list 2>/dev/null)
            
            if $branch_exists; then
                cleaned_records+=("$branch_name:$branch_ref:$timestamp:$status")
            fi
        done < .gw/active-worktrees
        
        local removed_count=$((total_records - ${#cleaned_records[@]}))
        
        if [ $removed_count -gt 0 ]; then
            echo -e "${YELLOW}发现 $removed_count 个过时的记录${NC}"
            
            if ! $dry_run; then
                # 更新记录文件
                printf "%s\n" "${cleaned_records[@]}" > .gw/active-worktrees
                print_success "记录文件已清理，移除了 $removed_count 个过时记录。"
            fi
        else
            print_success "记录文件正常，无需清理。"
        fi
    else
        print_info "记录文件不存在，创建新的记录文件。"
        if ! $dry_run; then
            touch .gw/active-worktrees
        fi
    fi

    # 显示清理总结
    echo ""
    if $dry_run; then
        print_info "=== 清理预览完成 ==="
        echo -e "${CYAN}💡 要执行实际清理，请运行：${NC}"
        echo -e "  ${YELLOW}gw wt-prune${NC}           # 交互式清理"
        echo -e "  ${YELLOW}gw wt-prune --force${NC}   # 强制清理"
    else
        print_success "=== Worktree清理完成 ==="
        echo ""
        echo -e "${CYAN}📊 清理后状态：${NC}"
        cmd_wt_list --simple
    fi

    return 0
} 