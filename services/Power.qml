pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Battery and power profiles (UPower, power-profiles-daemon).
Singleton {
    id: root

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery?.isPresent && battery?.type === UPowerDeviceType.Battery
    readonly property real level: battery?.percentage ?? 0 // 0..1
    readonly property bool charging: battery?.state === UPowerDeviceState.Charging || battery?.state === UPowerDeviceState.PendingCharge
    readonly property bool full: battery?.state === UPowerDeviceState.FullyCharged
    readonly property bool onBattery: UPower.onBattery
    // Seconds; 0 when unknown.
    readonly property real timeLeft: charging ? (battery?.timeToFull ?? 0) : (battery?.timeToEmpty ?? 0)
    readonly property bool low: hasBattery && onBattery && level <= 0.15

    // Available PowerProfile values, in UI order.
    readonly property var profiles: PowerProfiles.hasPerformanceProfile ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance] : [PowerProfile.PowerSaver, PowerProfile.Balanced]
    readonly property int profile: PowerProfiles.profile

    function setProfile(value: int): void {
        PowerProfiles.profile = value;
    }

    function profileKey(value: int): string {
        return value === PowerProfile.PowerSaver ? "saver" : value === PowerProfile.Performance ? "performance" : "balanced";
    }
}
