# no-rm-rf

A Claude Code hook that blocks destructive file deletion commands (`rm`, `shred`, `unlink`, `find -delete`) and suggests using `trash` instead. This allows deleted files to be recovered from the system trash.

## Main Script

`no-rm-rf.sh` - The hook script that intercepts Bash commands via Claude Code's `PreToolUse` event.

## Testing

Run tests with:

```bash
make test
```

This requires `bats` to be installed (`brew install bats-core` on macOS).

## Development Rules

### Version Updates

When making changes to `no-rm-rf.sh`, update the `VERSION` variable following semver:

- **MAJOR** (x.0.0): Breaking changes or fundamental behavior changes
- **MINOR** (0.x.0): New features, new blocked patterns, or new capabilities
- **PATCH** (0.0.x): Bug fixes, documentation updates, refactoring without behavior changes

### After Every Change

Always run `make test` after making any changes to ensure all tests pass.
