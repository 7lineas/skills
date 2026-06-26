#!/usr/bin/env bash
# Remove /show skill artifacts (repo snapshots/ dirs) under a search root.
set -euo pipefail

ROOT="${1:-$HOME/GitHub}"

if [[ ! -d "$ROOT" ]]; then
  echo "error: search root does not exist: $ROOT" >&2
  exit 1
fi

is_git_worktree_path() {
  local dir="$1"
  local probe="$dir"
  while [[ "$probe" != "/" ]]; do
    if [[ -d "$probe/.git" ]]; then
      return 0
    fi
    probe="$(dirname "$probe")"
  done
  return 1
}

should_skip() {
  local path="$1"
  case "$path" in
    */.git/*|*/node_modules/*|*/.android/*|*/.cursor/snapshots|*/.cursor/snapshots/*)
      return 0
      ;;
  esac
  return 1
}

total_dirs=0
total_bytes=0

while IFS= read -r dir; do
  should_skip "$dir" && continue
  is_git_worktree_path "$dir" || continue

  size=$(du -sk "$dir" 2>/dev/null | awk '{print $1}')
  file_count=$(find "$dir" -type f 2>/dev/null | wc -l | tr -d ' ')
  echo "remove: $dir (${file_count} files, $((size * 1024)) bytes)"
  rm -rf "$dir"
  total_dirs=$((total_dirs + 1))
  total_bytes=$((total_bytes + size * 1024))
done < <(
  find "$ROOT" -type d -name 'snapshots' \
    ! -path '*/.git/*' \
    ! -path '*/node_modules/*' \
    ! -path '*/.android/*' \
    ! -path '*/.cursor/snapshots' \
    ! -path '*/.cursor/snapshots/*' \
    2>/dev/null
)

# Stray playwright-cli captures sometimes land here instead of snapshots/
while IFS= read -r dir; do
  should_skip "$dir" && continue
  is_git_worktree_path "$dir" || continue
  [[ -d "$dir" ]] || continue
  media_count=$(find "$dir" -maxdepth 2 -type f \( -name '*.png' -o -name '*.webm' \) 2>/dev/null | wc -l | tr -d ' ')
  [[ "$media_count" -gt 0 ]] || continue
  size=$(du -sk "$dir" 2>/dev/null | awk '{print $1}')
  echo "remove: $dir (${media_count} media files, $((size * 1024)) bytes)"
  rm -rf "$dir"
  total_dirs=$((total_dirs + 1))
  total_bytes=$((total_bytes + size * 1024))
done < <(find "$ROOT" -type d -name '.playwright-cli' ! -path '*/node_modules/*' 2>/dev/null)

if [[ "$total_dirs" -eq 0 ]]; then
  echo "done: no /show capture directories found under $ROOT"
else
  echo "done: removed $total_dirs director(ies), freed ~$((total_bytes / 1024 / 1024)) MB under $ROOT"
fi
