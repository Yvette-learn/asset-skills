---
name: classify-beauty-assets
description: Classify beauty, makeup, and style-makeup asset packages from a source folder into user-provided categories, then optionally decrypt and re-encrypt the categorized folders with a user-provided effect field. Use when Codex needs to find named beauty or style-makeup assets, copy each matching zip package plus thumbnail image into categorized delivery folders, preserve case-sensitive matching by default, report missing or case-mismatched items, and prepare encrypted delivery folders with the same internal D:\need workflow used for effect assets.
---

# Classify Beauty Assets

## Workflow

1. Tie the task to the user's delivery or operations goal.
2. Read the user's source path, output path, and category list. This skill covers both beauty/makeup and style-makeup source folders.
3. If final delivery needs encryption, ask for the effect field every time. Do not assume `lingxing` or any other value.
4. Ask whether the categorized zip packages need decrypt-then-reencrypt or direct encrypt. If the user says they are already encrypted, use decrypt-then-reencrypt.
5. Before any copying, encryption, or temporary folder cleanup, ask for permission to modify files.
6. Use `scripts/classify_beauty_assets.py` for the scan and copy.
7. After classification, run `scripts/encrypt_asset_dirs.sh` on the output category folders when encryption is required.
8. Report copied items, missing items, likely case-only mismatches, zip/image counts, and encryption success counts.

## Matching Rules

- Match file stems case-sensitively by default.
- Treat an item as matching when the stem is exactly the requested name, or when it starts with `name_` for long-tail asset names such as `blush_k_502...`.
- Copy `.zip` and thumbnail images with suffix `.png`, `.jpg`, `.jpeg`, or `.webp`.
- If the source has a subfolder whose name equals the output category, search only inside that subfolder. This avoids cross-category collisions such as `yellow` in hair color and colored contact lenses.
- Use `--global-search` only when the user confirms that a target category should be filled from other source folders.
- If no exact-case file exists but a case-insensitive candidate exists, do not copy it unless the user confirms.

## Script Usage

Create a manifest JSON file shaped like:

```json
{
  "染发": ["yellow", "grey", "purple"],
  "口红": ["晕染", "11自然", "咬唇"]
}
```

Run a dry scan first:

```bash
python3 scripts/classify_beauty_assets.py --source /path/to/source --output /path/to/output --manifest manifest.json
```

After the user confirms file changes, run with `--execute`:

```bash
python3 scripts/classify_beauty_assets.py --source /path/to/source --output /path/to/output --manifest manifest.json --execute
```

Encrypt the categorized output folders only after classification is complete. Run a dry scan first:

```bash
bash scripts/encrypt_asset_dirs.sh --need-dir /mnt/d/need --decrypt-first always --effect EFFECT_VALUE -- /path/to/output/染发 /path/to/output/口红
```

After the user confirms encryption changes, add `--execute`:

```bash
bash scripts/encrypt_asset_dirs.sh --execute --need-dir /mnt/d/need --decrypt-first always --effect EFFECT_VALUE -- /path/to/output/染发 /path/to/output/口红
```

Use `--decrypt-first never` only when the user confirms the zip packages are not already encrypted.

## Encryption Rules

- Use the same `D:\need` encrypt/decrypt workflow as effect asset folders.
- Operate only on the categorized output folders passed to `scripts/encrypt_asset_dirs.sh`; do not search the original source tree during encryption.
- Process direct child `.zip` files in each category folder. Thumbnail images stay in the category folder and are counted for validation.
- Ask for the effect field every run.
- Use `--shorten-names always` only when the user explicitly asks to remove long-tail suffixes from zip/image filenames.

## Validation

- Confirm every requested asset has a zip and at least one thumbnail, or list it as missing.
- Confirm the output category folders match the manifest keys.
- Confirm total zip and image counts per category.
- Call out case-only mismatches separately from truly missing files.
- When encryption runs, confirm final zip counts match pre-encryption counts and encryption logs contain one `Success` line per zip.
