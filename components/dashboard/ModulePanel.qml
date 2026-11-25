import QtQuick
import Quickshell
import qs.components
import qs.theme

// A dashboard module's frame, in its theme's language (style.module):
// classic card; constellation glass (gradient, accent-tinted edge); facade
// front panel (metal gradient, bevels, 4 flat screws, silk title at
// x 40); modulaire aluminium plate (four flat screws, a sheen, a centered
// silk title; screen modules in the black finish); matrix rounded card on a
// dot grid. Title shown when tall enough.
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property string look: theme.style.module ?? "classic"

    property string title
    // Room kept on the right of the title row (a chip there).
    property real titleReserve: 0
    // Size tier (ModuleBase): bigger title, row and corners on big cells.
    property string tier: "normal"
    // Modulaire: "normal" (aluminium) or "black" (screen modules). Dark
    // only: in light the modules' text is dark (the theme's ink), it
    // would vanish on a black plate.
    property string finish: "normal"
    readonly property bool dark: theme.variant !== "light"
    readonly property bool black: look === "modulaire" && finish === "black" && dark
    readonly property real tierScale: tier === "poster" ? 1.6 : tier === "large" ? 1.3 : 1
    readonly property bool titled: !!title && height > 200
    readonly property real titleHeight: !titled ? 0 : tier === "poster" ? 48 : tier === "large" ? 38 : titleText.implicitHeight + 6

    // Façade dark: the mockup's metal front (light keeps its plain panel).
    readonly property bool facadeMetal: look === "facade" && dark

    Rectangle {
        id: face

        anchors.fill: parent
        radius: (root.look === "matrix" ? 28 : root.look === "facade" ? 6 : root.look === "modulaire" ? 3 : root.theme.radius.card) * root.tierScale
        color: root.theme.color.surface
        border.width: root.look === "modulaire" || root.facadeMetal ? 0 : root.look === "facade" ? 2 : root.theme.border.width
        border.color: root.look === "constellation" ? Qt.alpha(root.theme.color.accent, 0.35) : root.theme.color.line
        gradient: root.look === "constellation" ? glass : root.black ? blackPlate : root.look === "modulaire" ? alu : root.facadeMetal ? metal : null

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

        // Modulaire aluminium: surface to surface2, top to bottom.
        Gradient {
            id: alu
            GradientStop {
                position: 0
                color: root.theme.color.surface
            }
            GradientStop {
                position: 1
                color: root.theme.color.surface2
            }
        }

        // Modulaire black finish (screen modules), both variants.
        Gradient {
            id: blackPlate
            GradientStop {
                position: 0
                color: "#2A2B2D"
            }
            GradientStop {
                position: 1
                color: "#1F2022"
            }
        }

        // Façade metal front.
        Gradient {
            id: metal
            GradientStop {
                position: 0
                color: "#2B2F31"
            }
            GradientStop {
                position: 0.4
                color: "#1B1E20"
            }
            GradientStop {
                position: 1
                color: "#15181A"
            }
        }
    }

    // Modulaire: a horizontal sheen across the plate and a 1 px inner line.
    Rectangle {
        anchors.fill: parent
        visible: root.look === "modulaire"
        radius: face.radius
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0
                color: "transparent"
            }
            GradientStop {
                position: 0.5
                color: "#18FFFFFF"
            }
            GradientStop {
                position: 1
                color: "transparent"
            }
        }
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        visible: root.look === "modulaire"
        radius: Math.max(0, face.radius - 1)
        color: "transparent"
        border.width: 1
        border.color: root.dark || root.black ? "#14FFFFFF" : "#40000000"
    }

    // Dot grid (16 px).
    Canvas {
        anchors.fill: parent
        anchors.margins: 14
        // Visible without competing with the content.
        readonly property color dot: Qt.alpha(root.theme.color.ink, root.theme.variant === "light" ? 0.14 : 0.12)

        visible: root.look === "matrix"
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onDotChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.fillStyle = dot;
            for (let y = 0; y <= height; y += 16)
                for (let x = 0; x <= width; x += 16) {
                    ctx.beginPath();
                    ctx.arc(x, y, 1.2, 0, Math.PI * 2);
                    ctx.fill();
                }
        }
    }

    // Façade dark: bevels (light top, black bottom).
    Rectangle {
        visible: root.facadeMetal
        x: 3
        y: 0
        width: parent.width - 6
        height: 2
        color: "#1AFFFFFF"
    }
    Rectangle {
        visible: root.facadeMetal
        x: 3
        y: parent.height - 2
        width: parent.width - 6
        height: 2
        color: "black"
    }
    // Façade light: the old top bevel.
    Rectangle {
        visible: root.look === "facade" && !root.dark
        x: 2
        y: 2
        width: parent.width - 4
        height: 1
        color: Qt.alpha("white", 0.12)
    }

    // Flat screws in the corners: Façade 10 px, 18 px in; Modulaire 8 px,
    // 10 px in (as its hover cards).
    Repeater {
        model: root.look === "facade" || root.look === "modulaire" ? 4 : 0

        Rectangle {
            required property int index
            readonly property bool mod: root.look === "modulaire"
            readonly property real inset: mod ? 10 : 18
            width: mod ? 8 : 10
            height: width
            radius: width / 2
            x: index % 2 === 0 ? inset - width / 2 : root.width - inset - width / 2
            y: index < 2 ? inset - height / 2 : root.height - inset - height / 2
            color: mod ? "#8A8F92" : "#9AA0A3"
            border.width: mod ? 1 : 1.5
            border.color: Qt.alpha(color, mod ? 0.5 : 0.45)
        }
    }

    // Title: silk-screened (facade, modulaire) or a small label.
    ThemedText {
        id: titleText

        visible: root.titled
        // Never wider than the panel (long titles end with "…").
        width: Math.min(implicitWidth, parent.width - 36 - root.titleReserve)
        elide: Text.ElideRight
        // Modulaire: centered, but never under a chip on the right;
        // Façade: at 40 (clear of the screw).
        x: root.look === "modulaire" ? Math.max(18, Math.min((parent.width - width) / 2, parent.width - root.titleReserve - 10 - width)) : root.look === "facade" ? 40 * root.tierScale : 18 * root.tierScale
        y: (root.look === "modulaire" ? 12 : root.look === "facade" ? 11 : 10) * root.tierScale
        label: true
        text: root.look === "modulaire" || root.look === "facade" ? root.title.toUpperCase() : root.title
        font.family: root.look === "modulaire" ? root.theme.font.mono : root.theme.font.family
        font.weight: root.look === "facade" ? Font.Bold : Font.Normal
        // The same size on every module (Michroma is wide: a bit smaller).
        font.pixelSize: (root.look === "modulaire" ? 12 : 14) + (root.tier === "poster" ? (root.look === "modulaire" ? 4 : 5) : root.tier === "large" ? 2 : 0)
        font.letterSpacing: root.look === "facade" ? 2.8 : root.look === "modulaire" ? 1.7 : 1.5
        // Silk: Modulaire's ink (light on the black finish), Façade #C9CCC4.
        color: root.look === "modulaire" ? (root.black ? "#E9E7E1" : root.theme.color.ink) : root.facadeMetal ? Qt.alpha("#C9CCC4", 0.85) : root.look === "facade" ? (root.theme.color.silk ?? root.theme.color.soft) : root.theme.color.soft
    }
}
