from huggingface_hub import hf_hub_download
import shutil

print('Downloading VideoMAE model...')

# 下载模型文件
model_path = hf_hub_download(
    repo_id='MCG-NJU/videomae-base',
    filename='pytorch_model.bin'
)

# 移动到指定位置
target_path = 'models/mbt/pretrained_models/videomae_base_patch16_224.pth'
shutil.move(model_path, target_path)

print(f'✓ Model downloaded to: {target_path}')
  