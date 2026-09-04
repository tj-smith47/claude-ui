#!/bin/bash
# Symlinks this repo's statusline + theme into ~/.claude.
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p ~/.claude/themes

for pair in "statusline-command.sh:$HOME/.claude/statusline-command.sh" \
            "themes/dracula.json:$HOME/.claude/themes/dracula.json"; do
  src="$repo/${pair%%:*}"
  dst="${pair#*:}"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.bak-$(date +%s)"
    echo "backed up existing $dst"
  fi
  ln -sfn "$src" "$dst"
  echo "linked $dst -> $src"
done

echo 'Set "statusLine": {"type":"command","command":"bash ~/.claude/statusline-command.sh"} and "theme": "custom:dracula" in ~/.claude/settings.json.'
