param(
    [string]$ComfyRoot = $(if ($env:COMFYUI_ROOT) { $env:COMFYUI_ROOT } else { Join-Path (Split-Path $PSScriptRoot -Parent) "runtime\ComfyUI" }),
    [string]$Output = "$env:TEMP\comfyui-model-hashes.json"
)

$ErrorActionPreference = "Stop"
$manifest = Get-Content (Join-Path $PSScriptRoot "..\config\models.manifest.json") -Raw | ConvertFrom-Json
$rows = foreach ($model in $manifest.models) {
    $path = Join-Path $ComfyRoot $model.path
    if (Test-Path -LiteralPath $path) {
        $item = Get-Item -LiteralPath $path
        $hash = Get-FileHash -LiteralPath $path -Algorithm SHA256
        [pscustomobject]@{ id=$model.id; path=$model.path; size=$item.Length; sha256=$hash.Hash.ToLower() }
    }
}
$rows | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $Output -Encoding utf8
Write-Host "Wrote $Output"
