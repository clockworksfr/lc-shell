import QtQuick
import Quickshell
import qs.theme

// A display window inside a module (style.display): "vfd" (black glass,
// static scanlines, phosphor ink), "lcd" (green or amber LCD, dark ink),
// "none" (no window: children sit on the panel). Children read `ink`.
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property string kind: theme.style.display ?? "none"
    // LCD tint: "green" (system, weather) or "amber" (player, lyrics).
    property string tint: "green"
    readonly property color ink: kind === "lcd" ? (tint === "amber" ? (theme.color.lcdAmberInk ?? "#2A1A05") : (theme.color.lcdInk ?? "#1A2410")) : theme.color.ink
    readonly property color soft: kind === "lcd" ? Qt.alpha(ink, 0.65) : theme.color.soft
    readonly property real inset: kind === "none" ? 0 : 10
    default property alias content: inner.data

    Rectangle {
        anchors.fill: parent
        visible: root.kind !== "none"
        radius: 4
        color: root.kind === "lcd" ? (root.tint === "amber" ? (root.theme.color.lcdAmber ?? "#FFB547") : (root.theme.color.lcd ?? "#C6F37A")) : "#030505"
        border.width: 2
        border.color: Qt.alpha("black", 0.6)

        // Static scanlines (VFD).
        Canvas {
            anchors.fill: parent
            anchors.margins: 2
            visible: root.kind === "vfd" && !!root.theme.style.scanlines
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.fillStyle = "rgba(255,255,255,0.035)";
                for (let y = 0; y < height; y += 3)
                    ctx.fillRect(0, y, width, 1);
            }
        }
    }

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: root.inset
    }
}
