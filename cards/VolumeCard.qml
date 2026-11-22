import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Output device and volume, per-application volumes, microphone level.
Column {
    id: root

    property var block
    property ShellScreen screen
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    spacing: theme.space.m

    Item {
        width: parent.width
        implicitHeight: device.implicitHeight

        ThemedText {
            id: device
            width: parent.width - value.width - root.theme.space.s
            text: Audio.sinkName
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        ThemedText {
            id: value
            anchors.right: parent.right
            text: Audio.muted ? I18n.tr("common.muted") : I18n.percent(Audio.volume)
            color: Audio.muted ? root.theme.color.soft : root.theme.color.ink
            font.features: ({ "tnum": 1 })
        }
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
        visible: Audio.streams.length === 0
        text: I18n.tr("card.noApps")
        color: root.theme.color.soft
        font.pixelSize: root.theme.font.sizeS
    }

    Repeater {
        model: Audio.streams

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

    Row {
        width: parent.width
        spacing: root.theme.space.s

        ThemedText {
            width: parent.width * 0.38
            anchors.verticalCenter: parent.verticalCenter
            text: Audio.sourceMuted ? I18n.tr("common.muted") : Audio.sourceName
            color: Audio.sourceMuted ? root.theme.color.soft : root.theme.color.ink
            font.pixelSize: root.theme.font.sizeS
            elide: Text.ElideRight
        }

        // Live input level.
        Rectangle {
            width: parent.width * 0.62 - parent.spacing
            height: 6
            anchors.verticalCenter: parent.verticalCenter
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
    }

    PwNodePeakMonitor {
        id: mic
        node: Audio.sourceMuted ? null : Audio.source
        enabled: !Audio.sourceMuted
    }
}
