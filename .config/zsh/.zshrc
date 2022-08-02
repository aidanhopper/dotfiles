EDITOR="nvim"
ZSH_THEME="robbyrussell"
# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="false"

plugins=(
    git
    zsh-autosuggestions
	colored-man-pages
)

# Useful functions
fcd () cd "$(find $HOME -type d | fzf --preview 'tree {}')"


# Setting XDG environment vars
export XDG_STATE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share
export XDG_CACHE_HOME=$HOME/.cache
export XDG_CONFIG_HOME=$HOME/.config
# Setting PATH vars 
export PATH=/usr/local/bin:$PATH
export PATH=$HOME/.local/bin:$PATH

# Setting app specfic paths
export HISTFILE=$XDG_STATE_HOME/zsh/history
export XINITRC=$XDG_CONFIG_HOME/X11/xinitrc
export XAUTHORITY=$XDG_RUNTIME_DIR/Xauthority
export ZSH=$XDG_DATA_HOME/oh-my-zsh
export INPUTRC=$XDG_CONFIG_HOME/readline/inputrc
export LESSHISTFILE=$XDG_CACHE_HOME/less/history
export CUDA_CACHE_PATH=$XDG_CACHE_HOME/nv

# ZSH sources
source $ZSH/oh-my-zsh.sh
source $ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $ZSH/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# aliases
alias w=setbg
alias v="nvim"
alias fet="neofetch"
alias fzf="fzf --color bg:-1"
alias spending=slocksuspend
alias sus=slocksuspend
alias nvidia-settings="nvidia-settings --config='$XDG_CONFIG_HOME/nvidia/settings'"
alias x="startx $XINITRC"
alias cat=bat

# package manager aliases
alias xq=xbps-query
alias xi="sudo xbps-install"
alias xr="sudo xbps-remove"
cd
