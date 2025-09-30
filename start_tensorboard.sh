#!/bin/bash

# TensorBoard启动脚本

echo "=== MART TensorBoard Viewer ==="

# 激活conda环境
source /home/yyy/miniconda3/etc/profile.d/conda.sh
conda activate mart

# 查找最新的实验结果
ROOT_PATH="/home/yyy/MART/VAA_VideoEmotion8"
RESULTS_DIR="$ROOT_PATH/results"

if [ ! -d "$RESULTS_DIR" ]; then
    echo "Error: Results directory not found: $RESULTS_DIR"
    exit 1
fi

# 列出可用的实验
echo "Available experiments:"
ls -1t "$RESULTS_DIR" | head -10

echo ""
echo "Latest experiment:"
LATEST_EXP=$(ls -1t "$RESULTS_DIR" | head -1)
echo "$LATEST_EXP"

TENSORBOARD_DIR="$RESULTS_DIR/$LATEST_EXP/tensorboard"

if [ ! -d "$TENSORBOARD_DIR" ]; then
    echo "Error: TensorBoard directory not found: $TENSORBOARD_DIR"
    exit 1
fi

echo ""
echo "Starting TensorBoard..."
echo "TensorBoard directory: $TENSORBOARD_DIR"
echo "Open http://localhost:6006 in your browser"
echo "Press Ctrl+C to stop TensorBoard"
echo ""

# 启动TensorBoard
cd "$RESULTS_DIR/$LATEST_EXP"
tensorboard --logdir=tensorboard --port=6006 --host=0.0.0.0