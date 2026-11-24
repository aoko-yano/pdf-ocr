# PDF OCR - NDLOCR-Lite（国立国会図書館）
# https://github.com/ndl-lab/ndlocr-lite
# GPU不要・高速・CC BY 4.0

FROM python:3.11-slim-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    poppler-utils \
    git \
    && rm -rf /var/lib/apt/lists/*

# 版を固定する（ビルド時期で出力が変わらないように）。モデルはリポジトリの src/model に同梱
ARG NDLOCR_VERSION=2.0.0
WORKDIR /app
RUN git clone --depth 1 --branch "${NDLOCR_VERSION}" https://github.com/ndl-lab/ndlocr-lite.git \
    && pip install --no-cache-dir -r ndlocr-lite/requirements.txt

# pdf2image（PDF→画像変換）
RUN pip install --no-cache-dir pdf2image

COPY pdf_ocr.py /app/
ENV PYTHONUNBUFFERED=1
ENTRYPOINT ["python", "/app/pdf_ocr.py"]
CMD []
