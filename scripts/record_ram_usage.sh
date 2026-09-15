#!/usr/bin/env bash

set -eu

output_file="${1:-ram_usage.txt}"
interval_seconds="${2:-60}"

case "$interval_seconds" in
    ''|*[!0-9]*)
        printf 'Interval must be a non-negative integer: %s\n' "$interval_seconds" >&2
        exit 1
        ;;
esac

record_sample() {
    awk -v timestamp="$(date '+%Y-%m-%d %H:%M:%S')" '
        /^MemTotal:/     { total = $2 }
        /^MemAvailable:/ { available = $2 }
        END {
            used = total - available
            used_percent = (used / total) * 100
            printf "%s | total: %.2f GB | used: %.2f GB (%.1f%%) | available: %.2f GB\n",
                timestamp, total / 1024 / 1024, used / 1024 / 1024,
                used_percent, available / 1024 / 1024
        }
    ' /proc/meminfo >> "$output_file"
}

printf 'Recording RAM usage to %s every %s seconds. Press Ctrl+C to stop.\n' \
    "$output_file" "$interval_seconds"

while true; do
    record_sample
    sleep "$interval_seconds"
done
