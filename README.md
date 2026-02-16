# PDF OCR（スキャン書籍の文字起こし）

スキャンしたPDFからテキストを抽出。[YomiToku](https://github.com/kotaro-kinoshita/yomitoku)（日本語特化 AI-OCR）を Docker 上で実行します。

- [YomiToku 紹介記事](https://note.com/kotaro_kinoshita/n/n70df91659afc)

## 使い方

```powershell
cd c:\Users\nanak\Dropbox\PKM\pdf-ocr

# 入力ファイルを渡すだけ（出力は入力と同じディレクトリに 入力名.md）
# 入力は data 外でも可（実行前に data にコピーして作業）
.\run.ps1 .\data\book.pdf
.\run.ps1 C:\path\to\other\book.pdf

# 出力先を指定（任意のディレクトリ、相対パスはカレントディレクトリ基準）
.\run.ps1 .\data\book.pdf -Output .\output\book.md
.\run.ps1 .\data\book.pdf -Output C:\path\to\result.md

# 解像度を指定（デフォルト 200）
.\run.ps1 .\data\book.pdf -Dpi 250

# 軽量モード（メモリ節約、大容量PDF向け）
.\run.ps1 .\data\book.pdf -Lite
```

## 前提条件

- Docker Desktop（Windows）
- 初回はイメージビルドに数分かかります

## 出力

- 出力先を指定しない場合: 入力 PDF と同じディレクトリに `入力名.md` が生成されます
- `-Output` で指定した場合: 指定したパスに生成されます（ディレクトリがなければ自動作成）

## 注意

- YomiToku は CC BY-NC-SA 4.0。個人・研究目的は自由。商用利用は別途ライセンスが必要です。
- CPU モードで動作（Docker 内）。GPU を使う場合はローカルに yomitoku をインストールして直接実行してください。
