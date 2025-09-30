#!/bin/bash
# 修复版本：使用现有 MART tools 完整处理 VideoEmotionDataset 的脚本

echo "=== VideoEmotionDataset Processing with Existing Tools (Fixed Version) ==="
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

echo "Step 2: Converting videos to frames..."

# 创建输出目录
mkdir -p $OUTPUT_FRAMES_DIR

# 直接使用 ffmpeg 而不是调用 video2jpg.py
for emotion in Anger Anticipation Disgust Fear Joy Sadness Surprise Trust; do
    echo "  Processing $emotion frames..."

    emotion_dir="$TEMP_VIDEO_DIR/$emotion"
    output_emotion_dir="$OUTPUT_FRAMES_DIR/$emotion"

    if ls "$emotion_dir"/*.mp4 1> /dev/null 2>&1; then
        mkdir -p "$output_emotion_dir"

        for video_file in "$emotion_dir"/*.mp4; do
            if [[ -f "$video_file" ]]; then
                video_name=$(basename "$video_file" .mp4)
                frame_output_dir="$output_emotion_dir/$video_name"

                # 检查是否已经处理过
                if [[ -d "$frame_output_dir" ]] && [[ -f "$frame_output_dir/n_frames" ]]; then
                    echo "    Skip existing: $video_name"
                    continue
                fi

                mkdir -p "$frame_output_dir"

                echo "    Extracting frames: $video_name"

                # 使用更安全的 ffmpeg 命令
                if ffmpeg -i "$video_file" -vf scale=-1:240 -q:v 2 "$frame_output_dir/%06d.jpg" -y > /dev/null 2>&1; then
                    echo "    ✓ Successfully extracted frames for $video_name"
                else
                    echo "    ✗ Error extracting frames for $video_name"
                    # 删除失败的目录
                    rm -rf "$frame_output_dir"
                fi
            fi
        done
    else
        echo "    No videos found for $emotion"
    fi
done

echo "Step 3: Extracting audio..."

# 创建音频输出目录
mkdir -p $OUTPUT_AUDIO_DIR

# 直接使用 ffmpeg 而不是调用 video2mp3.py
for emotion in Anger Anticipation Disgust Fear Joy Sadness Surprise Trust; do
    echo "  Processing $emotion audio..."

    emotion_dir="$TEMP_VIDEO_DIR/$emotion"
    output_emotion_dir="$OUTPUT_AUDIO_DIR/$emotion"

    if ls "$emotion_dir"/*.mp4 1> /dev/null 2>&1; then
        mkdir -p "$output_emotion_dir"

        for video_file in "$emotion_dir"/*.mp4; do
            if [[ -f "$video_file" ]]; then
                video_name=$(basename "$video_file" .mp4)
                audio_output_file="$output_emotion_dir/$video_name.mp3"

                # 检查是否已经处理过
                if [[ -f "$audio_output_file" ]]; then
                    echo "    Skip existing: $video_name.mp3"
                    continue
                fi

                echo "    Extracting audio: $video_name"

                # 使用更安全的 ffmpeg 命令，增加错误处理
                if ffmpeg -i "$video_file" -vn -acodec mp3 -ab 128k "$audio_output_file" -y > /dev/null 2>&1; then
                    echo "    ✓ Successfully extracted audio for $video_name"
                else
                    echo "    ✗ Error extracting audio for $video_name (possibly no audio stream)"
                    # 对于没有音频的视频，创建一个无声的 mp3 文件
                    ffmpeg -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 -t 1 -acodec mp3 "$audio_output_file" -y > /dev/null 2>&1
                fi
            fi
        done
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

                if [[ ! -f "$srt_file" ]]; then
                    # 创建简单的字幕占位符
                    cat > "$srt_file" << EOF
1
00:00:00,000 --> 00:00:01,000
[No subtitles available]

EOF
                fi
            fi
        done
    fi
done

echo "Step 5: Counting frames..."

for emotion in Anger Anticipation Disgust Fear Joy Sadness Surprise Trust; do
    echo "  Counting frames for $emotion..."

    emotion_frames_dir="$OUTPUT_FRAMES_DIR/$emotion"

    if [[ -d "$emotion_frames_dir" ]]; then
        for video_dir in "$emotion_frames_dir"/*; do
            if [[ -d "$video_dir" ]]; then
                video_name=$(basename "$video_dir")
                n_frames_file="$video_dir/n_frames"

                if [[ ! -f "$n_frames_file" ]]; then
                    # 统计 jpg 文件数量
                    jpg_count=$(find "$video_dir" -name "*.jpg" | wc -l)

                    if [[ $jpg_count -lt 16 ]]; then
                        echo "    Warning: $video_name has insufficient frames: $jpg_count"
                        echo "0" > "$n_frames_file"
                    else
                        echo "$jpg_count" > "$n_frames_file"
                        echo "    $video_name: $jpg_count frames"
                    fi
                fi
            fi
        done
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

echo "  Generating train/test splits..."

# 使用 Python 生成训练和测试分割
python3 << 'PYTHON_SCRIPT'
import os
import random

# 收集所有有效视频
all_videos = []
emotions = ['Anger', 'Anticipation', 'Disgust', 'Fear', 'Joy', 'Sadness', 'Surprise', 'Trust']

for i, emotion in enumerate(emotions, 1):
    emotion_dir = os.path.join('VAA_VideoEmotion8/imgs', emotion)
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

if len(all_videos) > 0:
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
else:
    print('No valid videos found - creating empty files')
    open('tools/annotations/ve8/trainlist01.txt', 'w').close()
    open('tools/annotations/ve8/testlist01.txt', 'w').close()
PYTHON_SCRIPT

# 检查是否需要安装 pandas
echo "  Generating JSON annotation file..."
if python3 -c "import pandas" 2>/dev/null; then
    cd tools
    python3 ve8_json.py
    cd ..
else
    echo "    pandas not found, installing..."
    pip install pandas
    cd tools
    python3 ve8_json.py
    cd ..
fi

# 复制 JSON 文件到主目录
if [[ -f "tools/annotations/ve8/ve8_01.json" ]]; then
    cp "tools/annotations/ve8/ve8_01.json" "VAA_VideoEmotion8/ve8.json"
    echo "  ✓ Created ve8.json"
fi

echo "Step 7: Cleanup temporary files..."
rm -rf $TEMP_VIDEO_DIR

echo ""
echo "=== Processing Complete ==="

# 统计结果
frame_count=$(find VAA_VideoEmotion8/imgs -name "*.jpg" | wc -l)
audio_count=$(find VAA_VideoEmotion8/mp3 -name "*.mp3" | wc -l)
srt_count=$(find VAA_VideoEmotion8/srt -name "*.srt" | wc -l)

echo "Results:"
echo "  Frames extracted: $frame_count"
echo "  Audio files: $audio_count"
echo "  Subtitle files: $srt_count"
echo ""
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