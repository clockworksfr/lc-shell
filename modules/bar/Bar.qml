import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.theme

// Bar of "normal" screens, on any edge. Its look comes from the theme
// (theme.bar) and can be overridden per mode/screen in settings, next to
// the block lists:
//   position          "top" | "bottom" | "left" | "right"
//   left/center/right block entries; on a vertical bar: top/middle/bottom
//                     (also accepted as start/center/end)
//   style             "full" | "islands"
//   floating, margin, radius, opacity, border, padding, spacing,
//   height (horizontal thickness), verticalWidth (vertical thickness)
PanelWindow {
    id: bar

    property var config: ({})
    property var theme: Themes.fallback
    // Part of a frame (FrameWindow draws the background): docked, no
    // islands, no own background.
    property bool framed: false

    readonly property var look: Object.assign({}, theme.bar, config)
    // "top" | "bottom" | "left" | "right"; read by popups to open inward.
    readonly property string edge: ["top", "bottom", "left", "right"].includes(look.position) ? look.position : "top"
    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property bool islands: look.style === "islands" && !framed
    readonly property int thickness: vertical ? look.verticalWidth : look.height
    readonly property int gap: look.floating && !framed ? look.margin : 0
    // Space taken from the screen edge (what popups must clear).
    readonly property int extent: thickness + gap

    anchors {
        top: edge !== "bottom"
        bottom: edge !== "top"
        left: edge !== "right"
        right: edge !== "left"
    }
    margins {
        top: edge === "bottom" ? 0 : gap
        bottom: edge === "top" ? 0 : gap
        left: edge === "right" ? 0 : gap
        right: edge === "left" ? 0 : gap
    }
    implicitHeight: vertical ? 0 : thickness
    implicitWidth: vertical ? thickness : 0
    color: "transparent"
    WlrLayershell.namespace: "lc-bar"

    // "full": one band. Docked, the border is a single line on the inner edge.
    Rectangle {
        anchors.fill: parent
        visible: !bar.islands && !bar.framed
        radius: bar.look.floating ? bar.look.radius : 0
        color: Qt.alpha(bar.theme.color.bg, bar.look.opacity)
        border.width: bar.look.floating ? bar.look.border : 0
        border.color: bar.theme.color.line

        Rectangle {
            visible: !bar.look.floating && bar.look.border > 0
            color: bar.theme.color.line
            x: bar.edge === "left" ? parent.width - width : 0
            y: bar.edge === "top" ? parent.height - height : 0
            width: bar.vertical ? bar.look.border : parent.width
            height: bar.vertical ? parent.height : bar.look.border
        }
    }

    // Start / center / end zones, along the bar.
    BarZone {
        host: bar
        entries: bar.look.start ?? bar.look.top ?? bar.look.left ?? []
        x: bar.vertical ? 0 : (bar.islands ? 0 : bar.look.padding)
        y: bar.vertical ? (bar.islands ? 0 : bar.look.padding) : 0
    }

    BarZone {
        host: bar
        entries: bar.look.center ?? bar.look.middle ?? []
        x: bar.vertical ? 0 : (bar.width - width) / 2
        y: bar.vertical ? (bar.height - height) / 2 : 0
    }

    BarZone {
        host: bar
        entries: bar.look.end ?? (bar.vertical ? bar.look.bottom : undefined) ?? bar.look.right ?? []
        x: bar.vertical ? 0 : bar.width - width - (bar.islands ? 0 : bar.look.padding)
        y: bar.vertical ? bar.height - height - (bar.islands ? 0 : bar.look.padding) : 0
    }
}
