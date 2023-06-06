# tmux session manager

This script makes it easy to create, kill, detach and switch tmux sessions.

## Prerequisites

- [tmux](https://github.com/tmux/tmux)
- [zoxide](https://github.com/ajeetdsouza/zoxide)
- [fzf](https://github.com/junegunn/fzf) (>=0.35.0)
- [fd](https://github.com/sharkdp/fd)

add to bin

`[ ! -f /usr/local/bin/tm ] && ln -s tmux-session-manager.sh /usr/local/bin/tm`

```zsh

function tmux_session_maager() {
  result=$(tm | xargs)

  if [[ "$result" == *"[detached (from session"* ]]; then
    echo -en "\033]0;ms\a"
    echo "$result"
  else
    [ ! -z "$result" ] && [ -d "$result/" ] && cd "$result" || z  "$result"
  fi

  return 0

}

bindkey -s '^[z' '\C-u tmux_session_maager\n'

```


