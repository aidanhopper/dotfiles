# Succulent dotfiles

Purpose of this repo is to make my setup portable.

## Included programs:

- dwm 
- st 
- dmenu
- dwmblocks
- slock
- neovim
- zsh
- picom
- tmux
- redshift
- zathura

## How to use the setup script
**NOTE**: Setup script is currently only compatible with Void Linux.

Command to run a setup script.
```shell
git clone --depth 1 https://github.com/aidanhopper/dotfiles \
--recurse-submodules .dotfiles && chmox +x .dotfiles/setup \
&& .dotfiles/setup
```

## TODO: 
- Add Xresources support to neovim.
- Make new themes and theme switcher.
- Add checks to setup script to not run redundant commands.
- Add more distros to setup script.
- Improve dwm keybinds.
- Make autosetup script for glibc Void Linux iso with encrypted LUKS and separate home partition.
