# 保存された JSON を読み込んで 結果を解析・可視化するスクリプト

#!/bin/bash
#SBATCH --job-name=check_frame_predictions
#SBATCH --partition=a6000
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --time=00:10:00
#SBATCH --output=/home/ryoc1220/research/driveclip/experiments/logs/check_predictions.%A_%a.out
#SBATCH --error=/home/ryoc1220/research/driveclip/experiments/logs/check_predictions.%A_%a.err
#SBATCH --array=0-0   # 動画数に合わせて変更

#SLACK: notify-start
#SLACK: notify-end
#SLACK: notify-error

set -euo pipefail

# JSON のパス
VIDEO_NAME="test"   # 動画名に合わせて変更
JSON_PATH="/home/ryoc1220/shared/datasets/driveclip/data/frame_predictions/${VIDEO_NAME}/frame_predictions_${VIDEO_NAME}.json"

# Python スクリプトをここで直接実行（ダブルクォートで変数展開）
python3 - <<PYTHON_EOF
import json
from pathlib import Path
from collections import Counter

json_path = Path("${JSON_PATH}")

with open(json_path, 'r') as f:
    results = json.load(f)

print("=== Frame predictions ===")
for frame_path, info in results.items():
    print(f"{frame_path}: label={info['prediction']}, prob={info['prob_score']}")

# ラベル集計
labels = [info['prediction'] for info in results.values()]
label_counts = Counter(labels)
print("\n=== Label counts ===")
for label, count in label_counts.items():
    print(f"Label {label}: {count} frames")
PYTHON_EOF
