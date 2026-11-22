import QtQuick
import QtQuick.Shapes

// One annotation of the screenshot editor, in the screen's coordinates.
//   { type, color, size, points: [{x, y}], x1, y1, x2, y2, text, n, fill }
// type: pen | highlighter | line | arrow | rect | ellipse | text |
//       counter | pixelate
Item {
    id: root

    required property var data_
    // The image under the annotations: { source, x, y, w, h } (pixelate).
    property var view: ({})

    readonly property string type: data_.type ?? ""
    readonly property color ink: data_.color ?? "red"
    readonly property real size: data_.size ?? 4
    readonly property real boxX: Math.min(data_.x1 ?? 0, data_.x2 ?? 0)
    readonly property real boxY: Math.min(data_.y1 ?? 0, data_.y2 ?? 0)
    readonly property real boxW: Math.abs((data_.x2 ?? 0) - (data_.x1 ?? 0))
    readonly property real boxH: Math.abs((data_.y2 ?? 0) - (data_.y1 ?? 0))
    // Readable over the ink color (text outline, counter digits).
    readonly property color contrast: ink.hslLightness > 0.6 ? "#111111" : "#FFFFFF"

    // --- Strokes: pen, highlighter, line, arrow, ellipse ---
    Shape {
        visible: ["pen", "highlighter", "line", "arrow", "ellipse"].includes(root.type)
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.type === "highlighter" ? Qt.alpha(root.ink, 0.4) : root.ink
            strokeWidth: root.type === "highlighter" ? root.size * 4 : root.size
            fillColor: "transparent"
            capStyle: root.type === "highlighter" ? ShapePath.FlatCap : ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathPolyline {
                path: {
                    switch (root.type) {
                    case "pen":
                    case "highlighter":
                        return (root.data_.points ?? []).map(p => Qt.point(p.x, p.y));
                    case "line":
                        return [Qt.point(root.data_.x1, root.data_.y1), Qt.point(root.data_.x2, root.data_.y2)];
                    case "arrow":
                        return [Qt.point(root.data_.x1, root.data_.y1), arrow.base];
                    default:
                        return [];
                    }
                }
            }
        }

        ShapePath {
            strokeColor: root.type === "ellipse" ? root.ink : "transparent"
            strokeWidth: root.type === "ellipse" ? root.size : 0
            fillColor: root.type === "ellipse" && root.data_.fill ? root.ink : "transparent"

            PathAngleArc {
                moveToStart: true
                centerX: root.boxX + root.boxW / 2
                centerY: root.boxY + root.boxH / 2
                radiusX: root.type === "ellipse" ? root.boxW / 2 : 0
                radiusY: root.type === "ellipse" ? root.boxH / 2 : 0
                startAngle: 0
                sweepAngle: 360
            }
        }

        // Arrow head.
        ShapePath {
            strokeColor: "transparent"
            fillColor: root.type === "arrow" ? root.ink : "transparent"

            PathPolyline {
                path: root.type === "arrow" ? arrow.head : []
            }
        }
    }

    QtObject {
        id: arrow

        readonly property real dx: (root.data_.x2 ?? 0) - (root.data_.x1 ?? 0)
        readonly property real dy: (root.data_.y2 ?? 0) - (root.data_.y1 ?? 0)
        readonly property real length: Math.max(1, Math.hypot(dx, dy))
        readonly property real headLength: Math.min(length, Math.max(12, root.size * 4))
        readonly property real ux: dx / length
        readonly property real uy: dy / length
        // Where the shaft stops (under the head, not through its tip).
        readonly property point base: Qt.point((root.data_.x2 ?? 0) - ux * headLength * 0.7, (root.data_.y2 ?? 0) - uy * headLength * 0.7)
        readonly property var head: {
            const tipX = root.data_.x2 ?? 0, tipY = root.data_.y2 ?? 0;
            const bx = tipX - ux * headLength, by = tipY - uy * headLength;
            const half = headLength * 0.55;
            return [Qt.point(tipX, tipY), Qt.point(bx - uy * half, by + ux * half), Qt.point(bx + uy * half, by - ux * half), Qt.point(tipX, tipY)];
        }
    }

    // --- Rectangle ---
    Rectangle {
        visible: root.type === "rect"
        x: root.boxX
        y: root.boxY
        width: root.boxW
        height: root.boxH
        radius: 3
        color: root.data_.fill ? root.ink : "transparent"
        border.width: root.size
        border.color: root.ink
        antialiasing: true
    }

    // --- Pixelate: the image under it, enlarged from a tiny copy ---
    Item {
        visible: root.type === "pixelate"
        x: root.boxX
        y: root.boxY
        width: root.boxW
        height: root.boxH
        clip: true

        Image {
            readonly property real block: 12

            x: (root.view.x ?? 0) - root.boxX
            y: (root.view.y ?? 0) - root.boxY
            width: root.view.w ?? 0
            height: root.view.h ?? 0
            source: root.type === "pixelate" ? (root.view.source ?? "") : ""
            sourceSize: Qt.size(Math.max(1, Math.round(width / block)), Math.max(1, Math.round(height / block)))
            smooth: false
            mipmap: false
        }
    }

    // --- Text ---
    Text {
        visible: root.type === "text"
        x: root.data_.x1 ?? 0
        y: root.data_.y1 ?? 0
        text: root.data_.text ?? ""
        color: root.ink
        font.pixelSize: root.data_.fontSize ?? 24
        font.weight: Font.DemiBold
        style: Text.Outline
        styleColor: Qt.alpha(root.contrast, 0.6)
        textFormat: Text.PlainText
    }

    // --- Numbered marker ---
    Rectangle {
        readonly property real d: Math.max(22, root.size * 5 + 8)

        visible: root.type === "counter"
        x: (root.data_.x1 ?? 0) - d / 2
        y: (root.data_.y1 ?? 0) - d / 2
        width: d
        height: d
        radius: d / 2
        color: root.ink
        border.width: 2
        border.color: Qt.alpha(root.contrast, 0.8)
        antialiasing: true

        Text {
            anchors.centerIn: parent
            text: root.data_.n ?? 1
            color: root.contrast
            font.pixelSize: parent.d * 0.55
            font.weight: Font.Bold
        }
    }
}
