#!/bin/bash
# 脚本/actions/cmd_sp.sh
#
# 实现 'sp' (Save and Push) 命令逻辑。
# 快速保存所有当前更改并推送到远程。
# 依赖:
# - colors.sh
# - utils_print.sh
# - utils.sh (check_in_git_repo, get_current_branch_name)
# - cmd_save.sh (cmd_save function)
# - cmd_push.sh (cmd_push function)

cmd_sp() {
    if ! check_in_git_repo; then
        return 1
    fi

    local current_branch
    current_branch=$(get_current_branch_name)
    if [ $? -ne 0 ]; then
        print_error "无法获取当前分支名称。"
        return 1
    fi

    print_step "步骤 1/2: 保存当前工作区的所有变更 (gw save)..."
    if ! command -v cmd_save >/dev/null 2>&1; then
        print_error "命令 'cmd_save' 未找到或未导入。无法继续。"
        return 1
    fi
    
    # 调用 cmd_save，它会处理暂存和提交，并允许编辑提交信息
    # cmd_save 会自行检查是否有东西可提交
    if ! cmd_save "$@"; then # 将参数原样传递给 cmd_save, 以便支持 gw sp -m "message"
        print_error "保存变更失败或被用户取消。'gw sp' 操作终止。"
        return 1
    fi
    # 如果 cmd_save 执行了但没有实际提交任何东西（例如，工作区是干净的，或者用户在编辑提交信息时取消了），
    # 那么 cmd_save 应该返回一个非零退出码或者有相应的提示。我们在这里假设 cmd_save 成功意味着有东西被提交了。
    # 或者，我们可以在这里检查一下 HEAD 是否真的改变了，但为了简化，先依赖 cmd_save 的行为。
    print_success "变更已成功保存。"

    print_step "步骤 2/2: 推送当前分支 ('$current_branch') 到远程 (gw push)..."
    if ! command -v cmd_push >/dev/null 2>&1; then
        print_error "命令 'cmd_push' 未找到或未导入。无法继续。"
        return 1
    fi

    # 调用 cmd_push 推送当前分支。cmd_push 内部会使用 do_push_with_retry
    # 并且 do_push_with_retry 已经处理了远程不存在、-u 自动添加等逻辑
    if ! cmd_push; then # cmd_push 默认推送当前分支到其上游或默认远程
        print_error "推送分支 '$current_branch' 失败。'gw sp' 操作未完全完成。"
        return 1
    fi
    print_success "当前分支 ('$current_branch') 已成功推送到远程。"
    
    echo -e "${GREEN}=== 'gw sp' (保存并推送) 操作成功完成 ===${NC}"
    return 0
} 