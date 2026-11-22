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
    readonly property bool vfd: inDisplay && (theme.style.display ?? "none") === "vfd"

    property string text
    property real pixelSize: 64
    property color color: theme.color.nixie ?? theme.color.ink
    property bool inDisplay: false
    property bool glow: true

    implicitWidth: lcd ? lcdText.implicitWidth + window.inset * 2 + pixelSize * 0.3 : vfd ? hero.implicitWidth + pixelSize * 0.28 + 20 : hero.implicitWidth
    implicitHeight: lcd ? lcdText.implicitHeight + window.inset * 2 : vfd ? hero.implicitHeight + pixelSize * 0.12 + 20 : hero.implicitHeight

    // facade: the figure in its VFD window.
    Display {
        visible: root.vfd
        anchors.fill: parent
    }

    HeroText {
        id: hero
        anchors.centerIn: root.vfd ? parent : undefined
        visible: !root.lcd
        text: root.text
        pixelSize: root.pixelSize
        color: root.color
        glow: root.glow
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
            // Big figures: the theme's display font (Nixie One), amber.
            color: root.theme.color.nixie ?? window.ink
            font.family: root.theme.font.display
            font.pixelSize: root.pixelSize * 0.82
            font.features: ({ "tnum": 1 })
        }
    }
}
