#!/usr/bin/env bash
# Record a Claude Code session's state on its tmux PANE, for the picker.
# Wire this into Claude Code hooks (see README):  state.sh <working|waiting|idle>
#
# This is the pane-aware counterpart to the upstream session-scoped state.sh.
# Claude Code hooks inherit the Claude process environment, so $TMUX_PANE is set
# whenever Claude runs inside tmux. We record state on that exact pane, which
# lets multiple Claude instances coexist in a single tmux session without
# clobbering each other's status. Outside tmux this is a no-op.
[ -z "${TMUX_PANE:-}" ] && exit 0

# -p scopes the option to the pane identified by $TMUX_PANE. Guard with a no-op
# on failure (e.g. pane already gone) so a hook never blocks Claude.
tmux set-option -p -t "$TMUX_PANE" @claude_state "${1:-idle}" 2>/dev/null || exit 0
tmux set-option -p -t "$TMUX_PANE" @claude_state_at "$(date +%s)" 2>/dev/null || exit 0
exit 0
