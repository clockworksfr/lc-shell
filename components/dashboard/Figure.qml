import QtQuick
import Quickshell
import qs.components
import qs.theme

// The main figure of a module, in the theme's display font (HeroText:
// unlit segments, glow). With `inDisplay`, themes with an LCD
// (modulaire) show it in an amber LCD window, like the player's screen;
// others draw it as is.
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property bool lcd: inDisplay && (theme.style.display ?? "none") === "lcd"

    property string text
    property real pixelSize: 64
    property color color: theme.color.nixie ?? theme.color.ink
    property bool inDisplay: false

    implicitWidth: lcd ? lcdText.implicitWidth + window.inset * 2 + pixelSize * 0.3 : hero.implicitWidth
    implicitHeight: lcd ? lcdText.implicitHeight + window.inset * 2 : hero.implicitHeight

    HeroText {
        id: hero
        visible: !root.lcd
        text: root.text
        pixelSize: root.pixelSize
        color: root.color
    }

    Display {
        id: window

        visible: root.lcd
        anchors.fill: parent
        tint: "amber"

        Text {
            id: lcdText
            anchors.centerIn: parent
            text: root.text
            color: window.ink
            font.family: root.theme.font.lcd ?? root.theme.font.mono
            font.pixelSize: root.pixelSize * 0.82
            font.features: ({ "tnum": 1 })
        }
    }
}
