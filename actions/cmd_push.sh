#!/bin/bash
# 脚本/actions/cmd_push.sh
#
# 实现 'push' 命令逻辑的包装器。
# 它调用在 git_network_ops.sh 中定义的 do_push_with_retry 函数。
# 依赖:
# - core_utils/git_network_ops.sh (提供 do_push_with_retry)
# - (间接依赖 do_push_with_retry 的所有依赖项)

cmd_push() {
    # 直接将所有参数传递给核心推送函数
    if ! command -v do_push_with_retry >/dev/null 2>&1; then
        echo -e "${RED}错误: 核心函数 'do_push_with_retry' 未找到。请检查脚本完整性。${NC}" >&2
        return 127 # 表示命令未找到
    fi
    
    do_push_with_retry "$@"
    return $?
} 