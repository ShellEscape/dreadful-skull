#!/usr/bin/env bash

# if terminal command hangs then that means it is working as intended
# Exit if a command fails or a variable is unassigned
set -euo pipefail

# Must be run as root to interact with serial hardware and iptables
if [[ $EUID -ne 0 ]]; then
   echo "[-] This engine must be run as root (sudo)."
   exit 1
fi

SERIAL_PORT="/dev/pts/2" # Update to your active serial interface
BAUD_RATE="9600"
LOG_FILE="/var/log/gps_security.log"

# Configure the Linux kernel's serial interface parameters directly via stty
echo "[+] Configuring kernel serial line settings for $SERIAL_PORT..."
stty -F "$SERIAL_PORT" "$BAUD_RATE" raw -echo -echoe -echok

echo "[+] GPS Integrity Monitor active. Scanning stream..."

# Persistent trackers for anomaly detection
LAST_LAT=""
LAST_LON=""

execute_mitigation() {
    local reason=$1
    local details=$2

    echo "[!] CRITICAL: $reason | $details" | tee -a "$LOG_FILE"
    logger -p kern.crit "[GPS_DEFENSE] ATTACK DETECTED: $reason. $details"

    # 1. Sever Precision Time Protocol to protect system clock
    if systemctl is-active --quiet chrony; then
        systemctl stop chrony
        echo "$(date) - [ISOLATION] Halted chrony NTP daemon." >> "$LOG_FILE"
    fi

    # 2. Drop outgoing connections on network time ports via iptables
    if command -v iptables &> /dev/null; then
        iptables -A OUTPUT -p udp --dport 123 -j DROP
        echo "$(date) - [FIREWALL] Blocked outbound UDP Port 123." >> "$LOG_FILE"
    fi

    exit 2
}

# Read the serial interface line-by-line directly from the kernel buffer
while read -r line < "$SERIAL_PORT"; do
    # Filter for GPRMC sentences (Recommended Minimum Navigation Information)
    if [[ "$line" =~ ^\$GPRMC ]]; then

        # Parse comma-separated NMEA values using cut
        STATUS=$(echo "$line" | cut -d',' -f3)      # A=Active, V=Void (Warning)
        LAT_RAW=$(echo "$line" | cut -d',' -f4)     # Latitude string
        LON_RAW=$(echo "$line" | cut -d',' -f6)     # Longitude string

        # Anomaly 1: Check if the GPS receiver itself flags the data as invalid
        if [[ "$STATUS" == "V" ]]; then
            execute_mitigation "RECEIVER_VOID_FLAG" "GPS module reporting invalid tracking state (potential jamming/loss of fix)."
        fi

        # Anomaly 2: Check for abrupt, impossible positional shifts
        if [[ -n "$LAT_RAW" && -n "$LON_RAW" ]]; then
            if [[ -n "$LAST_LAT" && "$LAST_LAT" != "$LAT_RAW" ]]; then

                # Simple look-ahead check: if the coordinate prefix completely changes instantly
                # (e.g. jumping whole degrees from 39xx.xxxx to 55xx.xxxx)
                LAST_DEGREE=${LAST_LAT:0:2}
                CURR_DEGREE=${LAT_RAW:0:2}

                if [[ "$LAST_DEGREE" != "$CURR_DEGREE" ]]; then
                    execute_mitigation "SPATIAL_TELEMETRY_JUMP" "Instant geographic degree shift detected from $LAST_LAT to $LAT_RAW"
                fi
            fi

            # Update history cache
            LAST_LAT="$LAT_RAW"
            LAST_LON="$LON_RAW"
        fi
    fi
done
