import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.components
import qs.services
import qs.theme

// VU meter of the default output: one bar per channel (dB scale, -48..0,
// ticks every 12 dB; warn above -6 dB, red above -2 dB),
// with a falling peak marker. Bars run along the tile's longer side.
// Options: channels ("all" default, or "stereo" to keep only 2),
// preVolume (false: the level after the output volume, as heard).
ModuleBase {
    id: root

    readonly property bool horizontal: inner.width >= inner.height
    readonly property var levels: monitor.peaks.slice(0, root.options.channels === "all" || !root.options.channels ? 8 : 2)
    // With nothing playing, PipeWire stops sending peaks: the last ones
    // would stay. Peaks older than 250 ms count as silence.
    property real lastPeakAt: 0
    readonly property bool silent: now - lastPeakAt > 250
    property real now: 0

    // The sink's peaks are taken before its volume: apply it (PipeWire's
    // volume is cubic: gain = volume³; muted = silence), so the meter shows
    // what is heard. Option `preVolume: true` shows the raw signal.
    readonly property real gain: options.preVolume ? 1 : Audio.muted ? 0 : Math.pow(Audio.volume, 3)

    function toMeter(peak: real): real {
        peak *= root.gain;
        if (peak <= 0)
            return 0;
        return Math.max(0, Math.min(1, (20 * Math.log10(peak) + 48) / 48));
    }

    Connections {
        target: monitor
        function onPeaksChanged(): void {
            root.lastPeakAt = Date.now();
        }
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
                readonly property real level: root.silent ? 0 : root.toMeter(root.levels[index] ?? 0)
                property real smooth: 0
                property real hold: 0

                width: root.horizontal ? root.inner.width : (root.inner.width - root.theme.space.s * (root.levels.length - 1)) / root.levels.length
                height: root.horizontal ? (root.inner.height - root.theme.space.s * (root.levels.length - 1)) / root.levels.length : root.inner.height

                // Fast attack, slower release; the peak marker falls slowly.
                onLevelChanged: {
                    smooth = level > smooth ? level : smooth * 0.85 + level * 0.15;
                    hold = Math.max(level, hold);
                }

                Timer {
                    interval: 50
                    repeat: true
                    running: root.visible
                    onTriggered: {
                        root.now = Date.now();
                        // Release even when no new level comes.
                        meter.smooth = meter.level > meter.smooth ? meter.level : meter.smooth * 0.85 + meter.level * 0.15;
                        if (meter.smooth < 0.003)
                            meter.smooth = 0;
                        meter.hold = Math.max(meter.smooth, meter.hold - 0.01);
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Math.min(root.theme.radius.control, 6)
                    color: root.theme.color.surface2
                }

                Rectangle {
                    readonly property real amount: meter.smooth
                    x: 0
                    y: root.horizontal ? 0 : parent.height * (1 - amount)
                    width: root.horizontal ? parent.width * amount : parent.width
                    height: root.horizontal ? parent.height : parent.height * amount
                    radius: Math.min(root.theme.radius.control, 6)
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
