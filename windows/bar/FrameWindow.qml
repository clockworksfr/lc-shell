import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.theme

// Frame drawing: the screen minus a rounded inner rectangle (even-odd
// fill), plus an optional line along the inner edge. On the bottom layer:
// under windows, above the wallpaper, so the bar's content (top layer)
// stays on top of it. Click-through. Space is reserved by the bar and by
// FrameEdge surfaces, not here.
PanelWindow {
    id: win

    property var theme: Themes.fallback
    // { top, bottom, left, right } in px.
    property var sides: ({ top: 0, bottom: 0, left: 0, right: 0 })
    property int innerRadius: 18
    property int outline: 0
    property real fillOpacity: 1

    readonly property real x0: sides.left
    readonly property real y0: sides.top
    readonly property real x1: width - sides.right
    readonly property real y1: height - sides.bottom
    readonly property real r: Math.max(0, Math.min(innerRadius, (x1 - x0) / 2, (y1 - y0) / 2))

    readonly property string innerPath: `M ${x0 + r} ${y0} H ${x1 - r} A ${r} ${r} 0 0 1 ${x1} ${y0 + r} V ${y1 - r} A ${r} ${r} 0 0 1 ${x1 - r} ${y1} H ${x0 + r} A ${r} ${r} 0 0 1 ${x0} ${y1 - r} V ${y0 + r} A ${r} ${r} 0 0 1 ${x0 + r} ${y0} Z`

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "lc-frame"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region {}

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillRule: ShapePath.OddEvenFill
            // The bar's case color where the theme has one (Modulaire).
            fillColor: Qt.alpha(win.theme.bar?.caseColor || win.theme.color.surface, win.fillOpacity)
            strokeWidth: -1
            PathSvg {
                path: `M 0 0 H ${win.width} V ${win.height} H 0 Z ${win.innerPath}`
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: win.outline > 0 ? win.theme.color.line : "transparent"
            strokeWidth: win.outline
            PathSvg {
                path: win.innerPath
            }
        }
    }
}
