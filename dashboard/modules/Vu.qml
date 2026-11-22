import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.components
import qs.services
import qs.theme

// VU meter of the default output: one bar per channel (dB scale, -48..0,
// ticks every 12 dB; warn above -6 dB, red above -2 dB),
// with a falling peak marker. Bars run along the tile's longer side.
// Options: channels ("all" default, or "stereo" to keep only 2).
Item {
    id: root

    property ShellScreen screen
    property var options: ({})
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    readonly property bool horizontal: width >= height
    readonly property var levels: monitor.peaks.slice(0, root.options.channels === "all" || !root.options.channels ? 8 : 2)

    function toMeter(peak: real): real {
        if (peak <= 0)
            return 0;
        return Math.max(0, Math.min(1, (20 * Math.log10(peak) + 48) / 48));
    }

    PwNodePeakMonitor {
        id: monitor
        node: Audio.sink
        enabled: root.visible
    }

    Grid {
        anchors.fill: parent
        columns: root.horizontal ? 1 : Math.max(1, root.levels.length)
        spacing: root.theme.space.s

        Repeater {
            model: root.levels.length

            Item {
                id: meter

                required property int index
                readonly property real level: root.toMeter(root.levels[index] ?? 0)
                property real smooth: 0
                property real hold: 0

                width: root.horizontal ? root.width : (root.width - root.theme.space.s * (root.levels.length - 1)) / root.levels.length
                height: root.horizontal ? (root.height - root.theme.space.s * (root.levels.length - 1)) / root.levels.length : root.height

                // Fast attack, slower release; the peak marker falls slowly.
                onLevelChanged: {
                    smooth = level > smooth ? level : smooth * 0.85 + level * 0.15;
                    hold = Math.max(level, hold);
                }

                Timer {
                    interval: 50
                    repeat: true
                    running: root.visible
                    onTriggered: meter.hold = Math.max(meter.smooth, meter.hold - 0.01)
                }

                Rectangle {
                    anchors.fill: parent
                    radius: root.theme.radius.control
                    color: root.theme.color.surface2
                }

                Rectangle {
                    readonly property real amount: meter.smooth
                    x: 0
                    y: root.horizontal ? 0 : parent.height * (1 - amount)
                    width: root.horizontal ? parent.width * amount : parent.width
                    height: root.horizontal ? parent.height : parent.height * amount
                    radius: root.theme.radius.control
                    color: meter.smooth > 46 / 48 ? root.theme.color.urgent : meter.smooth > 42 / 48 ? root.theme.color.warn : root.theme.color.accent
                }

                // Ticks at -36, -24, -12 dB.
                Repeater {
                    model: [0.25, 0.5, 0.75]

                    Rectangle {
                        required property real modelData
                        x: root.horizontal ? parent.width * modelData : 0
                        y: root.horizontal ? 0 : parent.height * (1 - modelData)
                        width: root.horizontal ? 1 : parent.width
                        height: root.horizontal ? parent.height : 1
                        color: Qt.alpha(root.theme.color.ink, 0.25)
                        z: 1
                    }
                }

                Rectangle {
                    visible: meter.hold > 0.01
                    x: root.horizontal ? parent.width * meter.hold - width : 0
                    y: root.horizontal ? 0 : parent.height * (1 - meter.hold)
                    width: root.horizontal ? 3 : parent.width
                    height: root.horizontal ? parent.height : 3
                    color: root.theme.color.ink
                }
            }
        }
    }
}
