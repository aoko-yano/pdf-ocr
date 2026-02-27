# PDF OCR (scan-to-markdown)

Extract text from scanned PDF files by running OCR inside Docker.

## Structure

```text
pdf-ocr/
├── run-gui.ps1      # WPF GUI (multi-PDF batch)
├── run.ps1          # CLI wrapper
├── build-exe.ps1    # Build pdf-ocr.exe from run-gui.ps1
├── yomitoku/        # YomiToku engine
│   ├── Dockerfile
│   └── pdf_ocr.py
└── ndlocr/          # NDLOCR-Lite engine
    ├── Dockerfile
    └── pdf_ocr.py
```

## Engines

| Engine | Description | License |
|---|---|---|
| `yomitoku` (default) | Japanese OCR model | CC BY-NC-SA 4.0 |
| `ndlocr` | NDL OCR Lite, CPU-friendly | CC BY 4.0 |

## Prerequisites

- Docker Desktop (running)
- First run takes time for image build/model download

## GUI usage (recommended)

```powershell
cd c:\Users\nanak\Dropbox\PKM\pdf-ocr
.\run-gui.ps1
```

GUI features:
- Select multiple PDFs
- Select folder (recursive PDF scan)
- Drag and drop files/folders
- Output next to source or to a custom folder
- Engine/DPI/Lite options
- Per-file log and batch summary

## Build and run EXE

```powershell
cd c:\Users\nanak\Dropbox\PKM\pdf-ocr
.\build-exe.ps1
```

Then run `pdf-ocr.exe`.

Keep these in the same folder:
- `pdf-ocr.exe`
- `run.ps1`
- `yomitoku/`
- `ndlocr/`

## CLI usage

```powershell
cd c:\Users\nanak\Dropbox\PKM\pdf-ocr

# yomitoku (default)
.\run.ps1 C:\path\to\book.pdf
.\run.ps1 .\book.pdf -Output result.md -Dpi 250 -Lite

# ndlocr
.\run.ps1 .\book.pdf -Engine ndlocr
.\run.ps1 .\book.pdf -Engine ndlocr -Output result.md
```

Options:
- `-Output` output markdown path (default: same folder as input)
- `-Dpi` image DPI (default: 200)
- `-Engine` `yomitoku` or `ndlocr`
- `-Lite` only for `yomitoku`

## Troubleshooting

- If GUI shows many log lines, success/failure is decided by process exit code.
- If every task fails immediately, check Docker Desktop status.
- If EXE behaves differently, rebuild with `.\build-exe.ps1` after script updates.

## License

This repository is MIT licensed. See [LICENSE](LICENSE).
