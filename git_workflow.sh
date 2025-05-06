#!/bin/bash

# 脚本：增强版 Git 工作流助手 (Git Workflow - gw)
# 描述：根据实际工作流程优化的 Git 操作集合，提供便捷的一站式命令
# 版本：3.0

# --- 配置变量 ---
MAX_ATTEMPTS=${MAX_ATTEMPTS:-50}           # 最大尝试次数，可通过环境变量覆盖
DELAY_SECONDS=${DELAY_SECONDS:-1}          # 每次尝试之间的延迟（秒），可通过环境变量覆盖
REMOTE_NAME=${REMOTE_NAME:-"origin"}       # 默认的远程仓库名称，可通过环境变量覆盖
DEFAULT_MAIN_BRANCH=${DEFAULT_MAIN_BRANCH:-"master"}  # 默认的主分支名称，可通过环境变量覆盖

# --- 获取实际的主分支名称 (master 或 main) ---
get_main_branch_name() {
    # 检查 master 和 main 是否存在，优先返回存在的
    if git rev-parse --verify --quiet master >/dev/null 2>&1; then
        echo "master"
        return 0
    elif git rev-parse --verify --quiet main >/dev/null 2>&1; then
        echo "main"
        return 0
    else
        # 如果都不存在，返回配置的默认值
        echo "$DEFAULT_MAIN_BRANCH"
        return 0
    fi
}

# 设置实际使用的主分支名
MAIN_BRANCH=$(get_main_branch_name)

# 设置颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- 辅助打印函数 ---
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    # 警告信息使用黄色，并输出到 stderr
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

print_error() {
    # 错误信息使用红色，并输出到 stderr
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# 记录最后一次命令的执行状态
LAST_COMMAND_STATUS=0

# 设置中断处理
trap "echo -e '\n${YELLOW}脚本被用户中断，退出.${NC}'; exit 130" INT

# --- 工具函数 ---

# 获取当前分支名称
get_current_branch_name() {
    local branch_name
    branch_name=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    local exit_code=$?

    if [ $exit_code -ne 0 ] || [ -z "$branch_name" ] || [ "$branch_name" == "HEAD" ]; then
        echo -e "${RED}错误：无法确定当前分支名称，或您正处于 'detached HEAD' 状态。${NC}" >&2
        return 1
    fi
    echo "$branch_name"
    return 0
}

# 检查是否在 Git 仓库中
check_in_git_repo() {
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo -e "${RED}错误：当前目录不是 Git 仓库。${NC}"
        return 1
    fi
    return 0
}

# 检查是否有未提交的变更
check_uncommitted_changes() {
    if ! git diff-index --quiet HEAD --; then
        return 0  # 有变更返回0（成功）
    fi
    return 1  # 无变更返回1（失败）
}

# 检查是否有未追踪的文件
check_untracked_files() {
    if [ -n "$(git ls-files --others --exclude-standard)" ]; then
        return 0  # 有未追踪文件返回0（成功）
    fi
    return 1  # 无未追踪文件返回1（失败）
}

# 检查文件是否已暂存
is_file_staged() {
    local file="$1"
    git diff --cached --name-only | grep -q "^$file$"
    return $?
}

# 执行带重试的 Git 推送
do_push_with_retry() {
    local push_args=()
    local remote="$REMOTE_NAME"
    local branch_to_push=""
    local current_branch
    current_branch=$(get_current_branch_name)
    if [ $? -ne 0 ]; then return 1; fi

    # --- 前置检查：未提交的变更 ---
    if check_uncommitted_changes || check_untracked_files; then
        echo -e "${YELLOW}检测到未提交的变更或未追踪的文件。${NC}"
        # 列出具体文件
        echo "变更详情:"
        git status -s
        echo ""
        if confirm_action "是否要将所有变更添加到暂存区并提交，然后再推送？"; then
            echo -e "${BLUE}正在暂存所有变更...${NC}"
            cmd_add_all
            if [ $? -ne 0 ]; then
                echo -e "${RED}暂存变更失败，推送已取消。${NC}"
                return 1
            fi
            
            echo -e "${BLUE}正在提交变更...${NC}"
            # 调用 cmd_commit 时不带 -m，让用户在编辑器中输入信息
            cmd_commit
            if [ $? -ne 0 ]; then
                echo -e "${RED}提交失败或被取消，推送已取消。${NC}"
                return 1
            fi
            echo -e "${GREEN}变更已提交，继续推送...${NC}"
        else
            echo "推送已取消。请先处理未提交的变更。"
            return 1
        fi
    fi

    # 解析传入的参数，分离出远程和分支，保留其他 git push 参数
    local other_args=()
    local arg_count=$#
    local args_array=("$@") # 将参数存入数组

    # 尝试识别远程和分支参数，并处理 --set-upstream 等常见选项
    # 这是一个简化的解析，可能无法覆盖所有 git push 的复杂场景
    local potential_remote=""
    local potential_branch=""
    local set_upstream=false

    for (( i=0; i<$arg_count; i++ )); do
        local arg="${args_array[i]}"
        case "$arg" in
            -u|--set-upstream)
                set_upstream=true
                other_args+=("$arg")
                ;;
            -f|--force|--force-with-lease)
                other_args+=("$arg")
                ;;
            # 其他需要保留的标志...
            -*)
                other_args+=("$arg") # 保留其他选项
                ;;
            *)
                # 非选项参数，可能是远程或分支
                if [ -z "$potential_remote" ]; then
                    # 尝试检查是否是已知的远程仓库名
                    if git remote | grep -q "^$arg$"; then
                        potential_remote="$arg"
                    elif [ -z "$potential_branch" ]; then # 如果不是远程，可能是分支
                        potential_branch="$arg"
                    else # 如果远程和分支都已有值，则认为是其他参数
                        other_args+=("$arg")
                    fi
                elif [ -z "$potential_branch" ]; then
                    potential_branch="$arg"
                else
                    other_args+=("$arg") # 多余的非选项参数
                fi
                ;;
        esac
    done

    # 确定最终的远程和分支
    remote=${potential_remote:-$REMOTE_NAME} # 如果没指定远程，使用默认
    branch_to_push=${potential_branch:-$current_branch} # 如果没指定分支，推送当前分支

    # 组合最终的 push 参数
    push_args=("$remote" "$branch_to_push")
    push_args+=("${other_args[@]}") # 添加其他保留的参数

    # 如果是第一次推送当前分支，且用户没有指定 -u，自动添加 --set-upstream
    if ! git rev-parse --verify --quiet "refs/remotes/$remote/$current_branch" > /dev/null 2>&1 && \
       [ "$branch_to_push" == "$current_branch" ] && \
       ! $set_upstream; then
        if ! printf '%s\n' "${other_args[@]}" | grep -q -e '-u' -e '--set-upstream'; then
           echo -e "${BLUE}检测到是首次推送分支 '$current_branch' 到 '$remote'，将自动设置上游跟踪 (-u)。${NC}"
           push_args+=("--set-upstream")
        fi
    fi
    
    local command_str="git push ${push_args[*]}"
    
    echo -e "${GREEN}--- Git 推送重试执行 ---${NC}"
    echo "执行命令: $command_str"
    echo "最大尝试次数: $MAX_ATTEMPTS"
    if [ "$DELAY_SECONDS" -gt 0 ]; then
        echo "每次尝试间隔: ${DELAY_SECONDS} 秒"
    fi
    echo "-----------------------------------------"

    # 开始循环尝试
    for i in $(seq 1 $MAX_ATTEMPTS)
    do
       echo "--- 第 $i/$MAX_ATTEMPTS 次尝试 ---"

       # 执行 git push 命令
       git push "${push_args[@]}"

       # 检查退出状态码
       EXIT_CODE=$?
       if [ $EXIT_CODE -eq 0 ]; then
          echo -e "${GREEN}--- 推送成功 (第 $i 次尝试). 操作完成. ---${NC}"
          return 0
       else
          echo -e "${RED}!!! 第 $i 次尝试失败 (退出码: $EXIT_CODE). 正在重试... !!!${NC}"
       fi

       # 如果已经是最后一次尝试，则不需要等待
       if [ $i -eq $MAX_ATTEMPTS ]; then
           break
       fi

       # 如果配置了延迟，则等待
       if [ "$DELAY_SECONDS" -gt 0 ]; then
           sleep $DELAY_SECONDS
       fi
    done

    # 如果循环完成仍未成功
    echo -e "${RED}=== 尝试 $MAX_ATTEMPTS 次后推送仍失败. 操作终止. ===${NC}"
    return 1
}

# 执行带重试的 Git 拉取
do_pull_with_retry() {
    local pull_args=()
    local remote="$REMOTE_NAME"
    local branch_to_pull=""
    local current_branch
    current_branch=$(get_current_branch_name)
    if [ $? -ne 0 ]; then return 1; fi

    # 解析参数以确定远程和分支，保留其他选项如 --rebase, --ff-only
    local other_args=()
    local potential_remote=""
    local potential_branch=""
    local args_array=("$@")
    local arg_count=$#

    for (( i=0; i<$arg_count; i++ )); do
        local arg="${args_array[i]}"
        case "$arg" in
            # 保留 pull 支持的常见选项
            --rebase|--ff|--ff-only|--no-ff|--stat|--no-stat|-v|--verbose|-q|--quiet)
                other_args+=("$arg")
                ;;
             # 可以根据需要添加更多选项
            -*)
                other_args+=("$arg") # 保留其他未知选项
                ;;
            *)
                # 非选项参数，可能是远程或分支
                if [ -z "$potential_remote" ]; then
                    if git remote | grep -q "^$arg$"; then
                        potential_remote="$arg"
                    elif [ -z "$potential_branch" ]; then
                        potential_branch="$arg"
                    else
                        other_args+=("$arg")
                    fi
                elif [ -z "$potential_branch" ]; then
                    potential_branch="$arg"
                else
                    other_args+=("$arg")
                fi
                ;;
        esac
    done

    # 确定最终的远程和分支
    remote=${potential_remote:-$REMOTE_NAME} # 默认远程
    # 如果未指定分支，git pull 默认会拉取当前分支的上游
    # 如果指定了分支，则使用指定的分支
    if [ -n "$potential_branch" ]; then
       branch_to_pull=$potential_branch
       pull_args=("$remote" "$branch_to_pull")
    else
        # 未指定分支时，pull_args 只包含 remote，让 git pull 决定拉取哪个分支
        # 或者可以尝试获取当前分支的上游？但直接传 remote 更简单
        pull_args=("$remote")
    fi
    pull_args+=("${other_args[@]}") # 添加其他保留的参数

    local command_str="git pull ${pull_args[*]}"
    
    echo -e "${GREEN}--- Git 拉取重试执行 ---${NC}"
    echo "将尝试执行命令: $command_str"
    echo "最大尝试次数: $MAX_ATTEMPTS"
    if [ "$DELAY_SECONDS" -gt 0 ]; then
        echo "每次尝试间隔: ${DELAY_SECONDS} 秒"
    fi
    echo "-----------------------------------------"

    # 开始循环尝试
    for i in $(seq 1 $MAX_ATTEMPTS)
    do
       echo "--- 第 $i/$MAX_ATTEMPTS 次尝试: 执行 '$command_str' --- "

       # 执行 git pull 命令
       git pull "${pull_args[@]}"

       # 检查退出状态码
       EXIT_CODE=$?
       if [ $EXIT_CODE -eq 0 ]; then
          echo -e "${GREEN}--- 拉取成功 (第 $i 次尝试). 操作完成. ---${NC}"
          return 0
       else
          # 区分是否是合并冲突，冲突时重试无意义
          if git diff --name-only --diff-filter=U --relative | grep -q .; then
              echo -e "${RED}!!! 拉取失败：检测到合并冲突 (退出码: $EXIT_CODE)。请手动解决冲突后提交。!!!${NC}"
              echo -e "运行 'git status' 查看冲突文件。"
              echo -e "解决后运行 'gw add <冲突文件>' 和 'gw commit'。"
              return 1 # 返回失败，因为需要手动干预
          fi
          echo -e "${RED}!!! 第 $i 次尝试拉取失败 (退出码: $EXIT_CODE)。可能是网络问题，正在重试... !!!${NC}"
       fi

       # 如果已经是最后一次尝试，则不需要等待
       if [ $i -eq $MAX_ATTEMPTS ]; then
           break
       fi

       # 如果配置了延迟，则等待
       if [ "$DELAY_SECONDS" -gt 0 ]; then
           sleep $DELAY_SECONDS
       fi
    done

    # 如果循环完成仍未成功
    echo -e "${RED}=== 尝试 $MAX_ATTEMPTS 次后拉取仍失败. 操作终止. 请检查网络连接或错误信息. ===${NC}"
    return 1
}

