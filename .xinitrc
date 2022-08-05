#!/bin/sh

pkill redshift
redshift &
feh --no-fehbg --bg-fill -z $HOME/Pictures/nord
setxkbmap -option caps:escape
picom
pipewire
pipewire-pulse
xrdb ~/.Xresources 
dwmblocks &
while type dwm >/dev/null ; do dbus-launch --exit-with-session dwm && continue || break ; done
