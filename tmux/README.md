# Installation

## For me only
```bash
curl -H "Cache-Control: no-cache" https://raw.githubusercontent.com/kongjiadongyuan/terminal_config/main/tmux/tmux.conf > ~/.kjdy.tmux.conf
```

## For all users
```bash
curl -H "Cache-Control: no-cache" https://raw.githubusercontent.com/kongjiadongyuan/terminal_config/main/tmux/tmux.conf > ~/.tmux.conf
```

If strange characters appear at the top when tmux starts, you can consider modifying the value of `set -sg escape-time`.
