#!/usr/bin/env bash
# Install the mk-specs skill (copies, never symlinks). Safe to re-run: missing pieces are added, existing ones kept or updated.
#   --global          → ~/.claude/skills/mk-specs and ~/.agents/skills/mk-specs
#   --project <dir>   → <dir>/.claude/skills/mk-specs, <dir>/specs/mk-specs.yml (template, only if missing),
#                       mk-specs block in <dir>/AGENTS.md, `@AGENTS.md` in CLAUDE.md, a pointer line in GEMINI.md if present
#   --agents-dir      → with --project: also copy to <dir>/.agents/skills/mk-specs (agents that read .agents/skills, e.g. Codex)
#   --no-agent-files  → with --project: don't touch AGENTS.md / CLAUDE.md / GEMINI.md
#   --force           → overwrite a project copy that has local edits
#   --uninstall       → remove instead of install (with --global and/or --project; config and import lines are kept)
# Flags combine: install.sh --global --project .
set -euo pipefail

SKILL=mk-specs
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills/$SKILL"
MANIFEST=.mk-specs-manifest

usage() { sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
die() { echo "install.sh: $*" >&2; exit 1; }

GLOBAL=0 FORCE=0 UNINSTALL=0 AGENTS_DIR=0 AGENT_FILES=1 PROJECTS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --global) GLOBAL=1 ;;
    --project) [ $# -ge 2 ] || die "--project needs a directory"; PROJECTS+=("$2"); shift ;;
    --project=*) PROJECTS+=("${1#--project=}") ;;
    --force) FORCE=1 ;;
    --agents-dir) AGENTS_DIR=1 ;;
    --no-agent-files) AGENT_FILES=0 ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help) usage 0 ;;
    *) echo "install.sh: unknown option: $1" >&2; usage 1 ;;
  esac
  shift
done
[ "$GLOBAL" = 1 ] || [ ${#PROJECTS[@]} -gt 0 ] || usage 1
[ -f "$SRC/SKILL.md" ] || die "skill source not found: $SRC"

VERSION="$(grep -m1 -E '^[[:space:]]*version:' "$SRC/SKILL.md" | sed -E 's/.*version:[[:space:]]*"?([^"]*)"?.*/\1/')"

# Checksum list of the installed files (manifest itself and caches excluded).
manifest_of() {
  (cd "$1" && find . -type f ! -name "$MANIFEST" ! -name '.DS_Store' ! -path '*/__pycache__/*' -print | LC_ALL=C sort |
    while IFS= read -r f; do printf '%s %s\n' "$(cksum < "$f" | tr -s ' ' | cut -d' ' -f1,2)" "$f"; done)
}

copy_skill() {
  local dest="$1" tmp
  mkdir -p "$(dirname "$dest")"
  tmp="$(mktemp -d "$(dirname "$dest")/.$SKILL.XXXXXX")"
  (cd "$SRC" && tar cf - --exclude '__pycache__' --exclude '.DS_Store' .) | (cd "$tmp" && tar xf -)
  manifest_of "$tmp" > "$tmp/$MANIFEST"
  rm -rf "$dest"
  mv "$tmp" "$dest"
}

# Local edits = files that differ from what install.sh last wrote (the manifest). A copy that still matches the
# manifest is safe to replace even if not committed yet (e.g. re-running right after an update). Without a
# manifest, fall back to git: tracked files modified, or any untracked file in the skill folder.
has_local_edits() {
  local proj="$1" dest="$2" rel=".claude/skills/$SKILL"
  [ -d "$dest" ] || return 1
  if [ -f "$dest/$MANIFEST" ]; then
    [ "$(manifest_of "$dest")" != "$(cat "$dest/$MANIFEST")" ]
    return
  fi
  if git -C "$proj" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    [ -n "$(git -C "$proj" status --porcelain --untracked-files=all -- "$rel")" ]
    return
  fi
  return 0
}

installed_version() {
  [ -f "$1/SKILL.md" ] && grep -m1 -E '^[[:space:]]*version:' "$1/SKILL.md" | sed -E 's/.*version:[[:space:]]*"?([^"]*)"?.*/\1/' || echo none
}

echo "mk-specs $VERSION"

if [ "$GLOBAL" = 1 ]; then
  for base in "$HOME/.claude/skills" "$HOME/.agents/skills"; do
    dest="$base/$SKILL"
    if [ "$UNINSTALL" = 1 ]; then
      rm -rf "$dest" && echo "removed $dest"
    else
      old="$(installed_version "$dest")"
      copy_skill "$dest"
      echo "global: $dest ($old → $VERSION)"
    fi
  done
fi

for proj in ${PROJECTS[@]+"${PROJECTS[@]}"}; do
  [ -d "$proj" ] || die "project directory not found: $proj"
  proj="$(cd "$proj" && pwd)"
  dest="$proj/.claude/skills/$SKILL"
  if [ "$UNINSTALL" = 1 ]; then
    if has_local_edits "$proj" "$dest" && [ "$FORCE" != 1 ]; then
      die "$dest has local edits; commit them or pass --force"
    fi
    rm -rf "$dest" && echo "removed $dest (kept specs/mk-specs.yml)"
    if [ -d "$proj/.agents/skills/$SKILL" ]; then rm -rf "$proj/.agents/skills/$SKILL" && echo "removed $proj/.agents/skills/$SKILL"; fi
    if [ "$AGENT_FILES" = 1 ]; then python3 "$SRC/scripts/agent-files.py" "$proj" --uninstall; fi
    continue
  fi
  if has_local_edits "$proj" "$dest" && [ "$FORCE" != 1 ]; then
    die "$dest has uncommitted local edits; commit or discard them, or pass --force"
  fi
  old="$(installed_version "$dest")"
  copy_skill "$dest"
  echo "project: $dest ($old → $VERSION)"
  cfg="$proj/specs/mk-specs.yml"
  if [ -f "$cfg" ]; then
    echo "config: $cfg (kept)"
  else
    mkdir -p "$proj/specs"
    cp "$SRC/assets/mk-specs.yml.template" "$cfg"
    echo "config: $cfg (created from template — edit contexts, ids, tests, metrics.since)"
  fi
  if [ "$AGENTS_DIR" = 1 ]; then
    copy_skill "$proj/.agents/skills/$SKILL"
    echo "project: $proj/.agents/skills/$SKILL ($VERSION)"
  fi
  if [ "$AGENT_FILES" = 1 ]; then python3 "$SRC/scripts/agent-files.py" "$proj"; fi
done
