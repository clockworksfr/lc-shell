import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.blocks
import qs.theme

// Bar of "normal" screens. Its look comes from the theme (theme.bar) and can
// be overridden per mode/screen in shell.json, next to the block lists:
//   position          "top" | "bottom"
//   left/center/right block entries
//   style             "full" | "islands"
//   floating, margin, radius, opacity, border, padding, spacing, height
PanelWindow {
    id: bar

    property var config: ({})
    property var theme: Themes.fallback

    readonly property var look: Object.assign({}, theme.bar, config)
    readonly property bool atBottom: look.position === "bottom"
    readonly property bool islands: look.style === "islands"
    readonly property int edge: look.floating ? look.margin : 0

    anchors {
        top: !atBottom
        bottom: atBottom
        left: true
        right: true
    }
    margins {
        top: atBottom ? 0 : edge
        bottom: atBottom ? edge : 0
        left: edge
        right: edge
    }
    implicitHeight: look.height
    color: "transparent"
    WlrLayershell.namespace: "lc-bar"

    // "full": one band. Docked, the border is a single line on the inner edge.
    Rectangle {
        anchors.fill: parent
        visible: !bar.islands
        radius: bar.look.floating ? bar.look.radius : 0
        color: Qt.alpha(bar.theme.color.bg, bar.look.opacity)
        border.width: bar.look.floating ? bar.look.border : 0
        border.color: bar.theme.color.line

        Rectangle {
            visible: !bar.look.floating && bar.look.border > 0
            anchors.left: parent.left
            anchors.right: parent.right
            y: bar.atBottom ? 0 : parent.height - height
            height: bar.look.border
            color: bar.theme.color.line
        }
    }

    BarZone {
        anchors.left: parent.left
        anchors.leftMargin: bar.islands ? 0 : bar.look.padding
        host: bar
        entries: bar.look.left ?? []
    }

    BarZone {
        anchors.horizontalCenter: parent.horizontalCenter
        host: bar
        entries: bar.look.center ?? []
    }

    BarZone {
        anchors.right: parent.right
        anchors.rightMargin: bar.islands ? 0 : bar.look.padding
        host: bar
        entries: bar.look.right ?? []
    }
}