# 交互式选择文件
interactive_select_files() {
    local title="$1"
    local file_list=("${@:2}")
    local selected_files=()
    local num_files=${#file_list[@]}
    
    if [ $num_files -eq 0 ]; then
        echo "没有可选择的文件。"
        return 1
    fi

    # 在终端下使用更简单的选择方式，防止zsh兼容性问题
    echo -e "${CYAN}${title}${NC}"
    echo "输入文件编号（用空格分隔多个编号）来选择文件，或输入 'a' 选择全部，输入 'q' 取消。"
    echo ""

    # 显示所有文件，带编号
    for ((i=0; i<$num_files; i++)); do
        echo "[$i] ${file_list[$i]}"
    done
    echo ""
    
    echo -n "请选择 (0-$((num_files-1)), a=全部, q=取消): "
    read -r selection
    
    # 处理用户输入
    if [[ "$selection" == "q" ]]; then
        echo "已取消选择。"
        return 1
    elif [[ "$selection" == "a" ]]; then
        selected_files=("${file_list[@]}")
    else
        # 解析用户输入的编号
        for num in $selection; do
            if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -lt "$num_files" ]; then
                selected_files+=("${file_list[$num]}")
            else
                echo "忽略无效选择: $num"
            fi
        done
    fi
    
    if [ ${#selected_files[@]} -eq 0 ]; then
        echo "未选择任何文件。"
        return 1
    fi
    
    echo -e "${GREEN}已选择 ${#selected_files[@]} 个文件：${NC}"
    for file in "${selected_files[@]}"; do
        echo " - $file"
        echo "$file"  # 输出到 stdout 供调用者捕获
    done
    
    return 0
}

# 确认操作（Y/n）
confirm_action() {
    local message="$1"
    local default="${2:-Y}"  # 默认为 Y
    
    if [[ "$default" == "Y" ]]; then
        prompt="[Y/n]"
        default_answer="Y"
    else
        prompt="[y/N]"
        default_answer="N"
    fi
    
    echo -e -n "${YELLOW}$message $prompt ${NC}"
    read -r answer
    
    if [[ -z "$answer" ]]; then
        answer="$default_answer"
    fi
    
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# 获取正在编辑的提交消息文件路径
get_commit_msg_file() {
    local commit_msg_file=""
    
    # 检查是否处于提交编辑状态
    if [ -f ".git/COMMIT_EDITMSG" ]; then
        commit_msg_file=".git/COMMIT_EDITMSG"
    elif [ -f "$(git rev-parse --git-dir)/COMMIT_EDITMSG" ]; then
        commit_msg_file="$(git rev-parse --git-dir)/COMMIT_EDITMSG"
    fi
    
    echo "$commit_msg_file"
}

# --- 命令实现 ---

# 显示仓库的所有分支
cmd_branches() {
    if ! check_in_git_repo; then
        return 1
    fi
    
    echo -e "${CYAN}=== 本地分支列表 ===${NC}"
    
    # 获取当前分支名
    current_branch=$(get_current_branch_name)
    
    # 本地分支
    echo -e "${BOLD}本地分支:${NC}"
    git for-each-ref --sort=committerdate refs/heads/ --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))' | 
    while read -r branch; do
        if [[ $branch == "*"* ]]; then
            # 如果是当前分支，用绿色标记
            echo -e "${GREEN}$branch${NC}"
        else
            echo "$branch"
        fi
    done

    # 远程分支
    echo -e "\n${BOLD}远程分支:${NC}"
    git for-each-ref --sort=committerdate refs/remotes/ --format='%(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))' |
    grep -v "HEAD"
    
    return 0
}

# 切换分支
cmd_checkout() {
    if ! check_in_git_repo; then
        return 1
    fi

    local branch="$1"
    
    if [ -z "$branch" ]; then
        # 没有提供分支名，显示所有可选分支并交互式选择
        echo -e "${CYAN}可用分支:${NC}"
        branches=($(git branch --format="%(refname:short)" | sort))
        
        PS3="选择要切换的分支 (输入数字): "
        select branch_name in "${branches[@]}" "取消"; do
            if [ "$branch_name" = "取消" ]; then
                echo "已取消分支切换。"
                return 0
            elif [ -n "$branch_name" ]; then
                branch="$branch_name"
                break
            else
                echo "无效选择，请重试。"
            fi
        done
    fi
    
    # 检查是否有未提交的变更
    if check_uncommitted_changes || check_untracked_files; then
        echo -e "${YELLOW}⚠️ 警告：您有未提交的变更或未追踪的文件。${NC}"
        echo "1) 提交变更"
        echo "2) 暂存变更"
        echo "3) 放弃变更"
        echo "4) 保持变更并切换分支"
        echo "5) 取消操作"
        echo -n "请选择操作 [1-5]: "
        read -r choice
        
        case "$choice" in
            1)
                # 提交变更
                cmd_commit_all
                ;;
            2)
                # 暂存变更
                echo -e "${BLUE}正在暂存当前变更...${NC}"
                git stash save "Auto-stashed before checkout to $branch"
                ;;
            3)
                # 放弃变更
                if confirm_action "确定要放弃所有未提交的变更吗？这个操作不可逆！" "N"; then
                    echo -e "${BLUE}正在放弃变更...${NC}"
                    git reset --hard HEAD
                    git clean -fd
                else
                    echo "已取消。"
                    return 1
                fi
                ;;
            4)
                # 继续保持变更
                echo -e "${YELLOW}保持变更并尝试切换分支，如果有冲突可能会失败。${NC}"
                ;;
            5|*)
                echo "已取消分支切换。"
                return 1
                ;;
        esac
    fi
    
    # 执行分支切换
    echo -e "${BLUE}正在切换到分支 '$branch'...${NC}"
    git checkout "$branch"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}成功切换到分支 '$branch'${NC}"
        return 0
    else
        echo -e "${RED}切换分支失败，请检查分支名称或解决冲突。${NC}"
        return 1
    fi
}

# 创建并切换到新分支
cmd_new_branch() {
    # This function is now effectively replaced by gw_new().
    # Keep it here for now or remove it if cleanup is desired.
    # For safety, redirect calls to the new function or print a deprecation warning.
    echo -e "${YELLOW}警告: 'cmd_new_branch' 已被 'gw_new' 取代。请更新调用方式。${NC}"
    gw_new "$@" # Redirect to the new function
    return $?
}

# 删除分支
cmd_delete_branch() {
    if ! check_in_git_repo; then
        return 1
    fi

    local branch="$1"
    local force="$2"  # 是否强制删除
    
    if [ -z "$branch" ]; then
        # 没有提供分支名，显示所有可选分支并交互式选择
        current_branch=$(get_current_branch_name)
        echo -e "${CYAN}可删除的分支:${NC}"
        branches=($(git branch --format="%(refname:short)" | grep -v "^$current_branch$" | sort))
        
        if [ ${#branches[@]} -eq 0 ]; then
            echo "没有可删除的分支。"
            return 1
        fi
        
        PS3="选择要删除的分支 (输入数字): "
        select branch_name in "${branches[@]}" "取消"; do
            if [ "$branch_name" = "取消" ]; then
                echo "已取消分支删除操作。"
                return 0
            elif [ -n "$branch_name" ]; then
                branch="$branch_name"
                break
            else
                echo "无效选择，请重试。"
            fi
        done
    fi
    
    # 检查不能删除当前分支
    current_branch=$(get_current_branch_name)
    if [ "$branch" = "$current_branch" ]; then
        echo -e "${RED}错误：不能删除当前所在的分支。请先切换到其他分支。${NC}"
        return 1
    fi
    
    # 检查是否为主分支
    if [ "$branch" = "$MAIN_BRANCH" ]; then
        echo -e "${RED}错误：不能删除主分支。${NC}"
        return 1
    fi
    
    # 检查分支是否已合并
    is_merged=false
    if git branch --merged | grep -q "^..\?$branch$"; then
        is_merged=true
    fi
    
    # 根据是否已合并选择删除方式
    delete_flag="-d"  # 默认安全删除
    if [ "$force" = "force" ] || [ "$force" = "-f" ]; then
        delete_flag="-D"  # 强制删除
        echo -e "${YELLOW}⚠️ 警告：将强制删除分支 '$branch'，即使它包含未合并的更改。${NC}"
    elif [ "$is_merged" = false ]; then
        echo -e "${YELLOW}⚠️ 警告：分支 '$branch' 包含未合并到 '$current_branch' 的更改。${NC}"
        if confirm_action "是否要强制删除此分支？" "N"; then
            delete_flag="-D"  # 强制删除
        else
            echo "已取消分支删除操作。"
            return 1
        fi
    fi
    
    # 执行分支删除
    echo -e "${BLUE}正在删除分支 '$branch'...${NC}"
    git branch $delete_flag "$branch"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}成功删除分支 '$branch'${NC}"
        
        # 询问是否也删除远程分支
        if git ls-remote --heads "$REMOTE_NAME" "$branch" | grep -q "$branch"; then
            if confirm_action "是否同时删除远程分支 '$REMOTE_NAME/$branch'？" "N"; then
                echo -e "${BLUE}正在删除远程分支...${NC}"
                git push "$REMOTE_NAME" --delete "$branch"
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}成功删除远程分支 '$REMOTE_NAME/$branch'${NC}"
                else
                    echo -e "${RED}删除远程分支失败。${NC}"
                    return 1
                fi
            fi
        fi
        
        return 0
    else
        echo -e "${RED}删除分支失败。${NC}"
        return 1
    fi
}

