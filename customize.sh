#!/system/bin/sh
# ============================================
ui_print " "
ui_print "          ,----,                            "
ui_print "        ,/   .\`|                       ,--. "
ui_print "      ,\`   .'  :,--,     ,--,        ,--.'| "
ui_print "    ;    ;     /|'. \\   / .\`|    ,--,:  : | "
ui_print "  .'___,/    ,' ; \\ \`\\ /' / ; ,\`--.'\`|  ' : "
ui_print "  |    :     |  \`. \\  /  / .' |   :  :  | | "
ui_print "  ;    |.';  ;   \\  \\/  / ./  :   |   \\ | : "
ui_print "  \`----'  |  |    \\  \\.'  /   |   : '  '; | "
ui_print "      '   :  ;     \\  ;  ;    '   ' ;.    ; "
ui_print "      |   |  '    / \\  \\  \\   |   | | \\   | "
ui_print "      '   :  |   ;  /\\  \\  \\  '   : |  ; .' "
ui_print "      ;   |.'  ./__;  \\  ;  \\ |   | '\`--'   "
ui_print "      '---'    |   : / \\  \\  ;'   : |       "
ui_print "               ;   |/   \\  ' |;   |.'       "
ui_print "               \`---'     \`--\` '---'         "
ui_print " "
ui_print "            R14C 调 - v4.5"
ui_print "               by Txn2z虚空"
ui_print " "
ui_print "  Target  : Redmi14C"
ui_print "  Chipset : Helio G85 (MT6768)"
ui_print "  Goal    : Lightweight & Smooth"
ui_print " "
ui_print "  ----------------------------------------"
ui_print "  What's new in v4.5:"
ui_print "  + thermalbreakboost : scroll boost (25-41C)"
ui_print "  + service.sh        : read-ahead storage 512KB"
ui_print "  ----------------------------------------"
ui_print " "

# ------------ Device Info ------------
DEVICE_MODEL=$(getprop ro.product.model)
DEVICE_NAME=$(getprop ro.product.name)
DEVICE_BRAND=$(getprop ro.product.brand)
ANDROID_VER=$(getprop ro.build.version.release)
SDK_VER=$(getprop ro.build.version.sdk)
CHIPSET=$(getprop ro.board.platform)
ABI=$(getprop ro.product.cpu.abi)

ui_print "  Device Info"
ui_print "  ----------------------------------------"
ui_print "  Model    : $DEVICE_BRAND $DEVICE_MODEL ($DEVICE_NAME)"
ui_print "  Android  : $ANDROID_VER (SDK $SDK_VER)"
ui_print "  Chipset  : $CHIPSET"
ui_print "  ABI      : $ABI"
ui_print "  ----------------------------------------"
ui_print " "

ui_print "  Installing files..."
ui_print " "

FAILED=0

install_check() {
  local FILE="$1"
  local LABEL="$2"
  local PROGRESS="$3"
  if [ -f "$MODPATH/$FILE" ]; then
    ui_print "  ✓ $LABEL"
  else
    ui_print "  ✗ $LABEL  [FAILED]"
    FAILED=1
  fi
  set_progress "$PROGRESS"
  sleep 0.3
}

set_progress 0.0
install_check "vendor/etc/media_profiles_V1_0.xml"      "media_profiles_V1_0.xml"      0.14
install_check "vendor/etc/media_codecs_performance.xml" "media_codecs_performance.xml" 0.28
install_check "vendor/etc/media_codecs.xml"             "media_codecs.xml"             0.42
install_check "vendor/etc/powerscntbl.xml"              "powerscntbl.xml"              0.50
install_check "vendor/etc/powercontable.xml"            "powercontable.xml"            0.57
install_check "vendor/etc/power_app_cfg.xml"            "power_app_cfg.xml"            0.64
install_check "vendor/etc/thermalbreakboostconfig.xml"  "thermalbreakboostconfig.xml"  0.67
install_check "system/etc/task_profiles.json"           "task_profiles.json"           0.71
install_check "system/etc/init/surfaceflinger.rc"       "surfaceflinger.rc"            0.85
install_check "service.sh"                              "service.sh"                   0.93
install_check "system.prop"                             "system.prop"                  1.0

ui_print " "
if [ "$FAILED" -eq 0 ]; then
  ui_print "  ✓ All files installed successfully."
else
  ui_print "  ✗ One or more files failed to install."
fi
ui_print "  Please reboot your device."
ui_print " "
# ============================================
