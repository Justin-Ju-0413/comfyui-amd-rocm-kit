# Agent development guide

## Required reading

Before changing anything, read these files in order:

1. `PROJECT_STATE.md`
2. `TASKS.md`
3. `DECISIONS.md`
4. `CHANGELOG.md`

## Repository boundaries

- This is a deployment companion repository, not a fork of ComfyUI.
- Never commit models, virtual environments, user media, generated output, credentials, cookies, proxy secrets, or machine-specific absolute paths.
- Do not vendor third-party custom-node source. Pin upstream sources in `config/custom_nodes.lock.json` and keep local changes as checksum-guarded patches.
- Treat the configured external ComfyUI directory as a runtime installation. Do not delete or reset it.

## Workflow rules

- UI workflows end in `.ui.json`; API prompts end in `.api.json`.
- Public workflows must use `kit_test_portrait.png` or another generated neutral asset.
- Keep output prefixes under `kit/`.
- LTX 16GB defaults: NORMAL_VRAM, 512×704, 24fps, 256 VAE tile, spatial x2 upscaler.
- Flux 2 editing must route the encoded reference latent through `ReferenceLatent` conditioning.

## Change protocol

- Work on a feature branch.
- Run `python tests/validate_repo.py` and `powershell -File scripts/doctor.ps1 -StaticOnly`.
- Update `PROJECT_STATE.md` for material state changes, `TASKS.md` for task status, and `CHANGELOG.md` for user-visible changes.
- Record architectural decisions in `DECISIONS.md`.
- Never claim a GPU generation passed unless the output and timing are recorded in `docs/BENCHMARKS.md`.
