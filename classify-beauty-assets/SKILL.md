---
name: classify-beauty-assets
description: Classify beauty and makeup asset packages from a source folder into user-provided categories. Use when Codex needs to find named beauty assets, copy each matching zip package plus thumbnail image into categorized delivery folders, preserve case-sensitive matching by default, and report missing or case-mismatched items.
---

# Classify Beauty Assets

## Workflow

1. Tie the task to the user's delivery or operations goal.
2. Read the user's source path, output path, and category list. If any of these are missing, ask for only the missing value.
3. Before any copying or folder modification, ask for permission to modify files.
4. Use `scripts/classify_beauty_assets.py` for the scan and copy.
5. Report copied items, missing items, and likely case-only mismatches.

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

## Validation

- Confirm every requested asset has a zip and at least one thumbnail, or list it as missing.
- Confirm the output category folders match the manifest keys.
- Confirm total zip and image counts per category.
- Call out case-only mismatches separately from truly missing files.
