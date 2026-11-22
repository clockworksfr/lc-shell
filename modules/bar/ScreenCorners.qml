import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.theme

// Rounded screen corners, drawn over windows (but never over a fullscreen
// window: ScreenScope unloads this while one is shown). Click-through.
PanelWindow {
    id: win

    property var theme: Themes.fallback
    property int radius: 0
    // Screen bezel color: the corners read as the screen's own edge.
    property color fill: "black"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "lc-corners"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region {}

    Corner {
        radius: win.radius
        fill: win.fill
        anchors.top: parent.top
        anchors.left: parent.left
    }
    Corner {
        radius: win.radius
        fill: win.fill
        anchors.top: parent.top
        anchors.right: parent.right
        rotation: 90
    }
    Corner {
        radius: win.radius
        fill: win.fill
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        rotation: 180
    }
    Corner {
        radius: win.radius
        fill: win.fill
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        rotation: 270
    }

    // Top-left shape; the others are rotations of it.
    component Corner: Shape {
        property int radius: 0
        property color fill: "transparent"

        width: radius
        height: radius
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: fill
            strokeWidth: -1
            PathSvg {
                path: `M 0 0 L ${radius} 0 A ${radius} ${radius} 0 0 0 0 ${radius} Z`
            }
        }
    }
}
