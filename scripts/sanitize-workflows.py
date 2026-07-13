from __future__ import annotations

import copy
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NEUTRAL_PROMPT = (
    "A friendly studio portrait subject performs a graceful, rhythmic dance, "
    "raising both arms naturally and turning slightly while the camera remains fixed. "
    "Stable identity, realistic anatomy, smooth continuous motion, clean background."
)


def load(path: Path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def save(path: Path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def ui_nodes(workflow):
    return {int(node["id"]): node for node in workflow["nodes"]}


def bypass_ui_node(workflow, node_id: int, input_link_id: int, output_link_id: int):
    """Replace an empty one-input/one-output passthrough node with a direct link."""
    nodes = ui_nodes(workflow)
    if node_id not in nodes:
        return
    links = {int(link[0]): link for link in workflow.get("links", [])}
    incoming = links[input_link_id]
    outgoing = links[output_link_id]
    outgoing[1] = incoming[1]
    outgoing[2] = incoming[2]

    source = nodes[int(incoming[1])]
    source_output = source["outputs"][int(incoming[2])]
    source_output["links"] = [
        output_link_id if link_id == input_link_id else link_id
        for link_id in (source_output.get("links") or [])
    ]
    workflow["links"] = [link for link in workflow["links"] if int(link[0]) != input_link_id]
    workflow["nodes"] = [node for node in workflow["nodes"] if int(node["id"]) != node_id]


def sanitize_ui(path: Path):
    workflow = load(path)
    for node in workflow.get("nodes", []):
        node_type = node.get("type", "")
        values = node.get("widgets_values")
        if node_type == "LoadImage" and isinstance(values, list) and values:
            values[0] = "kit_test_portrait.png"
        if node_type == "SaveImage" and isinstance(values, list) and values:
            values[0] = "kit/image"
        if node_type == "VHS_VideoCombine" and isinstance(values, dict):
            values["filename_prefix"] = "kit/LTX23_I2V"
            values.pop("videopreview", None)
    if "ltx23" in path.name.lower():
        # rgthree's Power Lora Loader had no LoRA entries and was only a MODEL
        # passthrough. Removing it keeps the public workflow dependency-minimal.
        bypass_ui_node(workflow, node_id=301, input_link_id=613, output_link_id=590)
        nodes = ui_nodes(workflow)
        nodes[121]["widgets_values"] = [NEUTRAL_PROMPT]
        nodes[127]["widgets_values"] = [256, 32, 4096, 8]
        nodes[167]["widgets_values"] = ["kit_test_portrait.png", "image"]
        nodes[291]["widgets_values"] = [5]
        nodes[292]["widgets_values"] = [512]
        nodes[293]["widgets_values"] = [704]
        nodes[332]["mode"] = 0
    save(path, workflow)


for path in (ROOT / "workflows" / "image").glob("*.ui.json"):
    sanitize_ui(path)
sanitize_ui(ROOT / "workflows" / "video" / "ltx23_i2v_amd_16gb.ui.json")

flux = load(ROOT / "workflows" / "image" / "flux2_klein_4b_edit.api.json")
flux["3"]["inputs"]["text"] = "Transform the reference into a cinematic astronaut portrait while preserving identity."
flux["6"]["inputs"]["image"] = "kit_test_portrait.png"
flux["17"]["inputs"]["filename_prefix"] = "kit/flux2_edit"
save(ROOT / "workflows" / "image" / "flux2_klein_4b_edit.api.json", flux)

video = load(ROOT / "workflows" / "video" / "ltx23_i2v_2s_audio.api.json")
video["121"]["inputs"]["text"] = NEUTRAL_PROMPT
video["167"]["inputs"]["image"] = "kit_test_portrait.png"
video["291"]["inputs"]["value"] = 2
video["292"]["inputs"]["value"] = 512
video["293"]["inputs"]["value"] = 704
video["127"]["inputs"]["tile_size"] = 256
video["127"]["inputs"]["overlap"] = 32
video["140"]["inputs"]["filename_prefix"] = "kit/ltx23_i2v_2s_audio"
save(ROOT / "workflows" / "video" / "ltx23_i2v_2s_audio.api.json", video)

silent = copy.deepcopy(video)
silent["140"]["inputs"].pop("audio", None)
silent["140"]["inputs"]["filename_prefix"] = "kit/ltx23_i2v_2s_silent"
save(ROOT / "workflows" / "video" / "ltx23_i2v_2s_silent.api.json", silent)

five = copy.deepcopy(video)
five["291"]["inputs"]["value"] = 5
five["140"]["inputs"]["filename_prefix"] = "kit/ltx23_i2v_5s_audio"
save(ROOT / "workflows" / "video" / "ltx23_i2v_5s_audio.api.json", five)

chain = copy.deepcopy(video)
chain["121"]["inputs"]["text"] = "The edited astronaut gently floats and rotates in zero gravity, fixed camera, stable identity."
chain["167"]["inputs"]["image"] = "kit_edited_input.png"
chain["140"]["inputs"].pop("audio", None)
chain["140"]["inputs"]["filename_prefix"] = "kit/edit_to_video"
save(ROOT / "workflows" / "video" / "flux_edit_to_ltx23.api.json", chain)
