#!/system/bin/sh
MODDIR=${0%/*}
LOG=$MODDIR/service.log
echo "== $(date)" > "$LOG"
while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 2; done
sleep 20
w() {
  if [ -w "$2" ]; then
    echo "$1" > "$2" 2>/dev/null && echo "ok   $2 = $1" >> "$LOG" || echo "FAILED $2" >> "$LOG"
  else
    echo "skip $2 (not found)" >> "$LOG"
  fi
}
for B in /sys/block/mmcblk0; do
  [ -d "$B" ] || continue
  w 512 "$B/queue/read_ahead_kb"
  w 0   "$B/queue/iostats"
  w 0   "$B/queue/add_random"
done
