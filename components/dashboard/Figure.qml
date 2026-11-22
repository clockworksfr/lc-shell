import QtQuick
import QtQuick.Effects
import Quickshell
import qs.components
import qs.theme

// The main figure of a module: the theme's display font (HeroText: unlit
// segments, glow). With `tubes` in modulaire, one Nixie tube per character
// (dark glass, orange digit, a single glow for the group).
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property bool nixie: tubes && (theme.style.module ?? "") === "modulaire"

    property string text
    property real pixelSize: 64
    property color color: theme.color.nixie ?? theme.color.ink
    property bool tubes: false

    implicitWidth: nixie ? tubeRow.implicitWidth : hero.implicitWidth
    implicitHeight: nixie ? tubeRow.implicitHeight : hero.implicitHeight

    HeroText {
        id: hero
        visible: !root.nixie
        text: root.text
        pixelSize: root.pixelSize
        color: root.color
    }

    Row {
        id: tubeRow

        visible: root.nixie
        spacing: root.pixelSize * 0.08

        Repeater {
            model: root.nixie ? root.text.split("") : []

            Rectangle {
                required property string modelData
                readonly property bool digit: /[0-9]/.test(modelData)
                width: digit ? root.pixelSize * 0.62 : root.pixelSize * 0.22
                height: root.pixelSize * 1.18
                radius: digit ? width * 0.4 : 0
                color: digit ? Qt.rgba(0.08, 0.06, 0.05, 0.92) : "transparent"
                border.width: digit ? 1 : 0
                border.color: Qt.alpha("white", 0.12)

                Text {
                    anchors.centerIn: parent
                    text: parent.modelData
                    color: root.theme.color.nixie ?? root.theme.color.accent
                    font.family: root.theme.font.display
                    font.pixelSize: root.pixelSize * (parent.digit ? 0.9 : 0.8)
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: root.theme.color.glow ?? "#CCFF8A2A"
                        shadowBlur: 0.7
                        blurMax: 20
                        shadowHorizontalOffset: 0
                        shadowVerticalOffset: 0
                    }
                }
            }
        }
    }
}
