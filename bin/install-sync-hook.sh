#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK_DIR="$ROOT_DIR/.git/hooks"
HOOK="$HOOK_DIR/post-merge"

if [ ! -d "$ROOT_DIR/.git" ]; then
  echo "Not a git checkout: $ROOT_DIR" >&2
  exit 1
fi

mkdir -p "$HOOK_DIR"

if [ -e "$HOOK" ] && ! grep -q "lean-ai-coding-harness auto-sync" "$HOOK"; then
  backup="$HOOK.backup.$(date +%Y%m%d-%H%M%S)"
  cp -a "$HOOK" "$backup"
  cat >> "$HOOK" <<'HOOK_APPEND'

# lean-ai-coding-harness auto-sync
if [ -x "./bin/sync-deployments.py" ]; then
  echo "[lean-ai-coding-harness] syncing registered deployments after update..."
  ./bin/sync-deployments.py || true
fi
HOOK_APPEND
  chmod +x "$HOOK"
  echo "Appended auto-sync block to existing post-merge hook. Backup: $backup"
  exit 0
fi

cat > "$HOOK" <<'HOOK'
#!/usr/bin/env bash
set -euo pipefail

# lean-ai-coding-harness auto-sync
cd "$(git rev-parse --show-toplevel)"
if [ -x "./bin/sync-deployments.py" ]; then
  echo "[lean-ai-coding-harness] syncing registered deployments after update..."
  ./bin/sync-deployments.py || true
fi
HOOK
chmod +x "$HOOK"
echo "Installed post-merge auto-sync hook: $HOOK"
