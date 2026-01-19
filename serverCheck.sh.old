# 2025-09-15 MatsA 
# A lightweight monitoring agent for Linux environment
# MQTT broker subscribe example => mosquitto_sub -h localhost -t "servers/+"
# Scheduele example => crontab -e => add =>  */1 * * * * bash /home/pi/serverCheck.sh

# Settings
BROKER="macm.local"
BASE_TOPIC="servers/$(hostname)"
STATE_FILE="/tmp/.upgrades_last_run"

# Disk used in %
disk_used=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')

# Memory usage (% used)
mem_used=$(free | grep Mem | awk '{print int(100*$3/$2)}')


# CPU load averages (1, 5, 15 min)
                #cpu_load_1=$(awk '{print $1}' /proc/loadavg)
cpu_load_5=$(awk '{print $2*100}' /proc/loadavg)
                #cpu_load_15=$(awk '{print $3}' /proc/loadavg)

# Upgradable packages ?
# Check if the state file exists and if it's less than 24 hours old
if [ -f "$STATE_FILE" ] && find "$STATE_FILE" -mmin -1440 | grep -q .; then
    # File exists and is less than a day old, so read the value
    read -r last_run_timestamp upgrades < "$STATE_FILE"
    echo "Using cached value: $upgrades"
else
    # File does not exist or is older than a day, so run the command
    if command -v apt >/dev/null 2>&1; then
        upgrades=$(apt list --upgradable 2>/dev/null | tail -n +2 | wc -l)
    else
        upgrades="false"
    fi
    # Store the new value and the current timestamp
    echo "$(date +%s) $upgrades" > "$STATE_FILE"
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
  "timestamp": "$(date -Iseconds)"
}
EOF
)

#echo "$payload"
#echo "$BASE_TOPIC"

 # Publish to MQTT
mosquitto_pub -h "$BROKER" -t "$BASE_TOPIC" -m "$payload"
