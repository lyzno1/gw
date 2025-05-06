#!/bin/bash
# 脚本/actions/cmd_commit.sh
#
# Implements the 'commit' command logic.
# Dependencies:
# - colors.sh (for BLUE, GREEN, RED, YELLOW, NC)
# - utils_print.sh (for print_warning)
# - utils.sh (for check_in_git_repo, check_uncommitted_changes, get_commit_msg_file)

# 提交暂存的修改
cmd_commit() {
    if ! check_in_git_repo; then
        return 1
    fi

    # 首先检查是否有未暂存的修改，但不作为阻塞
    # check_uncommitted_changes "commit" # 这里暂时不直接调用，因为可能会让用户困惑

    # 检查是否有任何东西被暂存以供提交
    if git diff --cached --quiet; then
        print_warning "没有暂存的修改可以提交。"
        echo "您可能需要先使用 'gw add <文件>' 或 'gw aa' 来暂存修改。"
        return 1
    fi

    local commit_msg_option=""
    local commit_msg_file=""
    local commit_args=()

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -m|--message)
                if [ -n "$2" ]; then
                    commit_msg_option="-m"
                    commit_args+=("-m" "$2")
                    shift 2
                else
                    echo -e "${RED}错误: -m/--message 参数需要一个消息字符串。${NC}"
                    return 1
                fi
                ;;
            -F|--file)
                if [ -n "$2" ]; then
                    commit_msg_option="-F"
                    commit_msg_file="$2"
                    commit_args+=("-F" "$2")
                    shift 2
                else
                    echo -e "${RED}错误: -F/--file 参数需要一个文件路径。${NC}"
                    return 1
                fi
                ;;
            --no-verify)
                commit_args+=("--no-verify")
                shift
                ;;
            # 可以添加对 -S (GPG签名) 等其他 git commit 参数的支持
            *)
                echo -e "${YELLOW}警告: commit 命令忽略未知参数: $1${NC}"
                shift
                ;;
        esac
    done

    # 如果没有提供 -m 或 -F，则尝试获取标准提交信息
    if [ -z "$commit_msg_option" ]; then
        commit_msg_file=$(get_commit_msg_file) # 函数内部会处理失败情况
        if [ -z "$commit_msg_file" ]; then
            # get_commit_msg_file 内部会打印错误信息，这里直接返回
            return 1
        fi
        commit_args+=("-F" "$commit_msg_file")
    fi

    echo -e "${BLUE}正在提交暂存的修改...${NC}"
    # shellcheck disable=SC2068 # 我们希望 $commit_args 被展开
    git commit ${commit_args[@]}

    local commit_status=$?

    # 如果是通过 get_commit_msg_file 创建的临时文件，提交后删除它
    if [ -n "$commit_msg_file" ] && [[ "$commit_msg_file" == *"/COMMIT_EDITMSG_GW_"* ]]; then
        rm -f "$commit_msg_file"
    fi

    if [ $commit_status -eq 0 ]; then
        echo -e "${GREEN}成功提交修改。${NC}"
        return 0
    else
        echo -e "${RED}提交修改失败。${NC}"
        echo "可能的原因："
        echo " - 如果是 GPG 签名失败，请检查您的 GPG 配置。"
        echo " - 如果是 pre-commit hook 失败，请解决 hook 报告的问题。"
        echo " - 如果编辑器意外关闭或没有保存提交信息。"
        return 1
    fi
} 