#!/usr/bin/env bash
# Install the skills from this repo into a Claude Code skills directory.
# Default: symlink each skills/<name> into ~/.claude/skills (repo = source of truth).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$REPO_DIR/skills"
TARGET_DIR="${HOME}/.claude/skills"
MODE="link"
FORCE=0

usage() {
  echo "Usage: $0 [--copy] [--force] [--target <dir>]"
  echo "  --copy         copy skills instead of symlinking"
  echo "  --force        replace existing skills (existing dirs backed up to <name>.bak)"
  echo "  --target <dir> install directory (default: ~/.claude/skills)"
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --copy) MODE="copy"; shift ;;
    --force) FORCE=1; shift ;;
    --target) TARGET_DIR="${2:?--target needs a directory}"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage 1 ;;
  esac
done

[[ -d "$SRC_DIR" ]] || { echo "error: $SRC_DIR not found — run from a checkout of the repo"; exit 1; }
mkdir -p "$TARGET_DIR"

installed=0 skipped=0 replaced=0
for src in "$SRC_DIR"/*/; do
  name="$(basename "$src")"
  dest="$TARGET_DIR/$name"

  if [[ -e "$dest" || -L "$dest" ]]; then
    # Already a link to this repo? Nothing to do.
    if [[ -L "$dest" && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
      echo "  ok       $name (already linked)"
      continue
    fi
    if [[ $FORCE -eq 1 ]]; then
      rm -rf "${dest}.bak"
      mv "$dest" "${dest}.bak"
      echo "  backup   $name -> ${name}.bak"
      replaced=$((replaced + 1))
    else
      echo "  skip     $name (exists — use --force to replace)"
      skipped=$((skipped + 1))
      continue
    fi
  fi

  if [[ "$MODE" == "copy" ]]; then
    cp -r "$src" "$dest"
    echo "  copied   $name"
  else
    ln -s "${src%/}" "$dest"
    echo "  linked   $name"
  fi
  installed=$((installed + 1))
done

echo
echo "Done: $installed installed, $replaced replaced, $skipped skipped -> $TARGET_DIR"
[[ "$MODE" == "link" ]] && echo "Update later with: git -C $REPO_DIR pull"
