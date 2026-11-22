pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// What the on-screen display shows. It reacts to changes rather than to
// key presses, so it also works when keys are bound to wpctl/brightnessctl.
// Values are live bindings: repeated presses update the OSD while it's shown.
Singleton {
    id: root

    property bool shown: false
    property string kind // "volume" | "mic" | "brightness"
    property BrightnessMonitor monitor
    // Brightness shows on the screen that changed, the rest on the focused one.
    property string screenName

    readonly property real value: kind === "volume" ? Audio.volume
        : kind === "mic" ? Audio.sourceVolume
        : monitor?.brightness ?? 0
    readonly property bool muted: kind === "volume" ? Audio.muted
        : kind === "mic" ? Audio.sourceMuted
        : false
    readonly property string label: kind === "volume" ? Audio.sinkName
        : kind === "mic" ? Audio.sourceName
        : monitor?.name ?? ""

    readonly property int timeout: 1500

    function show(kind: string, monitor: BrightnessMonitor): void {
        root.kind = kind;
        root.monitor = monitor;
        root.screenName = monitor?.name ?? Hyprland.focusedMonitor?.name ?? "";
        root.shown = true;
        hide.restart();
    }

    Timer {
        id: hide
        interval: root.timeout
        onTriggered: root.shown = false
    }

    Connections {
        target: Audio

        function onSinkTouched(): void {
            root.show("volume", null);
        }
        function onSourceTouched(): void {
            root.show("mic", null);
        }
    }

    Connections {
        target: Brightness

        function onTouched(monitor: BrightnessMonitor): void {
            root.show("brightness", monitor);
        }
    }
}
