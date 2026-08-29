# driveclip

CLIP を使ったドライバ行動認識の実験。DriveCLIP（Zahid Hasan 他）の
公開実装に対して推論部分を改造し、フレーム単位の予測を動画単位の
ラベルに集約する処理を追加したもの。

## このリポジトリの位置づけ

**upstream のコードは含めない。** 実装本体は
[zahid-isu/DriveCLIP](https://github.com/zahid-isu/DriveCLIP) の
コミット `782ae3b` であり、こちらのコミットは1件も入っていない。
ここに置くのは、その上で加えた改変と追加だけ。

| | 内容 |
|---|---|
| `extern/DriveCLIP/modifications.patch` | `inference/inference.py`（+72/−18行）と `inference/frame.py`（+1行）への改変 |
| `extern/DriveCLIP/files/inference/aggregate_labels.py` | フレーム予測を動画単位ラベルへ集約する自作スクリプト |
| `extern/DriveCLIP/files/inference/scripts/` | 実行・検証用シェルスクリプト5本と対象動画リスト |

## 復元のしかた

```bash
git clone https://github.com/zahid-isu/DriveCLIP
cd DriveCLIP && git checkout 782ae3b
cp -r <このリポジトリ>/extern/DriveCLIP/files/. .
git apply <このリポジトリ>/extern/DriveCLIP/modifications.patch
```

## 実データの置き場所

| | 場所 | 容量 |
|---|---|---|
| 入力動画 | `~/data/driveclip/video/` | 755 MB |
| フレーム予測結果 | `~/work/driveclip/frame_predictions/` | 190 MB |
| 実行ログ | `~/work/driveclip/logs/` | 172 KB |
| Singularity イメージ | `~/containers/driveclip.sif` | 15 GB |
