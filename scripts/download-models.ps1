param(
    [string]$ComfyRoot = $(if ($env:COMFYUI_ROOT) { $env:COMFYUI_ROOT } else { Join-Path (Split-Path $PSScriptRoot -Parent) "runtime\ComfyUI" }),
    [ValidateSet("image-preview","image-quality","image-common","video","video-audio","auxiliary","face","all")]
    [string[]]$Group = @("image-preview","image-common"),
    [switch]$SkipHash
)

$ErrorActionPreference = "Stop"
$manifest = Get-Content (Join-Path $PSScriptRoot "..\config\models.manifest.json") -Raw | ConvertFrom-Json
$selected = $manifest.models | Where-Object { $Group -contains "all" -or $Group -contains $_.group }
foreach ($model in $selected) {
    if (-not $model.url) {
        Write-Warning "$($model.id) requires a manual, license-compatible download. Expected: $($model.path)"
        continue
    }
    $target = Join-Path $ComfyRoot $model.path
    $parent = Split-Path $target -Parent
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    $valid = $false
    if (Test-Path $target) {
        $item = Get-Item $target
        $valid = $item.Length -eq [int64]$model.size
        if ($valid -and $model.sha256 -and -not $SkipHash) {
            $valid = (Get-FileHash $target -Algorithm SHA256).Hash.ToLower() -eq $model.sha256
        }
    }
    if ($valid) { Write-Host "OK $($model.id)"; continue }
    Write-Host "Downloading $($model.id) -> $target"
    Start-BitsTransfer -Source $model.url -Destination $target -DisplayName "ComfyUI $($model.id)"
    if ((Get-Item $target).Length -ne [int64]$model.size) { throw "Size mismatch: $($model.id)" }
    if ($model.sha256 -and -not $SkipHash) {
        if ((Get-FileHash $target -Algorithm SHA256).Hash.ToLower() -ne $model.sha256) { throw "SHA256 mismatch: $($model.id)" }
    }
}
