import QtQuick
import Quickshell
import qs.components
import qs.theme

// A quick-settings tile in the theme's language (design study 9):
//   classic        tile: icon on top, label and sub-label at the bottom;
//                  accent fill when on
//   constellation  centered; accent → accent2 gradient when on
//   facade         hardware key with a LED (amber when on)
//   modulaire      lever switch and a green LED, silk label under
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

    signal tapped

    readonly property real m: Math.min(width, look === "matrix" ? pill.height : height)
    readonly property real labelSize: Math.max(15, Math.min(m * 0.17, 24))
    readonly property real iconSize: Math.max(22, Math.min(m * 0.3, 46))
    readonly property bool showSub: !!sub && width >= 150 && height >= 110 && look !== "matrix"
    readonly property color onInk: look === "classic" || look === "constellation" ? theme.color.bg : theme.color.ink

    // The tile (every look but modulaire's switch and matrix's pill).
    Rectangle {
        id: tile

        visible: root.look !== "matrix"
        anchors.fill: parent
        radius: root.look === "facade" || root.look === "modulaire" ? 4 : root.theme.radius.control * 1.5
        color: area.pressed ? Qt.darker(fill, 1.12) : fill
        border.width: root.look === "facade" ? 2 : root.on && (root.look === "classic" || root.look === "constellation") ? 0 : 1
        border.color: root.look === "facade" ? "black" : root.theme.color.line
        gradient: root.look === "constellation" && root.on ? starGradient : null

        readonly property color fill: root.on && root.look === "classic" ? root.theme.color.accent
            : root.look === "facade" || root.look === "modulaire" ? root.theme.color.surface3
            : root.theme.color.surface2

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

        // Facade / modulaire: the LED.
        Rectangle {
            visible: root.look === "facade" || root.look === "modulaire"
            x: 10
            y: 10
            width: 8
            height: 8
            radius: 4
            color: root.on ? (root.look === "facade" ? "#FFB547" : root.theme.color.ok) : Qt.alpha(root.theme.color.ink, 0.15)
            border.width: 1
            border.color: Qt.alpha("black", 0.5)

            Rectangle {
                visible: root.on
                anchors.centerIn: parent
                width: parent.width * 2.6
                height: width
                radius: width / 2
                color: Qt.alpha(parent.color, 0.25)
            }
        }

        // Classic: icon top-left, labels bottom-left. Constellation /
        // facade: centered.
        Icon {
            visible: root.look !== "modulaire"
            x: root.look === "classic" ? root.labelSize * 0.8 : (parent.width - width) / 2
            y: root.look === "classic" ? root.labelSize * 0.8 : (parent.height - height - labels.height - root.labelSize * 0.4) / 2
            name: root.icon
            filled: root.on
            size: root.iconSize
            color: root.on ? root.onInk : root.theme.color.ink
        }

        // Modulaire: a lever switch.
        Rectangle {
            id: lever

            visible: root.look === "modulaire"
            anchors.horizontalCenter: parent.horizontalCenter
            y: (parent.height - height - labels.height - root.labelSize * 0.5) / 2
            width: Math.min(parent.width * 0.5, root.iconSize * 1.6)
            height: width * 0.48
            radius: height / 2
            color: root.on ? Qt.alpha(root.theme.color.ok, 0.35) : Qt.alpha("black", 0.45)
            border.width: 1
            border.color: Qt.alpha("white", 0.18)

            Rectangle {
                width: parent.height - 6
                height: width
                radius: width / 2
                y: 3
                x: root.on ? parent.width - width - 3 : 3
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: "#E6E6E6"
                    }
                    GradientStop {
                        position: 1
                        color: "#8C8C8C"
                    }
                }

                Behavior on x {
                    NumberAnimation {
                        duration: Motion.ms(root.theme, "fast", "")
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        Column {
            id: labels

            x: root.look === "classic" ? root.labelSize * 0.8 : 0
            y: root.look === "classic" ? parent.height - height - root.labelSize * 0.7
                : root.look === "modulaire" ? lever.y + lever.height + root.labelSize * 0.5
                : (parent.height - height - root.iconSize - root.labelSize * 0.4) / 2 + root.iconSize + root.labelSize * 0.4
            width: parent.width - x * (root.look === "classic" ? 2 : 1)
            spacing: 2

            ThemedText {
                width: parent.width
                horizontalAlignment: root.look === "classic" ? Text.AlignLeft : Text.AlignHCenter
                elide: Text.ElideRight
                text: root.label
                font.family: root.look === "modulaire" ? root.theme.font.mono : root.theme.font.family
                font.capitalization: root.look === "facade" || root.look === "modulaire" ? Font.AllUppercase : Font.MixedCase
                font.pixelSize: root.look === "modulaire" ? root.labelSize * 0.8 : root.labelSize
                font.weight: Font.DemiBold
                color: root.on ? root.onInk : root.theme.color.ink
            }

            ThemedText {
                visible: root.showSub
                width: parent.width
                horizontalAlignment: root.look === "classic" ? Text.AlignLeft : Text.AlignHCenter
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
        height: Math.max(Math.min(parent.height, 56), Math.min(parent.height, 96))
        radius: height / 2
        color: root.on ? root.theme.color.ink : area.pressed ? Qt.alpha(root.theme.color.ink, 0.12) : "transparent"
        border.width: 1.5
        border.color: root.theme.color.ink

        Row {
            anchors.centerIn: parent
            spacing: root.labelSize * 0.5
            width: Math.min(implicitWidth, parent.width - parent.height * 0.6)

            Icon {
                id: pillIcon
                anchors.verticalCenter: parent.verticalCenter
                name: root.icon
                filled: root.on
                size: Math.min(root.iconSize, pill.height * 0.5)
                color: root.on ? root.theme.color.bg : root.theme.color.ink
            }

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, pill.width - pill.height * 0.6 - pillIcon.width - parent.spacing)
                elide: Text.ElideRight
                text: root.label
                font.family: root.theme.font.mono
                font.capitalization: Font.AllUppercase
                font.pixelSize: root.labelSize * 0.85
                color: root.on ? root.theme.color.bg : root.theme.color.ink
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
