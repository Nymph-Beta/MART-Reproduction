# 🔧 MART 目录下 Shell 脚本功能分析

## 📁 脚本清单和分类

### 🎯 **数据预处理脚本**（已完成使命）
| 文件名 | 状态 | 作用 |
|--------|------|------|
| `process_with_existing_tools.sh` | 原始版本 | 初始数据预处理脚本 |
| `process_with_existing_tools_fixed.sh` | 修复版本 | 改进的数据预处理脚本 |

### 🚀 **训练启动脚本**
| 文件名 | 状态 | 作用 |
|--------|------|------|
| `run.sh` | 原始版本 | 简单的训练启动脚本 |
| `run_training_with_logs.sh` | 增强版本 | 完整的训练脚本（推荐使用） |

### 📊 **监控工具脚本**
| 文件名 | 状态 | 作用 |
|--------|------|------|
| `start_tensorboard.sh` | 新增 | TensorBoard可视化启动脚本 |

---

## 📝 各脚本详细功能

### 1️⃣ **数据预处理脚本对比**

#### `process_with_existing_tools.sh`（原始版本）
```bash
功能：VideoEmotionDataset → VAA_VideoEmotion8 格式转换
- 重组视频文件结构
- 提取视频帧（使用Python tools）
- 提取音频文件
- 生成字幕占位符
- 创建标注文件
```

#### `process_with_existing_tools_fixed.sh`（修复版本）✅
```bash
功能：改进的数据预处理（实际使用的版本）
- 更稳定的视频处理逻辑
- 增强的错误处理
- 直接使用ffmpeg而不是Python脚本
- 更好的帧数统计和验证
- 完整的结果统计报告
```

**关系**：Fixed版本是对原始版本的全面改进，解决了处理过程中的各种问题。

---

### 2️⃣ **训练启动脚本对比**

#### `run.sh`（原始版本）
```bash
功能：基础训练启动
- 设置固定的实验名称
- 复制源码到结果目录
- 使用nohup后台运行
- 输出重定向到result.txt

限制：
- 硬编码的实验名称
- 无日志记录系统
- 无TensorBoard支持
- 参数不灵活
```

#### `run_training_with_logs.sh`（增强版本）✅
```bash
功能：完整的训练解决方案
- 自动生成时间戳实验名
- 集成日志记录系统
- TensorBoard支持
- 灵活的参数配置
- 训练状态监控
- 结果路径管理

优势：
- 现代化的训练流程
- 完整的监控体系
- 便于调试和分析
```

**关系**：新版本是对原始版本的现代化重写，增加了企业级训练所需的所有功能。

---

### 3️⃣ **监控工具脚本**

#### `start_tensorboard.sh`（新增功能）
```bash
功能：TensorBoard可视化启动
- 自动寻找最新实验结果
- 启动TensorBoard服务
- 提供Web界面访问指导

配套功能：
- 与run_training_with_logs.sh协同工作
- 实时监控训练进度
- 可视化损失和准确率曲线
```

---

## 🔄 脚本之间的工作流程关系

### **完整的项目流程**
```
1. 数据预处理阶段
   VideoEmotionDataset (原始数据)
        ↓
   process_with_existing_tools_fixed.sh  (数据转换)
        ↓
   VAA_VideoEmotion8 (MART格式数据)

2. 训练阶段
   run_training_with_logs.sh  (启动训练)
        ↓
   VAA_VideoEmotion8/results/ (训练结果)

3. 监控阶段
   start_tensorboard.sh  (可视化监控)
        ↓
   Web界面 http://localhost:6006
```

### **脚本使用顺序**
1. **首次使用**：`process_with_existing_tools_fixed.sh` （仅需运行一次）
2. **日常训练**：`run_training_with_logs.sh` （每次训练）
3. **结果监控**：`start_tensorboard.sh` （可选，用于可视化）

---

## 📊 当前推荐使用的脚本

### ✅ **生产环境推荐**
- `run_training_with_logs.sh` - 主要训练脚本
- `start_tensorboard.sh` - 监控脚本

### ⚠️ **已过时/备用**
- `run.sh` - 原始训练脚本（功能有限）
- `process_with_existing_tools.sh` - 原始预处理（有bug）

### ✅ **已完成使命**
- `process_with_existing_tools_fixed.sh` - 数据预处理已完成

---

## 🎯 实际使用建议

**对于训练任务，只需要关注两个脚本：**

1. **启动训练**：
```bash
./run_training_with_logs.sh
```

2. **监控训练**：
```bash
./start_tensorboard.sh
```

其他脚本主要是历史版本或特定用途，不影响日常训练使用。