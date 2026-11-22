import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.theme

// A drawer coming out of the bar: square corners on the bar side, rounded
// far corners, and two concave fillets joining the bar (the item is
// 2 × fillet wider, or taller, than the drawer body along the bar).
// `progress` 0 → 1 slides it out from the bar edge; children go inside the
// body.
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    // Edge of the bar it comes out of: "top" | "bottom" | "left" | "right".
    property string edge: "top"
    property real radius: theme.radius.panel
    property real fillet: 12
    property color color: theme.color.surface
    property real progress: 1
    default property alias content: body.data

    readonly property bool sideways: edge === "left" || edge === "right"
    readonly property real f: fillet
    readonly property real w: width
    readonly property real h: height

    clip: true

    Item {
        id: slider

        width: root.width
        height: root.height
        // Slide from the bar edge.
        x: root.edge === "left" ? -(1 - root.progress) * width : root.edge === "right" ? (1 - root.progress) * width : 0
        y: root.edge === "top" ? -(1 - root.progress) * height : root.edge === "bottom" ? (1 - root.progress) * height : 0

        Rectangle {
            id: body

            anchors.fill: parent
            anchors.leftMargin: root.sideways ? 0 : root.f
            anchors.rightMargin: root.sideways ? 0 : root.f
            anchors.topMargin: root.sideways ? root.f : 0
            anchors.bottomMargin: root.sideways ? root.f : 0
            color: root.color
            topLeftRadius: root.edge === "top" || root.edge === "left" ? 0 : root.radius
            topRightRadius: root.edge === "top" || root.edge === "right" ? 0 : root.radius
            bottomLeftRadius: root.edge === "bottom" || root.edge === "left" ? 0 : root.radius
            bottomRightRadius: root.edge === "bottom" || root.edge === "right" ? 0 : root.radius

            Glass {}
        }

        // Concave fillets at the bar-side ends of the body.
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            visible: root.f > 0

            ShapePath {
                fillColor: root.color
                strokeWidth: -1
                PathSvg {
                    path: {
                        const f = root.f, W = root.w, H = root.h;
                        switch (root.edge) {
                        case "bottom":
                            return `M 0 ${H} H ${f} V ${H - f} A ${f} ${f} 0 0 1 0 ${H} Z M ${W} ${H} H ${W - f} V ${H - f} A ${f} ${f} 0 0 0 ${W} ${H} Z`;
                        case "left":
                            return `M 0 0 V ${f} H ${f} A ${f} ${f} 0 0 1 0 0 Z M 0 ${H} V ${H - f} H ${f} A ${f} ${f} 0 0 0 0 ${H} Z`;
                        case "right":
                            return `M ${W} 0 V ${f} H ${W - f} A ${f} ${f} 0 0 0 ${W} 0 Z M ${W} ${H} V ${H - f} H ${W - f} A ${f} ${f} 0 0 1 ${W} ${H} Z`;
                        default:
                            return `M 0 0 H ${f} V ${f} A ${f} ${f} 0 0 0 0 0 Z M ${W} 0 H ${W - f} V ${f} A ${f} ${f} 0 0 1 ${W} 0 Z`;
                        }
                    }
                }
            }
        }
    }
}
