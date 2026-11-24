import QtQuick
import Quickshell
import qs.components
import qs.theme

// A titled section of a big module (size tiers large / poster), in its
// theme's language: classic a surface-2 pad, constellation a hairline,
// matrix a dotted rule on top, facade one VFD per zone, modulaire one
// LCD per zone (like the units of a rack). Children go in the content
// area (`body`) and read `ink`, `soft` and `textFont`.
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property string look: theme.style.module ?? "classic"
    readonly property bool onDisplay: display.kind !== "none"

    property string label
    // Label size (the module's t4) and inner spacing (its gap).
    property real labelSize: 15
    property real gap: 20
    // LCD tint (modulaire): "green" or "amber".
    property string tint: "green"

    readonly property color ink: display.ink
    readonly property color soft: display.soft
    readonly property string textFont: onDisplay ? display.textFont : theme.font.family
    readonly property real labelHeight: label ? labelText.implicitHeight + Math.round(gap * 0.45) : 0
    readonly property alias body: body
    default property alias content: body.data

    // Classic: a pad; constellation: a hairline frame.
    Rectangle {
        anchors.fill: parent
        visible: root.look === "classic" || root.look === "constellation"
        radius: root.theme.radius.card
        color: root.look === "classic" ? root.theme.color.surface2 : "transparent"
        border.width: root.look === "constellation" ? 1 : 0
        border.color: Qt.alpha(root.theme.color.accent, 0.28)
    }

    // Matrix: a dotted rule over the zone.
    Row {
        visible: root.look === "matrix"
        width: parent.width
        spacing: 6
        clip: true

        Repeater {
            model: root.look === "matrix" ? Math.floor(root.width / 9) : 0

            Rectangle {
                width: 3
                height: 3
                radius: 1.5
                color: Qt.alpha(root.theme.color.soft, 0.6)
            }
        }
    }

    // Pads: inside the pad / frame (classic, constellation), under the rule
    // (matrix), none around a display (facade, modulaire).
    readonly property real inset: look === "classic" || look === "constellation" ? Math.round(gap * 0.9) : 0
    readonly property real topInset: look === "matrix" ? Math.round(gap * 0.7) : inset

    ThemedText {
        id: labelText

        visible: !!root.label
        x: root.inset
        y: root.topInset
        width: parent.width - 2 * root.inset
        elide: Text.ElideRight
        label: true
        text: root.look === "facade" || root.look === "modulaire" ? root.label.toUpperCase() : root.label
        font.pixelSize: Math.round(root.labelSize)
        font.letterSpacing: 1.2
        color: root.look === "facade" ? (root.theme.color.silk ?? root.theme.color.soft) : root.theme.color.soft
    }

    // Facade / modulaire: the zone's own display window under its label.
    Display {
        id: display

        x: root.inset
        y: root.topInset + root.labelHeight
        width: parent.width - 2 * root.inset
        height: parent.height - y - root.inset
        tint: root.tint
        screen: root.look === "facade" || root.look === "modulaire"
    }

    Item {
        id: body

        readonly property real pad: root.onDisplay ? Math.round(root.gap * 0.8) : 0
        x: display.x + pad
        y: display.y + pad
        width: display.width - 2 * pad
        height: display.height - 2 * pad
    }
}
