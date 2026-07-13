@echo off
setlocal
set "COMFY_ROOT=%~1"
if "%COMFY_ROOT%"=="" if not "%COMFYUI_ROOT%"=="" set "COMFY_ROOT=%COMFYUI_ROOT%"
if "%COMFY_ROOT%"=="" set "COMFY_ROOT=%~dp0..\runtime\ComfyUI"
cd /d "%COMFY_ROOT%"
"%COMFY_ROOT%\venv\Scripts\python.exe" main.py --directml --listen 127.0.0.1 --port 8188
endlocal
