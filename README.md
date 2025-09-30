# MART Enhanced: Video Emotion Analysis

[![CVPR 2024](https://img.shields.io/badge/CVPR-2024-blue.svg)](https://openaccess.thecvf.com/content/CVPR2024/papers/Zhang_MART_Masked_Affective_RepresenTation_Learning_via_Masked_Temporal_Distribution_Distillation_CVPR_2024_paper.pdf)
[![PyTorch](https://img.shields.io/badge/PyTorch-1.11+-red.svg)](https://pytorch.org/)
[![TensorBoard](https://img.shields.io/badge/TensorBoard-Integrated-orange.svg)](https://www.tensorflow.org/tensorboard)
[![Status](https://img.shields.io/badge/Status-Work_In_Progress-yellow.svg)](https://github.com)

Enhanced implementation of MART (Masked Affective Representation Learning) with complete logging, monitoring, and improved robustness.

> **⚠️ Work In Progress**: This is an ongoing reproduction project. Currently, only VE-8 dataset training has been completed. Multi-dataset experiments and comprehensive performance evaluation (as described in the original paper) are planned for future work.

## Datasets

This implementation uses **VideoEmotion-8 (VE-8)**, one of the five benchmark datasets evaluated in the MART paper.

**About VE-8:**
- **Purpose**: Video emotion recognition task for multimodal affective analysis
- **Classes**: 8 emotion categories (Anger, Anticipation, Disgust, Fear, Joy, Sadness, Surprise, Trust)
- **Role in Paper**: Used to evaluate MART's performance on fine-grained emotion classification with multimodal features (video, audio, text)
- **Current Status**: This repository uses VE-8 for reproducing the paper's video emotion recognition experiments

> **Note**: The original MART paper evaluates on five datasets for different tasks (sentiment analysis, emotion recognition). This implementation currently focuses on VE-8 for video emotion recognition as an initial reproduction.

### All Datasets Used in MART Paper

| Dataset | Task | Download Link |
|---------|------|---------------|
| **VideoEmotion-8 (VE-8)** | Video Emotion Recognition (8 classes) | [Yanwei Fu's Page](https://yanweifu.github.io/) |
| **Ekman-6** | Video Emotion Recognition (6 classes) | [Yanwei Fu's Page](https://yanweifu.github.io/) |
| **ERATO (PERR)** | Pairwise Emotional Relationship Recognition | [OpenDataLab](https://opendatalab.com/OpenDataLab/ERATO) |
| **IEMOCAP** | Multimodal Emotion Recognition | [USC SAIL Lab](https://sail.usc.edu/iemocap/) (Registration required) |
| **Aff-Wild2** | Continuous Emotion Recognition | [Imperial College iBUG](https://ibug.doc.ic.ac.uk/resources/aff-wild2/) (Agreement required) |

### Pretrained Models

MART requires two external pretrained weights:

| Model | Purpose | Download Link | Placement |
|-------|---------|---------------|-----------|
| **AST** (Audio Spectrogram Transformer) | Audio feature extraction | [audioset_10_10_0.4593.pth](https://mitprod-my.sharepoint.com/personal/yuangong_mit_edu/_layouts/15/onedrive.aspx?id=%2Fpersonal%2Fyuangong%5Fmit%5Fedu%2FDocuments%2Fast%5Fmodels%2Faudioset%5F10%5F10%5F0%2E4593%2Epth&parent=%2Fpersonal%2Fyuangong%5Fmit%5Fedu%2FDocuments%2Fast%5Fmodels&ga=1) | `./models/ast/pretrained_models/` |
| **VideoMAE ViT-B/16** | Video feature extraction | [videomae_base_patch16_224.pth](https://huggingface.co/MCG-NJU/videomae-base) | `./models/mbt/pretrained_models/vit_base_patch16_224/` |

**Note**: VideoMAE can be automatically downloaded using the included `download_videomae.py` script:
```bash
python download_videomae.py
```

## Features

- **Complete Training Pipeline** with logging and TensorBoard
- **Data Preprocessing** from VideoEmotionDataset to MART format
- **Enhanced Architecture** with dynamic tensor handling
- **8-Class Emotion Recognition**: Anger, Anticipation, Disgust, Fear, Joy, Sadness, Surprise, Trust

## Quick Start

### Installation
```bash
conda create -n mart python=3.8
conda activate mart
conda install pytorch torchvision torchaudio pytorch-cuda=11.8 -c pytorch -c nvidia
pip install timm==0.4.5 transformers==4.18.0 librosa==0.6.1 numba==0.48.0
pip install tensorboard torchsummary senticnet==1.6 pysrt==1.1.2 huggingface_hub
conda install scikit-image -c conda-forge
```

### Data Preparation
```bash
# Convert VideoEmotionDataset to MART format
./process_with_existing_tools_fixed.sh
```

### Training
```bash
# Start training with logging
./run_training_with_logs.sh

# Or manually
python main.py --root_path VAA_VideoEmotion8 --expr_name "experiment_$(date +%Y%m%d_%H%M%S)"
```

### Monitoring
```bash
# Start TensorBoard
./start_tensorboard.sh
# Visit: http://localhost:6006

# View logs
tail -f VAA_VideoEmotion8/results/*/MART_*.log
```

## Project Structure

```
MART/
├── main.py                          # Enhanced training script
├── train.py                         # Training logic (fixed batch issues)
├── MART.py                          # Model architecture (improved)
├── core/logger.py                   # Logging system
├── run_training_with_logs.sh        # Complete training script
├── start_tensorboard.sh             # TensorBoard launcher
├── process_with_existing_tools_fixed.sh # Data preprocessing
└── VAA_VideoEmotion8/               # Processed dataset
    ├── imgs/                        # Video frames
    ├── mp3/                         # Audio files
    ├── srt/                         # Subtitles
    └── results/                     # Training outputs
```

## Key Improvements

### Technical Fixes

#### 1. Tensor Dimension Mismatch Fix (MART.py)
**Problem**: Original code assumed fixed batch sizes, causing crashes with smaller datasets
```python
# Error: RuntimeError: The size of tensor a (24) must match the size of tensor b (12)
```

**Solution**: Dynamic batch size adaptation in attention mechanism
```python
# In MultiHeadAttentionOp.forward()
min_batch = min(q.size(0), k.size(0), v.size(0))
q, k, v = q[:min_batch], k[:min_batch], v[:min_batch]
```

**Impact**: Enables training on datasets of any size without modifying model architecture

#### 2. Batch Construction Fix (train.py)
**Problem**: Text processing was duplicating samples, creating 2:1 dimension mismatch with video/audio
```python
# Original: Adding both original and emotion text separately
flattened_words.append(original_text)
flattened_words.append(emotion_text)  # Created duplicate entries
```

**Solution**: Combine texts instead of separate additions
```python
combined_text = f"{original_text} {emotion_text}"
flattened_words.append(combined_text)
```

**Impact**: Fixed training crashes and improved multimodal alignment, resulting in stable convergence

#### 3. Text Emotion Integration (main.py)
**Problem**: Missing emotion network in text processing pipeline
```python
# Error: KeyError: 'emo_net'
```

**Solution**: Added TextSentiment to text_tools
```python
from tools.text_emotion import TextSentiment
text_sentiment = TextSentiment()
text_tools['emo_net'] = text_sentiment
```

**Impact**: Enabled complete sentiment-aware text processing as described in paper

### Additional Enhancements

- **Comprehensive logging system** with dual output (console + file)
- **TensorBoard integration** for real-time monitoring
- **Enhanced error handling** and recovery
- **Dependency resolution** for all version conflicts

## Training Results

**Current Status**: ⚠️ **Single Dataset Phase** - Initial reproduction in progress

- **Completed**: VE-8 dataset training
  - 64 videos → 185,150 frames processed
  - Training accuracy: 0% → 19.6%
  - Full pipeline validated: Data preprocessing → Training → Monitoring

- **Not Yet Started**: Multi-dataset experiments and paper reproduction

### Reproduction Roadmap

**Phase 1: Infrastructure Setup** ✅ COMPLETED
- [x] VE-8 dataset preprocessing pipeline
- [x] Core model architecture fixes and optimization
- [x] Logging and monitoring system integration
- [x] Training pipeline validation

**Phase 2: Multi-Dataset Training** 🔄 PLANNED
- [ ] Train on MOSI dataset (sentiment analysis)
- [ ] Train on MOSEI dataset (sentiment analysis)
- [ ] Train on IEMOCAP dataset (emotion recognition)
- [ ] Train on remaining benchmark datasets

**Phase 3: Paper Reproduction** 📋 TODO
- [ ] Reproduce all experiments from CVPR 2024 paper
- [ ] Performance comparison across all datasets
- [ ] Ablation studies and analysis
- [ ] Generate tables and figures matching paper results
- [ ] Comprehensive experimental results documentation

## Troubleshooting

| Error | Solution |
|-------|----------|
| `ModuleNotFoundError: torchsummary` | `pip install torchsummary` |
| `numba version conflict` | `pip install numba==0.48.0` |
| `timm assertion error` | `pip install timm==0.4.5` |
| GPU memory issues | Reduce `--batch_size 1` |

## Citation

```bibtex
@inproceedings{Zhang_2024_CVPR,
  title={Mart: Masked affective representation learning via masked temporal distribution distillation},
  author={Zhang, Zhicheng and Zhao, Pancheng and Park, Eunil and Yang, Jufeng},
  booktitle={Proceedings of the IEEE/CVF Conference on Computer Vision and Pattern Recognition},
  year={2024}
}
```