import QtQuick
import QtQuick.Effects
import Quickshell
import qs.theme

// A big figure in the theme's display font: unlit segments behind it
// where the theme has them (style.ghostDigits: Façade's "88:88"), and the
// theme's glow around it (color.glow: VFD phosphor, Nixie tubes, Matrix
// dots in the dark variant). One effect per figure, redrawn only when its
// text changes.
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    property string text
    property real pixelSize: 48
    // Modulaire's figures are Nixie orange.
    property color color: theme.color.nixie ?? theme.color.ink
    property int horizontalAlignment: Text.AlignLeft
    // Unlit segments behind (where the theme has them); off for labels.
    property bool ghost: true
    // Off where the figure sits on something glowing already (gauges).
    property bool glow: true
    readonly property bool glows: glow && Qt.color(theme.color.glow ?? "#00000000").a > 0

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight
    // Text-like baseline (anchors.baseline: smaller figures beside it).
    baselineOffset: label.baselineOffset

    Text {
        anchors.fill: label
        visible: root.ghost && !!root.theme.style.ghostDigits
        text: root.text.replace(/[0-9]/g, "8")
        font: label.font
        horizontalAlignment: root.horizontalAlignment
        color: root.theme.color.ghost ?? "transparent"
    }

    Text {
        id: label

        width: root.width > 0 ? root.width : implicitWidth
        text: root.text
        horizontalAlignment: root.horizontalAlignment
        color: root.color
        font.family: root.theme.font.display
        font.weight: root.theme.font.displayWeight
        font.italic: !!root.theme.font.displayItalic
        font.pixelSize: root.pixelSize
        font.features: ({ "tnum": 1 })
        visible: !root.glows
    }

    MultiEffect {
        visible: root.glows
        anchors.fill: label
        source: label
        autoPaddingEnabled: true
        shadowEnabled: true
        shadowColor: root.theme.color.glow ?? "transparent"
        // Halo in proportion to the size: small figures stay sharp.
        shadowBlur: root.pixelSize < 40 ? 0.45 : 0.81
        blurMax: Math.round(Math.max(8, Math.min(24, root.pixelSize * 0.3)))
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
    }
}
