#!/bin/bash
# 使用现有 MART tools 完整处理 VideoEmotionDataset 的脚本

echo "=== VideoEmotionDataset Processing with Existing Tools ==="
echo "Current directory: $(pwd)"

# 定义路径
SOURCE_DIR="VideoEmotionDataset"
TEMP_VIDEO_DIR="temp_reorganized_videos"
OUTPUT_FRAMES_DIR="VAA_VideoEmotion8/imgs"
OUTPUT_AUDIO_DIR="VAA_VideoEmotion8/mp3"
OUTPUT_SRT_DIR="VAA_VideoEmotion8/srt"

# 检查源数据
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: $SOURCE_DIR not found!"
    exit 1
fi

echo "Step 1: Reorganizing video files..."

# 创建临时重组目录
mkdir -p $TEMP_VIDEO_DIR/{Anger,Anticipation,Disgust,Fear,Joy,Sadness,Surprise,Trust}

# 重组视频文件
declare -A emotion_map
emotion_map["VideoEmotionDataset1-Anger"]="Anger"
emotion_map["VideoEmotionDataset2-Anticipation"]="Anticipation"
emotion_map["VideoEmotionDataset3-Disgust"]="Disgust"
emotion_map["VideoEmotionDataset4-Fear"]="Fear"
emotion_map["VideoEmotionDataset5-Joy"]="Joy"
emotion_map["VideoEmotionDataset6-Sadness"]="Sadness"
emotion_map["VideoEmotionDataset7-Surprise"]="Surprise"
emotion_map["VideoEmotionDataset8-Trust"]="Trust"

for source_dir in $SOURCE_DIR/VideoEmotionDataset*; do
    if [[ -d "$source_dir" ]]; then
        dir_name=$(basename "$source_dir")
        target_emotion=${emotion_map[$dir_name]}

        echo "  Processing $dir_name -> $target_emotion"

        # 复制 flickr 视频
        if [[ -d "$source_dir/flickr" ]]; then
            find "$source_dir/flickr" -name "*.mp4" -exec cp {} "$TEMP_VIDEO_DIR/$target_emotion/" \;
        fi

        # 复制 youtube 视频
        if [[ -d "$source_dir/youtube" ]]; then
            find "$source_dir/youtube" -name "*.mp4" -exec cp {} "$TEMP_VIDEO_DIR/$target_emotion/" \;
        fi
    fi
done

echo "Step 2: Converting videos to frames using existing tools..."

# 创建输出目录
mkdir -p $OUTPUT_FRAMES_DIR

