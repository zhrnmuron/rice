#!/bin/bash

# Function to get battery percentage
get_battery_percentage() {
    # Works for most Linux laptops
    if [ -f /sys/class/power_supply/BAT0/capacity ]; then
        cat /sys/class/power_supply/BAT0/capacity
    else
        # Fallback using upower
        upower -i $(upower -e | grep BAT) | grep percentage | awk '{print $2}' | sed 's/%//'
    fi
}

# Array to keep track of which warnings have been sent
declare -A warned

while true; do
    battery_level=$(get_battery_percentage)

    if [ "$battery_level" == "20" ] && [ -z "${warned[20]}" ]; then
        notify-send "Battery Warning" "beep beep"
        warned[20]=1
    elif [ "$battery_level" == "15" ] && [ -z "${warned[15]}" ]; then
        notify-send "Battery Warning" "beep beep type shit"
        warned[15]=1
    elif [ "$battery_level" == "10" ] && [ -z "${warned[10]}" ]; then
        notify-send "Battery Warning" "i want you so bad"
        warned[10]=1
    elif [ "$battery_level" == "5" ] && [ -z "${warned[5]}" ]; then
        notify-send "Battery Critical" "NIGGA HOP OFF DISCORD AND PLUG ME IN"
        warned[5]=1
    fi

    # Reset warnings if battery is charged above 20%
    if [ "$battery_level" -gt 20 ]; then
        warned=()
    fi

    sleep 120 # check every 5 minutes
done

