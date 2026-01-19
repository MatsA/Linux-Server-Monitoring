#!/usr/bin/env bash

# 2026-01-19 MatsA
# Lightweight monitoring agent for Linux environment
# MQTT broker subscribe example => mosquitto_sub -h localhost -t "servers/+"
# Schedule example => crontab -e => add =>  */1 * * * * bash /home/pi/serverCheck.sh

# Settings
BROKER="macm.local"
BASE_TOPIC="servers/$(hostname)"
STATE_FILE="/tmp/.upgrades_last_run"
CACHE_TTL=$((12 * 3600))   # 12 hours in seconds

# Disk used in %
disk_used=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')

# Memory usage (% used)
mem_used=$(free | grep Mem | awk '{print int(100*$3/$2)}')

# CPU load averages (use 5min load as % of CPU)
cpu_load_5=$(awk '{print $2*100}' /proc/loadavg)

# Upgradable packages with TTL caching
now=$(date +%s)

if [ -f "$STATE_FILE" ]; then
    read -r last_run_timestamp upgrades < "$STATE_FILE"
    age=$((now - last_run_timestamp))

    if [ $age -lt $CACHE_TTL ]; then
        echo "Using cached value: $upgrades"
    else
        echo "Cache expired, refreshing..."
        if command -v apt >/dev/null 2>&1; then
            upgrades=$(apt list --upgradable 2>/dev/null | tail -n +2 | wc -l)
        else
            upgrades="False"
        fi
        echo "$now $upgrades" > "$STATE_FILE"
        echo "New value calculated: $upgrades"
    fi
else
    echo "No cache, creating..."
    if command -v apt >/dev/null 2>&1; then
        upgrades=$(apt list --upgradable 2>/dev/null | tail -n +2 | wc -l)
    else
        upgrades="False"
    fi
    echo "$now $upgrades" > "$STATE_FILE"
    echo "New value calculated: $upgrades"
fi

# Create JSON payload
payload=$(cat <<EOF
{
  "hostname": "$(hostname)",
  "disk_used_percent": $disk_used,
  "memory_used_percent": $mem_used,
  "cpu_load": $cpu_load_5,
  "upgradable_packages": $upgrades,
  "timestamp": "$(date '+%Y-%m-%d/%R')"
}
EOF
)

# Publish to MQTT
mosquitto_pub -h "$BROKER" -t "$BASE_TOPIC" -m "$payload"
