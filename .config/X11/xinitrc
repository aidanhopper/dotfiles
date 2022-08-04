#!/bin/bash

apps=(
	# 'mopidy'
  'picom'
  'pipewire'
  'pipewire-pulse'
	# 'dropbox'
)

for app in ${apps[@]}; do
	pgrep="$(pgrep $app)"
	if [[ $pgrep == "" ]]; then
		eval $app &
	fi
done

pkill redshift
redshift &
feh --no-fehbg --bg-fill -z $HOME/Pictures/nord
setxkbmap -option caps:escape
xrdb ~/.Xresources 
dwmblocks &
while type dwm >/dev/null ; do dbus-launch --exit-with-session dwm && continue || break ; done
