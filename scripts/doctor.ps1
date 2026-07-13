param(
    [string]$ComfyRoot = $(if ($env:COMFYUI_ROOT) { $env:COMFYUI_ROOT } else { Join-Path (Split-Path $PSScriptRoot -Parent) "runtime\ComfyUI" }),
    [switch]$StaticOnly
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()
$python = Join-Path $ComfyRoot "venv-rocm\Scripts\python.exe"

$validator = Join-Path $repoRoot "tests\validate_repo.py"
if (Test-Path $python) {
    & $python $validator
} elseif (Get-Command py -ErrorAction SilentlyContinue) {
    & py -3.12 $validator
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    & python $validator
} else {
    $errors.Add("Python 3.12 is required for repository validation")
}
if ($LASTEXITCODE -ne 0) { $errors.Add("Repository validation failed") }
if ($StaticOnly) {
    if ($errors.Count) { $errors | ForEach-Object { Write-Error $_ }; exit 1 }
    Write-Host "Static checks passed."
    exit 0
}

if (-not (Test-Path $python)) { $errors.Add("Missing ROCm Python: $python") }
if (-not (Test-Path (Join-Path $ComfyRoot "main.py"))) { $errors.Add("Not a ComfyUI root: $ComfyRoot") }

$manifest = Get-Content (Join-Path $repoRoot "config\models.manifest.json") -Raw | ConvertFrom-Json
foreach ($model in $manifest.models) {
    $path = Join-Path $ComfyRoot $model.path
    if (-not (Test-Path $path)) { $warnings.Add("Missing model [$($model.group)] $($model.path)"); continue }
    if ((Get-Item $path).Length -ne [int64]$model.size) { $errors.Add("Wrong model size: $($model.path)") }
}

if (Test-Path $python) {
    $probe = & $python -c "import json,torch; print(json.dumps({'torch':torch.__version__,'available':torch.cuda.is_available(),'name':torch.cuda.get_device_name(0) if torch.cuda.is_available() else None,'vram':torch.cuda.get_device_properties(0).total_memory if torch.cuda.is_available() else 0}))"
    $gpu = $probe | ConvertFrom-Json
    if ($gpu.torch -ne "2.9.1+rocm7.2.1") { $warnings.Add("Expected torch 2.9.1+rocm7.2.1, got $($gpu.torch)") }
    if (-not $gpu.available) { $errors.Add("ROCm GPU is unavailable to PyTorch") }
    if ($gpu.name -notmatch "Radeon RX 9070 XT") { $warnings.Add("Unverified GPU: $($gpu.name)") }
    if ([int64]$gpu.vram -lt 15GB) { $errors.Add("Expected about 16GB VRAM, got $($gpu.vram)") }
    & $python -m pip check
    if ($LASTEXITCODE -ne 0) { $errors.Add("pip check failed") }
}

$warnings | ForEach-Object { Write-Warning $_ }
if ($errors.Count) { $errors | ForEach-Object { Write-Error $_ }; exit 1 }
Write-Host "Doctor passed: repository, runtime, PyTorch and GPU are usable."
