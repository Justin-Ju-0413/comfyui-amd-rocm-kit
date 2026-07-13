from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []
model_exts = {".gguf", ".safetensors", ".ckpt", ".pth", ".pt", ".onnx"}
media_exts = {".png", ".jpg", ".jpeg", ".webp", ".mp4", ".mov", ".wav"}
absolute_windows = re.compile(r"(?<![A-Za-z])[A-Za-z]:(?:\\\\|/(?!/))")
secret_pattern = re.compile(r"(?i)(ghp_[a-z0-9]{20,}|github_pat_[a-z0-9_]{20,}|api[_-]?key\s*[:=]\s*['\"][^'\"]+)")


def fail(message: str):
    errors.append(message)


json_files = list(ROOT.rglob("*.json"))
for path in json_files:
    try:
        data = json.loads(path.read_text(encoding="utf-8-sig"))
    except Exception as exc:
        fail(f"invalid JSON {path.relative_to(ROOT)}: {exc}")
        continue
    text = path.read_text(encoding="utf-8-sig")
    if absolute_windows.search(text):
        fail(f"absolute Windows path in {path.relative_to(ROOT)}")

for path in ROOT.rglob("*"):
    if not path.is_file() or ".git" in path.parts:
        continue
    rel = path.relative_to(ROOT)
    if path.suffix.lower() in model_exts | media_exts:
        fail(f"binary/model asset is tracked: {rel}")
    if path.stat().st_size > 10 * 1024 * 1024:
        fail(f"file exceeds 10MB: {rel}")
    if path.suffix.lower() in {".md", ".json", ".py", ".ps1", ".bat", ".yml", ".yaml", ".patch"}:
        text = path.read_text(encoding="utf-8-sig", errors="replace")
        if absolute_windows.search(text):
            fail(f"absolute Windows path in {rel}")
        if secret_pattern.search(text):
            fail(f"possible secret in {rel}")

manifest = json.loads((ROOT / "config/models.manifest.json").read_text(encoding="utf-8"))
ids = set()
for model in manifest.get("models", []):
    for key in ("id", "group", "path", "size", "sha256", "url", "license"):
        if key not in model:
            fail(f"model missing {key}: {model}")
    if model.get("id") in ids:
        fail(f"duplicate model id: {model.get('id')}")
    ids.add(model.get("id"))
    digest = model.get("sha256")
    if digest is not None and not re.fullmatch(r"[0-9a-f]{64}", digest):
        fail(f"bad SHA256: {model.get('id')}")

flux = json.loads((ROOT / "workflows/image/flux2_klein_4b_edit.api.json").read_text(encoding="utf-8"))
if flux.get("7", {}).get("class_type") != "VAEEncode":
    fail("Flux edit must VAE-encode the source")
if flux.get("8", {}).get("class_type") != "ReferenceLatent" or flux["8"]["inputs"].get("latent") != ["7", 0]:
    fail("Flux edit positive conditioning must use ReferenceLatent")
if flux.get("9", {}).get("class_type") != "ReferenceLatent" or flux["9"]["inputs"].get("latent") != ["7", 0]:
    fail("Flux edit negative conditioning must use ReferenceLatent")

for path in (ROOT / "workflows/video").glob("*.api.json"):
    prompt = json.loads(path.read_text(encoding="utf-8"))
    if prompt["127"]["inputs"].get("tile_size") != 256:
        fail(f"LTX tile must be 256: {path.name}")
    if prompt["292"]["inputs"].get("value") != 512 or prompt["293"]["inputs"].get("value") != 704:
        fail(f"LTX dimensions must be 512x704: {path.name}")
    output = prompt["140"]["inputs"]
    if output.get("format") != "video/h264-mp4" or not output.get("filename_prefix", "").startswith("kit/"):
        fail(f"invalid LTX output settings: {path.name}")

if errors:
    print("\n".join(f"ERROR: {item}" for item in errors))
    sys.exit(1)
print(f"Repository validation passed: {len(json_files)} JSON files checked.")
