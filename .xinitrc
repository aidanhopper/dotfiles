#!/bin/sh

pkill redshift
redshift &
setxkbmap -option caps:escape
xrdb ~/.Xresources 
picom --experimental-backends &
//picom & 
dropbox start -i &
pipewire &
pipewire-pulse &
wireplumber &
setbg
dwmblocks &
while type dwm >/dev/null ; do dbus-launch --exit-with-session dwm && continue || break ; done

