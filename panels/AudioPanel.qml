import QtQuick
import Quickshell.Services.Pipewire
import qs.components
import qs.services
import qs.theme

// Output and input: volume, mute, device choice.
Column {
    id: root

    width: 360
    spacing: Theme.space.s

    Section {
        title: "Sortie"
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
        color: Theme.color.bg
    }

    Section {
        title: "Entrée"
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
        spacing: Theme.space.s

        Item {
            width: parent.width
            implicitHeight: header.implicitHeight

            ThemedText {
                id: header
                text: section.title
                font.pixelSize: Theme.font.sizeS
                color: Theme.color.fgMuted
            }

            ThemedText {
                anchors.right: parent.right
                text: section.muted ? "muet" : `${Math.round(section.volume * 100)} %`
                color: section.muted ? Theme.color.fgMuted : Theme.color.fg

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
                implicitHeight: deviceName.implicitHeight + Theme.space.s * 2
                radius: Theme.radius.s
                color: hover.containsMouse ? Theme.color.bg : "transparent"

                ThemedText {
                    id: deviceName
                    anchors.fill: parent
                    anchors.leftMargin: Theme.space.s
                    anchors.rightMargin: Theme.space.s
                    text: `${parent.selected ? "●" : "○"}  ${Audio.nodeName(parent.modelData)}`
                    color: parent.selected ? Theme.color.fg : Theme.color.fgMuted
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
