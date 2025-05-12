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
        # 美化本地分支列表
        local current_branch_name
        current_branch_name=$(get_current_branch_name)
        if [ $? -ne 0 ]; then return 1; fi

        # 获取主分支名称，确保 MAIN_BRANCH 变量已从 config_vars.sh 加载
        # 如果 MAIN_BRANCH 未定义或为空，则尝试动态获取或使用默认值
        local main_branch_to_compare="${MAIN_BRANCH:-$(get_main_branch_name)}"
        if [ -z "$main_branch_to_compare" ]; then
            # 作为最后的备用，如果 get_main_branch_name 也失败了
            if git show-ref --verify --quiet refs/heads/main; then
                main_branch_to_compare="main"
            elif git show-ref --verify --quiet refs/heads/master; then
                main_branch_to_compare="master"
            else
                print_warning "无法确定主分支名称，合并状态可能不准确。"
                main_branch_to_compare="" # 设为空，后续逻辑会跳过合并检查
            fi
        fi


        # 获取所有本地分支，并进行处理
        # 使用 --format 来获取更多信息，减少后续 git 命令调用
        # %(refname:short) - 分支名
        # %(upstream:short) - 上游分支名
        # %(committerdate:relative) - 最新提交相对时间
        # %(HEAD) - 是否为当前分支 ('*' or ' ')
        
        # 先获取所有本地分支名
        local local_branches=()
        while IFS= read -r branch; do
            local_branches+=("$branch")
        done < <(git for-each-ref --format='%(refname:short)' refs/heads/)

        if [ ${#local_branches[@]} -eq 0 ]; then
            print_info "没有本地分支。"
            return 0
        fi
        
        # 计算最大分支名长度用于对齐
        local max_branch_len=0
        for branch_name_for_len in "${local_branches[@]}"; do
            if [ ${#branch_name_for_len} -gt $max_branch_len ]; then
                max_branch_len=${#branch_name_for_len}
            fi
        done
        # 为了美观，给最大长度加一点buffer，比如2个空格
        max_branch_len=$((max_branch_len + 2))


        for branch_name in "${local_branches[@]}"; do
            local output_line=""
            local color_prefix=""
            local color_suffix="$NC" # No Color

            # 1. 当前分支标记和颜色
            if [ "$branch_name" = "$current_branch_name" ]; then
                output_line+="  * "
                color_prefix="$GREEN$BOLD" # 例如绿色加粗
            else
                output_line+="    "
                color_prefix="$NC" # 默认颜色
            fi

            # 2. 分支名 (带颜色和对齐)
            # output_line+="${color_prefix}${branch_name}${color_suffix}"
            # 使用 printf 实现对齐
            printf "%s" "$output_line" # 先打印星号和空格
            printf "${color_prefix}%-${max_branch_len}s${color_suffix}" "$branch_name"


            # 3. 远程同步状态
            local upstream_branch
            upstream_branch=$(git rev-parse --abbrev-ref "${branch_name}@{u}" 2>/dev/null)
            local sync_status_output=""

            if [ -n "$upstream_branch" ]; then
                local ahead_behind
                ahead_behind=$(git rev-list --count --left-right "${branch_name}...${upstream_branch}")
                local ahead=$(echo "$ahead_behind" | cut -f1)
                local behind=$(echo "$ahead_behind" | cut -f2)

                if [ "$ahead" -eq 0 ] && [ "$behind" -eq 0 ]; then
                    sync_status_output="${GREEN}(已同步 ${upstream_branch})${NC}"
                elif [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
                    sync_status_output="${YELLOW}(与 ${upstream_branch} 分叉: ↑${ahead} ↓${behind})${NC}"
                elif [ "$ahead" -gt 0 ]; then
                    sync_status_output="${YELLOW}(领先 ${upstream_branch} ${ahead} commit)${NC}"
                elif [ "$behind" -gt 0 ]; then
                    sync_status_output="${YELLOW}(落后 ${upstream_branch} ${behind} commit)${NC}"
                fi
            else
                sync_status_output="${GRAY}(无远程跟踪)${NC}"
            fi
            # 打印带颜色的同步状态，增加与第一列的间距
            echo -e -n "    $sync_status_output" # 使用4个空格作为分隔

            # 计算同步状态的可见长度以进行对齐
            local sync_status_no_color
            # sed 命令用于去除 ANSI 转义序列
            sync_status_no_color=$(echo "$sync_status_output" | sed -r 's/\x1b\[[0-9;]*[mGKH]//g')
            local visible_len_sync_status=${#sync_status_no_color}
            
            # 为同步状态列设定一个目标视觉宽度。
            # 分支名列的结束位置约是 (4 + max_branch_len)
            # 同步状态列在此之后，有4个前导空格。
            # 我们希望“最新提交时间”信息块开始于一个相对固定的列位置。
            # 预算：分支名(max_branch_len) + 分隔(4) + 同步状态可见内容(预算55)
            local time_info_start_col_target=$((4 + max_branch_len + 4 + 55)) 
            
            # 当前光标在打印完同步状态后的位置约是 (4 + max_branch_len + 4 + visible_len_sync_status)
            local current_cursor_pos_after_sync=$((4 + max_branch_len + 4 + visible_len_sync_status))
            local padding_to_time_info=$((time_info_start_col_target - current_cursor_pos_after_sync))

            if [ $padding_to_time_info -lt 1 ]; then
                padding_to_time_info=2 # 保证至少2个空格分隔
            fi
            # 不再限制最大间距，以优先保证列对齐
            printf "%*s" $padding_to_time_info ""

            # 4. 最新提交相对时间
            local last_commit_time_str=""
            local last_commit_time
            last_commit_time=$(git log -1 --format="%cr" "$branch_name" 2>/dev/null)
            if [ -n "$last_commit_time" ]; then
                last_commit_time_str="${GRAY}(最新: $last_commit_time)${NC}"
                echo -e -n "$last_commit_time_str"
            fi

            # 计算最新提交时间列的可见长度，为下一列对齐做准备
            local last_commit_time_no_color
            last_commit_time_no_color=$(echo "$last_commit_time_str" | sed -r 's/\x1b\[[0-9;]*[mGKH]//g')
            local visible_len_time_info=${#last_commit_time_no_color}
            
            # 预算：时间信息(预算25)
            local merge_info_start_col_target=$((time_info_start_col_target + 25))
            local current_cursor_pos_after_time=$((time_info_start_col_target + visible_len_time_info))
            local padding_to_merge_info=$((merge_info_start_col_target - current_cursor_pos_after_time))

            if [ $padding_to_merge_info -lt 1 ]; then
                 padding_to_merge_info=2 # 保证至少2个空格分隔
            fi
            # 不再限制最大间距
            # 只有在 last_commit_time_str 非空时才打印这个填充，否则合并信息会直接跟在同步状态后
            if [ -n "$last_commit_time_str" ]; then
                printf "%*s" $padding_to_merge_info ""
            else 
                # 如果没有时间信息，合并信息和同步信息之间也需要分隔
                # 此时，合并信息应该对齐到 time_info_start_col_target
                local padding_sync_to_merge=$((time_info_start_col_target - current_cursor_pos_after_sync))
                if [ $padding_sync_to_merge -lt 1 ]; then
                    padding_sync_to_merge=2
                fi
                printf "%*s" $padding_sync_to_merge ""
            fi

            # 5. 是否已合并到主分支 (仅对非主分支检查)
            if [ -n "$main_branch_to_compare" ] && [ "$branch_name" != "$main_branch_to_compare" ]; then
                if git branch --merged "$main_branch_to_compare" | grep -qw "$branch_name"; then
                    echo -e -n "${PURPLE}(已合并到 $main_branch_to_compare)${NC}"
                fi
            fi
            
            echo # 换行
        done
        return 0
    fi

    # --- 对于带参数的 gw branch ---
    # 保留原有的参数处理逻辑，但可以考虑对某些命令的输出或行为进行微调
    # 例如，gw branch -d <branch> 可以在删除前显示更多关于该分支的信息

    if [ "$1" = "-r" ]; then
        # TODO: 也可以考虑美化远程分支列表
        print_info "执行: git branch -r"
        git branch -r
        return 0
    elif [ "$1" = "-a" ]; then
        # TODO: 也可以考虑美化全部分支列表
        print_info "执行: git branch -a"
        git branch -a
        return 0
    else
        # 带参数调用：行为类似原生 git branch，但有一些增强提示
        case "$1" in
            # 对于已知的安全、非破坏性 'git branch' 列表/查询类选项
            --list|--show-current|--contains|--points-at|--edit-description|--no-color|--column|--sort=*|--merged|--no-merged|--abbrev=*|--show-object-ids)
                print_info "执行: git branch $@"
                git branch "$@"
                return $?
                ;;
            -d|-D|--delete|--force-delete)
                local branch_to_delete="$2"
                if [ -z "$branch_to_delete" ]; then
                    print_error "错误: 删除分支需要提供分支名称。"
                    print_info "用法: gw branch $1 <分支名>"
                    return 1
                fi
                # 检查是否尝试删除当前分支
                local current_branch_for_delete_check
                current_branch_for_delete_check=$(get_current_branch_name)
                if [ "$branch_to_delete" == "$current_branch_for_delete_check" ]; then
                    print_warning "您正在尝试删除当前所在的分支 ('$branch_to_delete')。"
                    print_info "通常需要先切换到其他分支。如果确定，'git branch -D $branch_to_delete' 可能需要。"
                    # 如果不是强制删除，则不继续执行
                    if [[ "$1" == "-d" || "$1" == "--delete" ]]; then
                         if ! confirm_action "仍要尝试删除当前分支 '$branch_to_delete' 吗 (可能失败或需要 -D)？"; then
                            print_info "删除操作已取消。"
                            return 1
                         fi
                    fi
                fi
                
                # 提示将要删除的分支信息
                local last_commit_info_delete
                last_commit_info_delete=$(git log -1 --pretty=format:"%h - %s (%cr by %cn)" "$branch_to_delete" 2>/dev/null)
                if [ -n "$last_commit_info_delete" ]; then
                    print_info "分支 '$branch_to_delete' 的最新提交: $last_commit_info_delete"
                else
                    print_warning "无法获取分支 '$branch_to_delete' 的最新提交信息 (可能分支不存在)。"
                fi

                if [[ "$1" == "-d" || "$1" == "--delete" ]]; then # 非强制删除
                    if ! git branch --merged | grep -qw "$branch_to_delete" && \
                       ! git branch --merged "$main_branch_to_compare" | grep -qw "$branch_to_delete"; then # 检查是否合并到当前或主分支
                        print_warning "分支 '$branch_to_delete' 似乎尚未合并到当前分支或主分支 ($main_branch_to_compare)。"
                        if ! confirm_action "确定要删除未合并的分支 '$branch_to_delete' 吗 (可能需要 -D)？"; then
                            print_info "删除操作已取消。"
                            return 1
                        fi
                    fi
                fi
                
                print_info "执行: git branch $@"
                git branch "$@"
                return $?
                ;;
            -m|--move)
                local old_name new_name
                if [ -n "$3" ]; then # gw branch -m old new
                    old_name="$2"
                    new_name="$3"
                else # gw branch -m new (renames current)
                    old_name=$(get_current_branch_name)
                    new_name="$2"
                fi
                if [ -z "$new_name" ]; then
                    print_error "错误: 重命名分支需要提供新名称。"
                    print_info "用法: gw branch -m [旧分支名] <新分支名>"
                    return 1
                fi
                print_info "准备将分支 '$old_name' 重命名为 '$new_name'..."
                print_info "执行: git branch $@"
                git branch "$@"
                return $?
                ;;
            *)
                # 对于未明确处理的参数，先警告一下，然后尝试透传给 git branch
                print_warning "警告: 'gw branch' 正在尝试将未知或未显式支持的参数 '$*' 传递给 'git branch'。"
                print_info "如果遇到问题，请查阅 'git branch --help' 或使用原生 git 命令。"
                git branch "$@"
                return $?
                ;;
        esac
    fi
}
