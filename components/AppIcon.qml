import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.theme

// An application icon (tray, active window, cards) that can follow the
// theme: "native" colors, "tinted" (duotone in the accent) or "mono" (a
// silhouette in the ink; the app's -symbolic icon when the theme has one).
// Native and tinted icons that would vanish on the bar (too little
// contrast with `background`) get their lightness inverted
// (appearance.appIconGuard).
// Setting appearance.appIcons, else the theme's style.appIcons.
// Shader: assets/shaders (tools/gen-shaders.sh).
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    property string source
    // Icon name, when known: lets mono use the app's symbolic icon.
    property string name
    property real size: 18
    // What the icon sits on (the bar or card surface).
    property color background: theme.color.surface
    readonly property bool guard: Config.get("appearance.appIconGuard") ?? true
    readonly property string mode: Config.get("appearance.appIcons") ?? theme.style.appIcons ?? "native"
    readonly property string symbolic: mode === "mono" && name ? Quickshell.iconPath(`${name}-symbolic`, true) : ""

    implicitWidth: size
    implicitHeight: size

    IconImage {
        anchors.fill: parent
        source: root.symbolic || root.source
        asynchronous: true

        layer.enabled: root.mode !== "native" || root.guard
        // Mipmaps: the shader reads the icon's average color.
        layer.mipmap: true
        layer.effect: ShaderEffect {
            readonly property color tint: root.mode === "mono" ? root.theme.color.ink : root.theme.color.accent
            readonly property color bg: root.background
            readonly property real mode: root.mode === "mono" ? 2 : root.mode === "tinted" ? 1 : 0
            readonly property real guard: root.guard ? 1 : 0
            readonly property real amount: Config.get("appearance.appIconTint") ?? 0.6
            readonly property real threshold: Config.get("appearance.appIconContrast") ?? 0.35

            fragmentShader: Qt.resolvedUrl("../assets/shaders/appicon.frag.qsb")
        }
    }
}
