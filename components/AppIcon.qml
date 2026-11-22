import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.theme

// An application icon (tray, active window, cards) that can follow the
// theme: "native" colors, "tinted" (desaturated, washed with the accent) or
// "mono" (in the theme's ink). Setting appearance.appIcons, else the
// theme's style.appIcons.
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    property string source
    property real size: 18
    readonly property string mode: Config.get("appearance.appIcons") ?? theme.style.appIcons ?? "native"

    implicitWidth: size
    implicitHeight: size

    IconImage {
        id: image
        anchors.fill: parent
        source: root.source
        asynchronous: true
        visible: root.mode === "native"
    }

    MultiEffect {
        anchors.fill: parent
        source: image
        visible: root.mode !== "native"
        saturation: -1
        colorization: root.mode === "mono" ? 1 : 0.55
        colorizationColor: root.mode === "mono" ? root.theme.color.ink : root.theme.color.accent
        brightness: root.mode === "mono" ? 0.1 : 0
    }
}
