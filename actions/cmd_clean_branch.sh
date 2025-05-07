#!/bin/bash
# 脚本/actions/cmd_clean_branch.sh
#
# 实现 'clean_branch' (或 'clean') 命令逻辑。
# 依赖:
# - colors.sh (颜色定义)
# - utils_print.sh (打印函数)
# - utils.sh (通用工具函数)
# - config_vars.sh (配置变量)
# - git_network_ops.sh (do_pull_with_retry)
# - cmd_rm_branch.sh (依赖 cmd_rm_branch 函数)

# 清理已合并的分支 (切换到主分支, 拉取, 删除本地和远程)
cmd_clean_branch() {
    if ! check_in_git_repo; then return 1; fi

    local target_branch="$1"
    # local force=false # clean 命令不直接接受 -f，它依赖 cmd_rm_branch 的 -f 逻辑（如果需要）

    if [ -z "$target_branch" ]; then
        print_error "请指定要清理的分支名称。"
        echo "用法: gw clean <已合并的分支名>"
        return 1
    fi
    
    if [ "$target_branch" = "$MAIN_BRANCH" ]; then
         print_error "不能清理主分支 ($MAIN_BRANCH)。"
         return 1
    fi
    
    # 检查是否有多余参数 (暂不支持其他参数)
    if [ $# -gt 1 ]; then # 只接受一个分支名参数
         print_warning "'clean' 命令当前只接受要清理的分支名作为唯一参数，已忽略其他参数: ${@:2}"
    fi

    echo -e "${CYAN}=== 清理分支 '$target_branch' ===${NC}"

    local current_branch
    current_branch=$(get_current_branch_name)
    if [ $? -ne 0 ]; then return 1; fi
    local stash_needed=false

    # 1. 如果当前不在主分支，先切换到主分支
    if [ "$current_branch" != "$MAIN_BRANCH" ]; then
        echo -e "${BLUE}当前不在主分支，准备切换到 '$MAIN_BRANCH'...${NC}"
        if check_uncommitted_changes || check_untracked_files; then
            echo -e "${YELLOW}检测到未提交的变更。在切换前需要处理:${NC}"
            echo "1) 暂存变更"
            echo "2) 取消清理"
            echo -n "请选择 [1-2]: "
            read -r choice
            if [ "$choice" = "1" ]; then
                 echo -e "${BLUE}正在暂存...${NC}"
                 if ! cmd_stash push -m "Auto-stash before cleaning branch $target_branch"; then
                     print_error "暂存失败，清理操作取消。"
                     return 1
                 fi
                 stash_needed=true
            else
                 echo "清理操作已取消。"
                 return 1
            fi
        fi
        if ! git checkout "$MAIN_BRANCH"; then
             print_error "切换到主分支失败。请检查工作区状态。"
             if $stash_needed; then echo -e "${YELLOW}正在尝试恢复之前暂存的变更...${NC}"; cmd_stash pop; fi
             return 1
        fi
        echo -e "${GREEN}已切换到主分支 '$MAIN_BRANCH'。${NC}"
    fi

    # 2. 拉取主分支最新代码
    echo -e "${BLUE}正在从远程 '$REMOTE_NAME' 更新主分支 '$MAIN_BRANCH'...${NC}"
    if ! do_pull_with_retry "$REMOTE_NAME" "$MAIN_BRANCH"; then # 使用 do_pull_with_retry
        print_error "拉取主分支更新失败。"
        if $stash_needed; then echo -e "${YELLOW}正在尝试恢复之前暂存的变更...${NC}"; cmd_stash pop; fi
        return 1
    fi
    echo -e "${GREEN}主分支已是最新。${NC}"

    # 3. 删除目标分支 (使用 cmd_rm_branch)
    # 需要确保 cmd_rm_branch 可用
    if ! command -v cmd_rm_branch >/dev/null 2>&1;
        then print_error "命令 'cmd_rm_branch' 未找到或未导入。清理操作中止。"; return 1;
    fi
    
    echo -e "${BLUE}准备删除分支 '$target_branch' (将调用 'gw rm $target_branch')...${NC}"
    # cmd_rm_branch 会处理合并检查和是否删除远程的交互
    # clean 命令不强制删除，如果 cmd_rm_branch 需要强制，用户会被询问或需要用 gw rm -f
    if cmd_rm_branch "$target_branch"; then # 不传递 force，让 cmd_rm_branch 自己判断
        echo -e "${GREEN}分支 '$target_branch' 清理完成 (通过调用 'gw rm')。${NC}"
    else
        print_error "分支 '$target_branch' 清理过程中删除步骤失败 (调用 'gw rm' 失败)。请检查上面的错误信息。"
        if $stash_needed; then echo -e "${YELLOW}正在尝试恢复之前暂存的变更...${NC}"; cmd_stash pop; fi
        return 1
    fi
    
    # 4. 如果之前暂存了，尝试恢复
    if $stash_needed; then
        echo -e "${BLUE}正在尝试恢复之前暂存的变更...${NC}"
        if cmd_stash pop; then
            print_success "成功恢复暂存的变更。"
        else
            print_warning "自动恢复暂存失败。可能存在冲突。请手动处理 (cmd_stash list)。"
        fi
    fi

    return 0
} 