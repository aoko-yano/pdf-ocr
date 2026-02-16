# PDF OCR - YomiToku（Docker 実行）
# 使い方: .\run.ps1 input.pdf [-Output output.md]
# 入力が data 外でも可。実行前に data にコピーして作業し、終了後に必要なら出力を移動

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$InputPdf,
    [Parameter(Mandatory=$false)]
    [string]$Output = "",
    [Parameter(Mandatory=$false)]
    [int]$Dpi = 200,
    [Parameter(Mandatory=$false)]
    [switch]$Lite
)

$ErrorActionPreference = "Stop"

$InputPdf = $InputPdf.Trim() -replace "`r`n", "" -replace "`n", ""

if (-not (Test-Path $InputPdf)) {
    Write-Error "ファイルが見つかりません: $InputPdf"
}

$inputFullPath = (Resolve-Path $InputPdf).Path
$inputDir = Split-Path $inputFullPath -Parent
$inputName = Split-Path $inputFullPath -Leaf

# 作業用 data ディレクトリ（pdf-ocr/data）
$workingDir = Join-Path $PSScriptRoot "data"
if (-not (Test-Path $workingDir)) {
    New-Item -ItemType Directory -Path $workingDir -Force | Out-Null
}
$workingDir = (Resolve-Path $workingDir).Path

# 入力が data 外ならコピー（コピーした場合は終了後に削除が必要）
$dockerInputPathLocal = $inputFullPath
if (-not $inputFullPath.StartsWith($workingDir + [System.IO.Path]::DirectorySeparatorChar) -and $inputFullPath -ne $workingDir) {
    $dockerInputPathLocal = Join-Path $workingDir $inputName
    Copy-Item -Path $inputFullPath -Destination $dockerInputPathLocal -Force
}
$dockerInputPathInContainer = "/data/" + ([System.IO.Path]::GetRelativePath($workingDir, $dockerInputPathLocal) -replace "\\", "/")

# 出力パス: -Output で指定。相対パスはカレントディレクトリ基準
$outputSpec = if ($Output) { $Output.Trim() } else { "" }

if ($outputSpec) {
    $outputFullPath = if ([System.IO.Path]::IsPathRooted($outputSpec)) {
        [System.IO.Path]::GetFullPath($outputSpec)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $outputSpec))
    }
} else {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($inputName)
    $outputFullPath = Join-Path $inputDir ($baseName + ".md")
}

$outputDir = Split-Path $outputFullPath -Parent
$outputName = Split-Path $outputFullPath -Leaf

# 出力が data 内かどうか（data 外なら Docker 終了後に移動が必要）
$outputDirNorm = [System.IO.Path]::GetFullPath($outputDir)
$workingDirNorm = [System.IO.Path]::GetFullPath($workingDir)
$needMoveOutput = ($outputDirNorm -ne $workingDirNorm) -and -not $outputFullPath.StartsWith($workingDirNorm + [System.IO.Path]::DirectorySeparatorChar)

# Docker 内では常に /data に出力。data 外の場合は一時ファイルで出力し、終了後に移動
$dockerOutputName = if ($needMoveOutput) { "ocr_output_temp.md" } else { $outputName }

docker info 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Dockerが起動していません。Docker Desktopを起動してください。"
}

$imageName = "pdf-ocr"
docker image inspect $imageName 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "イメージをビルド中..."
    docker build -t $imageName .
    if ($LASTEXITCODE -ne 0) { exit 1 }
}

Write-Host "OCR実行中: $inputName (YomiToku)"
Write-Host "出力先: $outputFullPath"
Write-Host ""

# 常に data ディレクトリを /data にマウント
$dockerArgs = @(
    "run", "--rm",
    "-v", "${workingDir}:/data",
    $imageName,
    $dockerInputPathInContainer,
    "/data/$dockerOutputName",
    "--dpi", $Dpi
)
if ($Lite) { $dockerArgs += "--lite" }
& docker $dockerArgs

if ($LASTEXITCODE -eq 0) {
    if ($needMoveOutput) {
        # 出力先が data 外: ファイルを移動
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        Move-Item -Path (Join-Path $workingDir $dockerOutputName) -Destination $outputFullPath -Force
    }
    if ($dockerInputPathLocal -ne $inputFullPath) {
        Remove-Item -Path $dockerInputPathLocal -Force -ErrorAction SilentlyContinue
    }
    Write-Host ""
    Write-Host "完了: $outputFullPath"
} else {
    if ($dockerInputPathLocal -ne $inputFullPath) {
        Remove-Item -Path $dockerInputPathLocal -Force -ErrorAction SilentlyContinue
    }
    Write-Host ""
    Write-Error "OCR処理でエラーが発生しました (終了コード: $LASTEXITCODE)"
    exit $LASTEXITCODE
}
