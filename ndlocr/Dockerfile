# PDF OCR - NDLOCR-Lite（国立国会図書館）
# https://github.com/ndl-lab/ndlocr-lite
# GPU不要・高速・CC BY 4.0

FROM python:3.11-slim-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    poppler-utils \
    git \
    git-lfs \
    curl \
    && rm -rf /var/lib/apt/lists/*

# NDLOCR-Lite を clone（モデルは git-lfs またはリポジトリに含まれる）
WORKDIR /app
RUN git lfs install \
    && git clone --depth 1 https://github.com/ndl-lab/ndlocr-lite.git \
    && cd ndlocr-lite \
    && git lfs pull \
    && pip install --no-cache-dir -r requirements.txt

# pdf2image（PDF→画像変換）
RUN pip install --no-cache-dir pdf2image

# モデルがなければリリースから取得（リポジトリに含まれない場合）
RUN cd /app/ndlocr-lite \
    && if [ ! -d src/model ] || [ -z "$(ls -A src/model 2>/dev/null)" ]; then \
        echo "モデルをリリースから取得中..."; \
        curl -sL "https://github.com/ndl-lab/ndlocr-lite/releases/download/1.1.0/ndlocr_lite_v1.1.0_linux.tar.gz" -o /tmp/ndlocr.tar.gz; \
        mkdir -p /tmp/ndl_extract && tar -xzf /tmp/ndlocr.tar.gz -C /tmp/ndl_extract; \
        MODEL_DIR=$(find /tmp/ndl_extract -name "model" -type d 2>/dev/null | head -1); \
        [ -n "$MODEL_DIR" ] && mkdir -p src/model && cp -r "$MODEL_DIR"/* src/model/ 2>/dev/null || true; \
        rm -rf /tmp/ndlocr.tar.gz /tmp/ndl_extract; \
    fi

COPY pdf_ocr.py /app/
ENV PYTHONUNBUFFERED=1
ENTRYPOINT ["python", "/app/pdf_ocr.py"]
CMD []
