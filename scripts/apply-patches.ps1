param(
    [string]$ComfyRoot = $(if ($env:COMFYUI_ROOT) { $env:COMFYUI_ROOT } else { Join-Path (Split-Path $PSScriptRoot -Parent) "runtime\ComfyUI" }),
    [string[]]$PatchId = @("controlnet-aux-dml-provider-name")
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$manifest = Get-Content (Join-Path $repoRoot "patches\manifest.json") -Raw | ConvertFrom-Json
foreach ($patch in $manifest.patches | Where-Object { $PatchId -contains $_.id }) {
    $target = Join-Path $ComfyRoot $patch.target
    $file = Join-Path $repoRoot "patches\$($patch.file)"
    if (-not (Test-Path $target)) { throw "Missing patch target: $target" }
    Push-Location $target
    try {
        git apply --check $file 2>$null
        if ($LASTEXITCODE -eq 0) {
            git apply $file
            if ($LASTEXITCODE -ne 0) { throw "Patch failed: $($patch.id)" }
            Write-Host "Applied $($patch.id)"
        } else {
            git apply --reverse --check $file 2>$null
            if ($LASTEXITCODE -eq 0) { Write-Host "Already applied: $($patch.id)" }
            else { throw "Patch does not match expected upstream version: $($patch.id)" }
        }
    } finally { Pop-Location }
}
