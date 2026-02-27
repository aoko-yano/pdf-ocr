param(
    [string]$OutputName = "pdf-ocr.exe"
)

$ErrorActionPreference = "Stop"

$scriptDir = if ($PSScriptRoot) { (Resolve-Path -LiteralPath $PSScriptRoot).Path } else { (Get-Location).Path }
$inputFile = Join-Path -Path $scriptDir -ChildPath "run-gui.ps1"
$outputFile = Join-Path -Path $scriptDir -ChildPath $OutputName

if (-not (Test-Path -LiteralPath $inputFile)) {
    throw ("Missing file: {0}" -f $inputFile)
}

if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    Write-Host "Installing ps2exe module for current user..."
    Install-Module -Name ps2exe -Scope CurrentUser -Force
}

Import-Module ps2exe -ErrorAction Stop

Write-Host ("Building {0}..." -f $outputFile)
Invoke-PS2EXE -inputFile $inputFile -outputFile $outputFile -noConsole -title "PDF OCR"

Write-Host ""
Write-Host ("Done: {0}" -f $outputFile)
Write-Host "Keep these in the same folder:"
Write-Host "- pdf-ocr.exe"
Write-Host "- run.ps1"
Write-Host "- yomitoku/ and ndlocr/"
