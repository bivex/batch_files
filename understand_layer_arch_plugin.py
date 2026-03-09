#!/Applications/Understand.app/Contents/MacOS/upython
"""Automatic architecture plugin + standalone preview for loreSystem.

Hexagonal / DDD rules used by this plugin:
  - presentation is an outer adapter layer.
  - application orchestrates use cases and may depend on domain.
  - domain is the core and should not depend on application, presentation,
    or infrastructure.
  - infrastructure is an outer adapter layer and may depend on domain.
  - preferred dependency direction:
      presentation -> application -> domain
      infrastructure -> domain
  - likely violations reported by `--violations-only`:
      presentation -> domain
      presentation -> infrastructure
      application -> infrastructure
      application -> presentation
      domain -> application|presentation|infrastructure
      infrastructure -> application|presentation

Plugin entrypoints:
  - name()
  - description()
  - build(arch, db)

Standalone examples:
  ./scripts/understand_layer_arch_plugin.py
  ./scripts/understand_layer_arch_plugin.py --coarse --exclude-init --exclude-examples
  ./scripts/understand_layer_arch_plugin.py --coarse --exclude-init --report-edges
  ./scripts/understand_layer_arch_plugin.py --coarse --exclude-init --report-edges --cross-layer-only
  ./scripts/understand_layer_arch_plugin.py --coarse --exclude-init --violations-only
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


def _trim_segments(layer: str, subdirs: list[str], coarse: bool) -> list[str]:
    if coarse:
        return subdirs[:1]
    if layer == "presentation":
        return subdirs[:2]
    if layer == "application":
        return subdirs[:2]
    if layer == "domain":
        return subdirs[:2]
    if layer == "infrastructure":
        return subdirs[:2]
    return subdirs[:2]


def classify_file(file_ent, coarse: bool = False, exclude_init: bool = False, exclude_examples: bool = False) -> str | None:
    rel = _rel_src_path(file_ent)
    if not rel:
        return None
    if exclude_examples and rel.startswith("src/application/examples/"):
        return None
    parts = rel.split("/")
    if len(parts) < 3:
        return None
    layer = parts[1]
    subdirs = parts[2:-1]
    file_name = parts[-1]
    module = Path(file_name).stem
    group = [layer] + _trim_segments(layer, subdirs, coarse)
    if module == "__init__":
        if exclude_init:
            return None
        return "/".join(group)
    if coarse:
        return "/".join(group)
    return "/".join(group + [module])


def top_layer(path: str) -> str:
    return path.split("/", 1)[0]


def is_violation_edge(src_group: str, dep_group: str) -> bool:
    src = top_layer(src_group)
    dep = top_layer(dep_group)
    if src == dep:
        return False
    if src == "domain":
        return dep in {"application", "presentation", "infrastructure"}
    if src == "application":
        return dep in {"presentation", "infrastructure"}
    if src == "presentation":
        return dep in {"domain", "infrastructure"}
    if src == "infrastructure":
        return dep in {"application", "presentation"}
    return False


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
    parser.add_argument("--coarse", action="store_true", help="Group by higher-level architecture buckets")
    parser.add_argument("--exclude-init", action="store_true", help="Exclude __init__.py files from preview")
    parser.add_argument("--exclude-examples", action="store_true", help="Exclude src/application/examples from preview")
    parser.add_argument("--report-edges", action="store_true", help="Show aggregated dependency edges between architecture groups")
    parser.add_argument("--cross-layer-only", action="store_true", help="With --report-edges, keep only edges that cross top-level layers")
    parser.add_argument("--violations-only", action="store_true", help="Show only likely DDD boundary violations; implies --report-edges and --cross-layer-only")
    return parser.parse_args()


def preview(
    db_path: Path,
    limit: int,
    show_samples: bool,
    coarse: bool,
    exclude_init: bool,
    exclude_examples: bool,
    report_edges: bool,
    cross_layer_only: bool,
    violations_only: bool,
) -> int:
    db = understand.open(str(db_path))
    try:
        mapped = []
        by_root = Counter()
        by_group = Counter()
        samples = defaultdict(list)
        ent_to_target = {}

        for file_ent in iter_source_files(db):
            target = classify_file(
                file_ent,
                coarse=coarse,
                exclude_init=exclude_init,
                exclude_examples=exclude_examples,
            )
            if not target:
                continue
            mapped.append((file_ent.longname(), target))
            ent_to_target[file_ent.longname()] = target
            root = target.split("/")[0]
            by_root[root] += 1
            group = target if coarse else ("/".join(target.split("/")[:-1]) or target)
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

        if report_edges or violations_only:
            edge_counts = Counter()
            for file_ent in iter_source_files(db):
                src_target = ent_to_target.get(file_ent.longname())
                if not src_target:
                    continue
                src_group = src_target if coarse else ("/".join(src_target.split("/")[:-1]) or src_target)
                seen = set()
                for dep in file_ent.depends():
                    dep_target = ent_to_target.get(dep.longname())
                    if not dep_target:
                        continue
                    dep_group = dep_target if coarse else ("/".join(dep_target.split("/")[:-1]) or dep_target)
                    if (cross_layer_only or violations_only) and top_layer(src_group) == top_layer(dep_group):
                        continue
                    if violations_only and not is_violation_edge(src_group, dep_group):
                        continue
                    edge = (src_group, dep_group)
                    if edge in seen:
                        continue
                    seen.add(edge)
                    edge_counts[edge] += 1

            print("\n## DDD boundary violations" if violations_only else "\n## Architecture edges")
            for (src_group, dep_group), count in edge_counts.most_common(limit):
                print(f"- {src_group} -> {dep_group}: {count}")

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
    raise SystemExit(
        preview(
            Path(args.db).expanduser().resolve(),
            args.limit,
            args.show_samples,
            args.coarse,
            args.exclude_init,
            args.exclude_examples,
            args.report_edges,
            args.cross_layer_only,
            args.violations_only,
        )
    )
