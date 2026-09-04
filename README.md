# claude-ui

Statusline command and Dracula theme for Claude Code, symlinked into `~/.claude`.

## Setup

```bash
git clone git@github.com:tj-smith47/claude-ui.git /opt/repos/claude-ui
/opt/repos/claude-ui/setup.sh
```

Then in `~/.claude/settings.json`:

```jsonc
"statusLine": { "type": "command", "command": "bash ~/.claude/statusline-command.sh" },
"theme": "custom:dracula"
```
