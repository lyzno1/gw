#!/bin/bash
# 脚本/actions/cmd_add.sh
#
# Implements the 'add' command logic.
# Dependencies:
# - colors.sh (for CYAN, NC, BLUE, GREEN, RED)
# - utils_print.sh (for print_error - though not directly used in this snippet, good to note)
# - utils.sh (for check_in_git_repo, interactive_select_files)

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