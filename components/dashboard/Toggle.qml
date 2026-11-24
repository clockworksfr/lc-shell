import QtQuick
import Quickshell
import qs.components
import qs.theme

// A quick-settings tile in the theme's language (design study 9):
//   classic        tile: icon on top, label and sub-label at the bottom;
//                  accent fill when on
//   constellation  centered; accent → accent2 gradient when on
//   facade         hardware key (metal gradient, black edge) with a LED
//                  on top (amber when on)
//   modulaire      no plate: a vertical lever (up = on) under a green LED,
//                  Michroma label under; More / placeholders greyed
//   matrix         pill (56–96 px), centered; filled with ink when on
// Sizes from the tile's smaller side: label clamp(15, m × 0.17, 24), icon
// clamp(22, m × 0.3, 46), sub-label at 72 % on tiles of 150 × 110 or more.
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property string look: theme.style.module ?? "classic"

    property string icon
    property string label
    property string sub
    property bool on: false
    // Not a switch (More, a placeholder): no lever or LED, the icon instead.
    property bool plain: false

    signal tapped

    function clamp(low: real, value: real, high: real): real {
        return Math.max(low, Math.min(high, value));
    }
    readonly property real m: Math.min(width, look === "matrix" ? pill.height : height)
    // Sizes per theme (design review): matrix from the pill's height,
    // modulaire's Michroma smaller, the others from the tile.
    readonly property real labelSize: look === "matrix" ? clamp(15, pill.height * 0.27, 20)
        : look === "modulaire" ? clamp(11, m * 0.1, 16)
        : clamp(15, m * 0.17, 24)
    readonly property real iconSize: look === "matrix" ? pill.height * 0.34 : clamp(22, m * 0.3, 46)
    // Modulaire: the lever's scale.
    readonly property real leverScale: clamp(1, m / 100, 2.2)
    // Low wide tiles (narrow columns, strips): icon (or lever) left, labels
    // right, all vertically centered.
    readonly property bool inline: look !== "matrix" && height < 110 && width >= height * 1.6
    readonly property bool showSub: !!sub && look !== "matrix" && (inline ? height >= 64 : width >= 150 && height >= 110)
    readonly property color onInk: look === "classic" || look === "constellation" ? theme.color.bg : theme.color.ink

    // The tile (every look but modulaire's switch and matrix's pill).
    Rectangle {
        id: tile

        visible: root.look !== "matrix"
        anchors.fill: parent
        radius: root.look === "facade" ? 4 : root.look === "classic" ? root.theme.radius.tile : root.theme.radius.control * 1.5
        color: root.look === "modulaire" ? "transparent" : area.pressed ? Qt.darker(fill, 1.12) : fill
        border.width: root.look === "facade" || root.look === "modulaire" ? 0 : root.on && (root.look === "classic" || root.look === "constellation") ? 0 : 1
        border.color: root.theme.color.line
        gradient: root.look === "constellation" && root.on ? starGradient : root.look === "facade" ? facadeKey : null

        readonly property color fill: root.on && root.look === "classic" ? root.theme.color.accent
            : root.theme.color.surface2

        // Façade: a metal key.
        Gradient {
            id: facadeKey
            GradientStop {
                position: 0
                color: area.pressed ? "#4A4E51" : "#5A5E61"
            }
            GradientStop {
                position: 1
                color: "#3A3E41"
            }
        }
        Rectangle {
            visible: root.look === "facade"
            x: 2
            y: 1
            width: parent.width - 4
            height: 1
            color: "#33FFFFFF"
        }
        Rectangle {
            visible: root.look === "facade"
            x: 1
            y: parent.height
            width: parent.width - 2
            height: 3
            color: "black"
        }

        Gradient {
            id: starGradient
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0
                color: root.theme.color.accent
            }
            GradientStop {
                position: 1
                color: root.theme.color.accent2 ?? root.theme.color.accent
            }
        }

        // Facade: the key's LED, centered on top. Modulaire: above the
        // lever (greyed on More / placeholders).
        Rectangle {
            visible: (root.look === "facade" && !root.plain) || root.look === "modulaire"
            readonly property real d: root.look === "facade" ? 7 : 9
            width: d
            height: d
            radius: d / 2
            // Low wide tiles: on the left, vertically centered.
            x: root.inline ? 8 : root.look === "modulaire" ? lever.x + (lever.width - width) / 2 : (parent.width - width) / 2
            y: root.inline ? (parent.height - height) / 2 : root.look === "modulaire" ? lever.y - height - 6 * root.leverScale : 8
            color: root.on && !root.plain ? (root.look === "facade" ? "#FF9D3A" : "#46C46A") : root.look === "facade" ? "#222222" : "#3B2A24"
            border.width: 1
            border.color: Qt.alpha("black", 0.5)

            Rectangle {
                visible: root.on && !root.plain
                anchors.centerIn: parent
                width: parent.width + 16
                height: width
                radius: width / 2
                color: Qt.alpha(parent.color, 0.25)
            }
        }

        // Classic: icon top-left, labels bottom-left. Constellation /
        // facade: centered.
        Icon {
            visible: root.look !== "modulaire"
            // Classic: inset by clamp(12, m × .12, 22).
            x: root.inline ? root.labelSize * 0.8 + (root.look === "facade" ? 14 : 0) : root.look === "classic" ? root.clamp(12, root.m * 0.12, 22) : (parent.width - width) / 2
            y: root.inline ? (parent.height - height) / 2 : root.look === "classic" ? root.clamp(12, root.m * 0.12, 22) : (parent.height - height - labels.height - root.labelSize * 0.4) / 2 + (root.look === "facade" ? 6 : 0)
            name: root.icon
            filled: root.on
            size: root.iconSize
            color: root.on ? root.onInk : root.theme.color.ink
        }

        // Modulaire: a vertical lever, up when on (greyed on More /
        // placeholders, which have no state).
        Rectangle {
            id: lever

            visible: root.look === "modulaire"
            opacity: root.plain ? 0.45 : 1
            width: 22 * root.leverScale
            height: 40 * root.leverScale
            x: root.inline ? 24 : (parent.width - width) / 2
            y: root.inline ? (parent.height - height) / 2 : (parent.height - height - labels.height - root.labelSize * 0.6 + 15 * root.leverScale) / 2
            radius: width / 2
            color: "#111111"
            border.width: 2
            border.color: "#80000000"

            Rectangle {
                width: 16 * root.leverScale
                height: width
                radius: width / 2
                x: (parent.width - width) / 2
                y: root.on && !root.plain ? 3 * root.leverScale : parent.height - height - 3 * root.leverScale
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: "#DDDDDD"
                    }
                    GradientStop {
                        position: 1
                        color: "#888888"
                    }
                }

                Behavior on y {
                    NumberAnimation {
                        duration: Motion.ms(root.theme, "fast", "")
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        Column {
            id: labels

            x: root.inline ? (root.look === "modulaire" ? lever.x + lever.width : root.labelSize * 0.8 + root.iconSize + (root.look === "facade" ? 14 : 0)) + root.labelSize * 0.6
                : root.look === "classic" ? root.clamp(12, root.m * 0.12, 22) : 0
            y: root.inline ? (parent.height - height) / 2
                : root.look === "classic" ? parent.height - height - root.clamp(12, root.m * 0.12, 22)
                : root.look === "modulaire" ? lever.y + lever.height + root.labelSize * 0.6
                : (parent.height - height - root.iconSize - root.labelSize * 0.4) / 2 + root.iconSize + root.labelSize * 0.4
            width: root.inline ? parent.width - x - root.labelSize * 0.6 : parent.width - x * (root.look === "classic" ? 2 : 1)
            spacing: 2

            ThemedText {
                width: parent.width
                horizontalAlignment: root.look === "classic" || root.inline ? Text.AlignLeft : Text.AlignHCenter
                elide: Text.ElideRight
                // Shrinks a little before eliding (long names in small tiles).
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 11
                text: root.label
                font.family: root.look === "modulaire" ? root.theme.font.mono : root.theme.font.family
                font.capitalization: root.look === "facade" || root.look === "modulaire" ? Font.AllUppercase : Font.MixedCase
                font.pixelSize: root.labelSize
                font.letterSpacing: root.look === "modulaire" ? root.labelSize * 0.12 : 0
                font.weight: root.look === "facade" ? Font.Bold : root.look === "constellation" ? Font.Medium : root.look === "modulaire" ? Font.Normal : Font.DemiBold
                color: root.look === "facade" ? "#E5E8E1" : root.on ? root.onInk : root.theme.color.ink
            }

            ThemedText {
                visible: root.showSub
                width: parent.width
                horizontalAlignment: root.look === "classic" || root.inline ? Text.AlignLeft : Text.AlignHCenter
                elide: Text.ElideRight
                text: root.sub
                font.pixelSize: root.labelSize * 0.72
                color: root.on ? Qt.alpha(root.onInk, 0.75) : root.theme.color.soft
            }
        }
    }

    // Matrix: a pill that turns over.
    Rectangle {
        id: pill

        visible: root.look === "matrix"
        anchors.centerIn: parent
        width: parent.width
        // 56–96 px high, centered in its cell (design review).
        height: Math.min(parent.height, root.clamp(56, Math.min(parent.height, parent.width * 0.45), 96))
        radius: height / 2
        color: root.on ? root.theme.color.ink : area.pressed ? Qt.alpha(root.theme.color.ink, 0.12) : "transparent"
        border.width: 1
        border.color: root.on ? root.theme.color.ink : root.theme.color.line

        Row {
            anchors.centerIn: parent
            spacing: pill.height * 0.16

            Icon {
                id: pillIcon
                anchors.verticalCenter: parent.verticalCenter
                name: root.icon
                filled: root.on
                size: Math.min(root.iconSize, pill.height * 0.5)
                color: root.on ? root.theme.color.bg : root.theme.color.ink
            }

            // Name, and its state under it when the pill is tall enough
            // (two lines of data: "SALON / 70 %").
            Column {
                // Measured apart (the texts' own widths follow the column).
                readonly property real room: pill.width - pill.height * 0.6 - pillIcon.width - pill.height * 0.16

                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(0, Math.min(room, Math.max(labelMetrics.advanceWidth, pillSub.visible ? subMetrics.advanceWidth : 0) + 2))

                TextMetrics {
                    id: labelMetrics
                    text: root.label.toUpperCase()
                    font.family: root.theme.font.mono
                    font.pixelSize: root.labelSize
                }

                TextMetrics {
                    id: subMetrics
                    text: root.sub
                    font.family: root.theme.font.mono
                    font.pixelSize: Math.max(10, root.labelSize * 0.72)
                }

                ThemedText {
                    id: pillLabel
                    width: parent.width
                    elide: Text.ElideRight
                    fontSizeMode: Text.HorizontalFit
                    minimumPixelSize: 11
                    text: root.label
                    font.family: root.theme.font.mono
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: root.labelSize * 0.08
                    font.pixelSize: root.labelSize
                    color: root.on ? root.theme.color.bg : root.theme.color.ink
                }

                // No sub-label in Matrix (design review).
                ThemedText {
                    id: pillSub
                    visible: false
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.sub
                    font.family: root.theme.font.mono
                    font.pixelSize: Math.max(10, root.labelSize * 0.72)
                    color: root.on ? Qt.alpha(root.theme.color.bg, 0.7) : root.theme.color.soft
                }
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: root.look === "matrix" ? pill : parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.tapped()
    }
}
