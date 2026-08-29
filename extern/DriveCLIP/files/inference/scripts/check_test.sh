#!/bin/bash
#SBATCH --job-name=DriveCLIP_infer
#SBATCH --partition=a6000
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=8G
#SBATCH --output=/home/ryoc1220/research/driveclip/experiments/logs/driveclip_infer.%A_%a.out
#SBATCH --error=/home/ryoc1220/research/driveclip/experiments/logs/driveclip_infer.%A_%a.err
#SBATCH --time=02:00:00
#SBATCH --array=0-0   # video_list.txt の行数に合わせて変更すること

# SLACK コメント行はあなたの環境で必要なら追加して下さい
#SLACK: notify-start
#SLACK: notify-end
#SLACK: notify-error

set -euo pipefail

# ---------------------------
# 環境 / パス（必要なら書き換える）
# ---------------------------
# Singularity image の実パスに置き換えてください．
SIF_PATH=/home/ryoc1220/shared/containers/driveclip.sif

# プロジェクトルート（ホスト）
HOST_PROJECT_ROOT=/home/ryoc1220/shared/extern/DriveCLIP

# リポジトリ内 inference スクリプトの位置（バインド後は /workspace/inference）
REPO_SUBDIR=inference

# 動画リスト（各行: <相対パス> <video_id>、例: data/video/foo.MP4 foo）
VIDEO_LIST=${HOST_PROJECT_ROOT}/${REPO_SUBDIR}/scripts/video_list.txt

# 実行時に必要に応じて変更
MASTER_PORT=29504

# ログ用ディレクトリ
mkdir -p ${HOST_PROJECT_ROOT}/logs
mkdir -p ${HOST_PROJECT_ROOT}/data/frame_predictions
mkdir -p ${HOST_PROJECT_ROOT}/${REPO_SUBDIR}/results

# ---------------------------
# NCCL / 分散用（推論では多く不要だが既存スタイルを踏襲）
# ---------------------------
export NCCL_DEBUG=INFO
export NCCL_ASYNC_ERROR_HANDLING=1
export NCCL_BLOCKING_WAIT=1
export NCCL_IB_DISABLE=1
export NCCL_NET=Socket
export TORCH_DISTRIBUTED_DEBUG=DETAIL

# 追加 NCCL 設定（必要に応じて調整）
export NCCL_P2P_DISABLE=1
export NCCL_SHM_DISABLE=0
export NCCL_SOCKET_IFNAME=^docker0,lo

export MASTER_PORT=${MASTER_PORT}
# GPU 指定（SLURM が管理するので通常は不要だが念のため）
# export CUDA_VISIBLE_DEVICES=0

# ---------------------------
# ジョブ配列 index から対象動画を取得
# ---------------------------
if [ ! -f "${VIDEO_LIST}" ]; then
  echo "ERROR: VIDEO_LIST not found at ${VIDEO_LIST}"
  exit 1
fi

LINE_NUM=$((SLURM_ARRAY_TASK_ID+1))
LINE=$(sed -n "${LINE_NUM}p" ${VIDEO_LIST})
if [ -z "${LINE}" ]; then
  echo "ERROR: No line ${LINE_NUM} in ${VIDEO_LIST}"
  exit 1
fi

VIDEO_REL=$(echo ${LINE} | awk '{print $1}')
VIDEO_ID=$(echo ${LINE} | awk '{print $2}')

if [ -z "${VIDEO_REL}" ] || [ -z "${VIDEO_ID}" ]; then
  echo "ERROR: video_list.txt format invalid at line ${LINE_NUM}. Expected '<path> <id>'"
  exit 1
fi

# ---------------------------
# ジョブ固有ディレクトリ
# ---------------------------
JOB_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_DIR=${HOST_PROJECT_ROOT}/runs/DriveCLIP_${JOB_TIMESTAMP}_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}
mkdir -p ${OUTPUT_DIR}

echo "[$(date)] JOB START: ${VIDEO_ID}"
echo "Video: ${VIDEO_REL}"
echo "Output dir: ${OUTPUT_DIR}"

# ---------------------------
# 実行: singularity exec
#  ワンライナーで内部シェルを実行する形式に合わせる
# ---------------------------
singularity exec --nv --cleanenv \
  --env PYTHONNOUSERSITE=1 \
  --bind /home/ryoc1220/shared/extern/DriveCLIP:/workspace \
  /home/ryoc1220/shared/containers/driveclip.sif \
  python3 - <<'PY'
import sys
import numpy, importlib
print('python', sys.version.split()[0])
print('numpy', numpy.__version__, numpy.__file__)
try:
    import cv2
    print('cv2', cv2.__version__, cv2.__file__)
except Exception as e:
    print('cv2 import ERROR:', e)
PY
