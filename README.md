# PDF OCR（PDF→Markdown）

スキャンしたPDFをOCRで文字起こしし、Markdownとして保存します。  
処理はDocker上で実行します。

born-digital のPDF（テキスト層があるもの）には使わないでください。`pdftotext` のほうが正確です。

## 構成

```text
pdf-ocr/
├── run.sh           # CLIラッパー
├── yomitoku/        # YomiToku エンジン
│   ├── Dockerfile
│   └── pdf_ocr.py
└── ndlocr/          # NDLOCR-Lite エンジン
    ├── Dockerfile
    └── pdf_ocr.py
```

## エンジン

| エンジン | 説明 | ライセンス |
|---|---|---|
| `yomitoku`（デフォルト） | 日本語OCRモデル。GPUで約13倍速い（実測: 4ページで CPU 78秒・GPU 6秒） | CC BY-NC-SA 4.0 |
| `ndlocr` | NDLOCR-Lite（v2.0.0 に固定。版は `ndlocr/Dockerfile` の `NDLOCR_VERSION`）。CPUでも速く、GPUにしても変わらないので常に CPU で動く。日本語専用で、é・è・à などは文字セットに無く脱落するので仏語には使えない | CC BY 4.0 |

## 前提条件

- Docker が起動していること
- GPU（`-d cuda`、デフォルト）を使う場合は NVIDIA ドライバ 580 以上と NVIDIA Container Toolkit。
  VRAM 8GB では llama-server（`localchat`）と同時に動かせないので、先に止めておく
- 初回実行時はイメージビルド／モデル取得のため時間がかかります。
  イメージはエンジン×デバイスごとに別で、`pdf-ocr-<engine>-<device>` という名前です

## 使い方

```bash
# yomitoku・GPU（デフォルト）
./run.sh /path/to/book.pdf
./run.sh book.pdf -o result.md --dpi 250

# ndlocr（常に CPU）
./run.sh book.pdf -e ndlocr

# yomitoku を CPU で動かす
./run.sh book.pdf -d cpu
```

主なオプション：
- `-o`, `--output` 出力Markdownパス（省略時は入力と同じフォルダ）
- `-e`, `--engine` `yomitoku` または `ndlocr`
- `-d`, `--device` `cuda` または `cpu`（デフォルト: `cuda`。`ndlocr` では無視）
- `--dpi` 画像DPI（デフォルト: 200）

## トラブルシューティング

- `pdf_ocr.py` や `Dockerfile` を更新したら、該当イメージを消して再ビルドさせてください
  （`docker rmi pdf-ocr-yomitoku-cuda` など）。
- `-d cuda` で `out of memory` が出たら、VRAM を使っている他のプロセス（llama-server など）を
  止めるか、`-d cpu` で実行してください。
- YomiToku のモデルは初回に HuggingFace から取得し、`~/.cache/huggingface` に置きます。

## ライセンス

このリポジトリはMIT Licenseです。詳細は [LICENSE](LICENSE) を参照してください。
