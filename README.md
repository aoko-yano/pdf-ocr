# PDF OCR（スキャン書籍の文字起こし）

スキャンしたPDFからテキストを抽出。Docker 上で OCR を実行します。

## 構成

```
pdf-ocr/
├── run.ps1          # 共通ラッパー
├── yomitoku/        # YomiToku エンジン
│   ├── Dockerfile
│   └── pdf_ocr.py
└── ndlocr/          # NDLOCR-Lite エンジン
    ├── Dockerfile
    └── pdf_ocr.py
```

## エンジン

| エンジン | 説明 | ライセンス |
|----------|------|------------|
| **YomiToku**（デフォルト） | [日本語特化 AI-OCR](https://github.com/kotaro-kinoshita/yomitoku) | CC BY-NC-SA 4.0 |
| **NDLOCR-Lite** | [国立国会図書館](https://github.com/ndl-lab/ndlocr-lite)・GPU不要・高速 | CC BY 4.0 |

## 使い方

```powershell
cd c:\Users\nanak\Dropbox\PKM\pdf-ocr

# YomiToku（デフォルト）
.\run.ps1 C:\path\to\book.pdf
.\run.ps1 .\book.pdf -Output result.md -Dpi 250 -Lite

# NDLOCR-Lite
.\run.ps1 .\book.pdf -Engine ndlocr
.\run.ps1 .\book.pdf -Engine ndlocr -Output result.md
```

## オプション

- `-Output`: 出力パス（省略時: 入力と同じディレクトリに `入力名.md`）
- `-Dpi`: 解像度（デフォルト: 200）
- `-Engine`: エンジン（`yomitoku` または `ndlocr`）
- `-Lite` / `--lite`: 軽量モード（yomitoku のみ、メモリ節約）

## 前提条件

- Docker Desktop
- 初回はイメージビルドに数分かかります（NDLOCR-Lite はモデル取得のためやや長め）

## 出力

- 出力先を指定しない場合: 入力 PDF と同じディレクトリに `入力名.md` が生成されます
- 入力・出力の親ディレクトリを Docker に直接マウントするため、data ディレクトリは不要です

## 注意

- **YomiToku**: CC BY-NC-SA 4.0。個人・研究目的は自由。商用利用は別途ライセンスが必要です。
- **NDLOCR-Lite**: CC BY 4.0。国立国会図書館が公開。
- CPU モードで動作（Docker 内）。GPU を使う場合はローカルにインストールして直接実行してください。
