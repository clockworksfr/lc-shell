import QtQuick
import Quickshell
import qs.components
import qs.theme
import qs.i18n

// Window cell: CellTiler floats windows of this workspace into it.
// Drawn as a faint frame, visible when the cell is empty.
Item {
    id: root

    property ShellScreen screen
    property var options: ({})
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    Rectangle {
        anchors.fill: parent
        radius: root.theme.radius.card
        color: "transparent"
        border.width: 1
        border.color: root.theme.color.line
    }

    // Big cells (tiers large / poster): faint hatching, a bigger label.
    readonly property real side: Math.min(width, height)
    readonly property bool large: side >= 760

    Canvas {
        anchors.fill: parent
        anchors.margins: 1
        visible: root.large
        property color ink: Qt.alpha(root.theme.color.line, 0.6)
        onInkChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = ink;
            ctx.lineWidth = 1;
            for (let d = -height; d < width; d += 28) {
                ctx.beginPath();
                ctx.moveTo(d, height);
                ctx.lineTo(d + height, 0);
                ctx.stroke();
            }
        }
    }

    ThemedText {
        anchors.centerIn: parent
        label: true
        text: I18n.tr("tile.window")
        font.pixelSize: root.side >= 1240 ? 20 : root.large ? 17 : root.theme.font.sizeS
        color: root.theme.color.soft
    }
}
