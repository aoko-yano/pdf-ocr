# PDF OCR - YomiToku (日本語特化 AI-OCR)
# https://note.com/kotaro_kinoshita/n/n70df91659afc
# https://github.com/kotaro-kinoshita/yomitoku

FROM python:3.11-slim-bookworm

# DEVICE=cuda は gcc も入れる。PyTorch の一部の演算が Triton を通り、Triton は実行時に
# C コンパイラでランチャをビルドする（無いと "Failed to find C compiler" で落ちる）
ARG DEVICE=cpu
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1-mesa-glx \
    libglib2.0-0 \
    $([ "$DEVICE" = cuda ] && echo gcc libc6-dev) \
    && rm -rf /var/lib/apt/lists/*

# PyTorch + YomiToku
# DEVICE=cpu は CPU 専用インデックスを使う。CUDA 版は数GBあり、ダウンロードがタイムアウトしやすい。
# DEVICE=cuda は CUDA 13.0 版（ホストの NVIDIA ドライバ 580 以上が必要）。
RUN pip install --no-cache-dir --timeout 120 --retries 5 \
        --index-url https://download.pytorch.org/whl/$([ "$DEVICE" = cuda ] && echo cu130 || echo cpu) \
        torch torchvision \
    && pip install --no-cache-dir --timeout 120 --retries 5 yomitoku

WORKDIR /app
COPY pdf_ocr.py .

ENV PYTHONUNBUFFERED=1
ENTRYPOINT ["python", "/app/pdf_ocr.py"]
CMD []
