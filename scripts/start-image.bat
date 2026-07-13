@echo off
setlocal
set "COMFY_ROOT=%~1"
if "%COMFY_ROOT%"=="" if not "%COMFYUI_ROOT%"=="" set "COMFY_ROOT=%COMFYUI_ROOT%"
if "%COMFY_ROOT%"=="" set "COMFY_ROOT=%~dp0..\runtime\ComfyUI"
cd /d "%COMFY_ROOT%"
set AUX_ORT_PROVIDERS=CPUExecutionProvider
"%COMFY_ROOT%\venv-rocm\Scripts\python.exe" main.py --listen 127.0.0.1 --port 8188 --use-pytorch-cross-attention
endlocal
