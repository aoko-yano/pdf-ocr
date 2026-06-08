param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$InputPdf,
    [Parameter(Mandatory = $false)]
    [string]$Output = "",
    [Parameter(Mandatory = $false)]
    [int]$Dpi = 200,
    [Parameter(Mandatory = $false)]
    [switch]$Lite,
    [Parameter(Mandatory = $false)]
    [ValidateSet("yomitoku", "ndlocr")]
    [string]$Engine = "yomitoku"
)

$ErrorActionPreference = "Stop"

# On PowerShell 7+, native stderr can become terminating errors.
# yomiToku logs INFO to stderr, so disable that behavior.
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    Set-Variable -Name PSNativeCommandUseErrorActionPreference -Value $false
}

$InputPdf = $InputPdf.Trim() -replace "`r`n", "" -replace "`n", ""
if (-not (Test-Path -LiteralPath $InputPdf)) {
    Write-Error ("File not found: {0}" -f $InputPdf)
    exit 1
}

$inputFullPath = (Resolve-Path -LiteralPath $InputPdf).Path
$inputDir = Split-Path -Path $inputFullPath -Parent
$inputName = Split-Path -Path $inputFullPath -Leaf

$outputSpec = if ($Output) { $Output.Trim() } else { "" }
if ($outputSpec) {
    if ([System.IO.Path]::IsPathRooted($outputSpec)) {
        $outputFullPath = [System.IO.Path]::GetFullPath($outputSpec)
    } else {
        $outputFullPath = [System.IO.Path]::GetFullPath((Join-Path -Path (Get-Location).Path -ChildPath $outputSpec))
    }
} else {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($inputName)
    $outputFullPath = Join-Path -Path $inputDir -ChildPath ($baseName + ".md")
}

$outputDir = Split-Path -Path $outputFullPath -Parent
$outputName = Split-Path -Path $outputFullPath -Leaf
if (-not (Test-Path -LiteralPath $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

& docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker is not running. Start Docker Desktop first."
    exit 1
}

$scriptDir = if ($PSScriptRoot) { (Resolve-Path -LiteralPath $PSScriptRoot).Path } else { (Get-Location).Path }
$engineDir = if ($Engine -eq "ndlocr") { "ndlocr" } else { "yomitoku" }
$imageName = if ($Engine -eq "ndlocr") { "pdf-ocr-ndlocr" } else { "pdf-ocr" }
$enginePath = Join-Path -Path $scriptDir -ChildPath $engineDir
$dockerfilePath = Join-Path -Path $enginePath -ChildPath "Dockerfile"

& docker image inspect $imageName *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host ("Building Docker image ({0})..." -f $Engine)
    & docker build -f $dockerfilePath -t $imageName $enginePath
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

$engineLabel = if ($Engine -eq "ndlocr") { "NDLOCR-Lite" } else { "YomiToku" }
Write-Host ("OCR input: {0} ({1})" -f $inputName, $engineLabel)
Write-Host ("Output: {0}" -f $outputFullPath)

$dockerArgs = @(
    "run", "--rm",
    "-v", ("{0}:/input" -f $inputDir),
    "-v", ("{0}:/output" -f $outputDir),
    $imageName,
    ("/input/{0}" -f $inputName),
    ("/output/{0}" -f $outputName),
    "--dpi", $Dpi
)
if ($Engine -eq "yomitoku" -and $Lite) {
    $dockerArgs += "--lite"
}

& docker @dockerArgs
$code = $LASTEXITCODE
if ($code -eq 0) {
    Write-Host ("Done: {0}" -f $outputFullPath)
    exit 0
}

Write-Error ("OCR failed (exit code: {0})" -f $code)
exit $code