# 删除本地分支 (新命令 gw rm)
cmd_rm_branch() {
    if ! check_in_git_repo; then return 1; fi

    local target="$1"
    local force=false
    local delete_remote=false # 暂不自动删除远程，保持与 cmd_delete_branch 逻辑一致，需要确认
    
    # 处理参数
    if [ -z "$target" ]; then
        echo -e "${RED}错误: 请指定要删除的分支名称或 'all'。${NC}"
        echo "用法: gw rm <分支名|all> [-f]"
        return 1
    fi
    shift # 移除 target 参数
    
    # 检查剩余参数是否有 -f
    for arg in "$@"; do
        if [ "$arg" = "-f" ] || [ "$arg" = "--force" ]; then
            force=true
            break
        fi
    done

    local current_branch
    current_branch=$(get_current_branch_name)
    if [ $? -ne 0 ]; then return 1; fi

    # --- 处理 gw rm all --- 
    if [ "$target" = "all" ]; then
        if [ "$current_branch" != "$MAIN_BRANCH" ]; then
            echo -e "${RED}错误: 'gw rm all' 只能在主分支 ($MAIN_BRANCH) 上执行以确保安全。${NC}"
            echo "您当前在分支 '$current_branch'。"
            return 1
        fi
        
        echo -e "${YELLOW}⚠️ 警告：即将删除除了 '$MAIN_BRANCH' 之外的所有本地分支！${NC}"
        
        # 使用 while read 替代 mapfile 提高兼容性
        local branches_to_delete=()
        while IFS= read -r branch_name; do
            # 过滤掉可能的空行
            if [ -n "$branch_name" ]; then
                branches_to_delete+=("$branch_name")
            fi
        done < <(git branch --format="%(refname:short)" | grep -v -e "^${MAIN_BRANCH}$" -e "^\* ${MAIN_BRANCH}$")
        
        # mapfile -t branches_to_delete < <(git branch --format="%(refname:short)" | grep -v -e "^${MAIN_BRANCH}$" -e "^\* ${MAIN_BRANCH}$")
        
        if [ ${#branches_to_delete[@]} -eq 0 ]; then
            echo "没有其他可删除的本地分支。"
            return 0
        fi
        
        echo "将要删除以下分支:"
        for b in "${branches_to_delete[@]}"; do echo " - $b"; done
        echo ""
        
        local confirm_msg="确认要删除这 ${#branches_to_delete[@]} 个本地分支吗？此操作不可逆！"
        if $force; then
            confirm_msg="强制删除模式 (-f): ${confirm_msg}"
        fi

        if ! confirm_action "$confirm_msg" "N"; then
            echo "已取消批量删除操作。"
            return 1
        fi
        
        local delete_flag="-d"
        if $force; then delete_flag="-D"; fi
        local success_count=0
        local fail_count=0
        
        echo -e "${BLUE}开始批量删除分支...${NC}"
        for branch in "${branches_to_delete[@]}"; do
            echo -n "删除分支 '$branch'... "
            if git branch $delete_flag "$branch"; then
                echo -e "${GREEN}成功${NC}"
                success_count=$((success_count + 1))
            else
                echo -e "${RED}失败${NC}"
                fail_count=$((fail_count + 1))
            fi
        done
        
        echo -e "${GREEN}批量删除完成。成功: $success_count, 失败: $fail_count ${NC}"
        if [ $fail_count -gt 0 ]; then
             echo -e "${YELLOW}提示: 删除失败的分支可能包含未合并的更改 (若未使用 -f) 或其他问题。${NC}"
             return 1 # 返回错误码表示部分失败
        fi
        return 0

    # --- 处理 gw rm <分支名> --- 
    else
        local branch="$target" # target 就是分支名
        
        # 不能删除当前分支
        if [ "$branch" = "$current_branch" ]; then
            echo -e "${RED}错误：不能删除当前所在的分支。请先切换到其他分支。${NC}"
            return 1
        fi
        
        # 不能删除主分支
        if [ "$branch" = "$MAIN_BRANCH" ]; then
            echo -e "${RED}错误：不能删除主分支 ($MAIN_BRANCH)。${NC}"
            return 1
        fi
        
        # 检查分支是否存在
        if ! git rev-parse --verify --quiet "refs/heads/$branch"; then
             echo -e "${RED}错误：本地分支 '$branch' 不存在。${NC}"
             return 1
        fi

        # 检查合并状态 (仅当非强制删除时)
        local delete_flag="-d"
        if $force; then
            delete_flag="-D"
            echo -e "${YELLOW}⚠️ 警告：将强制删除分支 '$branch'，即使它包含未合并的更改。${NC}"
        else
            # 检查是否已合并到当前分支
            # 注意：这里检查的是合并到 *当前* 分支，如果想检查合并到 main，需要切换或修改逻辑
            if ! git branch --merged | grep -q -E "(^|\s)${branch}$"; then
                 echo -e "${YELLOW}⚠️ 警告：分支 '$branch' 包含未合并到当前分支 ('$current_branch') 的更改。${NC}"
                 if confirm_action "是否要强制删除此分支？" "N"; then
                     delete_flag="-D" # 用户确认强制删除
                 else
                     echo "已取消分支删除操作。"
                     return 1
                 fi
            fi
        fi
        
        # 执行删除
        echo -e "${BLUE}正在删除本地分支 '$branch'...${NC}"
        if git branch $delete_flag "$branch"; then
            echo -e "${GREEN}成功删除本地分支 '$branch'${NC}"
            
            # 询问是否删除远程分支 (与 cmd_delete_branch 保持一致)
            if git ls-remote --heads "$REMOTE_NAME" "$branch" | grep -q "$branch"; then
                if confirm_action "是否同时删除远程分支 '$REMOTE_NAME/$branch'？" "N"; then
                    echo -e "${BLUE}正在删除远程分支...${NC}"
                    if git push "$REMOTE_NAME" --delete "$branch"; then
                        echo -e "${GREEN}成功删除远程分支 '$REMOTE_NAME/$branch'${NC}"
                    else
                        echo -e "${RED}删除远程分支失败。${NC}"
                        # 即使远程删除失败，本地删除已成功，返回成功码？还是失败？暂定返回成功
                    fi
                fi
            fi
            return 0
        else
            echo -e "${RED}删除本地分支失败。${NC}"
            return 1
        fi
    fi
}

# 获取状态摘要
cmd_status() {
    if ! check_in_git_repo; then
        return 1
    fi
    
    local fetch_remote=false
    local show_log=false
    # 解析参数
    local remaining_args=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -r|--remote)
                fetch_remote=true
                shift
                ;;
            -l|--log)
                show_log=true
                shift
                ;;
            *)
                # 保留无法识别的参数（如果需要传递给 git status 或其他）
                # 但对于 status，通常不需要其他参数
                echo -e "${YELLOW}警告: status 命令忽略未知参数: $1${NC}"
                shift
                ;;
        esac
    done
    
    if $fetch_remote; then
        echo -e "${BLUE}正在从远程仓库 '$REMOTE_NAME' 获取最新状态...${NC}"
        # 只在显式请求时才 fetch
        git fetch --quiet "$REMOTE_NAME"
        if [ $? -ne 0 ]; then
            echo -e "${YELLOW}警告: 从远程获取状态失败。可能无法看到最新的远程分支信息。${NC}"
        fi
    fi
    
    local current_branch
    current_branch=$(get_current_branch_name)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo -e "${CYAN}=== Git 本地仓库状态 ===${NC}" # 标题强调本地
    echo -e "${BOLD}当前分支:${NC} $current_branch"
    
    # 检查本地是否存在对应的远程跟踪分支信息
    local remote_branch_ref="refs/remotes/$REMOTE_NAME/$current_branch"
    if git show-ref --verify --quiet "$remote_branch_ref"; then
        local ahead_behind
        # 基于本地已有的信息进行比较，不自动 fetch
        ahead_behind=$(git rev-list --left-right --count "$current_branch...$remote_branch_ref" 2>/dev/null)
        if [ $? -eq 0 ]; then
            local ahead=$(echo "$ahead_behind" | awk '{print $1}')
            local behind=$(echo "$ahead_behind" | awk '{print $2}')
            
            local compare_info="与本地跟踪的 $REMOTE_NAME/$current_branch 比较:"
            if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
                compare_info+=" ${YELLOW}领先 $ahead, 落后 $behind${NC}"
            elif [ "$ahead" -gt 0 ]; then
                compare_info+=" ${GREEN}领先 $ahead${NC}"
            elif [ "$behind" -gt 0 ]; then
                compare_info+=" ${RED}落后 $behind${NC}"
            else
                compare_info+=" ${GREEN}已同步${NC}"
            fi
            echo -e "${BOLD}远程跟踪状态:${NC} $compare_info"
            
            if [ "$behind" -gt 0 ]; then
                echo -e "${YELLOW}  提示: 您的分支可能落后于远程，可执行 'gw fetch' 或 'gw pull' 更新。${NC}"
            fi
            if ! $fetch_remote ; then
                 echo -e "${PURPLE}  (此状态基于本地缓存，可能不是最新，使用 'gw status -r' 获取最新)${NC}"
        fi
    else
            echo -e "${BOLD}远程跟踪状态:${NC} ${YELLOW}无法计算与远程分支的差异 (也许刚 fetch 或有其他问题?) ${NC}"
        fi
    else
        # 检查分支是否是新建的且未推送
        if ! git log "$REMOTE_NAME/$current_branch..$current_branch" >/dev/null 2>&1; then 
             echo -e "${BOLD}远程跟踪状态:${NC} ${PURPLE}分支 '$current_branch' 尚未推送到远程 '$REMOTE_NAME' 或本地无跟踪信息${NC}"
        else
            # 如果远程分支不存在但本地有基于它的记录，说明可能远程分支已被删除
            echo -e "${BOLD}远程跟踪状态:${NC} ${YELLOW}远程分支 '$REMOTE_NAME/$current_branch' 可能已被删除或本地未同步${NC}"
        fi
       
    fi
    
    # 使用 'git status -sb' 获取更简洁的状态输出
    echo -e "\n${BOLD}本地变更详情 (git status -sb):${NC}"
    git status -sb
    
    # --- 只有在指定 -l/--log 时才显示日志和标签 ---
    if $show_log; then
    # 显示最近提交
        echo -e "\n${BOLD}最近提交 (-l):${NC}"
        # 使用更详细和彩色的格式
        git log -3 --pretty=format:"%C(yellow)%h%Creset %s %C(bold blue)<%an>%Creset %C(green)(%ar)%Creset%C(auto)%d%Creset"
    echo ""
    
    # 显示最近的标签
    latest_tag=$(git describe --tags --abbrev=0 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$latest_tag" ]; then
            echo -e "${BOLD}最近标签 (-l):${NC} $latest_tag"
        fi
    fi
    
    return 0
}

