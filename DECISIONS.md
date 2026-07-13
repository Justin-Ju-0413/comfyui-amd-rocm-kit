# Decisions

## 2026-07-13: companion repository

Keep upstream ComfyUI as a pinned dependency instead of maintaining a full fork. This keeps the repository small, makes upstream upgrades explicit, and prevents runtime data from being published.

## 2026-07-13: models stay outside Git

Models are represented by URLs, sizes, licenses and SHA256 values in a manifest. Git LFS is not used because the repository must remain cheap to clone and review.

## 2026-07-13: NORMAL_VRAM for LTX

On RX 9070 XT 16GB, the Q3 diffusion model with feed-forward chunking fits normal VRAM and samples on GPU. `--lowvram` caused unacceptable CPU/GPU transfer stalls.

## 2026-07-13: CPU DWPose

The tested DirectML ONNX provider returned black/empty DWPose output. The startup script sets `AUX_ORT_PROVIDERS=CPUExecutionProvider` until provider correctness is revalidated.

## 2026-07-13: public assets

Public workflows reference generated neutral test assets only. User media and representative outputs remain local.

