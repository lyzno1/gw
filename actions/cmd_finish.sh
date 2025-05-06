#!/bin/bash
# 脚本/actions/cmd_finish.sh
#
# 实现 'finish' 命令逻辑。
# 依赖:
# - colors.sh (颜色定义)
# - utils_print.sh (打印函数)
# - utils.sh (通用工具函数)
# - config_vars.sh (配置变量)
# - git_network_ops.sh (do_push_with_retry, do_pull_with_retry)
# - cmd_commit.sh (依赖 cmd_commit 函数，确保其已被 sourcing)

# 完成当前分支工作 (准备 PR/MR)
cmd_finish() {
    if ! check_in_git_repo; then return 1; fi

    local no_switch=false
    local do_pr=false # 标记是否创建 PR

    # 解析参数
    # 使用 getopt 进行更健壮的参数解析
    local_args=$(getopt -o np --long no-switch,pr -n 'gw finish' -- "$@")
    if [ $? != 0 ]; then 
        echo -e "${RED}参数解析错误。${NC}" >&2
        # show_help_finish # 假设有一个 cmd_finish 的特定帮助函数
        echo "用法: gw finish [--no-switch | -n] [--pr | -p]"
        return 1 
    fi

    eval set -- "$local_args"

    while true; do
        case "$1" in
            -n|--no-switch)
                no_switch=true
                shift
                ;;
            -p|--pr)
                do_pr=true
                shift
                ;;
            --)
                shift
                break
                ;;
            *)
                # 这是 getopt 不应该发生的情况
                echo -e "${RED}内部参数解析错误。${NC}" >&2
                return 1
                ;;
        esac
    done

    # 检查是否有其他非选项参数（目前 finish 不支持）
    if [ $# -gt 0 ]; then
        print_warning "'finish' 命令忽略了额外的参数: $@"
    fi

    local current_branch
    current_branch=$(get_current_branch_name)
    if [ $? -ne 0 ]; then return 1; fi

    if [ "$current_branch" = "$MAIN_BRANCH" ]; then
        print_warning "您当前在主分支 ($MAIN_BRANCH)。'finish' 命令通常用于功能分支。"
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
        echo "1) 暂存并提交所有变更"
        echo "2) 暂存变更 (stash) (不推荐，推送后 PR 中不包含)"
        echo "3) 取消完成操作"
        echo -n "请选择操作 [1-3]: "
        read -r choice

        case "$choice" in
            1)
                print_step "正在添加所有变更到暂存区..."
                if ! git add -A; then
                    print_error "添加变更失败 (git add -A)。请手动处理后重试。"
                    return 1
                fi
                
                if git diff --cached --quiet; then
                    print_info "没有需要提交的变更 (暂存区为空)。"
                else
                    print_step "请提交暂存的变更..."
                    # 确保 cmd_commit 可用
                    if ! command -v cmd_commit >/dev/null 2>&1;
                        then print_error "命令 'cmd_commit' 未找到或未导入。"; return 1;
                    fi
                    if ! cmd_commit; then # 调用 cmd_commit (通常会打开编辑器或使用其默认逻辑)
                        print_error "提交失败或被取消。请手动提交后重试。"
                        return 1
                    fi
                    echo -e "${GREEN}变更已成功提交。${NC}"
                fi
                ;;
            2)
                echo -e "${BLUE}正在暂存变更...${NC}"
                if git stash save "Stashed before finishing branch $current_branch"; then
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

    # 2. 推送当前分支 (使用 do_push_with_retry，它会自动处理 -u)
    echo -e "${BLUE}准备推送当前分支 '$current_branch' 到远程 '$REMOTE_NAME'...${NC}"
    if ! do_push_with_retry; then # 不带参数，do_push_with_retry 会自动推当前分支并设置上游
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
            # 尝试自动填充标题和正文。用户可以之后编辑。
            if gh pr create --base "$MAIN_BRANCH" --head "$current_branch" --fill --web; then
                echo -e "${GREEN}Pull Request 创建成功，并在浏览器中打开。${NC}"
            else
                print_error "Pull Request 创建失败。请手动检查或尝试在浏览器中创建。"
                echo -e "${CYAN}您可能需要运行 'gh auth login' 或检查 'gh' 的配置。${NC}"
            fi
        fi
    else
        echo -e "${CYAN}现在您可以前往 GitHub/GitLab 等平台基于 '$current_branch' 创建 Pull Request / Merge Request。${NC}"
        echo -e "${PURPLE}(提示: 下次可以使用 'gw finish --pr' 来尝试自动创建 GitHub PR)${NC}"
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