import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.theme

// A drawer that grows out of the bar, as if the widget's own zone (its
// island, or the bar band) extended: same fill as the bar, no line at the
// junction (it overlaps the bar's inner border by `overlap`), and one
// continuous border that leaves the bar's border, follows two concave
// fillets, then runs around the drawer.
//
// Drawn once for a bar on top (the drawer hanging below), rotated for the
// other edges. The item is 2 × fillet longer than the drawer body along the
// bar. `progress` 0 → 1 slides it out of the bar. Children go in the body.
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    // Edge of the bar it grows from: "top" | "bottom" | "left" | "right".
    property string edge: "top"
    property real radius: theme.radius.panel
    property real fillet: 12
    // How far it reaches into the bar (the bar's inner border width).
    property real overlap: 1
    property color color: theme.color.surface
    property color lineColor: theme.color.line
    property real lineWidth: theme.border.width
    property real progress: 1
    default property alias content: body.data

    readonly property bool sideways: edge === "left" || edge === "right"
    // Canonical (bar on top) size: along the bar × away from it.
    readonly property real along: sideways ? height : width
    readonly property real depth: sideways ? width : height

    clip: true

    Item {
        id: slider

        width: root.width
        height: root.height
        // Slide out of the bar.
        x: root.edge === "left" ? -(1 - root.progress) * width : root.edge === "right" ? (1 - root.progress) * width : 0
        y: root.edge === "top" ? -(1 - root.progress) * height : root.edge === "bottom" ? (1 - root.progress) * height : 0

        // Background and border, drawn for a top bar then rotated.
        Shape {
            id: shape

            readonly property real f: root.fillet
            readonly property real o: root.overlap
            readonly property real r: Math.max(0, Math.min(root.radius, (root.along - 2 * f) / 2, root.depth / 2))
            readonly property real cw: root.along
            readonly property real ch: root.depth

            width: cw
            height: ch
            x: (root.width - width) / 2
            y: (root.height - height) / 2
            rotation: root.edge === "bottom" ? 180 : root.edge === "left" ? -90 : root.edge === "right" ? 90 : 0
            preferredRendererType: Shape.CurveRenderer

            // Fill: a strip inside the bar (hides its border at the
            // junction), the fillets, the body with rounded far corners.
            ShapePath {
                fillColor: root.color
                strokeWidth: -1
                PathSvg {
                    path: {
                        const f = shape.f, o = shape.o, r = shape.r, cw = shape.cw, ch = shape.ch;
                        return `M 0 0 H ${cw} V ${o} A ${f} ${f} 0 0 0 ${cw - f} ${o + f} V ${ch - r} A ${r} ${r} 0 0 1 ${cw - f - r} ${ch} H ${f + r} A ${r} ${r} 0 0 1 ${f} ${ch - r} V ${o + f} A ${f} ${f} 0 0 0 0 ${o} Z`;
                    }
                }
            }

            // Border: continues the bar's border into the fillets and around
            // the drawer (nothing along the junction).
            ShapePath {
                fillColor: "transparent"
                strokeColor: root.lineWidth > 0 ? root.lineColor : "transparent"
                strokeWidth: Math.max(root.lineWidth, 0.01)
                capStyle: ShapePath.FlatCap
                PathSvg {
                    path: {
                        const f = shape.f, o = shape.o, r = shape.r, cw = shape.cw, ch = shape.ch;
                        return `M 0 ${o} A ${f} ${f} 0 0 1 ${f} ${o + f} V ${ch - r} A ${r} ${r} 0 0 0 ${f + r} ${ch} H ${cw - f - r} A ${r} ${r} 0 0 0 ${cw - f} ${ch - r} V ${o + f} A ${f} ${f} 0 0 1 ${cw} ${o}`;
                    }
                }
            }
        }

        // Content area: the body, in window coordinates (not rotated).
        Item {
            id: body

            x: root.edge === "left" ? root.overlap : root.sideways ? 0 : root.fillet
            y: root.edge === "top" ? root.overlap : !root.sideways ? 0 : root.fillet
            width: root.sideways ? root.width - root.overlap : root.width - root.fillet * 2
            height: root.sideways ? root.height - root.fillet * 2 : root.height - root.overlap
        }
    }
}
