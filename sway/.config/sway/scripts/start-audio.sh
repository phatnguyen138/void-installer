#!/bin/bash
# Start pipewire audio stack if not already running

# kill all running pipewire instances
killall pipewire
killall pipewire-pulse
killall wireplumber

# start pipewire
pipewire &

# start pipewire-pulse
pipewire-pulse &

# start wireplumber
wireplumber &
