#!/bin/bash

# 脚本/utils.sh
#
# 此文件定义了通用的工具函数。
# 旨在被其他脚本 source。
# 注意：某些函数可能依赖于 colors.sh (用于颜色输出) 和 utils_print.sh (用于打印函数)。

# 获取当前分支名称
get_current_branch_name() {
    local branch_name
    branch_name=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    local exit_code=$?

    if [ $exit_code -ne 0 ] || [ -z "$branch_name" ] || [ "$branch_name" == "HEAD" ]; then
        # 假设 print_error 来自 utils_print.sh, 颜色来自 colors.sh
        # 如果 utils_print.sh 未加载，此行会直接输出字符串
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

# 查找worktree根目录（包含.gw/worktree-config的目录）
find_worktree_root() {
    local current_dir=$(pwd)
    local original_dir="$current_dir"
    
    # 从当前目录向上查找包含.gw/worktree-config的目录
    while [ "$current_dir" != "/" ]; do
        if [ -f "$current_dir/.gw/worktree-config" ]; then
            echo "$current_dir"
            return 0
        fi
        current_dir=$(dirname "$current_dir")
    done
    
    return 1
} 