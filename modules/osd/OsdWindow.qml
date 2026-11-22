import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services
import qs.theme

// Volume / mic / brightness popup. Config (layout.json, module "osd"):
//   position: "bottom" | "top", margin: distance from the edge in px
PanelWindow {
    id: win

    property var config: ({})

    readonly property bool atTop: config.position === "top"
    readonly property string title: ({
            volume: "Volume",
            mic: "Micro",
            brightness: "Luminosité"
        })[Osd.kind] ?? ""

    // Only one edge anchored: layer shell centers the window horizontally.
    anchors.top: atTop
    anchors.bottom: !atTop
    margins.top: atTop ? (config.margin ?? 80) : 0
    margins.bottom: atTop ? 0 : (config.margin ?? 80)

    implicitWidth: 360
    implicitHeight: content.implicitHeight + Theme.space.m * 2
    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lc-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    // Click-through: an empty input region.
    mask: Region {}

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius.m
        color: Theme.color.surface

        Column {
            id: content

            anchors.fill: parent
            anchors.margins: Theme.space.m
            spacing: Theme.space.s

            Item {
                width: parent.width
                implicitHeight: titleText.implicitHeight

                ThemedText {
                    id: titleText
                    anchors.left: parent.left
                    text: win.title
                }

                ThemedText {
                    anchors.right: parent.right
                    text: Osd.muted ? "muet" : `${Math.round(Osd.value * 100)} %`
                    color: Osd.muted ? Theme.color.fgMuted : Theme.color.fg
                }
            }

            // Track; values above 100 % (volume boost) fill in the urgent color.
            Rectangle {
                width: parent.width
                height: 6
                radius: Theme.radius.s
                color: Theme.color.bg

                Rectangle {
                    width: parent.width * Math.min(Osd.value, 1)
                    height: parent.height
                    radius: parent.radius
                    color: Osd.muted ? Theme.color.fgMuted : Osd.value > 1 ? Theme.color.urgent : Theme.color.accent

                    Behavior on width {
                        NumberAnimation {
                            duration: 80
                        }
                    }
                }
            }

            ThemedText {
                width: parent.width
                text: Osd.label
                color: Theme.color.fgMuted
                font.pixelSize: Theme.font.sizeS
                elide: Text.ElideRight
            }
        }
    }
}
