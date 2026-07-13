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

