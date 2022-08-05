# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="false"



# Useful functions
fcd () cd "$(find $HOME -type d | fzf --preview 'tree {}')"

# Term enviroment var
TERMINAL=st
EDITOR=nvim
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

# ZSH plugins and theme
source $XDG_CONFIG_HOME/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source $XDG_CONFIG_HOME/zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fpath+=$XDG_CONFIG_HOME/zsh/typewritten
autoload -U promptinit; promptinit
autoload -U compinit; compinit
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
prompt typewritten

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

# package manager aliases
alias xq=xbps-query
alias xi="sudo xbps-install"
alias xr="sudo xbps-remove"
cd
