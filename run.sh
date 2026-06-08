#!/bin/bash
# PDF OCR - Linux CLIラッパー
# 使い方: ./run.sh <input.pdf> [-o output.md] [-e yomitoku|ndlocr] [--dpi 200] [--lite]
set -euo pipefail

usage() {
    echo "使い方: $0 <input.pdf> [-o output.md] [-e yomitoku|ndlocr] [--dpi 200] [--lite]"
    exit 1
}

# デフォルト値
OUTPUT=""
ENGINE="yomitoku"
DPI=200
LITE=""

# 引数パース
INPUT_PDF=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -e|--engine) ENGINE="$2"; shift 2 ;;
        --dpi)       DPI="$2";    shift 2 ;;
        --lite)      LITE="--lite"; shift ;;
        -h|--help)   usage ;;
        -*) echo "不明なオプション: $1"; usage ;;
        *)  INPUT_PDF="$1"; shift ;;
    esac
done

[[ -z "$INPUT_PDF" ]] && usage
INPUT_PDF="$(realpath "$INPUT_PDF")"
[[ ! -f "$INPUT_PDF" ]] && { echo "エラー: ファイルが見つかりません: $INPUT_PDF"; exit 1; }

INPUT_DIR="$(dirname "$INPUT_PDF")"
INPUT_NAME="$(basename "$INPUT_PDF")"
BASE_NAME="${INPUT_NAME%.pdf}"

if [[ -z "$OUTPUT" ]]; then
    OUTPUT="${INPUT_DIR}/${BASE_NAME}.md"
fi
OUTPUT="$(realpath -m "$OUTPUT")"
OUTPUT_DIR="$(dirname "$OUTPUT")"
OUTPUT_NAME="$(basename "$OUTPUT")"
mkdir -p "$OUTPUT_DIR"

# イメージ名
if [[ "$ENGINE" == "ndlocr" ]]; then
    IMAGE="pdf-ocr-ndlocr"
    ENGINE_DIR="ndlocr"
else
    IMAGE="pdf-ocr-yomitoku"
    ENGINE_DIR="yomitoku"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Docker 起動確認
docker info > /dev/null 2>&1 || { echo "エラー: Docker が起動していません"; exit 1; }

# イメージが未ビルドなら自動ビルド
if ! docker image inspect "$IMAGE" > /dev/null 2>&1; then
    echo "Dockerイメージをビルド中 (${ENGINE})..."
    docker build -t "$IMAGE" "${SCRIPT_DIR}/${ENGINE_DIR}/"
fi

echo "OCR開始: ${INPUT_NAME} (${ENGINE})"
echo "出力先: ${OUTPUT}"

# -u で実行ユーザーのUID:GIDを渡す（ファイルオーナーをrootにしない）
# /etc/passwd・/etc/group をマウント: PyTorch等がgetpwuid()でユーザー名を引くため必要
docker run --rm \
    -u "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    -v /etc/passwd:/etc/passwd:ro \
    -v /etc/group:/etc/group:ro \
    -v "${INPUT_DIR}:/input" \
    -v "${OUTPUT_DIR}:/output" \
    "$IMAGE" \
    "/input/${INPUT_NAME}" \
    "/output/${OUTPUT_NAME}" \
    --dpi "$DPI" \
    $LITE

echo "完了: ${OUTPUT}"
