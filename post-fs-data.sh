#!/system/bin/sh
MODDIR=${0%/*}
LOG=$MODDIR/mount.log
echo "== $(date)" > "$LOG"

# Bind-mount each module file onto its original path, copying the SELinux label from the original file
# (without this, the MediaTek HAL is denied by SELinux when reading the file: avc denied read system_file)
bindcfg() {
  SRC="$MODDIR/$1"
  DST="/$1"
  [ -f "$SRC" ] || { echo "skip (not found in module): $1" >> "$LOG"; return; }
  [ -f "$DST" ] || { echo "skip (not found on system): $1" >> "$LOG"; return; }
  CTX=$(ls -Z "$DST" 2>/dev/null | sed 's/ .*//')
  case "$CTX" in
    u:object_r:*) ;;
    *) CTX=u:object_r:vendor_configs_file:s0 ;;
  esac
  chmod 644 "$SRC"
  chcon "$CTX" "$SRC"
  mount --bind "$SRC" "$DST" && echo "ok $1 [$CTX]" >> "$LOG" || echo "FAILED mount $1" >> "$LOG"
}

# Media
bindcfg vendor/etc/media_profiles_V1_0.xml
bindcfg vendor/etc/media_codecs_performance.xml
bindcfg vendor/etc/media_codecs.xml

# MTK PowerHAL: scenario, command table, whitelist per-app
bindcfg vendor/etc/powerscntbl.xml
bindcfg vendor/etc/powercontable.xml
bindcfg vendor/etc/power_app_cfg.xml
bindcfg vendor/etc/thermalbreakboostconfig.xml

# Task profile & SurfaceFlinger
bindcfg system/etc/task_profiles.json
bindcfg system/etc/init/surfaceflinger.rc