# 修复 video2jpg.py 的参数问题并使用
for emotion in Anger Anticipation Disgust Fear Joy Sadness Surprise Trust; do
    echo "  Processing $emotion frames..."

    # 检查是否有视频文件
    if ls $TEMP_VIDEO_DIR/$emotion/*.mp4 1> /dev/null 2>&1; then
        # 直接调用修复后的 video2jpg 逻辑
        python3 -c "
import sys
sys.path.append('tools')
from video2jpg import class_process

class_process('$TEMP_VIDEO_DIR', '$OUTPUT_FRAMES_DIR', '$emotion')
"
    else
        echo "    No videos found for $emotion"
    fi
done

echo "Step 3: Extracting audio using existing tools..."

# 创建音频输出目录
mkdir -p $OUTPUT_AUDIO_DIR

# 修复 video2mp3.py 的参数问题并使用
for emotion in Anger Anticipation Disgust Fear Joy Sadness Surprise Trust; do
    echo "  Processing $emotion audio..."

    if ls $TEMP_VIDEO_DIR/$emotion/*.mp4 1> /dev/null 2>&1; then
        python3 -c "
import sys
sys.path.append('tools')
from video2mp3 import class_process

class_process('$TEMP_VIDEO_DIR', '$OUTPUT_AUDIO_DIR', '$emotion')
"
    else
        echo "    No videos found for $emotion"
    fi
done

echo "Step 4: Creating subtitle placeholders..."

# 创建字幕目录和占位符文件
mkdir -p $OUTPUT_SRT_DIR

for emotion in Anger Anticipation Disgust Fear Joy Sadness Surprise Trust; do
    mkdir -p "$OUTPUT_SRT_DIR/$emotion"

    if [[ -d "$OUTPUT_AUDIO_DIR/$emotion" ]]; then
        for audio_file in "$OUTPUT_AUDIO_DIR/$emotion"/*.mp3; do
            if [[ -f "$audio_file" ]]; then
                filename=$(basename "$audio_file" .mp3)
                srt_file="$OUTPUT_SRT_DIR/$emotion/$filename.srt"

                # 创建简单的字幕占位符
                cat > "$srt_file" << EOF
1
00:00:00,000 --> 00:00:01,000
[No subtitles available]

EOF
            fi
        done
    fi
done

echo "Step 5: Counting frames using existing tools..."

# 修改 n_frames.py 的路径并使用
for emotion in Anger Anticipation Disgust Fear Joy Sadness Surprise Trust; do
    echo "  Counting frames for $emotion..."

    if [[ -d "$OUTPUT_FRAMES_DIR/$emotion" ]]; then
        # 临时修改 n_frames.py 中的路径
        python3 -c "
import sys
import os
sys.path.append('tools')

# 模拟 n_frames.py 的功能但使用我们的路径
def class_process(dir_path, class_name):
    class_path = os.path.join(dir_path, class_name)
    if not os.path.isdir(class_path):
        return

    for file_name in os.listdir(class_path):
        video_dir_path = os.path.join(class_path, file_name)
        if not os.path.isdir(video_dir_path) or 'n_frames' in os.listdir(video_dir_path):
            continue

        image_indices = []
        for image_file_name in os.listdir(video_dir_path):
            if '.jpg' not in image_file_name:
                continue
            try:
                image_indices.append(int(image_file_name[:6]))
            except:
                continue

        if len(image_indices) < 16:
            n_frames = 0
        else:
            image_indices.sort(reverse=True)
            n_frames = image_indices[0]

        with open(os.path.join(video_dir_path, 'n_frames'), 'w+') as dst_file:
            dst_file.write(str(n_frames))

        print(f'  {file_name}: {n_frames} frames')

class_process('$OUTPUT_FRAMES_DIR', '$emotion')
"
    fi
done

echo "Step 6: Creating annotation files..."

# 创建标注目录
mkdir -p tools/annotations/ve8

# 生成 classInd.txt
cat > tools/annotations/ve8/classInd.txt << EOF
1 Anger
2 Anticipation
3 Disgust
4 Fear
5 Joy
6 Sadness
7 Surprise
8 Trust
EOF

# 生成训练和测试文件列表
echo "  Generating train/test splits..."

python3 -c "
import os
import random

# 收集所有有效视频
all_videos = []
emotions = ['Anger', 'Anticipation', 'Disgust', 'Fear', 'Joy', 'Sadness', 'Surprise', 'Trust']

for i, emotion in enumerate(emotions, 1):
    emotion_dir = os.path.join('$OUTPUT_FRAMES_DIR', emotion)
    if os.path.exists(emotion_dir):
        for video_dir in os.listdir(emotion_dir):
            video_path = os.path.join(emotion_dir, video_dir)
            n_frames_file = os.path.join(video_path, 'n_frames')

            if os.path.isdir(video_path) and os.path.exists(n_frames_file):
                with open(n_frames_file, 'r') as f:
                    n_frames = int(f.read().strip())
                if n_frames > 0:
                    all_videos.append((emotion, video_dir, i))

print(f'Found {len(all_videos)} valid videos')

# 随机分割 80:20
random.shuffle(all_videos)
split_idx = int(len(all_videos) * 0.8)
train_videos = all_videos[:split_idx]
test_videos = all_videos[split_idx:]

# 生成训练列表
with open('tools/annotations/ve8/trainlist01.txt', 'w') as f:
    for emotion, video_id, class_idx in train_videos:
        f.write(f'{emotion}/{video_id} {class_idx}\n')

# 生成测试列表
with open('tools/annotations/ve8/testlist01.txt', 'w') as f:
    for emotion, video_id, class_idx in test_videos:
        f.write(f'{emotion}/{video_id} {class_idx}\n')

print(f'Created {len(train_videos)} training and {len(test_videos)} test samples')
"

# 使用现有的 ve8_json.py 生成 JSON 文件
echo "  Generating JSON annotation file..."

cd tools
python3 ve8_json.py
cd ..

# 复制 JSON 文件到主目录
if [[ -f "tools/annotations/ve8/ve8_01.json" ]]; then
    cp "tools/annotations/ve8/ve8_01.json" "VAA_VideoEmotion8/ve8.json"
    echo "  ✓ Created ve8.json"
fi

echo "Step 7: Cleanup temporary files..."
rm -rf $TEMP_VIDEO_DIR

echo ""
echo "=== Processing Complete ==="
echo "Dataset structure:"
echo "  VAA_VideoEmotion8/"
echo "  ├── imgs/     (video frames)"
echo "  ├── mp3/      (audio files)"
echo "  ├── srt/      (subtitle files)"
echo "  └── ve8.json  (annotations)"
echo ""
echo "Next steps:"
echo "1. Update opts.py with correct root_path:"
echo "   --root_path $(pwd)/VAA_VideoEmotion8"
echo "2. Run training:"
echo "   python main.py --root_path $(pwd)/VAA_VideoEmotion8"