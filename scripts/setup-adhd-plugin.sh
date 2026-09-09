#!/usr/bin/env bash
#
# Install the i-have-adhd plugin for Claude Code.
#
# Shapes Claude Code output for an ADHD reader: action first, numbered steps,
# no tangents. Upstream: https://github.com/ayghri/i-have-adhd
#
# Usage:
#   scripts/setup-adhd-plugin.sh              # install, and enable always-on
#   scripts/setup-adhd-plugin.sh --no-always-on   # install only
#
# Safe to re-run: every step is idempotent.
#
# To undo:
#   rm -f "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.i-have-adhd-always"   # always-on off
#   claude plugin uninstall i-have-adhd@i-have-adhd                   # plugin off

set -euo pipefail

REPO_URL="https://github.com/ayghri/i-have-adhd"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLONE_DIR="$REPO_ROOT/i-have-adhd"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
FLAG_PATH="$CLAUDE_DIR/.i-have-adhd-always"

ALWAYS_ON=1
[ "${1:-}" = "--no-always-on" ] && ALWAYS_ON=0

command -v claude >/dev/null 2>&1 || {
  echo "error: the 'claude' CLI is not on PATH." >&2
  exit 1
}

# 1. Clone the plugin source (it is its own git repo, and .gitignore'd here).
if [ -d "$CLONE_DIR/.git" ]; then
  echo "==> Plugin source already cloned; updating"
  git -C "$CLONE_DIR" pull --ff-only
else
  echo "==> Cloning $REPO_URL"
  git clone "$REPO_URL" "$CLONE_DIR"
fi

# 2 & 3. Register the marketplace and install from it. Pass an absolute path so
# the registration does not depend on the caller's working directory.
echo "==> Registering marketplace"
claude plugin marketplace add "$CLONE_DIR"

echo "==> Installing plugin"
claude plugin install i-have-adhd@i-have-adhd

# 4. Opt in to the SessionStart hook, which injects the ruleset every session.
#    The hook stays inert unless this flag file exists.
if [ "$ALWAYS_ON" -eq 1 ]; then
  echo "==> Enabling always-on"
  mkdir -p "$CLAUDE_DIR"
  touch "$FLAG_PATH"
else
  echo "==> Skipping always-on (--no-always-on)"
fi

echo
echo "Done. Restart Claude Code for the plugin to load."
