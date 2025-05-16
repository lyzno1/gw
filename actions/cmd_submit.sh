#!/bin/bash
# 脚本/actions/cmd_submit.sh # Renamed from cmd_finish.sh
#
# 实现 'submit' 命令逻辑。 # Renamed from 'finish'
# 依赖:
# - colors.sh (颜色定义)
# - utils_print.sh (打印函数)
# - utils.sh (通用工具函数)
# - config_vars.sh (配置变量)
# - git_network_ops.sh (do_push_with_retry, do_pull_with_retry)
# - cmd_commit.sh (依赖 cmd_commit 函数，确保其已被 sourcing)

# 完成当前分支工作 (准备 PR/MR)
cmd_submit() { # Renamed from cmd_finish
    if ! check_in_git_repo; then return 1; fi

    local no_switch=false
    local do_pr=false
    local auto_merge=false
    local delete_branch_after_merge=false
    local merge_args=() # 存储传递给 gh pr merge 的参数

    # 手动参数解析，兼容 macOS/Linux
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--no-switch)
                no_switch=true
                shift
                ;;
            -p|--pr)
                do_pr=true
                shift
                ;;
           -a|--auto-merge) # 添加 -a 别名
               auto_merge=true
               do_pr=true # 自动合并隐含了需要先创建 PR
               shift
               ;;
           --delete-branch-after-merge)
               delete_branch_after_merge=true
               # 这个参数只在 --auto-merge 时有意义，但解析时先记录
               shift
               ;;
            *)
                # 其他参数可忽略或警告
                print_warning "'submit' 命令忽略了额外的参数: $1" # Renamed from 'finish'
                shift
                ;;
        esac
    done

    local current_branch
    current_branch=$(get_current_branch_name)
    if [ $? -ne 0 ]; then return 1; fi

    if [ "$current_branch" = "$MAIN_BRANCH" ]; then
        print_warning "您当前在主分支 ($MAIN_BRANCH)。'submit' 命令通常用于功能分支。" # Renamed from 'finish'
        if ! confirm_action "是否仍要继续执行推送主分支的操作？"; then
            echo "操作已取消。"
            return 1
        fi
    fi

    echo -e "${CYAN}=== 完成分支 '$current_branch' 工作流 ===${NC}"

    # 1. 检查未提交/未暂存的变更
    if check_uncommitted_changes || check_untracked_files; then
        echo -e "${YELLOW}检测到未提交的变更或未追踪的文件。${NC}"
        echo "变更详情:"
        git status -s
        echo ""
        echo "在完成前，您需要处理这些变更:"
        echo "1) 处理并提交变更"
        echo "2) 暂存变更 (stash) (不推荐，推送后 PR 中不包含)"
        echo "3) 取消完成操作"
        echo -n "请选择操作 [1-3]: "
        read -r choice

        case "$choice" in
            1)
                print_step "准备处理并提交变更..."
                # 调用 cmd_save，它会处理暂存和提交，并允许编辑提交信息
                # cmd_save 会自行处理 git add，所以这里的 git add -A 步骤可以省略
                # 它也会自行检查暂存区是否为空
                if ! command -v cmd_save >/dev/null 2>&1;
                    then print_error "命令 'cmd_save' 未找到或未导入。"; return 1;
                fi

                if ! cmd_save; then # 调用 cmd_save (它应该处理交互式提交信息)
                    print_error "保存 (暂存和提交) 失败或被取消。请手动处理后重试。"
                    return 1
                fi
                # cmd_save 成功后，变更已提交，这里不需要再额外处理
                echo -e "${GREEN}变更已成功保存 (暂存并提交)。${NC}"
                ;;
            2)
                echo -e "${BLUE}正在暂存变更...${NC}"
                if cmd_stash push -m "在完成分支 $current_branch 前自动暂存"; then
                    print_warning "变更已暂存，不会包含在本次推送和 PR 中。"
                else
                    print_error "暂存失败，操作已取消。"
                    return 1
                fi
                ;;
            3|*)
                echo "完成操作已取消。"
                return 1
                ;;
        esac
    else
        echo -e "${GREEN}未检测到需要提交或暂存的变更。${NC}"
    fi

    # --- 开始推送前的远程检查 --- 
    local remote_to_push_to="$REMOTE_NAME" # finish 命令通常推送到默认远程
    if ! git remote get-url "$remote_to_push_to" > /dev/null 2>&1; then
        print_warning "默认远程仓库 '$remote_to_push_to' 似乎未配置或没有有效的URL。"
        if confirm_action "是否希望现在添加远程仓库 '$remote_to_push_to'？"; then
            local new_remote_url=""
            echo -n -e "${CYAN}请输入远程仓库 '$remote_to_push_to' 的 URL: ${NC}"
            read -r new_remote_url
            
            if [ -z "$new_remote_url" ]; then
                print_error "未提供 URL，无法添加远程仓库。Submit 操作已取消。"
                return 1
            fi
            
            print_step "正在添加远程仓库: git remote add $remote_to_push_to $new_remote_url"
            if git remote add "$remote_to_push_to" "$new_remote_url"; then
                print_success "远程仓库 '$remote_to_push_to' 添加成功。"
            else
                print_error "添加远程仓库 '$remote_to_push_to' 失败。请检查错误信息或手动添加。Submit 操作已取消。"
                return 1
            fi
        else
            echo "操作已取消。请先配置远程仓库。"
            return 1
        fi
    fi
    # --- 远程检查结束 --- 

    # 2. 推送当前分支 (使用 do_push_with_retry)
    echo -e "${BLUE}准备推送当前分支 '$current_branch' 到远程 '$remote_to_push_to'...${NC}"
    # 确保核心推送函数可用
    if ! command -v do_push_with_retry >/dev/null 2>&1; then
        print_error "核心函数 'do_push_with_retry' 未找到。请检查脚本完整性。"
        return 127
    fi
    # cmd_submit 通常不接受 push 的额外参数，所以直接调用不带参数的 do_push_with_retry
    # 它会自动推送当前分支到默认远程并设置上游（如果需要）
    if ! do_push_with_retry; then 
        print_error "推送分支失败。请检查错误信息。"
        return 1
    fi
    echo -e "${GREEN}分支 '$current_branch' 已成功推送到远程。${NC}"

    # 3. 创建 Pull Request (如果指定了 --pr)
    if $do_pr; then
        if ! command -v gh >/dev/null 2>&1; then
            print_error "未检测到 GitHub CLI (gh)。请安装并配置 'gh' 后再使用 --pr 功能。"
            echo -e "${CYAN}您仍然需要手动前往 GitHub 创建 Pull Request。${NC}"
        else
            echo -e "${BLUE}正在通过 GitHub CLI 创建 Pull Request...${NC}"
            # 尝试自动填充标题和正文。
            # 注意：为了捕获 URL，我们不使用 --web 参数
            print_step "尝试使用 'gh pr create --fill' 创建 PR..."
            local pr_url

            # 使用 process substitution 来捕获输出并检查退出状态

            if pr_url=$(gh pr create --base "$MAIN_BRANCH" --head "$current_branch" --fill); then
                echo -e "${GREEN}Pull Request 创建成功: ${YELLOW}$pr_url${NC}"

                # 如果指定了自动合并
                if $auto_merge; then

                    echo -e "${BLUE}检测到 -a|--auto-merge，尝试立即使用 rebase 策略合并 PR...${NC}"
                    # 强制使用 rebase 策略
                    merge_args=("--rebase")

                    if $delete_branch_after_merge; then
                        echo -e "${BLUE}合并后将删除源分支 (--delete-branch)。${NC}"
                        merge_args+=("--delete-branch")
                    fi

                    print_step "执行: gh pr merge $pr_url ${merge_args[*]}"
                    if gh pr merge "$pr_url" "${merge_args[@]}"; then

                        echo -e "${GREEN}Pull Request 已成功使用 rebase 策略自动合并！${NC}"
                    else
                        print_error "自动合并 Pull Request (使用 rebase) 失败。"
                        echo -e "${CYAN}请检查错误信息、PR 状态（如检查是否通过、是否有冲突、是否允许 rebase 合并）以及您的合并权限。${NC}"
                        # 即使合并失败，PR 也已创建

                    fi
                else
                     # 如果没有指定 --auto-merge，提示用户可以在浏览器中查看
                     echo -e "${CYAN}您现在可以在浏览器中查看或手动合并此 PR: ${YELLOW}$pr_url${NC}"
                     # 尝试在浏览器中打开 (如果用户希望)
                     if confirm_action "是否在浏览器中打开此 PR？"; then
                         gh pr view "$pr_url" --web
                     fi
                fi
            else
                print_error "Pull Request 创建失败。请手动检查或尝试在浏览器中创建。"
                echo -e "${CYAN}您可能需要运行 'gh auth login' 或检查 'gh' 的配置。${NC}"
                # 如果 PR 创建失败，则无法进行后续步骤，但 submit 流程本身（切换分支等）可能仍需继续
            fi
        fi
    else
        echo -e "${CYAN}现在您可以前往 GitHub/GitLab 等平台基于 '$current_branch' 创建 Pull Request / Merge Request。${NC}"
        echo -e "${PURPLE}(提示: 下次可以使用 'gw submit --pr' 来尝试自动创建 GitHub PR，或使用 'gw submit -a' 尝试创建并 rebase 合并)${NC}"
        
    fi

    # 4. 询问是否切回主分支 (除非指定了 --no-switch)
    if ! $no_switch && [ "$current_branch" != "$MAIN_BRANCH" ]; then
        if confirm_action "是否要切换回主分支 ($MAIN_BRANCH) 并拉取更新？"; then
            echo -e "${BLUE}正在切换到主分支 '$MAIN_BRANCH'...${NC}"
            if git checkout "$MAIN_BRANCH"; then
                echo -e "${BLUE}正在拉取主分支最新代码...${NC}"
                if do_pull_with_retry "$REMOTE_NAME" "$MAIN_BRANCH"; then
                    echo -e "${GREEN}已成功切换到主分支并更新。${NC}"
                else
                    print_warning "已切换到主分支，但拉取更新失败。请稍后手动执行 'gw pull'。"
                fi
            else
                print_error "切换到主分支失败。请保持在当前分支 '$current_branch'。"
            fi
        fi
    fi

    echo -e "${GREEN}=== 分支 '$current_branch' 完成工作流结束 ===${NC}"
    return 0
} 