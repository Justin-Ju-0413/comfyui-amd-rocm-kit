param([string]$ComfyRoot = $(if ($env:COMFYUI_ROOT) { $env:COMFYUI_ROOT } else { Join-Path (Split-Path $PSScriptRoot -Parent) "runtime\ComfyUI" }))

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$destination = Join-Path $ComfyRoot "user\default\workflows\amd-rocm-kit"
New-Item -ItemType Directory -Force -Path $destination | Out-Null
Copy-Item (Join-Path $repoRoot "workflows\*.json") $destination -Recurse -Force
Write-Host "Installed workflows to $destination"
