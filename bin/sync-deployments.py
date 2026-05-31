#!/usr/bin/env python3
"""Synchronize lean-ai-coding-harness template updates into registered projects.

The sync is intentionally conservative:
- generic support files listed as managed_files can be created/updated from templates;
- project-specific files (CLAUDE.md, AGENTS.md, process/context.md by default) are never overwritten;
- when a managed file differs, it is updated only if it is clean in git, unless --allow-dirty is passed;
- every overwrite creates a timestamped backup under .lean-ai-harness-backup/.
"""
from __future__ import annotations

import argparse
import datetime as dt
import filecmp
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError as exc:  # pragma: no cover
    raise SystemExit("PyYAML is required. Install with: pip install PyYAML") from exc

ROOT = Path(__file__).resolve().parents[1]
TEMPLATES = ROOT / "templates"
DEFAULT_REGISTRY = ROOT / "deployments.yaml"


def rel_git_dirty(repo: Path, rel: str) -> bool:
    proc = subprocess.run(
        ["git", "-C", str(repo), "status", "--porcelain", "--", rel],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return bool(proc.stdout.strip())


def load_registry(path: Path) -> list[dict[str, Any]]:
    data = yaml.safe_load(path.read_text()) or {}
    projects = data.get("projects") or []
    if not isinstance(projects, list):
        raise SystemExit(f"Invalid registry: {path}: projects must be a list")
    return projects


def backup_path(project: Path, rel: str, stamp: str) -> Path:
    return project / ".lean-ai-harness-backup" / stamp / rel


def copy_with_backup(src: Path, dst: Path, project: Path, rel: str, stamp: str, dry_run: bool) -> str:
    if dst.exists():
        b = backup_path(project, rel, stamp)
        if not dry_run:
            b.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(dst, b)
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
        return "update"
    if not dry_run:
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
    return "create"


def sync_project(project: dict[str, Any], args: argparse.Namespace, stamp: str) -> tuple[int, int, int]:
    name = str(project.get("name") or project.get("path") or "<unnamed>")
    path = Path(str(project.get("path") or ""))
    mode = str(project.get("sync_mode") or "managed")
    managed = list(project.get("managed_files") or [])
    project_files = list(project.get("project_files") or [])

    if mode == "manual" and not args.include_manual:
        print(f"== {name}: manual, skipped ({path})")
        return (0, 0, 0)
    if not path.exists():
        print(f"== {name}: missing path, skipped: {path}")
        return (0, 0, 1)

    print(f"== {name}: {path}")
    creates = updates = warnings = 0

    for rel in project_files:
        dst = path / rel
        if dst.exists():
            print(f"  project-file: {rel} (preserve)")
        else:
            print(f"  warn: missing project file {rel}; create/customize manually or run installer")
            warnings += 1

    for rel in managed:
        src = TEMPLATES / rel
        dst = path / rel
        if not src.exists():
            print(f"  warn: template missing for managed file {rel}")
            warnings += 1
            continue
        if dst.exists() and filecmp.cmp(src, dst, shallow=False):
            print(f"  unchanged: {rel}")
            continue
        if dst.exists() and rel_git_dirty(path, rel) and not args.allow_dirty:
            print(f"  warn: dirty managed file skipped: {rel} (use --allow-dirty after review)")
            warnings += 1
            continue
        action = copy_with_backup(src, dst, path, rel, stamp, args.dry_run)
        if action == "create":
            creates += 1
            print(f"  create: {rel}")
        else:
            updates += 1
            print(f"  update: {rel}")

    return (creates, updates, warnings)


def main() -> int:
    parser = argparse.ArgumentParser(description="Sync lean-ai-coding-harness template updates into registered projects")
    parser.add_argument("--registry", default=str(DEFAULT_REGISTRY), help="Path to deployments.yaml")
    parser.add_argument("--project", action="append", help="Only sync named project(s); may be repeated")
    parser.add_argument("--dry-run", action="store_true", help="Show intended changes without writing")
    parser.add_argument("--allow-dirty", action="store_true", help="Allow overwriting dirty managed files after backup")
    parser.add_argument("--include-manual", action="store_true", help="Include projects marked sync_mode: manual")
    args = parser.parse_args()

    registry = Path(args.registry)
    projects = load_registry(registry)
    wanted = set(args.project or [])
    if wanted:
        projects = [p for p in projects if str(p.get("name")) in wanted]
        missing = wanted - {str(p.get("name")) for p in projects}
        if missing:
            print(f"Missing project(s) in registry: {', '.join(sorted(missing))}", file=sys.stderr)
            return 2

    stamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    print("Lean AI Coding Harness deployment sync")
    print(f"Registry: {registry}")
    print(f"Templates: {TEMPLATES}")
    if args.dry_run:
        print("Mode: dry-run")
    print()

    total_creates = total_updates = total_warnings = 0
    for project in projects:
        creates, updates, warnings = sync_project(project, args, stamp)
        total_creates += creates
        total_updates += updates
        total_warnings += warnings
        print()

    print(f"Summary: creates={total_creates} updates={total_updates} warnings={total_warnings}")
    return 1 if total_warnings else 0


if __name__ == "__main__":
    raise SystemExit(main())
