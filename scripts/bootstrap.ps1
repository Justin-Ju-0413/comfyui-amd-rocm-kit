param(
    [string]$InstallRoot = $(if ($env:COMFYUI_ROOT) { $env:COMFYUI_ROOT } else { Join-Path (Split-Path $PSScriptRoot -Parent) "runtime\ComfyUI" }),
    [string]$Python = "py",
    [switch]$SkipModels,
    [switch]$SkipCustomNodes
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$lock = Get-Content (Join-Path $repoRoot "config\comfyui.lock.json") -Raw | ConvertFrom-Json

function Invoke-Checked([string]$File, [string[]]$Arguments) {
    & $File @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$File failed with exit code $LASTEXITCODE" }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw "Git is required." }

if (-not (Test-Path $InstallRoot)) {
    Invoke-Checked git @("clone", $lock.repository, $InstallRoot)
}
if (-not (Test-Path (Join-Path $InstallRoot ".git"))) {
    throw "$InstallRoot exists but is not a ComfyUI Git checkout. Choose another -InstallRoot."
}

$dirty = git -C $InstallRoot status --porcelain
if ($LASTEXITCODE -ne 0) { throw "Cannot inspect $InstallRoot" }
if ($dirty) {
    Write-Warning "Existing ComfyUI checkout has local changes; core checkout is left untouched."
} else {
    Invoke-Checked git @("-C", $InstallRoot, "fetch", "origin", $lock.commit)
    Invoke-Checked git @("-C", $InstallRoot, "checkout", "--detach", $lock.commit)
}

$venv = Join-Path $InstallRoot "venv-rocm"
if (-not (Test-Path (Join-Path $venv "Scripts\python.exe"))) {
    if ($Python -eq "py") { Invoke-Checked py @("-3.12", "-m", "venv", $venv) }
    else { Invoke-Checked $Python @("-m", "venv", $venv) }
}
$venvPython = Join-Path $venv "Scripts\python.exe"
Invoke-Checked $venvPython @("-m", "pip", "install", "--upgrade", "pip")
Invoke-Checked $venvPython @("-m", "pip", "install", $lock.torch.url, $lock.torchvision.url, $lock.torchaudio.url)
Invoke-Checked $venvPython @("-m", "pip", "install", "-r", (Join-Path $InstallRoot "requirements.txt"))

if (-not $SkipCustomNodes) {
    & (Join-Path $PSScriptRoot "install-custom-nodes.ps1") -ComfyRoot $InstallRoot
    if ($LASTEXITCODE -ne 0) { throw "Custom-node installation failed." }
}
& (Join-Path $PSScriptRoot "install-workflows.ps1") -ComfyRoot $InstallRoot
& (Join-Path $PSScriptRoot "generate-test-assets.ps1") -ComfyRoot $InstallRoot
if (-not $SkipModels) {
    & (Join-Path $PSScriptRoot "download-models.ps1") -ComfyRoot $InstallRoot -Group image-preview,image-common
}
Write-Host "Bootstrap complete. Run scripts\doctor.ps1 -ComfyRoot '$InstallRoot'."
