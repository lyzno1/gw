#!/bin/bash

# 脚本/utils_print.sh
#
# 此文件定义了用于打印不同类型消息的辅助函数。
# 旨在被其他脚本 source。
# 注意：此文件依赖于 colors.sh 中定义的颜色变量。

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