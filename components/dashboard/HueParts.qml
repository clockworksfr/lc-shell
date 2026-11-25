import QtQuick
import Quickshell
import qs.components
import qs.theme

// Building blocks of the Hue module, in the theme's
// language: Swatch (a color, round or square), Switch (on / off, touch
// area of `hit`), Key (a scene button, active state per theme).
QtObject {
    component Swatch: Rectangle {
        id: swatch

        readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
        readonly property string look: theme.style.module ?? "classic"
        property color swatchColor: "#FFB46B"
        property bool selected: false
        property real size: 40

        signal tapped

        width: size
        height: size
        radius: look === "facade" ? 4 : size / 2
        color: swatchColor
        border.width: selected ? 3 : 1
        border.color: selected ? (theme.color.signal ?? theme.color.ink) : Qt.alpha("black", 0.35)

        // A thin halo of the color, inside its own room (no overlap).
        Rectangle {
            z: -1
            anchors.centerIn: parent
            width: parent.width + 6
            height: width
            radius: swatch.look === "facade" ? 6 : width / 2
            color: Qt.alpha(swatch.swatchColor, 0.22)
            visible: swatch.look !== "modulaire"
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -Math.max(0, (Math.min(72, swatch.theme.hit) - swatch.size) / 2)
            cursorShape: Qt.PointingHandCursor
            onClicked: swatch.tapped()
        }
    }

    component Switch: Item {
        id: sw

        readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
        readonly property string look: theme.style.module ?? "classic"
        property bool on: false
        property bool enabled: true
        // On a tile filled with the accent (classic, on): inverted colors.
        property bool onAccent: false

        signal toggled

        implicitWidth: Math.max(theme.hit, 52)
        implicitHeight: Math.max(theme.hit, 30)
        opacity: enabled ? 1 : 0.45

        Rectangle {
            id: track
            anchors.centerIn: parent
            width: sw.look === "facade" ? 40 : 52
            height: sw.look === "facade" ? 30 : 28
            radius: sw.look === "facade" ? 3 : height / 2
            color: sw.look === "facade" ? "#3A3E41"
                : sw.on ? (sw.onAccent ? sw.theme.color.onAccent : sw.look === "matrix" ? sw.theme.color.ink : sw.theme.color.accent)
                : (sw.look === "matrix" ? "transparent" : sw.theme.color.surface3)
            border.width: sw.look === "matrix" ? 1.5 : sw.look === "constellation" || sw.look === "facade" ? 1 : 0
            border.color: sw.look === "matrix" ? sw.theme.color.ink : sw.look === "facade" ? "black" : sw.theme.color.line

            // Facade: a key with its LED.
            Rectangle {
                visible: sw.look === "facade"
                anchors.centerIn: parent
                width: 8
                height: 8
                radius: 4
                color: sw.on ? "#FF9D3A" : "#222222"
            }

            // The knob.
            Rectangle {
                visible: sw.look !== "facade"
                width: sw.look === "matrix" ? 15 : parent.height - 6
                height: width
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                x: sw.on ? parent.width - width - (parent.height - height) / 2 : (parent.height - height) / 2
                color: sw.look === "matrix" ? (sw.on ? sw.theme.color.bg : sw.theme.color.ink) : sw.onAccent && sw.on ? sw.theme.color.accent : "white"

                Behavior on x {
                    NumberAnimation {
                        duration: Motion.ms(sw.theme, "fast", "")
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: sw.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: sw.toggled()
        }
    }

    component Key: Rectangle {
        id: key

        readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
        readonly property string look: theme.style.module ?? "classic"
        property string text
        property string icon
        property bool active: false
        property real textSize: 15

        signal tapped

        radius: look === "facade" || look === "modulaire" ? 4 : look === "classic" ? theme.radius.control * 1.5 : height / 2
        color: area.pressed ? Qt.darker(fill, 1.15) : fill
        gradient: look === "constellation" && active ? starGradient : null
        border.width: look === "matrix" || look === "constellation" ? 1.5 : look === "facade" ? 2 : 0
        border.color: look === "facade" ? "black" : look === "matrix" ? (active ? theme.color.ink : theme.color.line) : theme.color.line

        readonly property color fill: look === "modulaire" ? (active ? "#E8742A" : "#2A2B2D")
            : look === "facade" ? theme.color.surface3
            : look === "matrix" ? (active ? theme.color.ink : "transparent")
            : look === "constellation" ? "transparent"
            : active ? theme.color.accent : theme.color.surface2
        readonly property color ink: look === "modulaire" ? (active ? "#1A0D04" : theme.color.ink)
            : look === "matrix" ? (active ? theme.color.bg : theme.color.ink)
            : look === "classic" && active ? theme.color.onAccent
            : look === "constellation" && active ? theme.color.bg
            : theme.color.ink

        Gradient {
            id: starGradient
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0
                color: key.theme.color.accent
            }
            GradientStop {
                position: 1
                color: key.theme.color.accent2 ?? key.theme.color.accent
            }
        }

        // Facade: the key's LED.
        Rectangle {
            visible: key.look === "facade"
            x: 8
            y: 8
            width: 7
            height: 7
            radius: 3.5
            color: key.active ? "#FF9D3A" : "#222222"
        }

        Row {
            anchors.centerIn: parent
            spacing: 6
            width: Math.min(implicitWidth, key.width - 16)

            Icon {
                id: keyIcon
                visible: !!key.icon
                anchors.verticalCenter: parent.verticalCenter
                name: key.icon
                size: key.textSize * 1.3
                color: key.ink
            }

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, key.width - 16 - (keyIcon.visible ? keyIcon.width + 6 : 0))
                elide: Text.ElideRight
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 11
                text: key.text
                font.family: key.look === "modulaire" || key.look === "matrix" ? key.theme.font.mono : key.theme.font.family
                font.capitalization: key.look === "classic" ? Font.MixedCase : Font.AllUppercase
                font.letterSpacing: key.look === "facade" ? 0.8 : 0
                font.pixelSize: key.textSize
                font.weight: key.active ? Font.DemiBold : Font.Normal
                color: key.ink
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: key.tapped()
        }
    }
}
