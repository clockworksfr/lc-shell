import QtQuick
import Quickshell
import qs.theme

// A ladder of round LEDs (modulaire), lit up to `value` (0..1): green,
// yellow from 70 %, red from 85 % (#FF3B30), each with a halo; unlit
// warm brown #3A2C22.
// Vertical by default (bottom to top).
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    property real value: 0
    property bool vertical: true
    property int count: Math.max(8, Math.min(16, Math.floor((vertical ? height : width) / 18)))
    // Fits both ways (never past the ladder's length, 3 px gaps at least).
    readonly property real ledSize: Math.max(2, Math.min(Math.min(vertical ? width : height, 18) * 0.8, ((vertical ? height : width) - (count - 1) * 3) / count))

    Grid {
        anchors.centerIn: parent
        columns: root.vertical ? 1 : root.count
        spacing: Math.max(3, ((root.vertical ? root.height : root.width) - root.count * root.ledSize) / Math.max(1, root.count - 1))

        Repeater {
            model: root.count

            Item {
                id: led

                required property int index
                readonly property real size: root.ledSize
                // Vertical ladders fill from the bottom.
                readonly property real at: ((root.vertical ? root.count - 1 - index : index) + 0.5) / root.count
                readonly property bool lit: at <= root.value
                readonly property color tone: at >= 0.85 ? "#FF3B30" : at >= 0.7 ? "#E5C230" : "#46C46A"

                width: size
                height: size

                Rectangle {
                    visible: led.lit
                    anchors.centerIn: parent
                    width: led.size + 10
                    height: width
                    radius: width / 2
                    color: Qt.alpha(led.tone, 0.28)
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: led.lit ? led.tone : "#3A2C22"
                    border.width: 1
                    border.color: Qt.alpha("black", 0.5)
                }
            }
        }
    }
}
