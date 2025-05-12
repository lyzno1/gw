#!/bin/bash
# 脚本/actions/cmd_status.sh
#
# Implements the 'status' command logic.
# Dependencies:
# - colors.sh (for YELLOW, BLUE, CYAN, BOLD, NC, GREEN, RED, PURPLE)
# - utils.sh (for check_in_git_repo, get_current_branch_name)
# - config_vars.sh (for REMOTE_NAME)

# 获取状态摘要
cmd_status() {
    if ! check_in_git_repo; then
        return 1
    fi
    
    local fetch_remote=false
    local show_log=false
    # 解析参数
    # local remaining_args=() # Not currently used
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
                echo -e "${YELLOW}警告: status 命令忽略未知参数: $1${NC}"
                shift
                ;;
        esac
    done
    
    if $fetch_remote; then
        echo -e "${BLUE}正在从远程仓库 '$REMOTE_NAME' 获取最新状态...${NC}"
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
    
    echo -e "${CYAN}=== Git 本地仓库状态 ===${NC}"
    echo -e "${BOLD}当前分支:${NC} $current_branch"
    
    local remote_branch_ref="refs/remotes/$REMOTE_NAME/$current_branch"
    if git show-ref --verify --quiet "$remote_branch_ref"; then
        local ahead_behind
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
        if ! git log "$REMOTE_NAME/$current_branch..$current_branch" >/dev/null 2>&1; then 
             echo -e "${BOLD}远程跟踪状态:${NC} ${PURPLE}分支 '$current_branch' 尚未推送到远程 '$REMOTE_NAME' 或本地无跟踪信息${NC}"
        else
            echo -e "${BOLD}远程跟踪状态:${NC} ${YELLOW}远程分支 '$REMOTE_NAME/$current_branch' 可能已被删除或本地未同步${NC}"
        fi
    fi
    
    echo -e "\n${BOLD}本地变更详情 (git status -sb):${NC}"
    git status -sb
    
    if $show_log; then
        echo -e "\n${BOLD}最近提交 (-l):${NC}"
        git log -3 --pretty=format:"%C(yellow)%h%Creset %s %C(bold blue)<%an>%Creset %C(green)(%ar)%Creset%C(auto)%d%Creset"
        echo ""
    
        latest_tag=$(git describe --tags --abbrev=0 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$latest_tag" ]; then
            echo -e "${BOLD}最近标签 (-l):${NC} $latest_tag"
        fi
    fi
    
    echo "" # 在命令输出末尾添加一个空行
    return 0
}
