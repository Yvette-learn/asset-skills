# Asset Processing Codex Skills

This repository contains Codex Skills for asset delivery workflows:

- `classify-beauty-assets`: classify beauty, makeup, and style-makeup asset zip packages plus thumbnails by a user-provided manifest, then encrypt the categorized output folders when delivery requires it.
- `classify-effect-assets`: decrypt and re-encrypt already-prepared effect asset folders. It does not search source paths or classify effect assets.

The classification logic is reusable. The encryption workflow depends on your local/internal `D:\need` toolchain and is not included in this repository.

## Install

Copy the skill folders into your Codex skills directory:

```bash
mkdir -p ~/.codex/skills
cp -a classify-beauty-assets classify-effect-assets ~/.codex/skills/
```

On Windows, the equivalent target is usually:

```text
C:\Users\<your-user>\.codex\skills
```

Restart Codex or start a new session after copying.

## Skill 1: classify-beauty-assets

Use this Skill when you need to find named beauty or style-makeup assets and copy them into categorized delivery folders.

Typical prompt:

```text
Use $classify-beauty-assets to classify assets from D:\素材\美妆 into D:\交付\美妆 using this category list, then encrypt the categorized folders. Ask me for the effect field.
```

Classification dry-run example from WSL:

```bash
python3 ~/.codex/skills/classify-beauty-assets/scripts/classify_beauty_assets.py \
  --source /mnt/d/素材/美妆 \
  --output /mnt/d/交付/美妆 \
  --manifest examples/beauty_manifest.example.json
```

Execute classification after confirming file changes:

```bash
python3 ~/.codex/skills/classify-beauty-assets/scripts/classify_beauty_assets.py \
  --source /mnt/d/素材/美妆 \
  --output /mnt/d/交付/美妆 \
  --manifest examples/beauty_manifest.example.json \
  --execute
```

Then encrypt the categorized output folders. The effect field must be provided for every run:

```bash
bash ~/.codex/skills/classify-beauty-assets/scripts/encrypt_asset_dirs.sh \
  --need-dir /mnt/d/need \
  --decrypt-first always \
  --effect EFFECT_VALUE \
  -- /mnt/d/交付/美妆/染发 /mnt/d/交付/美妆/口红
```

Add `--execute` only after confirming encryption changes.

Matching behavior:

- Case-sensitive by default.
- Matches exact stems or long-tail stems like `blush_k_502...`.
- Copies `.zip` plus thumbnail images: `.png`, `.jpg`, `.jpeg`, `.webp`.
- If a source subfolder matches the category name, it searches only in that subfolder to avoid cross-category collisions.

## Skill 2: classify-effect-assets

Use this Skill when the user already gives target effect folders such as 2D, 3D, gesture, sticker, or similar delivery folders.

This Skill does not:

- search inside a source material library;
- classify assets by name;
- infer an effect field.

Typical prompt:

```text
Use $classify-effect-assets to decrypt and re-encrypt these already prepared folders. Ask me for the effect field.
```

Required local tool directory by default:

```text
D:\need
```

It must contain your internal tooling, including:

- `run_bash.sh`
- `批处理文件改.bat` when filename suffix cleanup is requested
- the required encryption executables and DLLs

Do not commit internal encryption binaries, customer assets, or delivery packages to GitHub.

Dry-run example from WSL:

```bash
bash ~/.codex/skills/classify-effect-assets/scripts/process_effect_assets.sh \
  --need-dir /mnt/d/need \
  --decrypt-first always \
  --effect EFFECT_VALUE \
  -- /mnt/d/交付/特效贴纸25个/手势-3个 /mnt/d/交付/特效贴纸25个/3D-7个
```

Execute after confirming file changes:

```bash
bash ~/.codex/skills/classify-effect-assets/scripts/process_effect_assets.sh \
  --execute \
  --need-dir /mnt/d/need \
  --decrypt-first always \
  --effect EFFECT_VALUE \
  -- /mnt/d/交付/特效贴纸25个/手势-3个 /mnt/d/交付/特效贴纸25个/3D-7个
```

Options:

- `--effect EFFECT_VALUE`: required every run. Do not hard-code this in prompts or scripts.
- `--decrypt-first always`: use when packages are already encrypted and must be re-encrypted with the current effect field.
- `--decrypt-first never`: use only when packages are confirmed not encrypted and can be encrypted directly.
- `--shorten-names always`: optional; use only when the user asks to remove long-tail suffixes from zip/image filenames.
- `--need-dir`: override the default `D:\need` tool location.

Validation expectations:

- Zip count stays the same before and after processing.
- Thumbnail image count stays the same.
- Final zip files do not start with `en_` or `de_`.
- If filename suffix cleanup runs, final direct-child zip/image filenames should not contain long-tail underscores.
- Encryption logs should contain one `Success` per zip.

## Safety Notes

These Skills are workflow helpers. They do not include customer assets or internal encryption binaries. Before running commands that copy, rename, decrypt, encrypt, or clear temporary folders, Codex should ask the user for permission.
