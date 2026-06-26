#!/usr/bin/env bash
# tmux-claude-pane-picker
#
# List, monitor status, and jump across Claude Code *panes* from a single popup.
# A fork of craftzdog/tmux-claude-session-manager, reworked to track individual
# panes instead of dedicated `claude-*` sessions — so multiple Claude instances
# can live inside one tmux session.
#
# tpm runs this file as an executable on tmux startup; it reads user options
# (with sensible defaults) and installs the key binding.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/helpers.sh
. "$CURRENT_DIR/scripts/helpers.sh"

list_key="$(get_tmux_option @claude_list_key 'u')"
w="$(get_tmux_option @claude_popup_width '90%')"
h="$(get_tmux_option @claude_popup_height '90%')"

# Open the picker. Bound DIRECTLY to display-popup (not via run-shell), so the
# popup always opens on the client that pressed the key — no host-guessing, no
# cross-client deadlock.
tmux bind-key "$list_key" \
  display-popup -w "$w" -h "$h" -E "$CURRENT_DIR/scripts/picker.sh"
