#!/bin/bash
# 脚本/actions/cmd_push.sh
#
# 实现 'push' 命令逻辑的包装器。
# 它调用在 git_network_ops.sh 中定义的 do_push_with_retry 函数。
# 在调用核心推送函数前，会检查远程仓库是否存在，并提示用户添加。
# 依赖:
# - colors.sh (颜色定义)
# - utils_print.sh (打印函数)
# - utils.sh (confirm_action)
# - config_vars.sh (REMOTE_NAME)
# - core_utils/git_network_ops.sh (提供 do_push_with_retry)

cmd_push() {
    # 尝试从参数中确定目标远程。这是一个简化版本，可能不覆盖所有 git push 的复杂参数情况。
    # 主要目的是为了交互式添加远程时有一个合理的默认远程名。
    local remote_to_interact_with="$REMOTE_NAME" # 默认为配置的远程
    local first_arg_is_remote=false

    if [ -n "$1" ] && ! [[ "$1" =~ ^- ]]; then # 如果第一个参数存在且不是选项
        if git remote | grep -qw "^$1$"; then
            remote_to_interact_with="$1"
            first_arg_is_remote=true
        fi
    fi

    # 检查确定的远程是否存在URL
    if ! git remote get-url "$remote_to_interact_with" > /dev/null 2>&1; then
        print_warning "远程仓库 '$remote_to_interact_with' 似乎未配置或没有有效的URL。"
        if confirm_action "是否希望现在添加远程仓库 '$remote_to_interact_with'？"; then
            local new_remote_name="$remote_to_interact_with"
            local new_remote_url=""
            
            # 如果第一个参数不是我们识别的远程名，并且我们用了默认的 REMOTE_NAME，
            # 也许用户想指定一个不同的名字，但这里为了简化，就用 remote_to_interact_with
            echo -n -e "${CYAN}请输入远程仓库 '$new_remote_name' 的 URL: ${NC}"
            read -r new_remote_url
            
            if [ -z "$new_remote_url" ]; then
                print_error "未提供 URL，无法添加远程仓库。推送操作已取消。"
                return 1
            fi
            
            print_step "正在添加远程仓库: git remote add $new_remote_name $new_remote_url"
            if git remote add "$new_remote_name" "$new_remote_url"; then
                print_success "远程仓库 '$new_remote_name' 添加成功。"
            else
                print_error "添加远程仓库 '$new_remote_name' 失败。请检查错误信息或手动添加。推送操作已取消。"
                return 1
            fi
        else
            echo "操作已取消。请先配置远程仓库。"
            return 1
        fi
    fi

    # 确保核心推送函数可用
    if ! command -v do_push_with_retry >/dev/null 2>&1; then
        print_error "核心函数 'do_push_with_retry' 未找到。请检查脚本完整性。"
        return 127 # 表示命令未找到
    fi
    
    # 调用核心推送函数
    do_push_with_retry "$@"
    return $?
} 