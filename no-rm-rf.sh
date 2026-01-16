#!/usr/bin/env bash
# Block destructive file deletion commands and suggest using trash instead.
# This is a Claude Code hook that runs on PreToolUse for Bash commands.

set -euo pipefail

VERSION="0.1.0"

if [[ "${1:-}" == "--version" || "${1:-}" == "-v" ]]; then
  echo "no-rm-rf $VERSION"
  exit 0
fi

# Ensure jq is available (hard fail if missing)
if ! command -v jq >/dev/null 2>&1; then
  cat >&2 <<'EOF'
ERROR: jq is required for no-rm-rf.sh. Please install it:
  - macOS: brew install jq
  - Linux: your package manager (e.g., apt install jq)
EOF
  exit 2
fi

# Read JSON from stdin and extract the command
input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""' 2>/dev/null) || exit 0

if [[ -z "$command" ]]; then
  exit 0
fi

# Remove quoted strings to avoid false positives
# This is a simplified version - bash regex is more limited than JS
strip_quotes() {
  local cmd="$1"
  # Remove double-quoted strings
  cmd=$(echo "$cmd" | sed -E 's/"([^"\\]|\\.)*"/""/g')
  # Remove single-quoted strings
  cmd=$(echo "$cmd" | sed -E "s/'[^']*'/''/g")
  echo "$cmd"
}

stripped=$(strip_quotes "$command")

# Check for git rm (allowed)
if echo "$stripped" | grep -qE '\bgit\s+rm\b'; then
  exit 0
fi

# Check for subshell patterns (check original command, not stripped)
subshell_blocked=false
if echo "$command" | grep -qE '\b(sh|bash|zsh|dash)\s+-c\s+.*\brm\b'; then
  subshell_blocked=true
elif echo "$command" | grep -qE '\b(sh|bash|zsh|dash)\s+-c\s+.*\bshred\b'; then
  subshell_blocked=true
elif echo "$command" | grep -qE '\b(sh|bash|zsh|dash)\s+-c\s+.*\bunlink\b'; then
  subshell_blocked=true
elif echo "$command" | grep -qE '\b(sh|bash|zsh|dash)\s+-c\s+.*\bfind\b.*-delete\b'; then
  subshell_blocked=true
fi

if [[ "$subshell_blocked" == "true" ]]; then
  cat >&2 <<'EOF'
BLOCKED: Do not use destructive file deletion commands (rm, shred, unlink). Use the 'trash' CLI instead:
  - trash file.txt
  - trash directory/

If trash is not installed:
  - macOS: brew install trash
  - Linux/npm: npm install -g trash-cli
EOF
  exit 2
fi

# Check destructive patterns on stripped command
is_destructive() {
  local cmd="$1"

  # Basic commands at start or after operators
  echo "$cmd" | grep -qE '(^|&&|\|\||;|\||\$\(|`)[ 	]*rm\b' && return 0
  echo "$cmd" | grep -qE '(^|&&|\|\||;|\||\$\(|`)[ 	]*shred\b' && return 0
  echo "$cmd" | grep -qE '(^|&&|\|\||;|\||\$\(|`)[ 	]*unlink\b' && return 0

  # Absolute/relative paths to rm
  echo "$cmd" | grep -qE '(^|&&|\|\||;|\||\$\(|`)[ 	]*/[^ ]*/rm\b' && return 0
  echo "$cmd" | grep -qE '(^|&&|\|\||;|\||\$\(|`)[ 	]*\./rm\b' && return 0

  # Via sudo, xargs, command, env
  echo "$cmd" | grep -qE '\bsudo\s+rm\b' && return 0
  echo "$cmd" | grep -qE '\bsudo\s+/[^ ]*/rm\b' && return 0
  echo "$cmd" | grep -qE '\bxargs\s+rm\b' && return 0
  echo "$cmd" | grep -qE '\bxargs\s+/[^ ]*/rm\b' && return 0
  echo "$cmd" | grep -qE '\bcommand\s+rm\b' && return 0
  echo "$cmd" | grep -qE '\benv\s+rm\b' && return 0

  # Backslash escape to bypass aliases
  echo "$cmd" | grep -qE '(^|&&|\|\||;|\||\$\(|`)[ 	]*\\rm\b' && return 0

  # find with -delete or -exec rm
  echo "$cmd" | grep -qE '\bfind\b.*\s-delete\b' && return 0
  echo "$cmd" | grep -qE '\bfind\b.*-exec\s+rm\b' && return 0
  echo "$cmd" | grep -qE '\bfind\b.*-exec\s+/[^ ]*/rm\b' && return 0

  return 1
}

if is_destructive "$stripped"; then
  cat >&2 <<'EOF'
BLOCKED: Do not use destructive file deletion commands (rm, shred, unlink). Use the 'trash' CLI instead:
  - trash file.txt
  - trash directory/

If trash is not installed:
  - macOS: brew install trash
  - Linux/npm: npm install -g trash-cli
EOF
  exit 2
fi

exit 0
