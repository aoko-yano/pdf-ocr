"""
PDF OCR - NDLOCR-Lite エントリポイント（Docker 内で実行）

[NDLOCR-Lite](https://github.com/ndl-lab/ndlocr-lite)（国立国会図書館）で
スキャンPDFからテキストを抽出。GPU不要・高速。CC BY 4.0。
"""
import argparse
import subprocess
import sys
import tempfile
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description="PDF OCR（NDLOCR-Lite）")
    parser.add_argument("input_pdf", help="入力PDFファイル")
    parser.add_argument("output_md", nargs="?", help="出力Markdown（省略時: 入力名.md）")
    parser.add_argument("--dpi", type=int, default=200, help="PDF読取解像度（デフォルト: 200）")
    args = parser.parse_args()

    pdf_path = Path(args.input_pdf).resolve()
    output = args.output_md or str(pdf_path.with_name(pdf_path.stem + ".md"))

    if not pdf_path.exists():
        print(f"エラー: ファイルが見つかりません: {pdf_path}", file=sys.stderr)
        sys.exit(1)

    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        imgdir = tmp / "images"
        ocrout = tmp / "ocr_out"
        imgdir.mkdir()
        ocrout.mkdir()

        # PDF → 画像
        try:
            from pdf2image import convert_from_path
        except ImportError:
            print("エラー: pdf2image が必要です。poppler-utils も必要です。", file=sys.stderr)
            sys.exit(1)

        print(f"PDFを画像に変換中: {pdf_path}", flush=True)
        images = convert_from_path(str(pdf_path), dpi=args.dpi)
        for i, img in enumerate(images):
            img.save(imgdir / f"page_{i:04d}.png")

        if not images:
            print("エラー: PDFから画像を抽出できませんでした", file=sys.stderr)
            sys.exit(1)

        # NDLOCR-Lite 実行（Docker: /app/ndlocr-lite, ローカル: 同階層の ndlocr-lite）
        ndlocr_src = Path("/app/ndlocr-lite/src")
        if not ndlocr_src.exists():
            ndlocr_src = Path(__file__).resolve().parent / "ndlocr-lite" / "src"
        ocr_py = ndlocr_src / "ocr.py"
        if not ocr_py.exists():
            print(f"エラー: NDLOCR-Lite が見つかりません: {ocr_py}", file=sys.stderr)
            sys.exit(1)

        print("OCR実行中（NDLOCR-Lite）...", flush=True)
        result = subprocess.run(
            [sys.executable, str(ocr_py), "--sourcedir", str(imgdir), "--output", str(ocrout)],
            cwd=str(ndlocr_src),
        )
        if result.returncode != 0:
            sys.exit(result.returncode)

        # txt をページ順に結合
        txt_files = sorted(ocrout.glob("*.txt"))
        if not txt_files:
            print("エラー: NDLOCR-Lite の出力が見つかりません", file=sys.stderr)
            sys.exit(1)

        parts = []
        for f in txt_files:
            parts.append(f.read_text(encoding="utf-8", errors="replace"))

        out_path = Path(output)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text("\n\n".join(parts), encoding="utf-8")

    print(f"完了: {output}")


if __name__ == "__main__":
    main()
