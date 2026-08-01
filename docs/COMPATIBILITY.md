# Compatibility matrix

This matrix separates measured configurations from expected or unsupported ones. Submit new results with the hardware-result issue template; do not generalize one successful machine to an entire GPU family.

| OS | GPU | System RAM | Runtime | Status | Evidence |
|---|---|---:|---|---|---|
| Windows 11 | Radeon RX 9070 XT 16GB (`gfx1201`) | 32GB + page file | Python 3.12.10, PyTorch 2.9.1 + ROCm 7.2.1 | Historically verified | [`PROJECT_STATE.md`](../PROJECT_STATE.md), [`BENCHMARKS.md`](BENCHMARKS.md) |
| Windows 11 | Other RDNA 4 GPUs | — | Same pinned runtime | Unverified | Community results needed |
| Linux | AMD GPUs | — | Native ROCm | Out of current scope | Use upstream ComfyUI/ROCm guidance |
| Windows | NVIDIA / Intel | — | CUDA / XPU | Unsupported by this kit | Use the relevant upstream distribution |

`doctor.ps1 -StaticOnly` validates repository structure without a GPU. A full `doctor.ps1` pass proves only that the local pinned runtime and detected device meet this kit's checks. Neither result is evidence that an unrun generation workflow passed.
