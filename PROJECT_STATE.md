# Project state

Last verified: 2026-07-14 (Asia/Shanghai)

## Runtime

- The verified runtime installation is external to this repository and is not tracked.
- Core commit: `f3a36e74`.
- Python 3.12.10, PyTorch 2.9.1+rocm7.2.1.
- GPU: AMD Radeon RX 9070 XT 16GB, gfx1201.
- System RAM: 32GB with a configured Windows page file.
- Default server: `127.0.0.1:8188`, PyTorch cross-attention, NORMAL_VRAM.

## Verified workflows

- Flux 2 Klein 4B preview: successful repeated 512×512 four-step runs.
- Flux 2 Klein 9B quality: successful 1024×1024 four-step run.
- Flux 2 edit: `VAEEncode -> ReferenceLatent -> conditioning`, successful source-to-astronaut transformation.
- LTX-2.3 full I2V: successful 512×704, 49-frame, 24fps, 2.04-second H.264 output.
- LTX audio: successful AAC LC, 48kHz stereo mux.
- SAM1 ViT-B: usable after threshold and morphological close.
- DWPose: CPU ONNX is correct; DirectML output was black on the tested models.
- The sanitized public Flux edit and LTX two-second API workflows were re-run successfully from this repository on 2026-07-14.
- `doctor.ps1` passes against the external verified runtime; the live node registry contains every public workflow node type.

## Known constraints

- LTX model loading can briefly exhaust most physical RAM; page file headroom is required.
- LTX `--lowvram` stalls due to per-layer CPU/GPU transfer; NORMAL_VRAM is the validated path.
- LTX VAE decode at tile 512 OOMs with audio models resident; tile 256 passes.
- Fast dance motion can blur hands and cause moderate identity drift.
- SAM2.1 small produced checkerboard artifacts in the tested environment; SAM1 ViT-B remains default.
- GitHub publication is pending a signed-in browser session; the complete Git history is already mirrored locally at the deployment-repository location.
