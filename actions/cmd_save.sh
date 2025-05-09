#!/bin/bash
# 脚本/actions/cmd_save.sh
#
# 实现 'save' 命令逻辑。
# 依赖:
# - colors.sh (颜色定义)
# - utils_print.sh (打印函数)
# - utils.sh (通用工具函数)
# - config_vars.sh (配置变量)

# 快速保存变更 (add + commit)
cmd_save() {
    if ! check_in_git_repo; then return 1; fi

    local message=""
    local files_to_add=() # 存储要添加的文件
    local commit_args=()  # 存储最终传递给 git commit 的参数
    local add_all=true    # 默认添加所有变更
    local use_standard_editor=false # 标记是否强制使用标准编辑器流程

    # 解析参数，区分 -m, -e 和文件路径
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -m|--message)
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
                 add_all=false 
                 files_to_add+=("$1")
                 shift
                ;;
        esac
    done

    echo -e "${BLUE}正在准备保存变更...${NC}"
    
    # 1. 添加变更
    if $add_all; then
         echo -e "${BLUE}正在添加所有变更到暂存区...${NC}"
         git add -A
         if [ $? -ne 0 ]; then
             echo -e "${RED}快速保存失败：添加所有变更时出错。${NC}"
             return 1
         fi
    elif [ ${#files_to_add[@]} -gt 0 ]; then
         echo -e "${BLUE}正在添加指定文件到暂存区: ${files_to_add[*]}${NC}"
         git add -- "${files_to_add[@]}"
         if [ $? -ne 0 ]; then
             echo -e "${RED}快速保存失败：添加指定文件时出错。${NC}"
             return 1
         fi
    else
         # 此情况理论上不会发生，因为 parse_args 后要么 add_all=true 要么 files_to_add 非空
         # 但为保险起见，如果没有任何文件被指定，则提示
         echo -e "${YELLOW}没有指定要保存的文件，也没有选择添加所有变更。${NC}"
         # 通常走不到这里，因为如果没有参数，add_all 默认是 true
         # 如果有非选项参数，add_all 会是 false, files_to_add 会有内容
         return 1 
    fi
    
    # 2. 检查是否有实际变更被暂存
    if git diff --cached --quiet; then
         if $add_all; then
             echo -e "${YELLOW}没有检测到需要保存的变更。${NC}"
         else
             echo -e "${YELLOW}指定的文件没有变更或未能添加到暂存区。${NC}"
         fi
         return 0 # 没有东西被暂存，这不是一个错误，而是操作完成
    fi

    # 3. 提交
    echo -e "${BLUE}准备提交暂存的变更...${NC}"
    local use_non_default_commit=false
    # save 命令的非默认提交流程判断：是否有 -m 或明确指定 -e
    if [[ " ${commit_args[*]} " =~ " -m " ]] || $use_standard_editor; then
        use_non_default_commit=true
    fi

    if $use_non_default_commit; then
        # 使用标准流程 (如果 commit_args 为空，且 use_standard_editor 为true, git commit 会打开编辑器)
        # 如果 commit_args 包含 -m "消息", 则直接使用消息提交
        echo -e "${BLUE}执行标准 git commit 流程...${NC}"
        if git commit "${commit_args[@]}"; then # 如果 commit_args 为空，等同于 git commit (可能打开编辑器)
            echo -e "${GREEN}快速保存成功！${NC}"
            return 0
        else
            echo -e "${RED}快速保存失败：提交时出错或被取消。${NC}"
            return 1
        fi
    else
        # 执行新的默认流程：准备 COMMIT_EDITMSG 让用户编辑，然后提交
        local git_dir
        git_dir=$(git rev-parse --git-dir)
        if [ $? -ne 0 ] || [ -z "$git_dir" ]; then
            echo -e "${RED}错误：无法获取 .git 目录路径。${NC}"
            return 1
        fi
        local commit_msg_file_orig="$git_dir/COMMIT_EDITMSG"
        local current_branch
        current_branch=$(get_current_branch_name)
        if [ $? -ne 0 ]; then
            # 不再使用 print_warning，以保持原有风格，只记录到变量
            current_branch="未知分支"
        fi
        
        # 准备提交信息文件模板，恢复原始提示 + 新增功能
        echo "" > "$commit_msg_file_orig"
        echo "# 请输入提交说明。以 '#' 开始的行将被忽略。" >> "$commit_msg_file_orig" # 保留原始提示
        echo "#" >> "$commit_msg_file_orig"
        echo "# 当前所在分支：$current_branch" >> "$commit_msg_file_orig" # 新增功能
        echo "#" >> "$commit_msg_file_orig"
        echo "# 暂存的变更：" >> "$commit_msg_file_orig" # 保留原始提示

        local staged_files_output
        # 获取暂存文件，只关心暂存区状态 (X)，不包括工作区状态 (Y)
        staged_files_output=$(git status --porcelain=v1 -uall | grep -E '^[MARCDU][[:space:]]')

        if [ -n "$staged_files_output" ]; then
            echo "$staged_files_output" | while IFS= read -r line; do
                local X=${line:0:1} # 只取第一个字符作为暂存区状态
                local file_path_raw=${line:3} # 去掉 "X " 前缀
                local display_status=""
                local file_display_path="$file_path_raw"

                case "$X" in
                    M) display_status="已修改："  ;; 
                    A) display_status="新文件："  ;; 
                    D) display_status="已删除："  ;; 
                    R) display_status="已重命名："; file_display_path=$(echo "$file_path_raw" | sed 's/ -> / → /g') ;; # 将 -> 替换为箭头
                    C) display_status="已复制："  ; file_display_path=$(echo "$file_path_raw" | sed 's/ -> / → /g') ;; # 将 -> 替换为箭头
                    U) display_status="合并冲突：";; 
                    *) display_status="未知($X)：";;
                esac
                
                # 输出格式: #<TAB>中文状态描述<TAB>文件路径
                # 使用 echo -e 来确保 	 被解释为制表符
                echo -e "#\t${display_status}\t${file_display_path}" >> "$commit_msg_file_orig"

            done
        else
            echo "# (没有检测到暂存的变更)" >> "$commit_msg_file_orig"
        fi
        echo "#" >> "$commit_msg_file_orig"
        
        # --- 尝试使用 code --wait 打开编辑器 ---
        local editor_opened_successfully=false
        if command -v code >/dev/null 2>&1; then
            print_info "检测到 'code' 命令，尝试使用 VS Code (或兼容 IDE) 打开编辑..."
            if code --wait "$commit_msg_file_orig"; then
                # code --wait 成功返回 (用户已关闭文件)
                editor_opened_successfully=true
                print_success "VS Code 编辑器已关闭。"
            else
                local exit_code=$?
                print_warning "'code --wait' 命令执行失败或未正常等待 (退出码: $exit_code)。"
                print_warning "可能是 VS Code 未正确安装或 code 命令未配置 --wait 支持。"
                # Fall through to manual confirmation
            fi
        else
            print_info "未检测到 'code' 命令。"
            # 可以选择性地在这里添加对 $EDITOR 的检查和调用
            # if [ -n "$EDITOR" ]; then ... else ... fi
            # 但根据用户需求，我们直接回退到打印路径
        fi
        
        # --- 如果编辑器未能自动打开并等待，则回退到手动确认 ---
        if ! $editor_opened_successfully; then
            echo -e "${YELLOW}请在你的编辑器中打开并编辑以下文件以输入提交信息:${NC}"
            echo -e "  ${CYAN}${BOLD}$commit_msg_file_orig${NC}"
            echo -e "(在 macOS 上，你可以尝试 ${BOLD}Cmd + 点击${NC} 上面的路径快速打开)"
            echo -e -n "${CYAN}编辑完成后，请按 Enter 键继续提交... (按 Ctrl+C 取消提交)${NC}"
            read -r # 等待用户按 Enter
            # 假设用户已经编辑完毕
        fi
        
        # --- 后续检查和提交逻辑 (保持不变) ---
        # 检查用户是否真的编辑了文件 (移除了所有#或空行，或添加了非注释内容)
        if ! grep -v -q -E '^#|^$' "$commit_msg_file_orig"; then
            echo -e "${RED}错误：提交信息文件为空或只包含注释行。提交已取消。${NC}"
            # 这里不删除原始 COMMIT_EDITMSG，git commit 失败时，git 自己会处理或保留它
            return 1
        fi        
        
        # 清理 COMMIT_EDITMSG 中的注释行和特定模板提示行，保存到新文件
        local cleaned_commit_msg_file="${commit_msg_file_orig}.gw_cleaned"
        # 移除注释行、特定模板提示行，并压缩连续的空行
        # 注意：这里的 grep -v 也需要更新以匹配脚本内定义的模板行
        grep -v -E '^#|请输入提交说明。以|当前所在分支：|暂存的变更：' "$commit_msg_file_orig" | awk 'NF > 0 {blank_lines=0; print} NF == 0 {if (blank_lines < 1) print; blank_lines++}' > "$cleaned_commit_msg_file"
        
        # 再次检查清理后的文件是否还有实际内容
        if ! grep -v -q -E '^$' "$cleaned_commit_msg_file"; then # 只需要检查是否全为空行
            echo -e "${RED}错误：清理后的提交信息为空。提交已取消。${NC}"
            rm -f "$cleaned_commit_msg_file" # 清理我们创建的临时文件
            return 1
        fi

        echo -e "${BLUE}使用编辑并清理后的文件 (${cleaned_commit_msg_file}) 继续提交...${NC}"
        # commit_args 此处应为空，因为我们没有 -m, -e, 等
        if git commit --file="$cleaned_commit_msg_file" "${commit_args[@]}"; then 
            echo -e "${GREEN}提交成功！${NC}"
            # Git 成功提交后会自动删除原始 COMMIT_EDITMSG (如果它是默认路径)
            # 我们需要删除我们创建的 .gw_cleaned 文件
            rm -f "$cleaned_commit_msg_file"
            # 确保原始的 COMMIT_EDITMSG 也被清理（以防万一git没删）
            if [ -f "$commit_msg_file_orig" ]; then
                 rm -f "$commit_msg_file_orig"
            fi
            return 0
        else
            echo -e "${RED}使用编辑后的文件提交失败。${NC}"
            echo -e "${YELLOW}原始提交信息文件仍保留在: $commit_msg_file_orig${NC}"
            echo -e "${YELLOW}清理后的提交信息文件仍保留在: $cleaned_commit_msg_file${NC}"
            echo "你可以检查文件内容和暂存区状态 ('git status')。"
            return 1
        fi
    fi
} 