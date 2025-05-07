#!/bin/bash
# 脚本/actions/cmd_branch.sh
#
# 实现 'branch' 命令逻辑。
# 当不带参数调用时，提供一个美化过的分支列表。
# 当带参数调用时，作为 'git branch' 的包装器，并对某些子命令提供增强的提示或校验。
# 依赖:
# - colors.sh (颜色定义)
# - utils.sh (check_in_git_repo, get_current_branch_name)
# - utils_print.sh (print_info, print_error, print_warning)

# 显示或操作分支
cmd_branch() {
    if ! check_in_git_repo; then
        return 1
    fi

    if [ "$#" -eq 0 ]; then
        # 只显示本地分支，当前分支高亮，分支名左对齐，摘要可选
        git for-each-ref --sort=-committerdate refs/heads/ --format='%(if)%(HEAD)%(then)*%(else) %(end) %(refname:short) %(objectname:short) %(contents:subject)' |
        awk '{
            head=$1; name=$2; sha=$3; $1=""; $2=""; $3=""; summary=substr($0,4);
            if(head=="*") {
                printf("\033[1;32m* %-20s %-8s %s\033[0m\n", name, sha, summary);
            } else {
                printf("  %-20s %-8s %s\n", name, sha, summary);
            }
        }'
        return 0
    fi
    if [ "$1" = "-r" ]; then
        # 只显示远程分支，格式同上
        git for-each-ref --sort=-committerdate refs/remotes/ --format='  %(refname:short) %(objectname:short) %(contents:subject)' |
        awk '{
            name=$1; sha=$2; $1=""; $2=""; summary=substr($0, length(name)+length(sha)+3);
            printf("  %-20s %-8s %s\n", name, sha, summary);
        }'
        return 0
    else
        # 带参数调用：行为类似原生 git branch，但有一些增强提示
        case "$1" in
            -a|-r|--list|--show-current|--contains|--points-at|--edit-description|--no-color|--column|--sort=*|--merged|--no-merged|--abbrev=*|--show-object-ids)
                # 对于已知的安全、非破坏性 'git branch' 列表/查询类选项
                print_info "执行: git branch $@"
                git branch "$@"
                return $?
                ;;
            -d|-D|--delete|--force-delete)
                local branch_to_delete="$2"
                # 检查是否尝试删除当前分支（虽然 git branch -d 自己会阻止，但可以提前提示）
                if [ -n "$branch_to_delete" ] && [ "$branch_to_delete" == "$(get_current_branch_name)" ]; then
                    print_warning "您正在尝试删除当前所在的分支 ('$branch_to_delete')。"
                    print_info "通常需要先切换到其他分支。如果确定，'git branch -D' 可能需要。"
                fi 
                if [ -z "$branch_to_delete" ]; then
                    print_error "错误: 删除分支需要提供分支名称。"
                    print_info "用法: gw branch $1 <分支名>"
                    return 1
                fi
                # 这里 "$@" 包括 -d/-D, 分支名, 以及可能的额外参数如 --force
                print_info "执行: git branch $@"
                git branch "$@"
                return $?
                ;;
            -m|--move)
                if [ -z "$2" ] || ([ "$3" == "$(get_current_branch_name)" ] && [ -z "$4" ]); then # git branch -m new_name OR git branch -m old_name new_name where old is current
                     # git branch -m <newname> (renames current)
                     # git branch -m <oldbranch> <newbranch>
                     local old_name_msg=""
                     if [ -n "$3" ]; then old_name_msg="分支 '$2' 到"; fi
                     print_info "执行重命名 ${old_name_msg}'$2' 为 '$3${4:+ -> $4}' (git branch $@)..."
                else
                     print_info "执行: git branch $@"
                fi
                git branch "$@"
                return $?
                ;;
            *)
                # 对于未明确处理的参数，先警告一下，然后尝试透传给 git branch
                # 这允许用户使用一些不常用的 git branch 参数，但风险自负
                print_warning "警告: 'gw branch' 正在尝试将未知或未显式支持的参数 '$*' 传递给 'git branch'。"
                print_info "如果遇到问题，请查阅 'git branch --help' 或使用原生 git 命令。"
                git branch "$@"
                return $?
                ;;
        esac
    fi
} 