import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.blocks
import qs.theme

// Horizontal bar. Config (from layout.json, module "bar"):
//   position: "top" | "bottom"
//   left / center / right: lists of block entries
PanelWindow {
    id: bar

    property var config: ({})

    readonly property bool atBottom: config.position === "bottom"

    anchors {
        top: !atBottom
        bottom: atBottom
        left: true
        right: true
    }
    implicitHeight: Theme.bar.height
    color: Theme.color.bg
    WlrLayershell.namespace: "lc-bar"

    BarZone {
        anchors.left: parent.left
        anchors.leftMargin: Theme.space.s
        entries: bar.config.left ?? []
        screen: bar.screen
    }

    BarZone {
        anchors.horizontalCenter: parent.horizontalCenter
        entries: bar.config.center ?? []
        screen: bar.screen
    }

    BarZone {
        anchors.right: parent.right
        anchors.rightMargin: Theme.space.s
        entries: bar.config.right ?? []
        screen: bar.screen
    }

    // Inline components can't see ids of the enclosing file,
    // so the screen is passed explicitly.
    component BarZone: Row {
        id: zone

        property var entries: []
        property ShellScreen screen

        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.space.m

        Repeater {
            model: zone.entries

            BlockSlot {
                required property var modelData
                entry: modelData
                screen: zone.screen
                anchors.verticalCenter: parent?.verticalCenter
            }
        }
    }
}
