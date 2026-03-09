#!/Applications/Understand.app/Contents/MacOS/upython
"""Automatic architecture plugin + standalone preview for loreSystem.

Plugin entrypoints:
  - name()
  - description()
  - build(arch, db)

Standalone examples:
  ./scripts/understand_layer_arch_plugin.py
  ./scripts/understand_layer_arch_plugin.py --limit 20 --show-samples
"""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
from pathlib import Path

import understand


PLUGIN_NAME = "LoreSystem Layer Architecture"
PLUGIN_DESCRIPTION = "Builds a layered architecture for src/ files using AutomaticArch."
REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_DB = REPO_ROOT / "loreSystem.und"


def name() -> str:
    return PLUGIN_NAME


def description() -> str:
    return PLUGIN_DESCRIPTION


def options(_options) -> None:
    return None


def _rel_src_path(file_ent) -> str | None:
    longname = Path(file_ent.longname())
    try:
        rel = longname.relative_to(REPO_ROOT)
    except ValueError:
        return None
    rel_str = rel.as_posix()
    return rel_str if rel_str.startswith("src/") else None


def _trim_segments(layer: str, subdirs: list[str]) -> list[str]:
    if layer == "presentation":
        return subdirs[:2]
    if layer == "application":
        return subdirs[:2]
    if layer == "domain":
        return subdirs[:2]
    if layer == "infrastructure":
        return subdirs[:2]
    return subdirs[:2]


def classify_file(file_ent) -> str | None:
    rel = _rel_src_path(file_ent)
    if not rel:
        return None
    parts = rel.split("/")
    if len(parts) < 3:
        return None
    layer = parts[1]
    subdirs = parts[2:-1]
    file_name = parts[-1]
    module = Path(file_name).stem
    group = [layer] + _trim_segments(layer, subdirs)
    if module == "__init__":
        return "/".join(group)
    return "/".join(group + [module])


def iter_source_files(db):
    for file_ent in db.files():
        rel = _rel_src_path(file_ent)
        if not rel or not rel.endswith(".py"):
            continue
        yield file_ent


def build(arch, db) -> None:
    files = list(iter_source_files(db))
    arch.set_progress_range(0, len(files) or 1)
    for idx, file_ent in enumerate(files, start=1):
        if arch.is_aborted():
            return
        target = classify_file(file_ent)
        if target:
            arch.add(file_ent, target)
        arch.set_progress_value(idx)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=PLUGIN_DESCRIPTION)
    parser.add_argument("--db", default=str(DEFAULT_DB), help="Path to .und database")
    parser.add_argument("--limit", type=int, default=15, help="Rows to show in summary sections")
    parser.add_argument("--show-samples", action="store_true", help="Print sample file -> arch mappings")
    return parser.parse_args()


def preview(db_path: Path, limit: int, show_samples: bool) -> int:
    db = understand.open(str(db_path))
    try:
        mapped = []
        by_root = Counter()
        by_group = Counter()
        samples = defaultdict(list)

        for file_ent in iter_source_files(db):
            target = classify_file(file_ent)
            if not target:
                continue
            mapped.append((file_ent.longname(), target))
            root = target.split("/")[0]
            by_root[root] += 1
            group = "/".join(target.split("/")[:-1]) or target
            by_group[group] += 1
            if len(samples[target]) < 3:
                samples[target].append(Path(file_ent.longname()).name)

        print(f"DB: {db.name()}")
        print(f"Mapped source files: {len(mapped)}")

        print("\n## Top layer buckets")
        for bucket, count in by_root.most_common(limit):
            print(f"- {bucket}: {count}")

        print("\n## Top architecture groups")
        for node, count in by_group.most_common(limit):
            print(f"- {node}: {count}")

        if show_samples:
            print("\n## Sample mappings")
            shown = 0
            for node in sorted(samples):
                print(f"- {node}")
                for file_name in samples[node]:
                    print(f"  - {file_name}")
                shown += 1
                if shown >= limit:
                    break
        return 0
    finally:
        db.close()


if __name__ == "__main__":
    args = parse_args()
    raise SystemExit(preview(Path(args.db).expanduser().resolve(), args.limit, args.show_samples))
