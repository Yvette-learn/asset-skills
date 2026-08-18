#!/usr/bin/env python3
import argparse
import json
import shutil
from pathlib import Path

IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp"}
ZIP_SUFFIXES = {".zip"}
ALL_SUFFIXES = ZIP_SUFFIXES | IMAGE_SUFFIXES


def parse_args():
    parser = argparse.ArgumentParser(description="Classify beauty asset zip files and thumbnails by manifest.")
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--case-insensitive", action="store_true")
    parser.add_argument("--global-search", action="store_true", help="Search all source folders even when a source subfolder matches the target category.")
    parser.add_argument("--execute", action="store_true", help="Copy files. Without this, only print the plan.")
    return parser.parse_args()


def load_manifest(path):
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise SystemExit("Manifest must be an object mapping category names to item lists.")
    for category, items in data.items():
        if not isinstance(category, str) or not isinstance(items, list) or not all(isinstance(i, str) for i in items):
            raise SystemExit("Manifest values must be lists of strings.")
    return data


def stem_matches(stem, item, case_insensitive):
    left = stem.casefold() if case_insensitive else stem
    right = item.casefold() if case_insensitive else item
    return left == right or left.startswith(right + "_")


def collect_files(source, output):
    output_resolved = output.resolve() if output.exists() else None
    files = []
    for path in source.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in ALL_SUFFIXES:
            continue
        if output_resolved:
            try:
                path.resolve().relative_to(output_resolved)
                continue
            except ValueError:
                pass
        files.append(path)
    return files


def rank_candidate(path, source, category):
    rel = path.relative_to(source)
    parts = rel.parts
    in_category = 0 if parts and parts[0] == category else 1
    exact_depth = len(parts)
    return (in_category, exact_depth, path.as_posix())


def main():
    args = parse_args()
    source = args.source
    output = args.output
    manifest = load_manifest(args.manifest)

    if not source.is_dir():
        raise SystemExit(f"Source directory not found: {source}")

    files = collect_files(source, output)
    copied = []
    missing = []
    case_mismatches = []

    for category, items in manifest.items():
        for item in items:
            category_dir = source / category
            if category_dir.is_dir() and not args.global_search:
                scoped_files = []
                for path in files:
                    try:
                        path.relative_to(category_dir)
                        scoped_files.append(path)
                    except ValueError:
                        pass
            else:
                scoped_files = files

            candidates = [p for p in scoped_files if stem_matches(p.stem, item, args.case_insensitive)]
            if not args.case_insensitive and not candidates:
                folded = [p for p in scoped_files if stem_matches(p.stem, item, True)]
                if folded:
                    case_mismatches.append((category, item, [p.relative_to(source).as_posix() for p in folded]))

            chosen = []
            for suffix_group in (ZIP_SUFFIXES, IMAGE_SUFFIXES):
                group = [p for p in candidates if p.suffix.lower() in suffix_group]
                if group:
                    chosen.append(sorted(group, key=lambda p: rank_candidate(p, source, category))[0])

            has_zip = any(p.suffix.lower() in ZIP_SUFFIXES for p in chosen)
            has_img = any(p.suffix.lower() in IMAGE_SUFFIXES for p in chosen)
            if not has_zip or not has_img:
                missing.append((category, item, has_zip, has_img))

            if args.execute and chosen:
                target_dir = output / category
                target_dir.mkdir(parents=True, exist_ok=True)
                for src in chosen:
                    dst = target_dir / src.name
                    shutil.copy2(src, dst)
                    copied.append((category, item, src, dst))
            else:
                for src in chosen:
                    copied.append((category, item, src, output / category / src.name))

    for category, item, src, dst in copied:
        action = "COPIED" if args.execute else "WOULD_COPY"
        print(f"{action} {category}/{item}: {src} -> {dst}")
    for category, item, has_zip, has_img in missing:
        print(f"MISSING {category}/{item}: zip={'yes' if has_zip else 'no'} image={'yes' if has_img else 'no'}")
    for category, item, paths in case_mismatches:
        print(f"CASE_MISMATCH {category}/{item}: {', '.join(paths)}")


if __name__ == "__main__":
    main()
