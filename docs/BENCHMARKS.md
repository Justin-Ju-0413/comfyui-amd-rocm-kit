# Verified benchmark baseline

Hardware: RX 9070 XT 16GB, Ryzen 7 7800X3D, 32GB RAM, Windows, PyTorch 2.9.1+ROCm 7.2.1.

| Workflow | Settings | Result |
|---|---|---|
| Flux 4B preview | 512×512, 4 steps, CFG 1, Euler | 22.22s cold; 3.05s and 3.04s hot |
| Flux 9B quality | 512×512, 4 steps | 50.64s, 24.17s, 43.36s |
| Flux 9B quality | 1024×1024, 4 steps | 114.01s, success |
| LTX-2.3 I2V | 512×704, 49 frames, 24fps | 2.04s H.264/yuv420p output |
| LTX-2.3 I2V audio | same video | AAC LC, 48kHz stereo |

LTX stage 1 ran at about 13.4 seconds per step; the three-step high-resolution stage ran at about 37 seconds per step. Full prompt execution was about 289 seconds after model availability.

## Public workflow acceptance run (2026-07-14)

The sanitized repository workflows were submitted directly to the live ComfyUI API with the generated neutral input asset.

| Workflow | Result | Wall time |
|---|---|---|
| `flux2_klein_4b_edit.api.json` | Reference image participated through `VAEEncode -> ReferenceLatent`; PNG written successfully | 131.2s cold/path switch |
| `ltx23_i2v_2s_silent.api.json` | H.264 High, yuv420p BT.709, 512x704, 49 frames, 24fps, 2.04s | 840.6s cold/path switch |

OpenCV decoded all 49 frames. FFmpeg 7.1 decoded the entire stream without errors. The longer LTX time includes switching from a loaded Flux path and loading/offloading the 22B Q3 model on a 16GB GPU; optimize only after repeatable warm-run measurements are collected.
