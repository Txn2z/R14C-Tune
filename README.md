<div align="center">

<img src="img/b.jpg" alt="R14C Tune" width="100%">

# R14C 调 (R14C Tune)

**A lightweight performance and smoothness module for the Redmi 14C (Helio G85 / MT6768)**

![Version](https://img.shields.io/badge/version-v4.5-blue)
![Status](https://img.shields.io/badge/status-beta-yellow)
![Root](https://img.shields.io/badge/root-Magisk%20%7C%20KernelSU%20%7C%20APatch-00B39B)
![Platform](https://img.shields.io/badge/platform-MT6768-orange)
![License](https://img.shields.io/badge/license-MIT-green)

</div>

---

> **Beta notice.** R14C Tune is under active development. Behavior may change between releases, and some tweaks are still being validated on real hardware. See [Known Limitations](#known-limitations) before installing.

## Overview

R14C Tune modifies the MediaTek PowerHAL configuration, media profiles, task profiles, and a small set of system properties to improve UI responsiveness and screen recording stability on the Redmi 14C.

Every step the module performs is logged, so you can verify exactly what was applied on your device instead of relying on guesswork.

## Features

| Area | Description |
|---|---|
| Screen recording | 720p media profiles and codec configuration, with the encoder input buffer raised from 10 to 20 to reduce stutter |
| Scroll boost | `thermalbreakboostconfig.xml` raises CPU frequency during scrolling (trigger range 25000-41000) |
| PowerHAL tuning | Adjusted `powerscntbl.xml`, `powercontable.xml`, and per-app whitelist (`power_app_cfg.xml`) |
| Task profiles | `task_profiles.json` with a `MaxPerformance` profile for the top-app cgroup |
| Storage | `read_ahead_kb` set to 512; `iostats` and `add_random` disabled on eMMC |
| Memory | Dalvik heap parameters tuned to reduce multitasking jank |

## Compatibility

| Requirement | Details |
|---|---|
| Device | Redmi 14C |
| Chipset | MediaTek Helio G85 (MT6768) |
| ROM | HyperOS |
| Root | Magisk 20.4+, KernelSU, KernelSU Next, or APatch (see note below) |

This module is built for the device above. **Do not install it on other devices.** PowerHAL and media configuration files differ between models, and incompatible files can cause instability or bootloops.

> **Root manager note.** The module uses the standard Magisk-style module format and applies its configuration through its own bind mounts in `post-fs-data.sh`, so it does not depend on a specific manager's mount system. Magisk is the reference format. KernelSU, KernelSU Next, and APatch are expected to work but have not all been verified, so please report any problems together with your manager's name and version. All paths in this document (`/data/adb/modules/R14C`) are the same across these managers.

## Installation

1. Download the latest zip from the **Releases** page.
2. Open your root manager (Magisk, KernelSU, KernelSU Next, or APatch), go to **Modules**, and select **Install** / **Install from storage**.
3. Confirm that the installer log reports success for every file.
4. Reboot.

## Verification

Run the following as root (`su`) after rebooting.

```sh
# Module is installed
ls /data/adb/modules/R14C

# Bind mounts succeeded (every line should start with "ok";
# a "FAILED" or "skip" line needs attention)
cat /data/adb/modules/R14C/mount.log

# service.sh ran and applied its changes
cat /data/adb/modules/R14C/service.log
cat /sys/block/mmcblk0/queue/read_ahead_kb        # expected: 512

# System properties were read
getprop windowsmgr.max_events_per_sec             # expected: 150
getprop dalvik.vm.heapsize                        # expected: 512m

# No SELinux denials related to the module
dmesg | grep avc | grep -E "vendor_configs|system_file"

# PowerHAL loaded the boost configuration
logcat -d | grep -i ThermalBreakConfigReader
```

## How It Works

`post-fs-data.sh` bind-mounts each configuration file from the module onto its original path. It copies the **SELinux label** from the original file onto the module's copy first. Without this, the MediaTek HAL can be denied read access (`avc: denied ... system_file`).

Files missing on the target system are skipped, and every result is written to `mount.log`. Runtime tweaks that require a finished boot are applied by `service.sh` and recorded in `service.log`.

## Module Structure

```
R14C/
├── META-INF/com/google/android/   # Module installer
├── customize.sh                   # Installer UI and file checks
├── post-fs-data.sh                # Bind mounts and SELinux labeling
├── service.sh                     # Post-boot tweaks
├── system.prop                    # System properties
├── module.prop
├── system/etc/
│   ├── init/surfaceflinger.rc
│   └── task_profiles.json
└── vendor/etc/
    ├── media_profiles_V1_0.xml
    ├── media_codecs.xml
    ├── media_codecs_performance.xml
    ├── powerscntbl.xml
    ├── powercontable.xml
    ├── power_app_cfg.xml
    └── thermalbreakboostconfig.xml
```

## Known Limitations

This is a beta release. The following items are known:

- **`surfaceflinger.rc` has no effect.** Init reads `.rc` files before `post-fs-data` runs, so the bind mount applies too late. A fix that moves SurfaceFlinger into the `top-app` cgroup from `service.sh` is planned.
- **Some `system.prop` entries may be ignored.** Certain `debug.*` and `ro.*` properties are not honored on newer Android and HyperOS builds. They cause no errors, but their effect has not been measured.
- **120 Hz is not unlocked.** The panel supports 120 Hz, but HyperOS caps the refresh rate through SmartPower and the `PRIORITY_MIUI_REFRESH_RATE` vote. This module does not yet address it.
- **Temporary lag right after boot.** For a few minutes after boot completes, the device may stutter, for example when opening the Control Center. This has been observed on the author's device. The exact cause has not been identified, so it is not claimed to be a module bug or a normal HyperOS post-boot task. Wait a few minutes before judging performance. If the lag persists well beyond that, please open an issue with your `service.log` and `mount.log`.
- **No benchmarks yet.** Perceived improvements vary by usage. Measure before and after on your own device.

## Adding Games

Per-app tuning lives in `vendor/etc/power_app_cfg.xml`, a PowerHAL whitelist keyed by package name. Several games (for example Mobile Legends, Free Fire, Free Fire MAX, and PUBG Mobile) are already listed.

To add a game, duplicate an existing entry (or use the template below) and change only the package name:

1. Find the package name of the game:
   ```sh
   pm list packages | grep -i <keyword>
   ```
2. Copy a full `<Package>...</Package>` block (for example `com.dts.freefiremax`) and paste it before the closing `</WHITELIST>` tag.
3. Change `name="..."` to the new package name.
4. Keep the file well-formed XML. A broken file can cause PowerHAL to ignore the whole configuration.
5. Reboot, launch the game, and check the log:
   ```sh
   logcat -d | grep -i -E "libPowerHal|<package name>"
   ```

### Template

Replace `com.example.game` with the package name of your game and paste the block before `</WHITELIST>`:

```xml
<Package name="com.example.game">
    <Activity name="Common">
        <FPS value="Common">
            <WINDOW mode="Common">
                <data cmd="PERF_RES_FPS_FPSGO_CONTROL_BY_PID" param1="1"></data>
                <data cmd="PERF_RES_FPS_FBT_QR_ENABLE" param1="1"></data>
                <data cmd="PERF_RES_FPS_FBT_QR_T2WNT_Y_P" param1="60"></data>
                <data cmd="PERF_RES_FPS_FBT_QR_T2WNT_Y_N" param1="10"></data>
                <data cmd="PERF_RES_FPS_FBT_RESCUE_F" param1="100"></data>
                <data cmd="PERF_RES_FPS_FBT_RESCUE_PERCENT" param1="50"></data>
                <data cmd="PERF_RES_FPS_FBT_ULTRA_RESCUE" param1="1"></data>
                <data cmd="PERF_RES_FPS_FBT_SHORT_RESCUE_NS" param1="16666666"></data>
                <data cmd="PERF_RES_FPS_FBT_MIN_RESCUE_PERCENT" param1="50"></data>
                <data cmd="PERF_RES_KSWAPD_AFFINITY" param1="16129"></data>
                <data cmd="PERF_RES_FPS_FBT_GCC_DOWN_QUOTA_PCT" param1="10"></data>
                <data cmd="PERF_RES_FPS_FBT_GCC_DOWN_STEP" param1="5"></data>
                <data cmd="PERF_RES_FPS_FBT_GCC_UP_QUOTA_PCT" param1="50"></data>
                <data cmd="PERF_RES_THERMAL_POLICY" param1="8"></data>
                <data cmd="PERF_RES_FPS_FPSGO_BOOST_LR" param1="1"></data>
                <data cmd="PERF_RES_FPS_FPSGO_BOOST_AFFINITY" param1="1"></data>
                <data cmd="PERF_RES_DRAM_CM_MGR" param1="1"></data>
                <data cmd="PERF_RES_NET_NETD_BOOST_UID" param1="1"></data>
                <data cmd="PERF_RES_NET_MD_WEAK_SIG_OPT" param1="1"></data>
                <data cmd="PERF_RES_NET_WIFI_LOW_LATENCY" param1="1"></data>
                <data cmd="PERF_RES_DRAM_OPP_MIN" param1="0"></data>
                <data cmd="PERF_RES_SCHED_UCLAMP_MIN_TA" param1="100"></data>
                <data cmd="PERF_RES_SCHED_BOOST" param1="1"></data>
                <data cmd="PERF_RES_CPUFREQ_MIN_CLUSTER_0" param1="3000000"></data>
                <data cmd="PERF_RES_CPUFREQ_MIN_CLUSTER_1" param1="3000000"></data>
                <data cmd="PERF_RES_GPU_FREQ_MIN" param1="0"></data>
                <data cmd="PERF_RES_CPUFREQ_CCI_FREQ" param1="1"></data>
                <data cmd="PERF_RES_FPS_FBT_BLC_BOOST" param1="1000"></data>
                <data cmd="PERF_RES_FPS_FBT_BOOST_TA" param1="1"></data>
                <data cmd="PERF_RES_SCHED_UTIL_UP_RATE_LIMIT_US_CLUSTER_0" param1="0"></data>
                <data cmd="PERF_RES_SCHED_UTIL_UP_RATE_LIMIT_US_CLUSTER_1" param1="0"></data>
                <data cmd="PERF_RES_POWERHAL_TOUCH_BOOST_CLUSTER_0_OPP" param1="0"></data>
                <data cmd="PERF_RES_POWERHAL_TOUCH_BOOST_CLUSTER_1_OPP" param1="0"></data>
                <data cmd="PERF_RES_POWERHAL_TOUCH_BOOST_EAS_BOOST" param1="100"></data>
            </WINDOW>
        </FPS>
    </Activity>
</Package>
```

This template is the same profile used by the Free Fire MAX entry.

**About the heavy entries.** The Free Fire entries use `PERF_RES_CPUFREQ_MIN_CLUSTER_0` and `PERF_RES_CPUFREQ_MIN_CLUSTER_1` with a value of `3000000`, `PERF_RES_SCHED_BOOST`, and a maximum-performance `PERF_RES_FPS_FBT_BLC_BOOST`. The requested minimum frequency is above what the Helio G85 can reach, so it most likely pins the CPU at its top frequency while the game runs. This was not verified on the kernel. Expect higher temperatures and battery drain. For a lighter profile, remove the two `CPUFREQ_MIN_CLUSTER` lines from the copied entry.

Games that enforce their own frame cap will not exceed it regardless of this file.

## Troubleshooting

If the device fails to boot or behaves unexpectedly:

1. Boot into **Safe Mode** using your root manager's method. Modules are disabled in this mode.
2. Alternatively, remove the module from recovery or ADB:
   ```sh
   rm -rf /data/adb/modules/R14C
   ```
3. Reboot.

Keep a way to remove the module available before you install it.

## Changelog

### v4.5 (beta)
- Added scroll boost through `thermalbreakboostconfig.xml` (trigger range 25000-41000)
- Added storage read-ahead of 512 KB in `service.sh`

## Disclaimer

This software is provided as is, without warranty of any kind. Modifying PowerHAL and system configuration can affect battery life, thermals, and stability. You use this module at your own risk. The author is not liable for any damage to your device or loss of data.

## License

Released under the [MIT License](LICENSE).

Configuration files included in this module are derived from stock Xiaomi and MediaTek files and have been modified. Original copyrights remain with their respective owners.

## Author

**Txn2z虚空**

Module name: R14C调 (as shown in your root manager).