# 添加修改到暂存区
cmd_add() {
    if ! check_in_git_repo; then
        return 1
    fi
    
    local files=("$@")
    
    # 如果没有指定文件，提供交互式选择
    if [ ${#files[@]} -eq 0 ]; then
        echo -e "${CYAN}=== 选择要添加到暂存区的文件 ===${NC}"
        
        # 获取所有未暂存的和未追踪的文件
        mapfile -t unstaged_files < <(git diff --name-only)
        mapfile -t untracked_files < <(git ls-files --others --exclude-standard)
        
        local all_files=("${unstaged_files[@]}" "${untracked_files[@]}")
        
        if [ ${#all_files[@]} -eq 0 ]; then
            echo "没有可添加的文件。"
            return 0
        fi
        
        # 交互式选择文件
        local selected_files=()
        while IFS= read -r file; do
            selected_files+=("$file")
        done < <(interactive_select_files "选择要添加到暂存区的文件" "${all_files[@]}")
        
        if [ ${#selected_files[@]} -eq 0 ]; then
            echo "未选择任何文件，操作已取消。"
            return 1
        fi
        
        files=("${selected_files[@]}")
    fi
    
    # 添加所选文件到暂存区
    echo -e "${BLUE}正在添加文件到暂存区...${NC}"
    git add -- "${files[@]}"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}成功添加 ${#files[@]} 个文件到暂存区。${NC}"
        return 0
    else
        echo -e "${RED}添加文件失败。${NC}"
        return 1
    fi
}

# 添加所有修改到暂存区
cmd_add_all() {
    if ! check_in_git_repo; then
        return 1
    fi
    
    echo -e "${BLUE}正在添加所有变更到暂存区...${NC}"
    git add -A
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}成功添加所有变更到暂存区。${NC}"
        return 0
    else
        echo -e "${RED}添加变更失败。${NC}"
        return 1
    fi
}

# 提交变更
cmd_commit() {
    if ! check_in_git_repo; then
        return 1
    fi
    
    local message=""
    local add_all_flag=false
    local commit_args=()
    local use_standard_editor=false # 新增标志，默认不使用标准编辑器流程
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -m|--message)
                if [ -n "$2" ]; then
                    message="$2"
                    commit_args+=("-m" "$message")
                    shift 2
                else
                    echo -e "${RED}错误: -m/--message 选项需要一个参数。${NC}"
                    return 1
                fi
                ;;
            -a|--all)
                add_all_flag=true
                commit_args+=("-a") # git commit -a 会自动暂存已跟踪文件的修改和删除
    shift
                ;;
            -e|--editor)
                use_standard_editor=true # 明确要求使用标准编辑器流程
                shift
                ;;
            -F|--file)
                 # 如果使用 -F 或 --file，也认为是"非默认"行为，走标准流程
                 commit_args+=("$1") 
                 if [ -n "$2" ]; then
                     commit_args+=("$2")
                     shift 2
                 else
                     echo -e "${RED}错误: $1 选项需要一个文件参数。${NC}"
                     return 1
                 fi
                 use_standard_editor=true # 标记为非默认流程
                 ;;
            --amend)
                 commit_args+=("$1")
                 use_standard_editor=true # amend 通常需要编辑器或基于旧消息
                 shift
                 ;;
            # 你可以在这里添加更多 git commit 支持的参数处理，例如 -S 等
            *)
                # ... (处理未知参数或无选项消息的逻辑保持不变) ...
                 if [ -z "$message" ] && [[ ! "$1" =~ ^- ]]; then
                     if [ ${#commit_args[@]} -eq 0 ]; then
                        message="$*"
                        commit_args+=("-m" "$message")
                     fi
                     break 
                else
                    echo -e "${YELLOW}警告: 忽略未知或不支持的参数: $1 ${NC}"
                    shift
                fi
                ;;
        esac
    done
    
    # 如果指定了 -a 标志... (这部分暂存检查逻辑不变) ...
    if ! $add_all_flag; then
        if git diff --cached --quiet; then
             echo -e "${YELLOW}没有暂存的变更可提交。${NC}"
             return 1
        fi
    else
         if git diff --quiet && git diff --cached --quiet; then
              echo -e "${YELLOW}没有任何已跟踪的文件发生变更。${NC}"
              return 1
         fi
    fi
    
    # --- 根据是否需要标准编辑器流程决定如何提交 ---
    # 如果用户提供了 -m, -F, --file, --amend, 或 -e/--editor，则使用标准 git commit
    local use_non_default_commit=false
    if [[ " ${commit_args[*]} " =~ " -m " ]] || \
       [[ " ${commit_args[*]} " =~ " -F " ]] || \
       [[ " ${commit_args[*]} " =~ " --file " ]] || \
       [[ " ${commit_args[*]} " =~ " --amend " ]] || \
       $use_standard_editor; then
        use_non_default_commit=true
    fi

    if $use_non_default_commit; then
        echo -e "${BLUE}执行标准 git commit 流程 (可能打开编辑器)...${NC}"
        if git commit "${commit_args[@]}"; then
            echo -e "${GREEN}提交成功！${NC}"
            return 0
        else
             # ... (标准提交流程失败的处理) ...
             echo -e "${RED}提交失败或被取消。${NC}"
             if git diff --cached --quiet && ! $add_all_flag; then
                  echo -e "${YELLOW}原因可能是没有暂存任何变更。${NC}"
             elif $add_all_flag && git diff --quiet && git diff --cached --quiet; then
                  echo -e "${YELLOW}原因可能是没有任何已跟踪的文件发生变更。${NC}"
             fi
             return 1
        fi
    else
        # --- 执行新的默认流程：打印路径、暂停、再提交 --- 
        echo -e "${BLUE}准备提交信息文件供编辑...${NC}"
        local git_dir
        git_dir=$(git rev-parse --git-dir)
        if [ $? -ne 0 ] || [ -z "$git_dir" ]; then
            echo -e "${RED}错误：无法获取 .git 目录路径。${NC}"
            return 1
        fi
        local commit_msg_file="$git_dir/COMMIT_EDITMSG"
        
        # 准备提交信息文件模板
        # 清空旧文件（如果存在）
        > "$commit_msg_file"
        echo "" >> "$commit_msg_file" # 开头空行
        echo "# 请输入提交说明。以 '#' 开始的行将被忽略。" >> "$commit_msg_file"
        echo "#" >> "$commit_msg_file"
        echo "# 暂存的变更：" >> "$commit_msg_file"
        git diff --cached --name-status | sed 's/^/# /' >> "$commit_msg_file"
        # 如果是 commit -a? (目前 commit -a 会走标准流程，不进这里)
        
        echo -e "${YELLOW}请在你的编辑器中打开并编辑以下文件以输入提交信息:${NC}"
        echo -e "  ${BOLD}$commit_msg_file${NC}"
        echo -e "(在 macOS 上，你可以尝试 ${BOLD}Cmd + 点击${NC} 上面的路径快速打开)"
        echo -e -n "${CYAN}编辑完成后，请按 Enter 键继续提交... (按 Ctrl+C 取消提交)${NC}"
        read -r # 等待用户按 Enter

        # 检查用户是否真的编辑了文件
        if ! grep -v -q -E '^#|^$' "$commit_msg_file"; then
            echo -e "${RED}错误：提交信息文件为空或只包含注释行。提交已取消。${NC}"
            rm -f "$commit_msg_file" # 清理模板文件
            return 1
        fi

        # --- 新增：清理 COMMIT_EDITMSG 中的注释行和模板提示行 ---
        local cleaned_commit_msg_file="${commit_msg_file}.cleaned"
        grep -v -E '^#|请输入提交说明|暂存的变更' "$commit_msg_file" | sed '/^$/N;/^\n$/D' > "$cleaned_commit_msg_file" # 移除#开头的行、模板提示和多余的空行

        # 检查清理后的文件是否还有实际内容
        if ! grep -v -q -E '^$' "$cleaned_commit_msg_file"; then
            echo -e "${RED}错误：清理后的提交信息为空。提交已取消。${NC}"
            rm -f "$commit_msg_file" "$cleaned_commit_msg_file"
            return 1
        fi

        echo -e "${BLUE}使用编辑并清理后的文件继续提交...${NC}"
        if git commit --file="$cleaned_commit_msg_file" "${commit_args[@]}"; then 
            echo -e "${GREEN}提交成功！${NC}"
            rm -f "$cleaned_commit_msg_file" # Git 成功后会删 COMMIT_EDITMSG，我们删掉清理后的
            # Git 成功提交后会自动清理 COMMIT_EDITMSG, 如果原始文件还在也应该清理
            if [ -f "$commit_msg_file" ]; then
                 rm -f "$commit_msg_file"
            fi
            return 0
        else
            echo -e "${RED}使用编辑后的文件提交失败。${NC}"
            echo -e "${YELLOW}原始提交信息文件仍保留在: $commit_msg_file${NC}"
            echo -e "${YELLOW}清理后的提交信息文件仍保留在: $cleaned_commit_msg_file${NC}"
            echo "你可以检查文件内容和暂存区状态 ('git status')。"
            return 1
        fi
    fi
}

# 合并分支
cmd_merge() {
    if ! check_in_git_repo; then return 1; fi
    
    local source_branch="$1"
    local current_branch
    current_branch=$(get_current_branch_name)
    if [ $? -ne 0 ]; then return 1; fi
    
    if [ -z "$source_branch" ]; then
        echo -e "${RED}错误: 请指定要合并到 '$current_branch' 的来源分支。${NC}"
        echo "用法: gw merge <来源分支> [git merge 的其他参数...]"
        return 1
    fi
    
    # 检查是否有未提交的变更
    if check_uncommitted_changes || check_untracked_files; then
        echo -e "${YELLOW}警告: 检测到未提交的变更或未追踪的文件。${NC}"
        echo "合并前建议先提交或暂存变更。"
        if ! confirm_action "是否仍要继续合并？"; then
            echo "合并操作已取消。"
            return 1
        fi
    fi
    
    echo -e "${BLUE}准备将分支 '$source_branch' 合并到 '$current_branch'...${NC}"
    shift # 移除已处理的 source_branch 参数
    
    # 执行 git merge，并将剩余参数传递过去
    if git merge "$source_branch" "$@"; then
        echo -e "${GREEN}成功将 '$source_branch' 合并到 '$current_branch'。${NC}"
        return 0
    else
        echo -e "${RED}合并 '$source_branch' 时遇到冲突或失败。${NC}"
        echo -e "请解决冲突后手动提交。你可以使用 'git status' 查看冲突文件。"
        echo -e "解决冲突后，运行 'gw add <冲突文件>' 然后 'gw commit'。"
        echo -e "如果想中止合并，可以运行 'git merge --abort'。"
        return 1
    fi
}

# 从远程获取更新 (不合并)
cmd_fetch() {
    if ! check_in_git_repo; then return 1; fi
    
    local remote=${1:-$REMOTE_NAME} # 默认使用 origin
    local fetch_args=()
    
    # 如果指定了远程名，则从参数中移除它
    if [ "$1" = "$remote" ]; then
        shift
    fi
    
    fetch_args=("$remote" "$@") # 包含远程名和所有其他 git fetch 参数
    
    echo -e "${BLUE}正在从远程仓库 '$remote' 获取最新信息...${NC}"
    if git fetch "${fetch_args[@]}"; then
        echo -e "${GREEN}成功从 '$remote' 获取更新。${NC}"
        # 可以考虑在这里显示一些 fetch 的摘要信息
        # git fetch --verbose "${fetch_args[@]}"
        return 0
    else
        echo -e "${RED}从 '$remote' 获取更新失败。${NC}"
        return 1
    fi
}

# 显示差异
cmd_diff() {
    if ! check_in_git_repo; then return 1; fi
    
    # 直接将所有参数传递给 git diff
    # 用户可以自行添加 --cached, 文件路径等
    git diff "$@"
    # git diff 的退出码通常为 0 (无差异) 或 1 (有差异)，我们不视为脚本错误
    return 0 
}

# 显示提交历史
cmd_log() {
    if ! check_in_git_repo; then return 1; fi
    
    # 直接将所有参数传递给 git log
    # 为了更好的分页体验，检测是否在 TTY 环境，如果是，则使用 less
    if [ -t 1 ]; then # 检查 stdout 是否连接到终端
        git log --color=always "$@" | less -R
    else
        git log "$@"
    fi
    # git log 的退出码我们不视为脚本错误
    return 0
}

# 同步当前分支 (拉取主分支最新代码并 rebase)
cmd_sync() {
    if ! check_in_git_repo; then return 1; fi

    local original_branch
    original_branch=$(get_current_branch_name)
    if [ $? -ne 0 ]; then return 1; fi

    if [ "$original_branch" = "$MAIN_BRANCH" ]; then
        echo -e "${YELLOW}您已在主分支 ($MAIN_BRANCH)。正在尝试拉取最新代码...${NC}"
        if git pull "$REMOTE_NAME" "$MAIN_BRANCH"; then
            echo -e "${GREEN}主分支已更新。${NC}"
            return 0
        else
            echo -e "${RED}拉取主分支更新失败。${NC}"
            return 1
        fi
    fi

    echo -e "${CYAN}=== 同步当前分支 ('$original_branch') ===${NC}"

    # 1. 检查未提交的变更
    local stash_needed=false
    if check_uncommitted_changes || check_untracked_files; then
        echo -e "${YELLOW}检测到未提交的变更或未追踪的文件。${NC}"
        echo "在同步操作前，建议先处理这些变更。"
        echo "1) 暂存 (stash) 变更并在同步后尝试恢复"
        echo "2) 提交变更"
        echo "3) 取消同步"
        echo -n "请选择操作 [1-3]: "
        read -r choice
        
        case "$choice" in
            1)
                echo -e "${BLUE}正在暂存当前变更...${NC}"
                if git stash save "Auto-stash before sync on $original_branch"; then
                    stash_needed=true
                else
                    echo -e "${RED}暂存失败，同步已取消。${NC}"
                    return 1
                fi
                ;;
            2)
                echo -e "${BLUE}请提交您的变更。${NC}"
                cmd_commit # 让用户提交
                if [ $? -ne 0 ]; then
                    echo -e "${RED}提交失败或被取消，同步已取消。${NC}"
                    return 1
                fi
                ;;
            3|*)
                echo "同步操作已取消。"
                return 1
                ;;
        esac
    fi

    # 2. 切换到主分支
    echo -e "${BLUE}切换到主分支 ($MAIN_BRANCH)...${NC}"
    if ! git checkout "$MAIN_BRANCH"; then
        echo -e "${RED}切换到主分支失败。请检查您的工作区状态。${NC}"
        # 如果之前暂存了，尝试恢复
        if $stash_needed; then
            echo -e "${YELLOW}正在尝试恢复之前暂存的变更...${NC}"
            git stash pop
        fi
        return 1
    fi

    # 3. 拉取主分支最新代码
    echo -e "${BLUE}正在从远程 '$REMOTE_NAME' 拉取主分支 ($MAIN_BRANCH) 的最新代码...${NC}"
    # if ! git pull "$REMOTE_NAME" "$MAIN_BRANCH"; then
    if ! do_pull_with_retry "$REMOTE_NAME" "$MAIN_BRANCH"; then
        echo -e "${RED}拉取主分支更新失败。${NC}"
        echo -e "${BLUE}正在切换回原分支 '$original_branch'...${NC}"
        git checkout "$original_branch"
        # 如果之前暂存了，尝试恢复
        if $stash_needed; then
            echo -e "${YELLOW}正在尝试恢复之前暂存的变更...${NC}"
            git stash pop
        fi
        return 1
    fi
    echo -e "${GREEN}主分支已更新。${NC}"

    # 4. 切换回原分支
    echo -e "${BLUE}切换回原分支 '$original_branch'...${NC}"
    if ! git checkout "$original_branch"; then
        echo -e "${RED}切换回原分支 '$original_branch' 失败。${NC}"
        echo -e "${YELLOW}您的代码仍在最新的主分支上。请手动切换。${NC}"
         # 如果之前暂存了，需要提示用户手动恢复
        if $stash_needed; then
            echo -e "${YELLOW}请注意：您之前暂存的变更需要手动恢复 (git stash pop)。${NC}"
        fi
        return 1
    fi

    # 5. Rebase 当前分支到主分支
    echo -e "${BLUE}正在将当前分支 '$original_branch' Rebase 到最新的 '$MAIN_BRANCH'...${NC}"
    if git rebase "$MAIN_BRANCH"; then
        echo -e "${GREEN}成功将 '$original_branch' Rebase 到 '$MAIN_BRANCH'。${NC}"
    else
        echo -e "${RED}Rebase 操作失败或遇到冲突。${NC}"
        echo -e "请解决 Rebase 冲突。"
        echo -e "解决冲突后，运行 'gw add <冲突文件>' 然后 'git rebase --continue'。"
        echo -e "如果想中止 Rebase，可以运行 'git rebase --abort'。"
        # Rebase 失败时，暂存的变更不自动恢复，因为可能与 Rebase 冲突
        if $stash_needed; then
             echo -e "${YELLOW}请注意：您之前暂存的变更在 Rebase 成功后需要手动恢复 (git stash pop)。${NC}"
        fi
                return 1
            fi

    # 6. 如果之前暂存了，尝试恢复
    if $stash_needed; then
        echo -e "${BLUE}正在尝试恢复之前暂存的变更...${NC}"
        if git stash pop; then
            echo -e "${GREEN}成功恢复暂存的变更。${NC}"
        else
            echo -e "${RED}自动恢复暂存失败。可能存在冲突。${NC}"
            echo -e "请运行 'git status' 查看详情，并手动解决冲突。未恢复的暂存在 'git stash list' 中。"
            # 即使 pop 失败，同步的主要流程已完成，返回成功码？或者返回错误码？暂定返回成功
        fi
    fi

    echo -e "${GREEN}=== 分支 '$original_branch' 同步完成 ===${NC}"
    return 0
}

