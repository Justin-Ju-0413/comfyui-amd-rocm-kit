param([string]$ComfyRoot = $(if ($env:COMFYUI_ROOT) { $env:COMFYUI_ROOT } else { Join-Path (Split-Path $PSScriptRoot -Parent) "runtime\ComfyUI" }))

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$lock = Get-Content (Join-Path $repoRoot "config\custom_nodes.lock.json") -Raw | ConvertFrom-Json
$python = Join-Path $ComfyRoot "venv-rocm\Scripts\python.exe"
$nodeRoot = Join-Path $ComfyRoot "custom_nodes"
New-Item -ItemType Directory -Force -Path $nodeRoot | Out-Null

foreach ($node in $lock.nodes) {
    $target = Join-Path $nodeRoot $node.name
    if (-not (Test-Path $target)) {
        git clone $node.repository $target
        if ($LASTEXITCODE -ne 0) { throw "Clone failed: $($node.name)" }
    }
    if ($node.commit -and (Test-Path (Join-Path $target ".git"))) {
        git -C $target fetch origin $node.commit
        git -C $target checkout --detach $node.commit
        if ($LASTEXITCODE -ne 0) { throw "Checkout failed: $($node.name)" }
    }
    $requirements = Join-Path $target "requirements.txt"
    if (Test-Path $requirements) {
        & $python -m pip install -r $requirements
        if ($LASTEXITCODE -ne 0) { throw "Requirements failed: $($node.name)" }
    }
}

Write-Host "Custom nodes installed. Version-only entries are checked by doctor.ps1."
