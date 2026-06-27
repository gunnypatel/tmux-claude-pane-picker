# tmux-claude-pane-picker

Run many [Claude Code](https://claude.com/claude-code) sessions across your
projects — then **list them, see which are done vs. still working, and jump to one** from a single popup.

- **A picker** (`prefix` + `u`) listing every running Claude pane.
- **Live status** per pane — `working` / `waiting` / `idle` — driven by Claude Code hooks.
- **A live preview** of each pane's screen right in the picker.
- **Smart jump** — selecting a pane resumes it in a popup.

Status is optional: without the hooks the picker still lists, previews, and jumps — panes just show `?` instead of a color.

## Prerequisites

- **tmux ≥ 3.2** (for `display-popup`)
- **[fzf](https://github.com/junegunn/fzf)**
- **[Claude Code](https://claude.com/claude-code)** CLI

## Install (tpm)

Add to `~/.tmux.conf` (or `~/.config/tmux/tmux.conf`):

```tmux
set -g @plugin 'gunnypatel/tmux-claude-pane-picker'
```

Then hit `prefix` + `I` to install.

## Usage

| Key            | Action                      |
| -------------- | --------------------------- |
| `prefix` + `u` | Open the pane picker       |

Inside the picker:

| Key                       | Action                    |
| ------------------------- | ------------------------- |
| `enter`                   | Jump to the pane          |
| `↑` / `↓`, type to filter | fzf navigation            |

Panes needing your attention (`waiting`, `idle`) sort to the top.

## Status setup (optional, recommended)

Add to your Claude Code settings (`~/.claude/settings.json`), merging into any existing `hooks` block:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.config/tmux/plugins/tmux-claude-pane-picker/scripts/state.sh working"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "permission_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.config/tmux/plugins/tmux-claude-pane-picker/scripts/state.sh waiting"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "AskUserQuestion",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.config/tmux/plugins/tmux-claude-pane-picker/scripts/state.sh waiting"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.config/tmux/plugins/tmux-claude-pane-picker/scripts/state.sh idle"
          }
        ]
      }
    ]
  }
}
```

## Options

```tmux
set -g @claude_pane_list_key 'u'     # prefix key: open the picker
set -g @claude_popup_width   '90%'   # popup width
set -g @claude_popup_height  '90%'   # popup height
```

## License

MIT — based on [tmux-claude-session-manager](https://github.com/craftzdog/tmux-claude-session-manager) by Takuya Matsuyama
