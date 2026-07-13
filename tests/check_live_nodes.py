from __future__ import annotations

import argparse
import json
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--base", default="http://127.0.0.1:8188")
args = parser.parse_args()

with urllib.request.urlopen(args.base + "/object_info", timeout=60) as response:
    info = json.load(response)

missing: list[str] = []
for path in (ROOT / "workflows").rglob("*.api.json"):
    prompt = json.loads(path.read_text(encoding="utf-8-sig"))
    for node_id, node in prompt.items():
        class_type = node.get("class_type")
        if class_type not in info:
            missing.append(f"{path.relative_to(ROOT)} node {node_id}: {class_type}")

for path in (ROOT / "workflows").rglob("*.ui.json"):
    workflow = json.loads(path.read_text(encoding="utf-8-sig"))
    definitions = workflow.get("definitions") or {}
    local_subgraphs = {
        graph.get("id")
        for graph in definitions.get("subgraphs", [])
        if isinstance(graph, dict) and graph.get("id")
    }
    for node in workflow.get("nodes", []):
        class_type = node.get("type")
        if class_type in {"Note", "MarkdownNote", "GetNode", "SetNode", "PrimitiveNode"}:
            continue
        if class_type in local_subgraphs:
            continue
        if class_type not in info:
            missing.append(f"{path.relative_to(ROOT)} node {node.get('id')}: {class_type}")

if missing:
    raise SystemExit("Missing live node types:\n" + "\n".join(missing))
print("All public workflow node types exist in the live ComfyUI service.")
