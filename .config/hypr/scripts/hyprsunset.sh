#!/usr/bin/env bash
#hyprsunset.sh

if pgrep hyprsunset > /dev/null; then
    pkill hyprsunset
else
    hyprsunset -t 3500 &
fi

