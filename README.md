# PDF OCR（PDF→Markdown）

スキャンしたPDFをOCRで文字起こしし、Markdownとして保存します。  
処理はDocker上で実行します。

## 構成

```text
pdf-ocr/
├── run-gui.ps1      # WPF GUI（複数PDF一括処理）
├── run.ps1          # CLIラッパー
├── build-exe.ps1    # run-gui.ps1 から pdf-ocr.exe を生成
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
| `yomitoku`（デフォルト） | 日本語OCRモデル | CC BY-NC-SA 4.0 |
| `ndlocr` | NDLOCR-Lite（CPUでも高速） | CC BY 4.0 |

## 前提条件

- Docker Desktop が起動していること
- 初回実行時はイメージビルド／モデル取得のため時間がかかります

## GUIで使う（推奨）

```powershell
cd c:\Users\nanak\Dropbox\PKM\pdf-ocr
.\run-gui.ps1
```

GUIでできること：
- 複数PDFの選択
- フォルダ指定（再帰的にPDF収集）
- ファイル／フォルダのドラッグ＆ドロップ
- 出力先を入力元と同じフォルダ or 別フォルダで指定
- エンジン／DPI／Liteモード設定
- ファイル単位ログと最終集計表示

## EXEを作成して使う

```powershell
cd c:\Users\nanak\Dropbox\PKM\pdf-ocr
.\build-exe.ps1
```

生成後は `pdf-ocr.exe` を実行してください。

同じフォルダに置く必要があるもの：
- `pdf-ocr.exe`
- `run.ps1`
- `yomitoku/`
- `ndlocr/`

## CLIで使う

```powershell
cd c:\Users\nanak\Dropbox\PKM\pdf-ocr

# yomitoku（デフォルト）
.\run.ps1 C:\path\to\book.pdf
.\run.ps1 .\book.pdf -Output result.md -Dpi 250 -Lite

# ndlocr
.\run.ps1 .\book.pdf -Engine ndlocr
.\run.ps1 .\book.pdf -Engine ndlocr -Output result.md
```

主なオプション：
- `-Output` 出力Markdownパス（省略時は入力と同じフォルダ）
- `-Dpi` 画像DPI（デフォルト: 200）
- `-Engine` `yomitoku` または `ndlocr`
- `-Lite` `yomitoku` のみ有効

## トラブルシューティング

- GUIログに多くの行が出ても、最終的な成否は終了コードで判定されます。
- 全件が即失敗する場合は、Docker Desktopの起動状態を確認してください。
- スクリプト更新後にEXEの挙動が古い場合は、`.\build-exe.ps1` で再生成してください。

## ライセンス

このリポジトリはMIT Licenseです。詳細は [LICENSE](LICENSE) を参照してください。
