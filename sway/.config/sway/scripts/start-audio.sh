#!/bin/bash
# Start pipewire audio stack if not already running

if ! pgrep -x pipewire > /dev/null; then
    pipewire &
    sleep 1
fi

if ! pgrep -x pipewire-pulse > /dev/null; then
    pipewire-pulse &
    sleep 1
fi

if ! pgrep -x wireplumber > /dev/null; then
    wireplumber &
fi
