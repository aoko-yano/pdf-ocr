# PDF OCR - YomiToku (日本語特化 AI-OCR)
# https://note.com/kotaro_kinoshita/n/n70df91659afc
# https://github.com/kotaro-kinoshita/yomitoku

FROM python:3.11-slim-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# PyTorch (CPU) + YomiToku
# CPU専用インデックスを指定する。既定のPyPIホイールはCUDAライブラリを同梱していて
# 数GBあり、ダウンロードがタイムアウトしやすい。
RUN pip install --no-cache-dir --timeout 120 --retries 5 \
        --index-url https://download.pytorch.org/whl/cpu \
        torch torchvision \
    && pip install --no-cache-dir --timeout 120 --retries 5 yomitoku

WORKDIR /app
COPY pdf_ocr.py .

ENV PYTHONUNBUFFERED=1
ENTRYPOINT ["python", "/app/pdf_ocr.py"]
CMD []
