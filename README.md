# no-rm-rf

A Claude Code hook that blocks destructive file deletion commands and suggests using `trash` instead. Deleted files can then be recovered from the system trash.

> **Note:** This is a best-effort attempt to catch common destructive patterns, not a comprehensive security barrier. There will always be edge cases and creative ways to delete files that aren't covered.

## Blocked Commands

| Category | Examples |
|----------|----------|
| Direct commands | `rm`, `shred`, `unlink` |
| Path variants | `/bin/rm`, `/usr/bin/rm`, `./rm` |
| Bypass attempts | `command rm`, `env rm`, `\rm`, `sudo rm`, `xargs rm` |
| Subshells | `sh -c "rm ..."`, `bash -c "rm ..."` |
| Find commands | `find . -delete`, `find . -exec rm {} \;` |

## Allowed Commands

- `git rm` (tracked by git, recoverable)
- `echo 'rm test'` (quoted strings are safe)
- `trash` (the recommended alternative)
- All other commands

## Installation

### 1. Install dependencies

The script requires `jq` and `trash`:

```bash
# macOS
brew install jq trash

# Linux
sudo apt install jq
npm install -g trash-cli
```

### 2. Install the script

```bash
# Create scripts directory
mkdir -p ~/.scripts

# Download the script
curl -o ~/.scripts/no-rm-rf.sh https://raw.githubusercontent.com/kkyr/no-rm-rf/main/no-rm-rf.sh

# Make it executable
chmod +x ~/.scripts/no-rm-rf.sh
```

### 3. Configure Claude Code

Add to your global settings at `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.scripts/no-rm-rf.sh"
          }
        ]
      }
    ]
  }
}
```

### 4. Add instructions for Claude (optional but recommended)

Create or append to `~/.claude/CLAUDE.md`:

```markdown
## REQUIRED - Use `trash` instead of `rm`

Destructive file deletion commands are blocked by the `no-rm-rf` hook:
- `rm`, `rm -rf`, `shred`, `unlink`, `find -delete`

Use `trash` instead:
- `trash file.txt`
- `trash folder/`

Install trash:
- macOS: `brew install trash`
- Linux/npm: `npm install -g trash-cli`
```

## Development

```bash
# Run tests (requires bats)
make test

# Install bats
# macOS: brew install bats-core
# Linux: sudo apt install bats
```

## How It Works

The hook runs on every Bash command via Claude Code's `PreToolUse` event:

1. Parses JSON input from stdin
2. Strips quoted strings to avoid false positives
3. Checks for destructive patterns
4. Returns exit code 2 with error message if blocked
5. Returns exit code 0 to allow the command

## Acknowledgements

Inspired by [claude-rm-rf](https://github.com/zcaceres/claude-rm-rf).
