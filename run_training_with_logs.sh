#!/bin/bash

# MART训练脚本，包含完整的日志和TensorBoard监控

echo "=== MART Training with Enhanced Logging and TensorBoard ==="

# 激活conda环境
source /home/yyy/miniconda3/etc/profile.d/conda.sh
conda activate mart

# 设置参数
ROOT_PATH="/home/yyy/MART/VAA_VideoEmotion8"
EXP_NAME="mart_enhanced_$(date +%Y%m%d_%H%M%S)"

echo "Starting MART training..."
echo "Root path: $ROOT_PATH"
echo "Experiment name: $EXP_NAME"

# 运行训练，将输出重定向到日志文件
python main.py \
    --root_path "$ROOT_PATH" \
    --expr_name "$EXP_NAME" \
    --n_epochs 5 \
    --batch_size 1 \
    --learning_rate 0.0001 \
    2>&1 | tee training_$(date +%Y%m%d_%H%M%S).log

echo ""
echo "Training completed!"
echo ""

# 显示日志文件位置
if [ -d "$ROOT_PATH/results/$EXP_NAME" ]; then
    echo "Results saved to: $ROOT_PATH/results/$EXP_NAME"
    echo "TensorBoard logs: $ROOT_PATH/results/$EXP_NAME/tensorboard"
    echo ""
    echo "To view TensorBoard:"
    echo "  conda activate mart"
    echo "  cd $ROOT_PATH/results/$EXP_NAME"
    echo "  tensorboard --logdir=tensorboard --port=6006"
    echo "  Then open http://localhost:6006 in your browser"
fi

echo ""
echo "Log files created:"
find . -name "*.log" -newer /tmp/start_time 2>/dev/null | head -5

echo ""
echo "=== Training Summary ==="
if [ -f "training_$(date +%Y%m%d)*.log" ]; then
    echo "Final accuracy:"
    grep "History Best Accuracy" training_*.log | tail -1
fi