#!/usr/bin/env bash
# Install the skills from this repo into one or more agent skills directories.
# Default: symlink each skills/<name> into ~/.claude/skills (repo = source of truth).
# The SKILL.md format is the same across tools, so the same files work for
# Claude Code (~/.claude/skills), Codex (~/.codex/skills) and the shared
# cross-tool location (~/.agents/skills).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$REPO_DIR/skills"
MODE="link"
FORCE=0
DOTFILES=0
TARGETS=()

usage() {
  echo "Usage: $0 [--claude] [--codex] [--agents] [--target <dir>] [--copy] [--force]"
  echo "  --claude       install into ~/.claude/skills   (Claude Code) [default]"
  echo "  --codex        install into ~/.codex/skills    (OpenAI Codex)"
  echo "  --agents       install into ~/.agents/skills   (shared cross-tool location)"
  echo "  --target <dir> install into a custom directory"
  echo "  --copy         copy skills instead of symlinking"
  echo "  --force        replace existing skills (existing dirs backed up to <name>.bak)"
  echo "  --dotfiles     also link claude/ (CLAUDE.md, commands, scripts) into ~/.claude"
  echo "Targets are cumulative: '$0 --claude --codex' installs into both."
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --claude) TARGETS+=("$HOME/.claude/skills"); shift ;;
    --codex)  TARGETS+=("$HOME/.codex/skills"); shift ;;
    --agents) TARGETS+=("$HOME/.agents/skills"); shift ;;
    --target) TARGETS+=("${2:?--target needs a directory}"); shift 2 ;;
    --copy) MODE="copy"; shift ;;
    --force) FORCE=1; shift ;;
    --dotfiles) DOTFILES=1; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage 1 ;;
  esac
done
[[ ${#TARGETS[@]} -eq 0 ]] && TARGETS=("$HOME/.claude/skills")

[[ -d "$SRC_DIR" ]] || { echo "error: $SRC_DIR not found — run from a checkout of the repo"; exit 1; }

for TARGET_DIR in "${TARGETS[@]}"; do
  echo "==> $TARGET_DIR"
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

  echo "  done: $installed installed, $replaced replaced, $skipped skipped"
  echo
done

[[ "$MODE" == "link" ]] && echo "Update later with: git -C $REPO_DIR pull"

# ---------------------------------------------------------------------------
# --dotfiles: link the personal Claude Code config (claude/) into ~/.claude
#   ~/.claude/CLAUDE.md            -> claude/CLAUDE.md   (personal part only)
#   ~/.claude/commands/<name>.md   -> claude/commands/<name>.md
#   ~/.claude/scripts/<name>/      -> claude/scripts/<name>/
# Company-specific sections of an existing CLAUDE.md are moved to
# ~/.claude/CLAUDE.work.md (imported by claude/CLAUDE.md, never committed here).
# ---------------------------------------------------------------------------
if [[ $DOTFILES -eq 1 ]]; then
  CLAUDE_DIR="$HOME/.claude"
  echo "==> $CLAUDE_DIR (dotfiles)"
  link_one() { # src dest
    local src="$1" dest="$2"
    if [[ -L "$dest" && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then echo "  ok       $dest"; return; fi
    if [[ -e "$dest" || -L "$dest" ]]; then mv "$dest" "${dest}.bak"; echo "  backup   $dest -> ${dest}.bak"; fi
    mkdir -p "$(dirname "$dest")"; ln -s "$src" "$dest"; echo "  linked   $dest"
  }
  if [[ -f "$CLAUDE_DIR/CLAUDE.md" && ! -L "$CLAUDE_DIR/CLAUDE.md" && ! -f "$CLAUDE_DIR/CLAUDE.work.md" ]]; then
    n="$(grep -n -m1 -E '^# .*Company Context' "$CLAUDE_DIR/CLAUDE.md" | cut -d: -f1 || true)"
    if [[ -n "$n" ]]; then tail -n +"$n" "$CLAUDE_DIR/CLAUDE.md" > "$CLAUDE_DIR/CLAUDE.work.md"; echo "  split    company section -> $CLAUDE_DIR/CLAUDE.work.md"; fi
  fi
  [[ -f "$CLAUDE_DIR/CLAUDE.work.md" ]] || { printf '# Work context\n\n(company-specific instructions, kept out of the public skills repo)\n' > "$CLAUDE_DIR/CLAUDE.work.md"; echo "  created  $CLAUDE_DIR/CLAUDE.work.md (empty stub)"; }
  link_one "$REPO_DIR/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
  for f in "$REPO_DIR"/claude/commands/*.md; do link_one "$f" "$CLAUDE_DIR/commands/$(basename "$f")"; done
  for d in "$REPO_DIR"/claude/scripts/*/; do link_one "${d%/}" "$CLAUDE_DIR/scripts/$(basename "$d")"; done
  echo
fi
