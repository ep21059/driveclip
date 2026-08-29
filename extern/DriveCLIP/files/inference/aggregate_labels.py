#!/usr/bin/env python3
import json
import argparse
from pathlib import Path
from collections import Counter
import matplotlib.pyplot as plt

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--json_path', required=True, help='Path to frame predictions JSON')
    parser.add_argument('--output_dir', required=True, help='Directory to save aggregated results')
    return parser.parse_args()

def main():
    args = parse_args()
    Path(args.output_dir).mkdir(parents=True, exist_ok=True)

    # JSON 読み込み
    with open(args.json_path) as f:
        frame_data = json.load(f)

    # ラベル集計
    labels = [v['prediction'] for v in frame_data.values()]
    counts = Counter(labels)

    print("=== Label counts ===")
    for label, c in counts.items():
        print(f"Label {label}: {c} frames")

    # 簡易可視化
    plt.bar(counts.keys(), counts.values())
    plt.xlabel('Label')
    plt.ylabel('Frame count')
    plt.title('Frame Label Distribution')
    plt.savefig(Path(args.output_dir) / 'label_distribution.png')
    print("Saved bar chart to", Path(args.output_dir) / 'label_distribution.png')

if __name__ == "__main__":
    main()
