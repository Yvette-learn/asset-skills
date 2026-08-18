---
name: classify-effect-assets
description: Prepare classified effect asset delivery folders containing zip packages and thumbnails. Use when Codex needs to process 2D, 3D, gesture, sticker, or other effect asset folders by shortening long-tail file names, processing image names as well as zip names, decrypting already-encrypted packages when required, re-encrypting with a user-provided effect field, and validating delivery counts.
---

# Classify Effect Assets

## Workflow

1. Tie the task to the user's delivery or operations goal.
2. Identify the target delivery folders and count direct child `.zip` files and thumbnail images.
3. Ask the user for the effect field every time encryption is required. Do not assume `lingxing` or any other value.
4. Ask whether these packages need decrypt-then-reencrypt or direct encrypt. If the user says they are already encrypted, use decrypt-then-reencrypt.
5. Before any file changes, ask permission to modify folders and clear `D:\need` temporary directories.
6. Run `scripts/process_effect_assets.sh` from WSL bash. The script invokes Git Bash internally only for `D:\need\run_bash.sh`.
7. Report final zip/image counts, remaining long-tail names, and encryption success counts.

## Required Local Tools

Use the user's fixed tool directory unless they provide another:

- `D:\need\run_bash.sh`
- `D:\need\批处理文件改.bat`
- `D:\need\批量修改文件名.bat`
- `D:\need\decrypt`
- `D:\need\encrypt`

The script also creates and clears `D:\need\jiemi` when decrypting.

## File Name Rules

- Run `批处理文件改.bat` for both zip and image files, not zip only.
- This bat keeps only the part before the first underscore, so files like `heart_xxx.zip` and `heart_xxx.png` become `heart.zip` and `heart.png`.
- Strip `de_` from decrypted zip inputs before re-encryption.
- Strip `en_` from encrypted output zip files before copying them back.
- After processing, flag any direct child `.zip` or thumbnail image that still contains `_`.

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

## Validation

- Confirm each requested folder retains the same number of zip files as before processing.
- Confirm thumbnail image counts are unchanged.
- Confirm no direct child zip or thumbnail image remains with `_` in the filename.
- Confirm no final zip starts with `en_` or `de_`.
- Confirm the encryption log contains one `Success` line per zip.