# 快速保存变更 (add + commit)
cmd_save() {
    if ! check_in_git_repo; then return 1; fi

    local message=""
    local files_to_add=() # 存储要添加的文件
    local commit_args=() # 存储最终传递给 git commit 的参数
    local add_all=true # 默认添加所有变更
    local use_standard_editor=false # 新增标志

    # 解析参数，区分 -m, -e 和文件路径
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -m|--message)
                # ... (-m 处理不变) ...
                 if [ -n "$2" ]; then
                    message="$2"
                    commit_args+=("-m" "$message")
                    shift 2 
                else
                    echo -e "${RED}错误: -m/--message 选项需要一个参数。${NC}"
                    echo "用法: gw save [-m \"提交消息\"] [-e] [文件...]"
            return 1
        fi
                ;;
            -e|--editor)
                use_standard_editor=true # 明确要求使用标准编辑器流程
                shift
                ;;
            -*)
                echo -e "${RED}错误: 'save' 命令不支持选项 '$1'。${NC}"
                echo "用法: gw save [-m \"提交消息\"] [-e] [文件...]"
                return 1
                ;;
            *)
                # ... (文件处理不变) ...
                 add_all=false 
                 files_to_add+=("$1")
                 shift
                ;;
        esac
    done

    echo -e "${BLUE}正在准备保存变更...${NC}"
    
    # 1. 添加变更 (逻辑不变)
    if $add_all; then
        # ... (add -A) ...
         echo -e "${BLUE}正在添加所有变更到暂存区...${NC}"
         git add -A
         if [ $? -ne 0 ]; then
             echo -e "${RED}快速保存失败：添加所有变更时出错。${NC}"
             return 1
         fi
    elif [ ${#files_to_add[@]} -gt 0 ]; then
        # ... (add 指定文件) ...
         echo -e "${BLUE}正在添加指定文件到暂存区: ${files_to_add[*]}${NC}"
         git add -- "${files_to_add[@]}"
         if [ $? -ne 0 ]; then
             echo -e "${RED}快速保存失败：添加指定文件时出错。${NC}"
             return 1
         fi
    else
        # ... (无文件处理不变) ...
         echo -e "${YELLOW}没有指定要保存的文件，也没有添加所有变更。${NC}"
         return 1 
    fi
    
    # 2. 检查是否有实际变更被暂存 (逻辑不变)
    if git diff --cached --quiet; then
        # ... (无暂存变更处理不变) ...
         if $add_all; then
             echo -e "${YELLOW}没有检测到需要保存的变更。${NC}"
         else
             echo -e "${YELLOW}指定的文件没有变更或未能添加到暂存区。${NC}"
         fi
         return 0
    fi

    # 3. 提交
    echo -e "${BLUE}准备提交暂存的变更...${NC}"
    local use_non_default_commit=false
    # save 命令不处理 -F, --file, --amend，只看是否有 -m 或 -e
    if [[ " ${commit_args[*]} " =~ " -m " ]] || $use_standard_editor; then
        use_non_default_commit=true
    fi

    if $use_non_default_commit; then
        # 使用标准流程 (如果 commit_args 为空，则 git commit 会打开编辑器)
        echo -e "${BLUE}执行标准 git commit 流程 (可能打开编辑器)...${NC}"
        if git commit "${commit_args[@]}"; then
            echo -e "${GREEN}快速保存成功！${NC}"
            return 0
        else
            echo -e "${RED}快速保存失败：提交时出错或被取消。${NC}"
            return 1
        fi
    else
        # --- 执行新的默认流程：打印路径、暂停、再提交 --- 
        local git_dir
        git_dir=$(git rev-parse --git-dir)
        if [ $? -ne 0 ] || [ -z "$git_dir" ]; then
            echo -e "${RED}错误：无法获取 .git 目录路径。${NC}"
            return 1
        fi
        local commit_msg_file="$git_dir/COMMIT_EDITMSG"
        
        # 准备提交信息文件模板
        > "$commit_msg_file"
        echo "" >> "$commit_msg_file"
        echo "# 请输入提交说明。以 '#' 开始的行将被忽略。" >> "$commit_msg_file"
        echo "#" >> "$commit_msg_file"
        echo "# 暂存的变更：" >> "$commit_msg_file"
        git diff --cached --name-status | sed 's/^/# /' >> "$commit_msg_file"
        
        echo -e "${YELLOW}请在你的编辑器中打开并编辑以下文件以输入提交信息:${NC}"
        echo -e "  ${BOLD}$commit_msg_file${NC}"
        echo -e "(在 macOS 上，你可以尝试 ${BOLD}Cmd + 点击${NC} 上面的路径快速打开)"
        echo -e -n "${CYAN}编辑完成后，请按 Enter 键继续提交... (按 Ctrl+C 取消提交)${NC}"
        read -r 

        # 检查用户是否真的编辑了文件 (移除了所有#或空行，或添加了非注释内容)
        if ! grep -v -q -E '^#|^$' "$commit_msg_file"; then
            echo -e "${RED}错误：提交信息文件为空或只包含注释行。提交已取消。${NC}"
            rm -f "$commit_msg_file" # 清理模板文件
            return 1
        fi

        # --- 新增：清理 COMMIT_EDITMSG 中的注释行 ---
        local cleaned_commit_msg_file="${commit_msg_file}.cleaned"
        grep -v '^#' "$commit_msg_file" | sed '/^$/N;/^\n$/D' > "$cleaned_commit_msg_file" # 移除#开头的行和多余的空行

        # 检查清理后的文件是否还有实际内容
        if ! grep -v -q -E '^$' "$cleaned_commit_msg_file"; then
            echo -e "${RED}错误：清理后的提交信息为空。提交已取消。${NC}"
            rm -f "$commit_msg_file" "$cleaned_commit_msg_file"
            return 1
        fi

        echo -e "${BLUE}使用编辑并清理后的文件继续提交...${NC}"
        if git commit --file="$cleaned_commit_msg_file" "${commit_args[@]}"; then 
            echo -e "${GREEN}提交成功！${NC}"
            rm -f "$cleaned_commit_msg_file" # Git 成功后会删 COMMIT_EDITMSG，我们删掉清理后的
            # Git 成功提交后会自动清理 COMMIT_EDITMSG, 如果原始文件还在也应该清理
            if [ -f "$commit_msg_file" ]; then
                 rm -f "$commit_msg_file"
            fi
            return 0
        else
            echo -e "${RED}使用编辑后的文件提交失败。${NC}"
            echo -e "${YELLOW}原始提交信息文件仍保留在: $commit_msg_file${NC}"
            echo -e "${YELLOW}清理后的提交信息文件仍保留在: $cleaned_commit_msg_file${NC}"
            echo "你可以检查文件内容和暂存区状态 ('git status')。"
            return 1
        fi
    fi
}

# 完成当前分支工作 (准备 PR/MR)
cmd_finish() {
    if ! check_in_git_repo; then return 1; fi

    local no_switch=false
    local do_pr=false # <--- 新增: 标记是否创建 PR

    # 检查参数
    for arg in "$@"; do
        case "$arg" in
            --no-switch|-n)
                no_switch=true
                ;;
            --pr|-p) # <--- 新增: 支持 PR 参数
                do_pr=true
                ;;
            *)
                # 更新警告信息，包含新的支持参数
                echo -e "${YELLOW}警告: 'finish' 命令当前只支持 '-n/--no-switch' 和 '-p/--pr' 参数，忽略其他参数: $arg ${NC}"
                ;;
        esac
    done
    # 如果有其他不支持的参数，可以给出警告或错误
    # 这段逻辑现在由上面的 case "*" 处理，可以简化或移除，但为了确保所有情况都被覆盖，暂时保留注释掉的旧逻辑框架
    # if [ $# -gt 0 ] && ! $no_switch && ! $do_pr; then
    #      # 复杂的参数检查，确保只接受了支持的参数
    #      local valid_args=0
    #      if $no_switch; then ((valid_args++)); fi
    #      if $do_pr; then ((valid_args++)); fi
    #      if [ $# -ne $valid_args ]; then
    #          echo -e "${YELLOW}警告: 'finish' 命令当前只支持 '-n'/'--no-switch' 和 '-p'/'--pr' 参数，忽略其他参数: $@ ${NC}"
    #      fi
    # fi

    local current_branch
    current_branch=$(get_current_branch_name)
    if [ $? -ne 0 ]; then return 1; fi

    if [ "$current_branch" = "$MAIN_BRANCH" ]; then
        echo -e "${YELLOW}警告: 您当前在主分支 ($MAIN_BRANCH)。'finish' 命令通常用于功能分支。${NC}"
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
        echo "1) 提交所有变更"
        echo "2) 暂存变更 (不推荐，推送后 PR 中不包含)"
        echo "3) 取消完成操作"
        echo -n "请选择操作 [1-3]: "
        read -r choice

        case "$choice" in
            1)
                echo -e "${BLUE}请提交您的变更。${NC}"
                # 使用 cmd_commit -a 模式尝试自动添加并提交
                # 或者直接调用 cmd_commit 让用户在编辑器处理
                # 这里选择调用 cmd_commit -a，如果用户需要更精细控制会取消
                if ! cmd_commit -a; then # 尝试添加所有已跟踪文件并提交
                   # 如果 cmd_commit -a 失败 (可能因为用户取消，或没有变更，或只想提交部分)
                   # 再次检查状态，如果仍有未提交变更则提示并退出
                   if check_uncommitted_changes || check_untracked_files; then
                       echo -e "${RED}提交失败或变更未完全处理。请手动提交或暂存后再试。${NC}"
                       return 1
                   fi
                fi
                echo -e "${GREEN}变更已提交。${NC}"
                ;;
            2)
                echo -e "${BLUE}正在暂存变更...${NC}"
                if git stash save "Stashed before finishing branch $current_branch"; then
                    echo -e "${YELLOW}警告: 变更已暂存，不会包含在本次推送和 PR 中。${NC}"
                else
                    echo -e "${RED}暂存失败，操作已取消。${NC}"
            return 1
        fi
                ;;
            3|*)
                echo "完成操作已取消。"
                return 1
                ;;
        esac
    else
        echo -e "${GREEN}未检测到需要提交的变更。${NC}"
    fi

    # 2. 推送当前分支 (使用 do_push_with_retry，它会自动处理 -u)
    echo -e "${BLUE}准备推送当前分支 '$current_branch' 到远程 '$REMOTE_NAME'...${NC}"
    # 调用时不带参数，do_push_with_retry 会自动推当前分支并设置上游
    if ! do_push_with_retry; then
        echo -e "${RED}推送分支失败。请检查错误信息。${NC}"
        return 1
    fi

    echo -e "${GREEN}分支 '$current_branch' 已成功推送到远程。${NC}"
    # --- 新增: 创建 Pull Request ---
    if $do_pr; then
        if ! command -v gh >/dev/null 2>&1; then
            echo -e "${RED}错误: 未检测到 GitHub CLI (gh)。请安装并配置 'gh' 后再使用 --pr 功能。${NC}"
            echo -e "${CYAN}您仍然需要手动前往 GitHub 创建 Pull Request。${NC}"
        else
            echo -e "${BLUE}正在通过 GitHub CLI 创建 Pull Request...${NC}"
            # 自动从当前分支创建到 MAIN_BRANCH 的 PR，并填充信息
            # 用户可以修改 --title 和 --body 来定制 PR 的标题和内容
            # --fill 会使用提交信息自动填充
            if gh pr create --base "$MAIN_BRANCH" --head "$current_branch" --fill; then
                echo -e "${GREEN}Pull Request 创建成功。${NC}"
            else
                echo -e "${RED}Pull Request 创建失败。请手动检查或尝试在浏览器中创建。${NC}"
                echo -e "${CYAN}您可能需要运行 'gh auth login' 或检查 'gh' 的配置。${NC}"
            fi
        fi
    else
        echo -e "${CYAN}现在您可以前往 GitHub/GitLab 等平台基于 '$current_branch' 创建 Pull Request / Merge Request。${NC}"
        echo -e "${PURPLE}(提示: 下次可以使用 'gw finish --pr' 来尝试自动创建 GitHub PR)${NC}"
    fi
    # --- 结束: 创建 Pull Request ---

    # 3. 询问是否切回主分支 (除非指定了 --no-switch)
    if ! $no_switch && [ "$current_branch" != "$MAIN_BRANCH" ]; then
        if confirm_action "是否要切换回主分支 ($MAIN_BRANCH) 并拉取更新？"; then
            echo -e "${BLUE}正在切换到主分支 '$MAIN_BRANCH'...${NC}"
            if git checkout "$MAIN_BRANCH"; then
                echo -e "${BLUE}正在拉取主分支最新代码...${NC}"
                # if git pull "$REMOTE_NAME" "$MAIN_BRANCH"; then
                if do_pull_with_retry "$REMOTE_NAME" "$MAIN_BRANCH"; then
                    echo -e "${GREEN}已成功切换到主分支并更新。${NC}"
                else
                    echo -e "${YELLOW}已切换到主分支，但拉取更新失败。请稍后手动执行 'gw pull'。${NC}"
                fi
            else
                echo -e "${RED}切换到主分支失败。请保持在当前分支 '$current_branch'。${NC}"
            fi
        fi
    fi

    echo -e "${GREEN}=== 分支 '$current_branch' 完成工作流结束 ===${NC}"
    return 0
}
# 清理已合并的分支 (切换到主分支, 拉取, 删除本地和远程)
cmd_clean_branch() {
    if ! check_in_git_repo; then return 1; fi

    local target_branch="$1"
    local force=false # clean 命令默认不强制删除，依赖 rm 的合并检查

    if [ -z "$target_branch" ]; then
        echo -e "${RED}错误: 请指定要清理的分支名称。${NC}"
        echo "用法: gw clean <已合并的分支名>"
        return 1
    fi
    
    if [ "$target_branch" = "$MAIN_BRANCH" ]; then
         echo -e "${RED}错误: 不能清理主分支 ($MAIN_BRANCH)。${NC}"
         return 1
    fi
    
    # 检查是否有多余参数 (暂不支持 -f)
    if [ $# -gt 1 ]; then
         echo -e "${YELLOW}警告: 'clean' 命令当前不接受除分支名外的其他参数，已忽略。${NC}"
    fi

    echo -e "${CYAN}=== 清理分支 '$target_branch' ===${NC}"

    local current_branch
    current_branch=$(get_current_branch_name)
    if [ $? -ne 0 ]; then return 1; fi
    local stash_needed=false

    # 1. 如果当前不在主分支，先切换到主分支
    if [ "$current_branch" != "$MAIN_BRANCH" ]; then
        echo -e "${BLUE}当前不在主分支，准备切换到 '$MAIN_BRANCH'...${NC}"
        # 检查未提交变更
        if check_uncommitted_changes || check_untracked_files; then
            echo -e "${YELLOW}检测到未提交的变更。在切换前需要处理:${NC}"
            echo "1) 暂存变更"
            echo "2) 取消清理"
            echo -n "请选择 [1-2]: "
            read -r choice
            if [ "$choice" = "1" ]; then
                 echo -e "${BLUE}正在暂存...${NC}"
                 if ! git stash save "Auto-stash before cleaning branch $target_branch"; then
                     echo -e "${RED}暂存失败，清理操作取消。${NC}"
                     return 1
                 fi
                 stash_needed=true
            else
                 echo "清理操作已取消。"
                 return 1
            fi
        fi
        # 执行切换
        if ! git checkout "$MAIN_BRANCH"; then
             echo -e "${RED}切换到主分支失败。请检查工作区状态。${NC}"
             if $stash_needed; then git stash pop; fi # 尝试恢复
             return 1
        fi
        echo -e "${GREEN}已切换到主分支 '$MAIN_BRANCH'。${NC}"
    fi

    # 2. 拉取主分支最新代码
    echo -e "${BLUE}正在从远程 '$REMOTE_NAME' 更新主分支 '$MAIN_BRANCH'...${NC}"
    if ! do_pull_with_retry "$REMOTE_NAME" "$MAIN_BRANCH"; then
        echo -e "${RED}拉取主分支更新失败。${NC}"
        # 即使拉取失败，也可能继续尝试删除分支？或者中止？暂定中止
        if $stash_needed; then git stash pop; fi # 尝试恢复
        return 1
    fi
    echo -e "${GREEN}主分支已是最新。${NC}"

    # 3. 删除目标分支 (使用 cmd_rm_branch 的逻辑，但不带 all)
    echo -e "${BLUE}准备删除分支 '$target_branch'...${NC}"
    # 注意：cmd_rm_branch 内部会检查分支是否存在、是否是当前（现在不可能是了）、是否是主分支
    # 它还会检查合并状态（默认 -d），并询问是否删除远程
    if cmd_rm_branch "$target_branch"; then
        echo -e "${GREEN}分支 '$target_branch' 清理完成。${NC}"
    else
        echo -e "${RED}分支 '$target_branch' 清理过程中删除步骤失败。请检查上面的错误信息。${NC}"
        if $stash_needed; then git stash pop; fi # 尝试恢复
        return 1
    fi
    
    # 4. 如果之前暂存了，尝试恢复
    if $stash_needed; then
        echo -e "${BLUE}正在尝试恢复之前暂存的变更...${NC}"
        if git stash pop; then
            echo -e "${GREEN}成功恢复暂存的变更。${NC}"
        else
            echo -e "${RED}自动恢复暂存失败。可能存在冲突。请手动处理 (git stash list)。${NC}"
        fi
    fi

    return 0
}

# 创建并切换到新分支 (函数名改为 gw_new 以匹配调用约定)
gw_new() {
    local new_branch_name="$1"
    local local_flag=false
    local base_branch_param=""

    # 解析参数，处理 --local 标志和可选的基础分支
    if [[ "$2" == "--local" ]]; then
        local_flag=true
        base_branch_param="$3" # 基础分支是第三个参数
    elif [[ "$1" && "$2" && ! "$2" =~ ^- ]]; then
        # 如果第二个参数不是选项，认为是基础分支
        base_branch_param="$2"
    # else # 如果只有新分支名，base_branch_param 保持空
    fi

    # 如果未提供新分支名
    if [[ -z "$new_branch_name" ]]; then
        print_error "错误：需要提供新分支名称。"
        show_help # Use print_error and show_help for consistency
        return 1
    fi

    # 验证分支名是否有效 (使用 print_error)
    if ! git check-ref-format --branch "$new_branch_name"; then
        print_error "错误：无效的分支名称 '$new_branch_name'。"
        return 1
    fi

    # 确定基础分支 (使用 main_branch_name 变量)
    local base_branch=${base_branch_param:-$MAIN_BRANCH} # Use the determined MAIN_BRANCH variable
    print_info "将基于分支 '${base_branch}' 创建新分支 '${new_branch_name}'."

    # --- BEGIN MODIFIED COMMENT ---
    # 检查基础分支是否存在于本地或远程。如果只在远程存在，尝试获取它。
    # 如果指定了 --local，我们假设基础分支在本地是存在的，因为我们不打算拉取。
    # --- END MODIFIED COMMENT ---
    local base_branch_exists_locally=false
    if git rev-parse --verify --quiet "refs/heads/$base_branch" > /dev/null 2>&1; then
        base_branch_exists_locally=true
    fi

    if ! $base_branch_exists_locally && ! $local_flag; then
        # 如果本地不存在且不是 local 模式，尝试从远程获取
        if git rev-parse --verify --quiet "refs/remotes/$REMOTE_NAME/$base_branch" > /dev/null 2>&1; then
            print_warning "警告：本地不存在基础分支 '${base_branch}'，但远程存在。尝试从远程获取..."
            # 尝试只 fetch 这个特定的分支引用
            if ! git fetch "$REMOTE_NAME" "$base_branch":"refs/remotes/$REMOTE_NAME/$base_branch"; then
                 print_error "错误：无法从远程 '${REMOTE_NAME}' 获取基础分支 '${base_branch}' 的引用。"
                 return 1
            fi
            # 创建本地跟踪分支
             if ! git branch "$base_branch" "refs/remotes/$REMOTE_NAME/$base_branch"; then
                 print_error "错误：创建本地跟踪分支 '${base_branch}' 失败。"
                 return 1
             fi
            print_success "成功获取并创建本地基础分支 '${base_branch}'。"
            base_branch_exists_locally=true
        else
            print_error "错误：基础分支 '${base_branch}' 在本地和远程 '${REMOTE_NAME}' 都不存在。"
            return 1
        fi
    elif ! $base_branch_exists_locally && $local_flag; then
         print_error "错误：--local 模式要求基础分支 '${base_branch}' 必须在本地存在。"
         return 1
    fi

    # 切换到基础分支 (现在确保它本地存在)
    print_step "1/3: 切换到基础分支 '${base_branch}'..."
    if ! git checkout "$base_branch"; then
        print_error "错误：切换到基础分支 '${base_branch}' 失败。"
        return 1
    fi
    print_success "已切换到基础分支 '${base_branch}'。"

    # 如果不是 --local 模式，则拉取最新代码
    if [[ "$local_flag" == false ]]; then
        print_step "2/3: 拉取基础分支 '${base_branch}' 的最新代码..."
        # 使用带重试的 pull，并指定 rebase
        if ! do_pull_with_retry --rebase "$REMOTE_NAME" "$base_branch"; then
            print_error "错误：从 '${REMOTE_NAME}/${base_branch}' 拉取代码 (rebase) 失败。"
            print_warning "请检查网络连接或手动解决冲突后重试。"
            # 停留在基础分支让用户解决
            return 1
        fi
        print_success "基础分支 '${base_branch}' 已更新至最新。"
    else
        print_step "2/3: 跳过拉取最新代码 (--local 模式)。基础分支状态为本地当前状态。" # 更清晰的提示
    fi

    # 创建并切换到新分支
    print_step "3/3: 创建并切换到新分支 '${new_branch_name}'..."
    if git rev-parse --verify --quiet "refs/heads/$new_branch_name" > /dev/null 2>&1; then
         print_warning "警告：分支 '${new_branch_name}' 已存在。将直接切换到该分支。"
         if ! git checkout "$new_branch_name"; then
             print_error "错误：切换到已存在的分支 '${new_branch_name}' 失败。"
             return 1
         fi
    else
        if ! git checkout -b "$new_branch_name"; then
            print_error "错误：创建并切换到新分支 '${new_branch_name}' 失败。"
            # 这里可以尝试切换回基础分支以保持状态一致性
            git checkout "$base_branch"
            return 1
        fi
    fi

    print_success "操作完成！已创建并切换到新分支 '${new_branch_name}'。"
    print_info "现在可以开始在新分支上进行开发了。"
}

# 显示帮助信息
show_help() {
    echo -e "${BOLD}Git 工作流助手 (gw) 使用说明${NC}"
    echo "用法: gw <命令> [参数...]"
    echo ""
    echo -e "${CYAN}⭐ 核心工作流命令 ⭐${NC}"
    printf "${YELLOW}  gw new <branch_name> [--local] [base_branch=${MAIN_BRANCH}]${NC}\n" # Updated help text
    printf "    从最新的主分支 (${MAIN_BRANCH}) 或指定的基础分支创建并切换到一个新的开发分支。\n"
    printf "    ${CYAN}--local ${NC}   - 基于本地的基础分支状态创建，跳过自动拉取最新代码。\n" # Added description for --local
    echo "  save [-m "消息"] [-e] [文件...] - 快速保存变更: 添加指定文件 (默认全部) 并提交"
    echo "                            (无 -m/-e 则打印文件路径暂停编辑, -e 强制编辑器)"
    echo "  sync                    - 同步开发分支: 拉取主分支最新代码并 rebase 当前分支"
    echo "  finish [-n|--no-switch] [-p|--pr] - 完成当前分支开发: 检查/提交, 推送, 准备 PR/MR"
    echo "                            (-n 不切主分支, -p/-pr 尝试自动创建 GitHub PR)"
    echo "  clean <分支名>          - 清理已合并分支: 切主分支->更新->删除本地/远程"
    echo "  main | master [...]     - 推送主分支 ($MAIN_BRANCH) 到远程 (用于主分支维护, 可加 -f 等)"
    echo ""
    echo -e "${CYAN}常用 Git 操作:${NC}"
    echo "  status [-r] [-l]        - 显示工作区状态 (默认纯本地; -r 获取远程; -l 显示日志)"
    echo "  add [文件...]           - 添加文件到暂存区 (无参数则交互式选择)"
    echo "  add-all                 - 添加所有变更到暂存区 (git add -A)"
    echo "  commit [-m \"消息\"] [-a] [-e] [-F 文件] [--amend] - 提交暂存或指定变更"
    echo "                            (无 -m 等选项则打印文件路径暂停编辑, -e 强制编辑器, -a 添加已跟踪)"
    echo "  pull [远程] [分支] [...] - 拉取并合并远程更新 (带重试, 支持 git pull 参数)"
    echo "  push [远程] [分支] [...] - 推送本地提交到远程 (带重试, 自动处理 -u, 支持 git push 参数)"
    echo "  fetch [远程] [...]      - 从远程获取最新信息，但不合并 (git fetch)"
    echo ""
    echo -e "${CYAN}其他分支操作:${NC}"
    echo "  branch                  - 列出本地分支 (使用原生 git branch)"
    echo "  branch -a               - 列出所有分支 (本地和远程跟踪)"
    echo "  checkout <分支名>       - 切换到已存在的分支 (会处理未提交变更)"
    echo "  merge <来源分支> [...]  - 合并指定分支到当前分支 (可加 git merge 参数)"
    echo "  rm <分支名> [-f]        - 删除指定本地分支 (可选删远程, -f 强制)"
    echo "  rm all [-f]             - (仅限主分支)删除除主分支外所有本地分支 (-f 强制)"
    echo ""
    echo -e "${CYAN}历史与差异:${NC}"
    echo "  log [...]               - 显示提交历史 (支持 git log 参数, 带分页)"
    echo "  diff [...]              - 显示变更差异 (支持 git diff 参数, 如 --cached)"
    echo -e "  reset <目标> [...]      - ${RED}危险:${NC} 将当前分支或文件重置到指定状态"
    echo -e "                            (谨慎使用! 支持 git reset 参数, 如 --hard, commit ID, HEAD~)"
    echo ""
    echo -e "${CYAN}兼容旧版 (gp) 命令:${NC}"
    echo "  1 | first <分支名> [...] - 首次推送指定分支 (带 -u)"
    echo "  2 [...]                 - 推送主分支 ($MAIN_BRANCH) (同 gw main)"
    echo "  3 | other <分支名> [...] - 推送已存在的指定分支 (不带 -u)"
    echo "  4 | current [...]       - 推送当前所在分支 (自动处理 -u)"
    echo ""
    echo -e "${CYAN}其他:${NC}"
    echo "  help, --help, -h        - 显示此帮助信息"
    echo ""
    echo -e "${YELLOW}环境变量:${NC}"
    echo "  MAIN_BRANCH (默认: $MAIN_BRANCH) - 可通过环境变量覆盖主分支名"
    echo "  REMOTE_NAME (默认: $REMOTE_NAME) - 可通过环境变量覆盖默认远程名"
    echo "  MAX_ATTEMPTS (默认: $MAX_ATTEMPTS), DELAY_SECONDS (默认: $DELAY_SECONDS) - 控制推送/拉取重试"
    echo ""
    echo -e "${YELLOW}提示:${NC} 大部分命令在 Git 命令基础上增加了交互提示和工作流优化。"
    echo -e "对于 push/pull/log/diff/branch/merge 等命令, 你仍然可以使用它们原生支持的 Git 参数。"
}

# 重置变更 (git reset)
cmd_reset() {
    if ! check_in_git_repo; then return 1; fi

    local args_string="$*"
    local confirm_needed=false

    # 检查参数中是否包含 --hard
    if [[ " $args_string " =~ " --hard " ]]; then # 注意参数两边的空格，避免匹配 --harder 之类的
        confirm_needed=true
    fi

    if $confirm_needed; then
        echo -e "${RED}${BOLD}警告：您正在尝试使用 'git reset --hard'！${NC}"
        echo -e "${RED}这将永久丢弃您工作目录和暂存区中所有未提交的变更，对应到您重置的目标。${NC}"
        echo -e "${RED}这个操作是不可逆的！${NC}"
        echo -e -n "${YELLOW}如果您确实要执行此操作，请输入 'yes': ${NC}"
        read -r confirmation
        if [ "$confirmation" != "yes" ]; then
            echo "操作已取消。"
            return 1
        fi
        echo -e "${BLUE}确认通过，继续执行 'git reset --hard'...
${NC}"
    fi

    echo -e "${BLUE}正在执行: git reset $args_string${NC}"
    git reset "$@"
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}git reset 操作成功完成。${NC}"
    else
        echo -e "${RED}git reset 操作失败 (退出码: $exit_code)。${NC}"
    fi
    return $exit_code
}

