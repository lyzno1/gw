#!/bin/bash
# 脚本/actions/cmd_pull.sh
#
# 实现 'pull' 命令逻辑的包装器。
# 它调用在 git_network_ops.sh 中定义的 do_pull_with_retry 函数。
# 依赖:
# - colors.sh (颜色定义, 例如 BLUE, NC)
# - core_utils/git_network_ops.sh (提供 do_pull_with_retry)
# - (间接依赖 do_pull_with_retry 的所有依赖项)

cmd_pull() {
    if ! command -v do_pull_with_retry >/dev/null 2>&1; then
        echo -e "${RED}错误: 核心函数 'do_pull_with_retry' 未找到。请检查脚本完整性。${NC}" >&2
        return 127 # 表示命令未找到
    fi

    echo -e "${BLUE}准备执行 git pull (通过 gw pull, 带重试)...${NC}"
    if do_pull_with_retry "$@"; then
        return 0
    else
        # do_pull_with_retry 内部会打印具体的错误或冲突信息
        return 1
    fi
} 