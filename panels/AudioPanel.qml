import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.components
import qs.services
import qs.theme
import qs.i18n

// Output and input: volume, mute, device choice.
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    width: 360
    spacing: root.theme.space.s

    Section {
        title: I18n.tr("audio.output")
        muted: Audio.muted
        volume: Audio.volume
        maxVolume: Audio.maxVolume
        devices: Audio.sinks
        current: Audio.sink
        onToggleMute: Audio.toggleMute()
        onVolumeMoved: value => Audio.setVolume(value)
        onPicked: node => Audio.setDefaultSink(node)
    }

    Rectangle {
        width: parent.width
        height: 1
        color: root.theme.color.bg
    }

    Section {
        title: I18n.tr("audio.input")
        muted: Audio.sourceMuted
        volume: Audio.sourceVolume
        maxVolume: 1
        devices: Audio.sources
        current: Audio.source
        onToggleMute: Audio.toggleSourceMute()
        onVolumeMoved: value => Audio.setSourceVolume(value)
        onPicked: node => Audio.setDefaultSource(node)
    }

    component Section: Column {
        id: section

        readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

        property string title
        property bool muted
        property real volume
        property real maxVolume
        property list<PwNode> devices
        property PwNode current

        signal toggleMute
        signal volumeMoved(real value)
        signal picked(PwNode node)

        width: parent.width
        spacing: section.theme.space.s

        Item {
            width: parent.width
            implicitHeight: header.implicitHeight

            ThemedText {
                id: header
                text: section.title
                font.pixelSize: section.theme.font.sizeS
                color: section.theme.color.fgMuted
            }

            ThemedText {
                anchors.right: parent.right
                text: section.muted ? I18n.tr("common.muted") : I18n.percent(section.volume)
                color: section.muted ? section.theme.color.fgMuted : section.theme.color.fg

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: section.toggleMute()
                }
            }
        }

        Slider {
            width: parent.width
            value: section.volume
            to: section.maxVolume
            dimmed: section.muted
            onMoved: value => section.volumeMoved(value)
        }

        Repeater {
            model: section.devices

            Rectangle {
                required property PwNode modelData
                readonly property bool selected: modelData === section.current

                width: section.width
                implicitHeight: deviceName.implicitHeight + section.theme.space.s * 2
                radius: section.theme.radius.s
                color: hover.containsMouse ? section.theme.color.bg : "transparent"

                ThemedText {
                    id: deviceName
                    anchors.fill: parent
                    anchors.leftMargin: section.theme.space.s
                    anchors.rightMargin: section.theme.space.s
                    text: `${parent.selected ? "●" : "○"}  ${Audio.nodeName(parent.modelData)}`
                    color: parent.selected ? section.theme.color.fg : section.theme.color.fgMuted
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: section.picked(parent.modelData)
                }
            }
        }
    }
}
