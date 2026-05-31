#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  install-lean-harness.sh /path/to/project [--dry-run] [--force] [--allow-non-git]

Options:
  --dry-run        Show what would be copied, but do not write files
  --force          Overwrite existing files after creating backups
  --allow-non-git  Allow install into a directory that is not inside a git repo
USAGE
}

if [ $# -lt 1 ]; then
  usage
  exit 2
fi

PROJECT="$1"
shift || true
DRY_RUN=0
FORCE=0
ALLOW_NON_GIT=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --force) FORCE=1 ;;
    --allow-non-git) ALLOW_NON_GIT=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
  shift
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_DIR="$ROOT_DIR/templates"

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "Template directory not found: $TEMPLATE_DIR" >&2
  exit 1
fi

if [ ! -d "$PROJECT" ]; then
  echo "Project directory not found: $PROJECT" >&2
  exit 1
fi

PROJECT="$(cd "$PROJECT" && pwd)"

if [ "$ALLOW_NON_GIT" -ne 1 ]; then
  if ! git -C "$PROJECT" rev-parse --show-toplevel >/dev/null 2>&1; then
    echo "Refusing to install outside a git repository: $PROJECT" >&2
    echo "Pass --allow-non-git if this is intentional." >&2
    exit 1
  fi
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$PROJECT/.lean-ai-harness-backup/$STAMP"

copy_one() {
  local rel="$1"
  local src="$TEMPLATE_DIR/$rel"
  local dst="$PROJECT/$rel"

  if [ -e "$dst" ]; then
    if cmp -s "$src" "$dst"; then
      echo "unchanged: $rel"
      return 0
    fi

    if [ "$FORCE" -ne 1 ]; then
      echo "exists, skip: $rel (use --force to overwrite; existing file left unchanged)"
      return 0
    fi

    echo "backup+overwrite: $rel"
    if [ "$DRY_RUN" -ne 1 ]; then
      mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
      cp -a "$dst" "$BACKUP_DIR/$rel"
      mkdir -p "$(dirname "$dst")"
      cp -a "$src" "$dst"
    fi
  else
    echo "create: $rel"
    if [ "$DRY_RUN" -ne 1 ]; then
      mkdir -p "$(dirname "$dst")"
      cp -a "$src" "$dst"
    fi
  fi
}

export -f copy_one >/dev/null 2>&1 || true

echo "Lean AI Coding Harness install"
echo "Project: $PROJECT"
echo "Templates: $TEMPLATE_DIR"
[ "$DRY_RUN" -eq 1 ] && echo "Mode: dry-run"
[ "$FORCE" -eq 1 ] && echo "Mode: force overwrite with backups at .lean-ai-harness-backup/$STAMP"
echo

while IFS= read -r -d '' file; do
  rel="${file#$TEMPLATE_DIR/}"
  copy_one "$rel"
done < <(find "$TEMPLATE_DIR" -type f -print0 | sort -z)

if [ "$DRY_RUN" -eq 1 ]; then
  echo
  echo "Dry run complete. No files were written."
else
  echo
  echo "Install complete."
  if [ -d "$BACKUP_DIR" ]; then
    echo "Backups: $BACKUP_DIR"
  fi
  echo "Next steps:"
  echo "  1. Edit CLAUDE.md and process/context.md with project-specific facts."
  echo "  2. Run: git status --short"
  echo "  3. Use process/routing.md for route decisions and ./bin/check-agent-routes from the harness repo to verify available lanes."
  echo "  4. Use process/research/ for durable agy/external research briefs when needed."
  echo "  5. Review generated files before committing."
fi
