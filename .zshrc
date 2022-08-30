# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="false"

# Useful functions
fcd () cd "$(find $HOME -type d | fzf --preview 'tree {}')"

# Term enviroment var
TERMINAL=st
EDITOR=nvim

# Enabling history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_SAVE_NO_DUPS

# Setting XDG environment vars
export XDG_STATE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share
export XDG_CACHE_HOME=$HOME/.cache
export XDG_CONFIG_HOME=$HOME/.config

# Setting PATH vars 
export PATH=/usr/local/bin:$PATH
export PATH=$HOME/.local/bin:$PATH
# export PATH=$HOME/.dotfiles/.local/bin/statusbar:$PATH

# Setting app specfic paths
export HISTFILE=$XDG_STATE_HOME/zsh/history
export XINITRC=$XDG_CONFIG_HOME/X11/xinitrc
export XAUTHORITY=$XDG_RUNTIME_DIR/Xauthority
export INPUTRC=$XDG_CONFIG_HOME/readline/inputrc
export LESSHISTFILE=$XDG_CACHE_HOME/less/history
export CUDA_CACHE_PATH=$XDG_CACHE_HOME/nv

# ZSH plugins/theme/options
source $XDG_CONFIG_HOME/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source $XDG_CONFIG_HOME/zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#4c566a'
fpath+=$XDG_CONFIG_HOME/zsh/typewritten
autoload -U promptinit; promptinit
autoload -U compinit; compinit
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu select
_comp_options+=(globdots) # shows hidden files
TYPEWRITTEN_SYMBOL="%B$%b"
prompt typewritten
setopt extendedglob
unsetopt CASE_GLOB

# vi mode
bindkey -v
KEYTIMEOUT=1
cursor_mode() {
  # See https://ttssh2.osdn.jp/manual/4/en/usage/tips/vim.html for cursor shapes
  cursor_block='\e[2 q'
  cursor_beam='\e[6 q'

  function zle-keymap-select {
    if [[ ${KEYMAP} == vicmd ]] ||
      [[ $1 = 'block' ]]; then
      echo -ne $cursor_block
    elif [[ ${KEYMAP} == main ]] ||
      [[ ${KEYMAP} == viins ]] ||
      [[ ${KEYMAP} = '' ]] ||
      [[ $1 = 'beam' ]]; then
      echo -ne $cursor_beam
    fi
  }

  zle-line-init() {
      echo -ne $cursor_beam
  }

  zle -N zle-keymap-select
  zle -N zle-line-init
}
cursor_mode

# Edit line in vim with ctrl-e:
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line


# aliases
alias w=setbg
alias v="nvim"
alias fet="neofetch"
alias fzf="fzf --color bg:-1"
alias spending=slocksuspend
alias sus=slocksuspend
alias nvidia-settings="nvidia-settings --config='$XDG_CONFIG_HOME/nvidia/settings'"
alias x=startx
alias cat=bat
alias ls="ls --color"

# git aliases
alias gp="git push"
alias gc="git commit"
alias ga="git add"
alias gs="git status"
alias emacsclient="emacsclient -n"

# package manager aliases
alias xq=xbps-query
alias xi="sudo xbps-install"
alias xr="sudo xbps-remove"
cd
