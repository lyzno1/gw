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
        # --- 生成新的 COMMIT_EDITMSG 内容 ---
        {
            echo "" # 用户要求的第一行换行
            echo "# Please enter the commit message for your changes. Lines starting"
            echo "# with '#' will be ignored, and an empty message aborts the commit."
            echo "#"
            echo "# On branch: $current_branch"
            echo "#"
            echo "# Changes to be committed:"
            echo "#   (use \"gw unstage <file>...\" or \"git reset HEAD <file>...\" to unstage)"
            echo "#"

            local staged_files_output
            staged_files_output=$(git status --porcelain=v1 -uall | grep -E '^[MARCDU][[:space:]]')
            local status_desc_width=12 # 固定状态描述的宽度

            if [ -n "$staged_files_output" ]; then
                echo "$staged_files_output" | while IFS= read -r line; do
                    local X=${line:0:1} # Staged status
                    local file_path_raw=${line:3}
                    local status_desc=""
                    local file_display_for_commit="$file_path_raw"

                    case "$X" in
                        M) status_desc="modified:";;
                        A) status_desc="new file:";;
                        D) status_desc="deleted:";;
                        R) status_desc="renamed:"; file_display_for_commit=$(echo "$file_path_raw" | sed 's/ -> / → /g');;
                        C) status_desc="copied:"; file_display_for_commit=$(echo "$file_path_raw" | sed 's/ -> / → /g');;
                        U) status_desc="unmerged:";; # Should ideally not happen if `gw save` is used after resolving
                        *) status_desc="staged:";;
                    esac
                    
                    # 使用 printf 进行对齐: # (8个空格缩进) status_desc (固定宽度) filepath
                    printf "#       %-*s %s\n" "$status_desc_width" "$status_desc" "$file_display_for_commit"
                done
            else
                echo "#       (no changes staged for commit)"
            fi
            echo "#"
            echo "# --------------------------------------------------------------------"
            echo "# 操作指南:"
            echo "# 1. 在文件上方空白区域输入您的提交信息。"
            echo "# 2. 完成编辑后，请保存此文件。"
            echo "# 3. 如何继续提交:"
            echo "#    - 如果编辑器是由脚本自动打开的 (例如 VS Code):"
            echo "#      直接关闭此编辑器即可，提交会自动进行。"
            echo "#    - 如果您是手动打开的此文件 (例如根据终端提示的路径):"
            echo "#      请返回到终端界面，然后按 Enter 键。"
            echo "#"
            echo "# 如需取消本次提交:"
            echo "#   - 在终端中按 Ctrl+C。"
            echo "#   - 或者，保留此文件为空 (或只含注释行) 并继续，提交也会自动中止。"
            echo "# --------------------------------------------------------------------"
        } > "$commit_msg_file_orig"
        # --- COMMIT_EDITMSG 内容生成完毕 ---

        # --- 尝试使用配置的或默认的编辑器打开 ---
        local editor_opened_successfully=false
        local editor_to_use=""
        local editor_source_msg=""
        local tried_fallback=false

        # 1. 尝试从 gw 偏好文件读取（无论命令是否存在都尝试）
        local gw_editor_pref_file="$HOME/.gw_editor_pref"
        if [ -f "$gw_editor_pref_file" ] && [ -s "$gw_editor_pref_file" ]; then
            local preferred_editor_cmd
            preferred_editor_cmd=$(cat "$gw_editor_pref_file")
            if [ -n "$preferred_editor_cmd" ]; then
                local cmd_head_pref
                cmd_head_pref=$(echo "$preferred_editor_cmd" | awk '{print $1}')
                if ! command -v "$cmd_head_pref" >/dev/null 2>&1; then
                    print_warning "gw 偏好文件中配置的编辑器命令 '$cmd_head_pref' 未找到，但仍将尝试使用。"
                fi
                editor_to_use="$preferred_editor_cmd"
                editor_source_msg="gw 偏好设置 ($gw_editor_pref_file)"
            fi
        fi

        # 2. 如果 gw 偏好未设置，则尝试 code --wait
        if [ -z "$editor_to_use" ] && command -v code >/dev/null 2>&1; then
            editor_to_use="code --wait"
            editor_source_msg="'code --wait' 命令"
        fi

        # 3. 尝试 $VISUAL
        if [ -z "$editor_to_use" ] && [ -n "$VISUAL" ] && command -v "$VISUAL" >/dev/null 2>&1; then
            editor_to_use="$VISUAL"
            editor_source_msg="\$VISUAL 环境变量"
        fi
        
        # 4. 尝试 $EDITOR
        if [ -z "$editor_to_use" ] && [ -n "$EDITOR" ] && command -v "$EDITOR" >/dev/null 2>&1; then
            editor_to_use="$EDITOR"
            editor_source_msg="\$EDITOR 环境变量"
        fi

        # --- 实际尝试打开编辑器 ---
        if [ -n "$editor_to_use" ]; then
            print_info "检测到编辑器 ($editor_source_msg)，尝试使用 '$editor_to_use' 打开编辑..."
            local editor_cmd_parts=()
            read -r -a editor_cmd_parts <<< "$editor_to_use"
            if "${editor_cmd_parts[@]}" "$commit_msg_file_orig"; then
                editor_opened_successfully=true
                print_success "编辑器已关闭。"
            else
                local exit_code=$?
                print_warning "编辑器命令 '$editor_to_use' 执行失败或未正常等待 (退出码: $exit_code)。"
                # 如果是用户自定义的编辑器，允许降级为默认
                if [ -f "$gw_editor_pref_file" ] && [ -s "$gw_editor_pref_file" ]; then
                    echo -e "${YELLOW}你设置的编辑器命令执行失败，是否要切换为默认编辑器 (code --wait) 并重试？${NC}"
                    if confirm_action "切换为默认编辑器 (code --wait) 并自动更新 gw ide？"; then
                        echo "code --wait" > "$gw_editor_pref_file"
                        print_success "已将 gw ide 设置为 code --wait。即将重新执行保存流程..."
                        tried_fallback=true
                    else
                        print_info "你选择不切换为默认编辑器，操作中止。"
                        return 1
                    fi
                fi
            fi
        else
            print_info "未检测到可用的自动编辑器配置 (gw 偏好, code, $VISUAL, $EDITOR)。"
        fi
        
        # --- 如果编辑器未能自动打开并等待，则回退到手动确认 ---
        if ! $editor_opened_successfully && ! $tried_fallback; then
            echo -e "${YELLOW}请在你的编辑器中打开并编辑以下文件以输入提交信息:${NC}"
            echo -e "  ${CYAN}${BOLD}$commit_msg_file_orig${NC}"
            echo -e "(在 macOS 上，你可以尝试 ${BOLD}Cmd + 点击${NC} 上面的路径快速打开)"
            echo -e -n "${CYAN}编辑完成后，请按 Enter 键继续提交... (按 Ctrl+C 取消提交)${NC}"
            read -r # 等待用户按 Enter
            # 假设用户已经编辑完毕
        fi

        # --- 如果刚才自动切换为默认编辑器，则重新执行 save 流程 ---
        if $tried_fallback; then
            print_info "重新执行 gw save..."
            gw save "$@"
            return $?
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
