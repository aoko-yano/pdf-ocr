# PDF OCR（Docker 実行）
# 使い方: .\run.ps1 input.pdf [-Output output.md] [-Engine yomitoku|ndlocr]
# 任意のパスの PDF を任意のパスの md に出力（data ディレクトリ不要）

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$InputPdf,
    [Parameter(Mandatory=$false)]
    [string]$Output = "",
    [Parameter(Mandatory=$false)]
    [int]$Dpi = 200,
    [Parameter(Mandatory=$false)]
    [switch]$Lite,
    [Parameter(Mandatory=$false)]
    [ValidateSet("yomitoku", "ndlocr")]
    [string]$Engine = "yomitoku"
)

$ErrorActionPreference = "Stop"

$InputPdf = $InputPdf.Trim() -replace "`r`n", "" -replace "`n", ""

if (-not (Test-Path $InputPdf)) {
    Write-Error "ファイルが見つかりません: $InputPdf"
}

$inputFullPath = (Resolve-Path $InputPdf).Path
$inputDir = Split-Path $inputFullPath -Parent
$inputName = Split-Path $inputFullPath -Leaf

# 出力パス
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

if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

docker info 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Dockerが起動していません。Docker Desktopを起動してください。"
}

$scriptDir = if ($PSScriptRoot) { (Resolve-Path $PSScriptRoot).Path } else { (Get-Location).Path }
$imageName = if ($Engine -eq "ndlocr") { "pdf-ocr-ndlocr" } else { "pdf-ocr" }
$engineDir = if ($Engine -eq "ndlocr") { "ndlocr" } else { "yomitoku" }

docker image inspect $imageName 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "イメージをビルド中 ($Engine)..."
    docker build -f (Join-Path $engineDir "Dockerfile") -t $imageName (Join-Path $scriptDir $engineDir)
    if ($LASTEXITCODE -ne 0) { exit 1 }
}

$engineLabel = if ($Engine -eq "ndlocr") { "NDLOCR-Lite" } else { "YomiToku" }
Write-Host "OCR実行中: $inputName ($engineLabel)"
Write-Host "出力先: $outputFullPath"
Write-Host ""

# 入力・出力の親ディレクトリを直接マウント（data 経由なし）
$dockerArgs = @(
    "run", "--rm",
    "-v", "${inputDir}:/input",
    "-v", "${outputDir}:/output",
    $imageName,
    "/input/$inputName",
    "/output/$outputName",
    "--dpi", $Dpi
)
if ($Engine -eq "yomitoku" -and $Lite) { $dockerArgs += "--lite" }
& docker $dockerArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "完了: $outputFullPath"
} else {
    Write-Host ""
    Write-Error "OCR処理でエラーが発生しました (終了コード: $LASTEXITCODE)"
    exit $LASTEXITCODE
}
