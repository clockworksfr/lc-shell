import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Output device (pickable) and volume, per-application volumes, input
// device (pickable) and its live level.
Column {
    id: root

    property var block
    property ShellScreen screen
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    spacing: theme.space.m

    // Output: current device (tap to pick another), volume.
    DevicePicker {
        width: parent.width
        icon: "speaker"
        devices: Audio.sinks
        current: Audio.sink
        trailing: Audio.muted ? I18n.tr("common.muted") : I18n.percent(Audio.volume)
        trailingColor: Audio.muted ? root.theme.color.soft : root.theme.color.ink
        onPicked: node => Audio.setDefaultSink(node)
    }

    Slider {
        width: parent.width
        value: Audio.volume
        to: Audio.maxVolume
        dimmed: Audio.muted
        onMoved: value => Audio.setVolume(value)
    }

    ThemedText {
        text: I18n.tr("card.apps")
        label: true
        color: root.theme.color.soft
    }

    ThemedText {
        visible: Audio.appStreams.length === 0
        text: I18n.tr("card.noApps")
        color: root.theme.color.soft
        font.pixelSize: root.theme.font.sizeS
    }

    Repeater {
        model: Audio.appStreams

        Row {
            required property PwNode modelData

            width: root.width
            spacing: root.theme.space.s

            ThemedText {
                width: parent.width * 0.38
                anchors.verticalCenter: parent.verticalCenter
                text: Audio.streamName(parent.modelData)
                font.pixelSize: root.theme.font.sizeS
                elide: Text.ElideRight
            }

            Slider {
                width: parent.width * 0.62 - parent.spacing
                value: parent.modelData.audio?.volume ?? 0
                dimmed: parent.modelData.audio?.muted ?? false
                onMoved: value => {
                    if (parent.modelData.audio)
                        parent.modelData.audio.volume = value;
                }
            }
        }
    }

    ThemedText {
        text: I18n.tr("card.microphone")
        label: true
        color: root.theme.color.soft
    }

    // Input: current device (tap to pick another), live level.
    DevicePicker {
        width: parent.width
        icon: Audio.sourceMuted ? "mic_off" : "mic"
        devices: Audio.sources
        current: Audio.source
        trailing: Audio.sourceMuted ? I18n.tr("common.muted") : I18n.percent(Audio.sourceVolume)
        trailingColor: Audio.sourceMuted ? root.theme.color.soft : root.theme.color.ink
        onPicked: node => Audio.setDefaultSource(node)
    }

    Rectangle {
        width: parent.width
        height: 6
        radius: root.theme.radius.full
        color: root.theme.color.surface2

        Rectangle {
            readonly property real peak: mic.peak > 0 ? Math.max(0, Math.min(1, (20 * Math.log10(mic.peak) + 60) / 60)) : 0
            width: parent.width * peak
            height: parent.height
            radius: parent.radius
            color: root.theme.color.ok

            Behavior on width {
                NumberAnimation {
                    duration: 80
                }
            }
        }
    }

    PwNodePeakMonitor {
        id: mic
        node: Audio.sourceMuted ? null : Audio.source
        enabled: !Audio.sourceMuted
    }
}
