---
name: classify-effect-assets
description: Decrypt and re-encrypt already-prepared effect asset delivery folders containing zip packages and thumbnails with a user-provided effect field. Use when Codex needs to process existing 2D, 3D, gesture, sticker, or other effect folders that the user has already identified; do not search a source asset path or classify effect assets inside this skill. Supports optional long-tail zip/image filename shortening only when the user asks for suffix cleanup.
---

# Encrypt Effect Assets

## Workflow

1. Tie the task to the user's delivery or operations goal.
2. Identify the target delivery folders and count direct child `.zip` files and thumbnail images. Do not search an asset library path or classify files.
3. Ask the user for the effect field every time encryption is required. Do not assume `lingxing` or any other value.
4. Ask whether these packages need decrypt-then-reencrypt or direct encrypt. If the user says they are already encrypted, use decrypt-then-reencrypt.
5. Ask whether long-tail zip/image filenames should be shortened only when the user explicitly requests suffix cleanup.
6. Before any file changes, ask permission to modify folders and clear `D:\need` temporary directories.
7. Run `scripts/process_effect_assets.sh` from WSL bash. The script invokes Git Bash internally only for `D:\need\run_bash.sh`.
8. Report final zip/image counts, remaining long-tail names when suffix cleanup ran, and encryption success counts.

## Required Local Tools

Use the user's fixed tool directory unless they provide another:

- `D:\need\run_bash.sh`
- `D:\need\批处理文件改.bat` when filename shortening is requested
- `D:\need\decrypt`
- `D:\need\encrypt`

The script also creates and clears `D:\need\jiemi` when decrypting.

## File Name Rules

- File-name shortening is optional. Use `--shorten-names always` only when the user asks to remove long-tail suffixes.
- When shortening is enabled, run `批处理文件改.bat` for both zip and image files, not zip only.
- This bat keeps only the part before the first underscore, so files like `heart_xxx.zip` and `heart_xxx.png` become `heart.zip` and `heart.png`.
- Strip `de_` from decrypted zip inputs before re-encryption.
- Strip `en_` from encrypted output zip files before copying them back.
- After processing with shortening enabled, flag any direct child `.zip` or thumbnail image that still contains `_`.

## Script Usage

Run a dry scan from WSL:

```bash
bash scripts/process_effect_assets.sh --need-dir /mnt/d/need --decrypt-first always --effect EFFECT_VALUE -- /path/to/effect-folder
```

After the user confirms file changes, add `--execute`:

```bash
bash scripts/process_effect_assets.sh --execute --need-dir /mnt/d/need --decrypt-first always --effect EFFECT_VALUE -- /path/to/effect-folder /path/to/another-effect-folder
```

Use `--decrypt-first never` only when the user confirms the packages are not already encrypted and should be directly encrypted.
Add `--shorten-names always` only when the user requests suffix cleanup.

## Validation

- Confirm each requested folder retains the same number of zip files as before processing.
- Confirm thumbnail image counts are unchanged.
- If suffix cleanup ran, confirm no direct child zip or thumbnail image remains with `_` in the filename.
- Confirm no final zip starts with `en_` or `de_`.
- Confirm the encryption log contains one `Success` line per zip.