# 主函数
main() {
    if ! check_in_git_repo; then
        # 允许 help 命令在非 git 仓库目录执行
        if [[ "$1" != "help" && "$1" != "--help" && "$1" != "-h" ]]; then
           return 1
        fi
    fi

    local command="$1"
    # 如果没有命令，提示使用 help
    if [ -z "$command" ]; then
        # show_help # 不再直接显示完整帮助
        echo "请输入一个命令。运行 'gw help' 查看可用命令。"
        return 1 # 返回错误码，因为没有执行有效命令
    fi
    shift # 移除命令参数，剩下的是命令的参数
    
    case "$command" in
        status)
            cmd_status "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        add)
            # cmd_add 内部处理无参数时的交互
            cmd_add "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        add-all)
            cmd_add_all
            LAST_COMMAND_STATUS=$?
            ;;
        commit)
            cmd_commit "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        save)
            cmd_save "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        push)
            # do_push_with_retry 处理提交检查和参数解析
            do_push_with_retry "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        pull)
            # 直接调用 git pull，可以增加交互或检查
            echo -e "${BLUE}准备执行 git pull (带重试)...${NC}"
            # git pull "$@"
            # 使用带重试的 pull
            if do_pull_with_retry "$@"; then
                 LAST_COMMAND_STATUS=0
            else
                 # do_pull_with_retry 内部已经打印了错误和冲突信息
                 LAST_COMMAND_STATUS=1
            fi
            # if [ $LAST_COMMAND_STATUS -ne 0 ]; then
            #     echo -e "${RED}git pull 失败。请检查错误信息。${NC}"
            # fi
            ;;
        fetch)
            cmd_fetch "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        sync)
             # cmd_sync 不接受额外参数
             if [ $# -gt 0 ]; then
                echo -e "${RED}错误: 'sync' 命令不接受参数。${NC}"
                LAST_COMMAND_STATUS=1
             else
                cmd_sync
                LAST_COMMAND_STATUS=$?
             fi
             ;;
        # --- 分支相关命令 ---    
        branch)
            case "$1" in
                 ""|-a|-r|--list|--show-current) 
                    git branch "$@" # 使用原生 git branch 列出分支
                    LAST_COMMAND_STATUS=$?
                    ;;
                 -d|-D)
                     local branch_to_delete="$2"
                     if [ -z "$branch_to_delete" ]; then
                        echo -e "${RED}错误: 请提供要删除的分支名称。${NC}"
                        LAST_COMMAND_STATUS=1
                     else
                        echo -e "${BLUE}正在使用 'git branch $@' 删除分支...${NC}"
                        git branch "$@"
                        LAST_COMMAND_STATUS=$?
                     fi
                     ;;
                 *)
                     # 移除创建分支的逻辑
                     echo -e "${RED}错误: 未知的 'branch' 子命令或选项 '$1'。${NC}"
                     echo "创建分支请使用 'gw new <分支名>'。"
                     echo "删除分支请使用 'gw rm <分支名>' 或 'git branch -d/-D <分支名>'。"
                     echo "查看分支请使用 'gw branch' 或 'git branch'。"
                     LAST_COMMAND_STATUS=1
                     ;;
            esac
            ;;
        rm) # 新增的删除命令
            cmd_rm_branch "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        checkout|switch|co)
            # 支持 checkout, switch, co 作为切换分支的别名
            cmd_checkout "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        merge)
            cmd_merge "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        # --- 历史与差异 ---    
        diff)
            cmd_diff "$@"
            LAST_COMMAND_STATUS=$? # diff 返回 1 表示有差异，不一定是错误
            ;;
        log)
            cmd_log "$@"
            LAST_COMMAND_STATUS=$? # log 通常返回 0
            ;;
        # --- 工作流命令 --- 
        new)
            # 使用更新后的函数名 gw_new
            gw_new "$@" # Pass all remaining arguments to gw_new
            LAST_COMMAND_STATUS=$?
            ;;
        finish)
            cmd_finish "$@" # 直接将所有参数传递给 cmd_finish
            LAST_COMMAND_STATUS=$?
            ;;
        main|master)
            # 明确推送主分支
            echo -e "${BLUE}准备推送主分支 ($MAIN_BRANCH)...${NC}"
            # 将所有剩余参数传递给 push，允许例如 gw main -f
            do_push_with_retry "$REMOTE_NAME" "$MAIN_BRANCH" "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        # --- 兼容旧版 gp 命令 (数字模式) --- 
        1|first)
            local branch_arg="$1"
            if [ -z "$branch_arg" ]; then
                echo -e "${RED}错误: 命令 '1' 或 'first' 需要指定分支名称。${NC}"
                echo "用法: gw 1 <分支名> [...]"
                LAST_COMMAND_STATUS=1
            else
                echo -e "${BLUE}执行首次推送 (模式 1) 分支 '$branch_arg' (带 -u)...${NC}"
                shift # 移除分支名参数
                # 显式添加 -u，并将剩余参数传递
                do_push_with_retry "-u" "$REMOTE_NAME" "$branch_arg" "$@"
                LAST_COMMAND_STATUS=$?
            fi
            ;;
        2)
            echo -e "${BLUE}执行推送主分支 (模式 2)...${NC}"
            # 将所有剩余参数传递给 push，允许例如 gw 2 -f
            do_push_with_retry "$REMOTE_NAME" "$MAIN_BRANCH" "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        3|other)
            local branch_arg="$1"
            if [ -z "$branch_arg" ]; then
                echo -e "${RED}错误: 命令 '3' 或 'other' 需要指定分支名称。${NC}"
                echo "用法: gw 3 <分支名> [...]"
                LAST_COMMAND_STATUS=1
            else
                echo -e "${BLUE}执行推送指定分支 (模式 3) '$branch_arg'...${NC}"
                shift # 移除分支名参数
                # 不带 -u，并将剩余参数传递
                do_push_with_retry "$REMOTE_NAME" "$branch_arg" "$@"
                LAST_COMMAND_STATUS=$?
            fi
            ;;
        4|current)
            echo -e "${BLUE}执行推送当前分支 (模式 4)...${NC}"
            local current_branch
            current_branch=$(get_current_branch_name)
            if [ $? -ne 0 ]; then 
                LAST_COMMAND_STATUS=1
            else
                # 推送当前分支，do_push_with_retry 会处理首次推送的 -u
                # 将所有剩余参数传递给 push，允许例如 gw 4 -f
                do_push_with_retry "$REMOTE_NAME" "$current_branch" "$@"
                LAST_COMMAND_STATUS=$?
            fi
            ;;
        # --- 重置命令 --- 
        reset)
            cmd_reset "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        # --- 清理命令 ---
        clean)
            cmd_clean_branch "$@"
            LAST_COMMAND_STATUS=$?
            ;;
        # --- 帮助 ---    
        help|--help|-h)
            show_help
            LAST_COMMAND_STATUS=0
            ;;
        # --- 未知命令 ---    
        *)
            echo -e "${RED}错误: 未知命令 \"$command\"${NC}"
            # show_help # 不再直接显示完整帮助
            echo "请运行 'gw help' 查看可用命令。"
            LAST_COMMAND_STATUS=1
            ;;
    esac

    # 脚本最终退出码为最后执行命令的退出码
    exit $LAST_COMMAND_STATUS
}

# --- 脚本入口 ---

# 设置脚本在出错时退出 (可选，但推荐)
# set -e

# 执行主函数，并将所有参数传递给它
main "$@"

