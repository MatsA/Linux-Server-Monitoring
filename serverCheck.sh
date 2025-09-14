
# A lightweight monitoring agent for Linux environment
# On the MQTT  broker => mosquitto_sub -h localhost -t "servers/+"

# MQTT settings
BROKER="macm.local"
BASE_TOPIC="servers/$(hostname)"

# Disk used in %
disk_used=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')

# Memory usage (% used)
mem_used=$(free | grep Mem | awk '{print int(100*($2-$4)/$2)}')


# CPU load averages (1, 5, 15 min)
                #cpu_load_1=$(awk '{print $1}' /proc/loadavg)
cpu_load_5=$(awk '{print $2*100}' /proc/loadavg)
                #cpu_load_15=$(awk '{print $3}' /proc/loadavg)

# Upgradable packages
upgrades=$(apt list --upgradable 2>/dev/null | tail -n +2 | wc -l)

# Create JSON payload
payload=$(cat <<EOF
{
  "hostname": "$(hostname)",
  "disk_used_percent": $disk_used,
  "memory_used_percent": $mem_used,
  "cpu_load": "$cpu_load_5",
  "upgradable_packages": $upgrades,
  "timestamp": "$(date -Iseconds)"
}
EOF
)

#echo "$payload"
#echo "$BASE_TOPIC"

 # Publish to MQTT
mosquitto_pub -h "$BROKER" -t "$BASE_TOPIC" -m "$payload"