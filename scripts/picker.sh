#!/usr/bin/env bash
# Interactive picker for running Claude Code panes (anywhere in the server).
#
#   picker.sh           fzf picker; on enter, jumps the client to the chosen pane.
#   picker.sh --list    print the rows only (used by fzf's ctrl-x reload).
#
# Unlike the upstream session-scoped manager, this tracks individual *panes*, so
# several Claude instances can share one tmux session. A pane is considered a
# Claude pane when ANY of these hold:
#   - it has a @claude_state pane option (set by our state.sh hook), OR
#   - its title starts with the Claude busy/idle glyph (Claude sets pane title), OR
#   - its current command looks like the Claude binary / a bare version string.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=helpers.sh
. "$DIR/helpers.sh"

# Field delimiter for list-panes output and fzf. Tab keeps paths/titles intact.
TAB=$'\t'

# is_claude_pane <state> <title> <cmd>
# Returns 0 when the pane should appear in the picker.
is_claude_pane() {
  local state="$1" title="$2" cmd="$3"
  [ -n "$state" ] && return 0
  case "$title" in
  '✳'*) return 0 ;; # Claude sets the pane title to "✳ <task summary>"
  esac
  case "$cmd" in
  claude | claude-code | claude\ * | *claude) return 0 ;;
  # Claude often reports its version (e.g. "2.1.185") as the pane command.
  [0-9]*.[0-9]*.[0-9]*) return 0 ;;
  esac
  return 1
}

emit_rows() {
  local now line sess win_i win_n pane_i pane_id cmd title path state at
  now=$(date +%s)
  # One line per pane, fields tab-separated. Order must match the read below.
  tmux list-panes -a -F \
    "#{session_name}${TAB}#{window_index}${TAB}#{window_name}${TAB}#{pane_index}${TAB}#{pane_id}${TAB}#{pane_current_command}${TAB}#{pane_title}${TAB}#{pane_current_path}${TAB}#{@claude_state}${TAB}#{@claude_state_at}" \
    2>/dev/null | while IFS="$TAB" read -r sess win_i win_n pane_i pane_id cmd title path state at; do
    is_claude_pane "$state" "$title" "$cmd" || continue

    local icon rank ago
    case "$state" in
    waiting) icon=$'\033[33m●\033[0m waiting' rank=0 ;; # yellow - needs input
    idle) icon=$'\033[32m●\033[0m idle   ' rank=1 ;;    # green  - done, your turn
    working) icon=$'\033[31m●\033[0m working' rank=3 ;; # red    - busy, leave it
    *) icon=$'\033[90m●\033[0m   ?    ' rank=2 ;;       # grey   - unknown (no hook yet)
    esac
    if [ -n "$at" ]; then ago="$(((now - at) / 60))m"; else ago='-'; fi

    # Trim Claude's leading glyph from the title for a cleaner column; keep the
    # raw title searchable anyway via the location string below.
    local task="${title#✳ }"
    local loc="${sess} › w${win_i}:${win_n} › p${pane_i}"

    # Columns:
    #   1 rank        (hidden, for sort)
    #   2 pane_id     (hidden, the jump target — %N)
    #   3 icon+state
    #   4 age
    #   5 location    "sess › wI:name › pP"
    #   6 path        (home-shortened)
    #   7 task        (Claude's current task summary, the bonus)
    # fzf shows 3..7 (--with-nth); matching runs over the visible columns, so
    # session name, window, pane, path, and task are all fuzzy-searchable.
    printf '%s\t%s\t%s\t%5s\t%s\t%s\t%s\n' \
      "$rank" "$pane_id" "$icon" "$ago" "$loc" "${path/#$HOME/~}" "$task"
  done | sort -t"$TAB" -k1,1n -k4,4n
  # rank asc (attention-needed floats up), then age asc within a rank.
}

[ "${1:-}" = '--list' ] && {
  emit_rows
  exit 0
}

if ! command -v fzf >/dev/null 2>&1; then
  tmux display-message "tmux-claude-pane-picker: fzf is required for the picker"
  exit 0
fi

self="${BASH_SOURCE[0]}"
export FZF_DEFAULT_OPTS=''
sel=$(emit_rows | fzf --ansi --delimiter='\t' --with-nth=3,4,5,6,7 \
  --reverse --cycle --header='Claude panes · enter: jump · ctrl-x: kill pane' \
  --preview="tmux capture-pane -ept {2}" --preview-window='right,62%,wrap' \
  --bind="ctrl-x:execute-silent(tmux kill-pane -t {2})+reload($self --list)")

[ -z "$sel" ] && exit 0
target=$(printf '%s' "$sel" | cut -f2) # the pane id, %N

# Jump in place: move the invoking client to the target pane's session, window,
# and pane. switch-client handles the cross-session case; select-window/pane
# land us exactly on the chosen pane. Each step is best-effort.
sess=$(tmux display-message -p -t "$target" '#{session_name}' 2>/dev/null)
[ -n "$sess" ] && tmux switch-client -t "$sess" 2>/dev/null
tmux select-window -t "$target" 2>/dev/null
tmux select-pane -t "$target" 2>/dev/null
