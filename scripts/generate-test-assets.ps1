param([string]$ComfyRoot = $(if ($env:COMFYUI_ROOT) { $env:COMFYUI_ROOT } else { Join-Path (Split-Path $PSScriptRoot -Parent) "runtime\ComfyUI" }))

$ErrorActionPreference = "Stop"
$inputDir = Join-Path $ComfyRoot "input"
New-Item -ItemType Directory -Force -Path $inputDir | Out-Null
$python = Join-Path $ComfyRoot "venv-rocm\Scripts\python.exe"
$output = Join-Path $inputDir "kit_test_portrait.png"
$target = Join-Path $inputDir "kit_test_target.png"
$code = @'
from PIL import Image, ImageDraw
import sys

def make(path, palette):
    w, h = 512, 704
    im = Image.new("RGB", (w, h), palette[0])
    d = ImageDraw.Draw(im)
    for y in range(h):
        t = y / (h - 1)
        c = tuple(int(palette[0][i]*(1-t) + palette[1][i]*t) for i in range(3))
        d.line((0, y, w, y), fill=c)
    d.ellipse((156, 92, 356, 292), fill=palette[2], outline=(245,245,245), width=5)
    d.rounded_rectangle((104, 270, 408, 650), 70, fill=palette[3], outline=(245,245,245), width=5)
    d.ellipse((215, 160, 235, 180), fill=(25,25,25))
    d.ellipse((277, 160, 297, 180), fill=(25,25,25))
    d.arc((220, 185, 292, 240), 10, 170, fill=(80,35,45), width=5)
    im.save(path)

make(sys.argv[1], ((34,55,92),(218,151,110),(225,183,158),(70,120,175)))
make(sys.argv[2], ((45,38,70),(130,92,150),(191,151,128),(115,82,140)))
'@
& $python -c $code $output $target
if ($LASTEXITCODE -ne 0) { throw "Failed to generate neutral test assets." }
Write-Host "Generated $output and $target"
