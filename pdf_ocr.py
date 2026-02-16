"""
PDF OCR - YomiToku エントリポイント（Docker 内で実行）

[YomiToku](https://github.com/kotaro-kinoshita/yomitoku) 日本語特化 AI-OCR で
スキャンPDFからテキストを抽出。https://note.com/kotaro_kinoshita/n/n70df91659afc
"""
import argparse
import subprocess
import sys
import tempfile
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description="PDF OCR（YomiToku）")
    parser.add_argument("input_pdf", help="入力PDFファイル")
    parser.add_argument("output_md", nargs="?", help="出力Markdown（省略時: 入力名.md）")
    parser.add_argument("--dpi", type=int, default=200, help="PDF読取解像度（デフォルト: 200）")
    parser.add_argument("--lite", action="store_true", help="軽量モード（メモリ節約）")
    args = parser.parse_args()

    pdf_path = Path(args.input_pdf).resolve()
    output = args.output_md or str(pdf_path.with_name(pdf_path.stem + ".md"))

    if not pdf_path.exists():
        print(f"エラー: ファイルが見つかりません: {pdf_path}", file=sys.stderr)
        sys.exit(1)

    with tempfile.TemporaryDirectory() as tmpdir:
        outdir = Path(tmpdir) / "ocr_out"
        outdir.mkdir()

        cmd = [
            "yomitoku",
            str(pdf_path),
            "-f", "md",
            "-o", str(outdir),
            "--dpi", str(args.dpi),
            "-d", "cpu",
            "--combine",
        ]
        if args.lite:
            cmd.append("--lite")

        print(f"処理中: {pdf_path}", flush=True)
        result = subprocess.run(cmd, cwd="/data")
        if result.returncode != 0:
            sys.exit(result.returncode)

        md_files = sorted(outdir.rglob("*.md"))
        if not md_files:
            print("エラー: YomiToku の出力が見つかりません", file=sys.stderr)
            sys.exit(1)

        parts = []
        for f in md_files:
            parts.append(f.read_text(encoding="utf-8", errors="replace"))

        Path(output).write_text("\n\n".join(parts), encoding="utf-8")

    print(f"完了: {output}")


if __name__ == "__main__":
    main()
