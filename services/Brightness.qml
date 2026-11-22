pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Brightness of every screen, see BrightnessMonitor.
Singleton {
    id: root

    // DRM connector name -> i2c bus, from `ddcutil detect`.
    property var ddcBuses: ({})

    readonly property list<BrightnessMonitor> monitors: variants.instances
    readonly property BrightnessMonitor focused: forScreen(Hyprland.focusedMonitor?.name ?? "")
    readonly property real step: 0.05

    signal touched(monitor: BrightnessMonitor)

    function forScreen(name: string): BrightnessMonitor {
        return monitors.find(m => m.name === name) ?? null;
    }

    function increment(): void {
        focused?.setBrightness(focused.brightness + step);
    }

    function decrement(): void {
        focused?.setBrightness(focused.brightness - step);
    }

    Variants {
        id: variants
        model: Quickshell.screens

        BrightnessMonitor {
            id: monitor
            ddcBuses: root.ddcBuses
            onTouched: root.touched(monitor)
        }
    }

    // Screens come and go (eGPU hotplug): re-detect once things settle.
    Connections {
        target: Quickshell

        function onScreensChanged(): void {
            redetect.restart();
        }
    }

    Timer {
        id: redetect
        interval: 2000
        onTriggered: detect.running = true
    }

    Process {
        id: detect
        running: true
        command: ["ddcutil", "detect", "--brief"]
        stdout: StdioCollector {
            onStreamFinished: {
                // Pairs of "I2C bus: /dev/i2c-N" then "DRM connector: cardX-NAME".
                const buses = {};
                let bus = -1;
                for (const line of text.split("\n")) {
                    const busMatch = line.match(/I2C bus:\s*\/dev\/i2c-(\d+)/);
                    if (busMatch)
                        bus = parseInt(busMatch[1]);
                    const connector = line.match(/DRM connector:\s*card\d+-(\S+)/);
                    if (connector && bus >= 0)
                        buses[connector[1]] = bus;
                }
                root.ddcBuses = buses;
            }
        }
    }
}
