import QtQuick
import Quickshell
import qs.components
import qs.theme

// A dashboard module's frame, in its theme's language (style.module):
// classic card; constellation glass (gradient, accent-tinted edge); facade
// front panel (2 px bezel, top bevel, screws, silk-screened title);
// modulaire brushed aluminium with screws and a centered silk title;
// matrix rounded card on a dot grid. Title shown when tall enough.
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property string look: theme.style.module ?? "classic"

    property string title
    readonly property bool titled: !!title && height > 200
    readonly property real titleHeight: titled ? titleText.implicitHeight + 6 : 0

    Rectangle {
        id: face

        anchors.fill: parent
        radius: root.look === "matrix" ? 28 : root.look === "facade" || root.look === "modulaire" ? root.theme.radius.card : root.theme.radius.card
        color: root.theme.color.surface
        border.width: root.look === "facade" ? 2 : root.theme.border.width
        border.color: root.look === "constellation" ? Qt.alpha(root.theme.color.accent, 0.35) : root.theme.color.line
        gradient: root.look === "constellation" ? glass : root.look === "modulaire" ? alu : null

        Gradient {
            id: glass
            GradientStop {
                position: 0
                color: root.theme.color.surface2
            }
            GradientStop {
                position: 1
                color: root.theme.color.surface
            }
        }

        Gradient {
            id: alu
            GradientStop {
                position: 0
                color: Qt.lighter(root.theme.color.surface, 1.12)
            }
            GradientStop {
                position: 0.5
                color: root.theme.color.surface
            }
            GradientStop {
                position: 1
                color: Qt.darker(root.theme.color.surface, 1.1)
            }
        }
    }

    // Brushed metal: fine horizontal strokes.
    Canvas {
        anchors.fill: parent
        anchors.margins: 2
        visible: root.look === "modulaire"
        opacity: 0.5
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            for (let y = 0; y < height; y += 2) {
                ctx.fillStyle = (y / 2) % 3 === 0 ? "rgba(255,255,255,0.035)" : "rgba(0,0,0,0.03)";
                ctx.fillRect(0, y, width, 1);
            }
        }
    }

    // Dot grid (16 px).
    Canvas {
        anchors.fill: parent
        anchors.margins: 14
        visible: root.look === "matrix"
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.fillStyle = Qt.alpha(root.theme.color.ink, 0.07);
            for (let y = 0; y <= height; y += 16)
                for (let x = 0; x <= width; x += 16) {
                    ctx.beginPath();
                    ctx.arc(x, y, 1.2, 0, Math.PI * 2);
                    ctx.fill();
                }
        }
    }

    // Top bevel (facade).
    Rectangle {
        visible: root.look === "facade"
        x: 2
        y: 2
        width: parent.width - 4
        height: 1
        color: Qt.alpha("white", 0.12)
    }

    // Screws in the corners.
    Repeater {
        model: root.theme.style.screws ? 4 : 0

        Rectangle {
            required property int index
            readonly property real inset: 9
            width: 9
            height: 9
            radius: 4.5
            x: index % 2 === 0 ? inset - width / 2 : root.width - inset - width / 2
            y: index < 2 ? inset - height / 2 : root.height - inset - height / 2
            color: Qt.darker(root.theme.color.surface, 1.35)
            border.width: 1
            border.color: Qt.alpha("black", 0.4)

            Rectangle {
                anchors.centerIn: parent
                width: 6
                height: 1.5
                rotation: 35 + parent.index * 20
                color: Qt.alpha("black", 0.5)
            }
        }
    }

    // Title: silk-screened (facade, modulaire) or a small label.
    ThemedText {
        id: titleText

        visible: root.titled
        x: root.look === "modulaire" ? (parent.width - width) / 2 : 18
        y: 10
        label: true
        text: root.title
        font.family: root.look === "modulaire" ? root.theme.font.mono : root.theme.font.family
        font.pixelSize: root.look === "modulaire" ? Math.max(11, root.height * 0.04) : Math.max(13, root.height * 0.045)
        font.letterSpacing: 1.5
        color: root.look === "facade" ? (root.theme.color.silk ?? root.theme.color.soft) : root.theme.color.soft
    }
}
