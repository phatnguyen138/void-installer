#!/bin/bash
killall -q pipewire wireplumber pipewire-pulse

pipewire &

sleep 1

pipewire-pulse &
sleep 1

wireplumber &
