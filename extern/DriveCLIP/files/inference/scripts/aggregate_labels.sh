#動画ごとのフレーム予測 JSON を読み込み、ラベル出現比率を表示・保存する Python スクリプト

#!/bin/bash
#SBATCH --job-name=aggregate_labels
#SBATCH --partition=a6000
#SBATCH --gres=gpu:0                       # GPU不要なら 0 に
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=2G
#SBATCH --output=/home/ryoc1220/DriveCLIP/logs/aggregate_labels_%j.out
#SBATCH --error=/home/ryoc1220/DriveCLIP/logs/aggregate_labels_%j.err
#SBATCH --time=00:10:00

#SLACK: notify-start
#SLACK: notify-end
#SLACK: notify-error

set -euo pipefail

# ---------- 必須：あなたのホスト上のプロジェクトルート ----------
HOST_PROJECT_ROOT=/home/ryoc1220/DriveCLIP

# Singularity image の絶対パス（実際の場所に合わせて修正）
SIF_PATH=${HOST_PROJECT_ROOT}/singularity/driveclip.sif

# リポジトリ内のスクリプト配置（コンテナ内では /workspace にマウントされる）
REPO_SUBDIR=inference

# 対象動画ID（必要に応じて配列ジョブに置き換え）
VIDEO_ID=test

# ホスト側の JSON と出力ディレクトリを直接指定（/workspace を使わない）
JSON_PATH_HOST=${HOST_PROJECT_ROOT}/data/frame_predictions/${VIDEO_ID}/frame_predictions_${VIDEO_ID}.json
OUTPUT_DIR_HOST=${HOST_PROJECT_ROOT}/data/frame_predictions/${VIDEO_ID}/aggregate

mkdir -p "${OUTPUT_DIR_HOST}"

# Singularity 実行：ホストのプロジェクトルートを /workspace にバインド
singularity exec --nv --cleanenv \
    --env PYTHONNOUSERSITE=1 \
    --bind ${HOST_PROJECT_ROOT}:/workspace \
    ${SIF_PATH} \
    bash -c "
      set -euo pipefail
      # container 内からは /workspace を参照できる
      JSON_PATH=/workspace/data/frame_predictions/${VIDEO_ID}/frame_predictions_${VIDEO_ID}.json
      OUTPUT_DIR=/workspace/data/frame_predictions/${VIDEO_ID}/aggregate
      mkdir -p \"\$OUTPUT_DIR\"


      # 実際に Python スクリプトを実行（inference フォルダにある aggregate_labels.py を想定）
      python3 /workspace/${REPO_SUBDIR}/aggregate_labels.py \
          --json_path \"\$JSON_PATH\" \
          --output_dir \"\$OUTPUT_DIR\"
    "

# host 側で結果を確認
echo "Saved outputs to: ${OUTPUT_DIR_HOST}"
ls -lh "${OUTPUT_DIR_HOST}" || true
