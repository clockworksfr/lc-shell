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
// bar. `progress` 0 → 1 grows it out of the bar: the zone deepens (rounded
// far edge and fillets following) while the content stays in place,
// uncovered as it goes. Children go in the body.
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    // Edge of the bar it grows from: "top" | "bottom" | "left" | "right".
    property string edge: "top"
    property real radius: theme.radius.panel
    property real fillet: 12
    // Fillet at each end along the bar (low = left / top); 0 = the body
    // continues the island's end in a straight line.
    property real filletLow: fillet
    property real filletHigh: fillet
    // How far it reaches into the bar (the bar's inner border width).
    property real overlap: 1
    property color color: theme.color.surface
    property color lineColor: theme.color.line
    property real lineWidth: theme.border.width
    property real progress: 1
    default property alias content: body.data

    readonly property bool sideways: edge === "left" || edge === "right"
    // How much of the depth shows (reduced motion: all, the drawer fades).
    readonly property real reveal: Motion.reduced ? 1 : Math.max(0, Math.min(1, progress))
    // Content shows from 40 % of the opening (and fades first on closing).
    readonly property real contentOpacity: Motion.reduced ? progress : Math.max(0, Math.min(1, (progress - 0.4) / 0.6))
    // Canonical (bar on top) size: along the bar × away from it.
    readonly property real along: sideways ? height : width
    readonly property real depth: sideways ? width : height
    // Depth shown, from the bar's side.
    readonly property real shownDepth: depth * reveal

    clip: true

    Item {
        id: slider

        width: root.width
        height: root.height
        opacity: Motion.reduced ? root.progress : 1

        // Background and border, drawn for a top bar then rotated.
        Shape {
            id: shape

            // Canonical (top bar) left / right fillets: the rotation turns
            // the canonical left end into the screen's right (bottom bar)
            // or bottom (left bar) end.
            readonly property real fl: root.edge === "bottom" || root.edge === "left" ? root.filletHigh : root.filletLow
            readonly property real fr: root.edge === "bottom" || root.edge === "left" ? root.filletLow : root.filletHigh
            readonly property real o: root.overlap
            readonly property real cw: root.along
            readonly property real ch: root.depth
            // The path, as deep as shown: fillets and corners shrink to fit
            // while it's shallow.
            readonly property real rh: Math.max(o, root.shownDepth)
            readonly property real room: Math.max(0, rh - o)
            readonly property real a: Math.min(fl, room)
            readonly property real b: Math.min(fr, room)
            readonly property real r: Math.max(0, Math.min(root.radius, (cw - a - b) / 2, room - Math.max(a, b), rh / 2))

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
                        const a = shape.a, b = shape.b, o = shape.o, r = shape.r, cw = shape.cw, ch = shape.rh;
                        return `M 0 0 H ${cw} V ${o} A ${b} ${b} 0 0 0 ${cw - b} ${o + b} V ${ch - r} A ${r} ${r} 0 0 1 ${cw - b - r} ${ch} H ${a + r} A ${r} ${r} 0 0 1 ${a} ${ch - r} V ${o + a} A ${a} ${a} 0 0 0 0 ${o} Z`;
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
                        const a = shape.a, b = shape.b, o = shape.o, r = shape.r, cw = shape.cw, ch = shape.rh;
                        // No fillet on a side: the line starts at the island's
                        // own border (no stroke inside the bar).
                        return `M 0 ${a > 0 ? o : 0} A ${a} ${a} 0 0 1 ${a} ${o + a} V ${ch - r} A ${r} ${r} 0 0 0 ${a + r} ${ch} H ${cw - b - r} A ${r} ${r} 0 0 0 ${cw - b} ${ch - r} V ${o + b} A ${b} ${b} 0 0 1 ${cw} ${b > 0 ? o : 0}`;
                    }
                }
            }
        }

        // The shown part, from the bar's side: the content is clipped to it
        // and doesn't move.
        Item {
            id: window_

            readonly property real d: Math.ceil(root.shownDepth)

            clip: root.reveal < 1
            x: root.edge === "right" ? root.width - d : 0
            y: root.edge === "bottom" ? root.height - d : 0
            width: root.sideways ? d : root.width
            height: root.sideways ? root.height : d

            // Content area: the body, in window coordinates (not rotated).
            Item {
                id: body

                opacity: root.contentOpacity
                x: (root.edge === "left" ? root.overlap : root.sideways ? 0 : root.filletLow) - window_.x
                y: (root.edge === "top" ? root.overlap : !root.sideways ? 0 : root.filletLow) - window_.y
                width: root.sideways ? root.width - root.overlap : root.width - root.filletLow - root.filletHigh
                height: root.sideways ? root.height - root.filletLow - root.filletHigh : root.height - root.overlap
            }
        }
    }
}
