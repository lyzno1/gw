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
        # 无参数调用：显示美化版的分支列表
        echo -e "${CYAN}=== 分支概览 ===${NC}"
        
        local current_branch
        current_branch=$(get_current_branch_name)
        
        echo -e "${BOLD}本地分支:${NC}"
        # 使用 git for-each-ref 提供更详细和彩色的输出
        # HEAD 标记当前分支, refname:short 分支名, objectname:short commit SHA 短码
        # contents:subject 最新提交信息, authorname 作者, committerdate:relative 相对提交时间
        git for-each-ref --sort=-committerdate refs/heads/ --format='%(HEAD)%(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))' |
        while IFS= read -r branch_line; do # 使用 IFS= 和 -r 确保整行读取，包括前导空格
            if [[ $branch_line == \** ]]; then # 检查行首是否为 '*' (当前分支标记)
                # 当前分支高亮显示 (通常是绿色，但 git for-each-ref 内部的 %(HEAD) 会处理)
                # 我们这里确保整个行是绿色（如果需要覆盖 for-each-ref 的颜色）
                # 或者依赖 for-each-ref 的 HEAD 标记和颜色
                # 为了简单，如果 HEAD 标记存在，我们就相信 for-each-ref 的颜色，否则整行用默认色
                # 实际上，git for-each-ref 的 %(HEAD) 会输出 '*'，我们可以用它来判断并额外高亮
                echo -e "${GREEN}${branch_line}${NC}" # 将当前分支整行用绿色高亮
            else
                echo -e "  $branch_line" # 非当前分支，加两个空格缩进以示区别
            fi
        done
        if ! git for-each-ref refs/heads/ --count=1 --format="%(refname)" > /dev/null 2>&1; then
             echo "  (没有本地分支)"
        fi

        echo -e "\n${BOLD}远程跟踪分支:${NC}"
        git for-each-ref --sort=-committerdate refs/remotes/ --format='  %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))' | \
        grep -v "/HEAD\$" # 过滤掉指向远程 HEAD 的特殊引用
        if ! git for-each-ref refs/remotes/ --count=1 --format="%(refname)" | grep -v "/HEAD\$" > /dev/null 2>&1; then
             echo "  (没有远程跟踪分支)"
        fi
        
        echo -e "\n${CYAN}提示:${NC} 使用 'gw branch <原生git branch参数>' (如 -a, -r, -d <名>) 执行原生命令。"
        echo -e "      创建分支推荐: 'gw new <名>', 删除分支推荐: 'gw rm <名>'。"

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