#!/bin/bash

# 脚本/config_vars.sh
#
# 此文件定义了脚本的核心配置变量。
# 旨在被其他脚本 source。

# --- 配置变量 ---
MAX_ATTEMPTS=${MAX_ATTEMPTS:-50}           # 最大尝试次数，可通过环境变量覆盖
DELAY_SECONDS=${DELAY_SECONDS:-1}          # 每次尝试之间的延迟（秒），可通过环境变量覆盖
REMOTE_NAME=${REMOTE_NAME:-origin}       # 默认的远程仓库名称，可通过环境变量覆盖
DEFAULT_MAIN_BRANCH=${DEFAULT_MAIN_BRANCH:-master}  # 默认的主分支名称，可通过环境变量覆盖 

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