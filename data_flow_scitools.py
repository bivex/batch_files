#!/Applications/Understand.app/Contents/MacOS/upython
"""Show practical data flow for an Understand entity.

Examples:
  ./scripts/understand_data_flow.py src.presentation.gui.tabs.worlds_tab.WorldsTab._add_world
  ./scripts/understand_data_flow.py src.presentation.gui.main_window.MainWindow._perform_save
  ./scripts/understand_data_flow.py src.presentation.gui.tabs.worlds_tab.WorldsTab._add_world --kind Function --limit 12
"""

from __future__ import annotations

import argparse
from pathlib import Path

import understand


REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_DB = REPO_ROOT / "loreSystem.und"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Understand data-flow probe")
    parser.add_argument("entity", help="Fully-qualified entity name to inspect")
    parser.add_argument("--kind", default="Function", help="Understand kind filter for lookup")
    parser.add_argument("--db", default=str(DEFAULT_DB), help="Path to .und database")
    parser.add_argument("--limit", type=int, default=10, help="Rows per section")
    return parser.parse_args()


def label(ent) -> str:
    if ent is None:
        return ""
    try:
        value = ent.longname()
        if value:
            return str(value)
    except Exception:
        pass
    try:
        return str(ent.name())
    except Exception:
        return str(ent)


def open_db(path: Path):
    try:
        return understand.open(str(path))
    except Exception as exc:
        print(f"ERROR opening DB: {path}")
        print(f"{type(exc).__name__}: {exc}")
        raise SystemExit(2)


def resolve_entity(db, name: str, kind: str):
    matches = db.lookup(name, kind) if kind else db.lookup(name)
    if not matches:
        print(f"No entity matched: {name!r} (kind={kind!r})")
        raise SystemExit(1)
    if len(matches) > 1:
        print("Multiple matches found; using the first exact/ordered match:")
        for ent in matches[:8]:
            print(f"  - {ent.kindname()} | {label(ent)}")
    return matches[0]


def collect_refs(ent, refkinds: str):
    rows = []
    for ref in ent.refs(refkinds):
        rows.append((ref.kindname(), label(ref.ent()), ref.line(), ref.column()))
    rows.sort(key=lambda row: (row[2], row[3], row[1]))
    seen = set()
    unique = []
    for row in rows:
        if row not in seen:
            seen.add(row)
            unique.append(row)
    return unique


def print_section(title: str, rows, limit: int) -> None:
    print(f"\n## {title} ({len(rows)})")
    if not rows:
        print("-")
        return
    for kind, ent_name, line, column in rows[:limit]:
        print(f"- L{line}:C{column} | {kind:<6} | {ent_name}")


def print_local_flows(ent, limit: int) -> None:
    try:
        locals_ = list(ent.ents("Define"))
    except Exception:
        locals_ = []
    print(f"\n## Locals and parameters ({len(locals_)})")
    if not locals_:
        print("-")
        return
    for local in locals_[:limit]:
        setby = list(local.refs("Setby"))
        useby = list(local.refs("Useby"))
        print(f"- {local.kindname():<9} | {label(local)}")
        if setby:
            first = setby[0]
            print(f"  setby: L{first.line()}:C{first.column()} | {first.kindname()}")
        else:
            print("  setby: -")
        if useby:
            refs = ", ".join(f"L{r.line()}:{r.column()}" for r in useby[:5])
            print(f"  useby: {refs}")
        else:
            print("  useby: -")


def print_cfg(ent) -> None:
    print("\n## Control flow")
    try:
        cfg = ent.control_flow_graph()
        nodes = list(cfg.nodes())
        print(f"- trivial: {cfg.is_trivial()}")
        print(f"- nodes: {len(nodes)}")
        lines = [line for node in nodes for line in (node.line_begin(), node.line_end()) if line is not None]
        if lines:
            print(f"- span: L{min(lines)}..L{max(lines)}")
    except Exception as exc:
        print(f"- unavailable: {type(exc).__name__}: {exc}")


def main() -> int:
    args = parse_args()
    db = open_db(Path(args.db).expanduser().resolve())
    try:
        ent = resolve_entity(db, args.entity, args.kind)
        print(f"DB: {db.name()}")
        print(f"Entity: {label(ent)}")
        print(f"Kind: {ent.kindname()}")

        print_section("Inputs (Use)", collect_refs(ent, "Use"), args.limit)
        print_section("Writes (Set)", collect_refs(ent, "Set"), args.limit)
        print_section("Calls (Call)", collect_refs(ent, "Call"), args.limit)
        print_section("Definitions (Define)", collect_refs(ent, "Define"), args.limit)
        print_local_flows(ent, args.limit)
        print_cfg(ent)
        return 0
    finally:
        db.close()


if __name__ == "__main__":
    raise SystemExit(main())
