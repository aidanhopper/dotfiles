#!/bin/sh

pkill redshift
redshift &
feh --no-fehbg --bg-fill -z $HOME/Pictures/nord
setxkbmap -option caps:escape
xrdb ~/.Xresources 
picom &
pipewire &
pipewire-pulse &
dwmblocks &
while type dwm >/dev/null ; do dbus-launch --exit-with-session dwm && continue || break ; done
