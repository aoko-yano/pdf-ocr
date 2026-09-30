#!/bin/bash
# PDF OCR - Linux CLIラッパー
# 使い方: ./run.sh <input.pdf> [-o output.md] [-e yomitoku|ndlocr] [-d cuda|cpu] [--dpi 200] [--lite]
set -euo pipefail

usage() {
    echo "使い方: $0 <input.pdf> [-o output.md] [-e yomitoku|ndlocr] [-d cuda|cpu] [--dpi 200] [--lite]"
    exit 1
}

# デフォルト値
OUTPUT=""
ENGINE="yomitoku"
DEVICE="cuda"
DPI=200
LITE=""

# 引数パース
INPUT_PDF=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -e|--engine) ENGINE="$2"; shift 2 ;;
        -d|--device) DEVICE="$2"; shift 2 ;;
        --dpi)       DPI="$2";    shift 2 ;;
        --lite)      LITE="--lite"; shift ;;
        -h|--help)   usage ;;
        -*) echo "不明なオプション: $1"; usage ;;
        *)  INPUT_PDF="$1"; shift ;;
    esac
done

[[ -z "$INPUT_PDF" ]] && usage
[[ "$ENGINE" == yomitoku || "$ENGINE" == ndlocr ]] || { echo "不明なエンジン: $ENGINE"; usage; }
[[ "$DEVICE" == cuda || "$DEVICE" == cpu ]] || { echo "不明なデバイス: $DEVICE"; usage; }
# ndlocr は GPU にしても速くならない（実測 2026-09-30、4ページで CPU 12.3秒・GPU 11.7秒）ので CPU 固定
[[ "$ENGINE" == ndlocr ]] && DEVICE=cpu
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

# エンジン×デバイスごとに別イメージ（CPU 版に CUDA ライブラリを積まないため）
IMAGE="pdf-ocr-${ENGINE}-${DEVICE}"
GPU_OPT=()
DEVICE_OPT=""
if [[ "$DEVICE" == cuda ]]; then
    GPU_OPT=(--gpus all)
    DEVICE_OPT="--device cuda"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Docker 起動確認
docker info > /dev/null 2>&1 || { echo "エラー: Docker が起動していません"; exit 1; }

# イメージが未ビルドなら自動ビルド
if ! docker image inspect "$IMAGE" > /dev/null 2>&1; then
    echo "Dockerイメージをビルド中 (${ENGINE}, ${DEVICE})..."
    docker build --build-arg DEVICE="$DEVICE" -t "$IMAGE" "${SCRIPT_DIR}/${ENGINE}/"
fi

echo "OCR開始: ${INPUT_NAME} (${ENGINE}, ${DEVICE})"
echo "出力先: ${OUTPUT}"

# YomiToku はモデルを HuggingFace から取るので、ホストのキャッシュを貸して毎回の再取得（約100秒）を避ける
HF_CACHE="${HOME}/.cache/huggingface"
mkdir -p "$HF_CACHE"

# -u で実行ユーザーのUID:GIDを渡す（ファイルオーナーをrootにしない）
# /etc/passwd・/etc/group をマウント: PyTorch等がgetpwuid()でユーザー名を引くため必要
docker run --rm "${GPU_OPT[@]}" \
    -u "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    -v "${HF_CACHE}:/tmp/.cache/huggingface" \
    -v /etc/passwd:/etc/passwd:ro \
    -v /etc/group:/etc/group:ro \
    -v "${INPUT_DIR}:/input" \
    -v "${OUTPUT_DIR}:/output" \
    "$IMAGE" \
    "/input/${INPUT_NAME}" \
    "/output/${OUTPUT_NAME}" \
    --dpi "$DPI" \
    $LITE $DEVICE_OPT

echo "完了: ${OUTPUT}"
