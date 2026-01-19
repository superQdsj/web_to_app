#!/bin/bash

# 获取当前 Git 仓库的根目录
GIT_ROOT=$(git rev-parse --show-toplevel)
PROJECT_NAME=$(basename "$GIT_ROOT")
PARENT_DIR=$(dirname "$GIT_ROOT")

# 检查输入参数
BRANCH_NAME=$1
if [ -z "$BRANCH_NAME" ]; then
    echo "❌ 缺少参数。用法: gwt <分支名>"
    exit 1
fi

# 定义新工作树的路径 (位于当前项目平级目录)
NEW_WT_PATH="$PARENT_DIR/${PROJECT_NAME}_$BRANCH_NAME"

echo "🚀 正在创建工作树: $NEW_WT_PATH"

# 1. 创建 Git 工作树
# 检查分支是否已存在
if git rev-parse --verify "$BRANCH_NAME" >/dev/null 2>&1; then
    echo "📍 使用现有分支: $BRANCH_NAME"
    git worktree add "$NEW_WT_PATH" "$BRANCH_NAME"
else
    echo "🌿 创建并检出新分支: $BRANCH_NAME"
    git worktree add "$NEW_WT_PATH" -b "$BRANCH_NAME"
fi

# 2. 初始化 Flutter 环境
# 脚本会进入新目录下的 nga_app 文件夹并运行 pub get
if [ -d "$NEW_WT_PATH/nga_app" ]; then
    echo "📦 正在初始化 Flutter 依赖 (fvm flutter pub get)..."
    cd "$NEW_WT_PATH/nga_app" && fvm flutter pub get
else
    echo "⚠️ 未找到 nga_app 目录，跳过 pub get。"
fi

echo "✅ 完成！"
echo "📂 目录: $NEW_WT_PATH"
echo "💻 输入以下命令打开新项目:"
echo "   code $NEW_WT_PATH"
