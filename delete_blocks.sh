#!/bin/bash

SCRIPT_DIR=$1

input_tags_with_spaces=$(echo "$input_tags" | tr ',' ' ')

# 读取用户输入的标签，用空格分隔
read -rp "tags to delete (split by space or ,): " input_tags

# 将输入的字符串转换为数组
IFS=' ' read -r -a tags <<< "$input_tags"

# 遍历每个标签并删除其内容
for tag in "${tags[@]}"; do
    # 使用 sed 删除 {tag ... }tag 包含的内容，包括花括号所在行
    sed -i "/^{${tag}/,/^}${tag}/d" ${SCRIPT_DIR}/blocks.txt
done

echo "delete finish."
