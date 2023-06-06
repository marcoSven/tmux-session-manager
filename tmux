#!/usr/bin/env bash

tmux ls &>/dev/null
TMUX_STATUS=$?

[ ! $TMUX_STATUS -eq 0 ] && exit 0

tmux list-sessions -F '#{session_last_attached} #{session_name}' | sort --numeric-sort --reverse | awk '{print $2}'