import QtQuick
import Quickshell
import qs.components
import qs.components.dashboard
import qs.i18n
import qs.services
import qs.theme

// Theme switcher (tests, demos): the current theme's name; a tap moves
// every screen to the next theme (normal and modules alike), the corner
// button flips light / dark. Written to the settings like the Appearance
// page does.
ModuleBase {
    id: root

    readonly property var ids: Object.keys(Themes.definitions)
    readonly property string current: Themes.themeFor("modules")

    function next(): void {
        const id = ids[(ids.indexOf(current) + 1) % ids.length];
        Config.set("appearance.themes", { normal: id, modules: id });
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.next()
    }

    Column {
        anchors.centerIn: parent
        width: parent.width
        spacing: root.gap / 3

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: "palette"
            size: Math.min(root.ch * 0.28, 48)
            color: root.theme.color.accent
        }

        ThemedText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: I18n.tr(`theme.${root.current}`)
            font.family: root.theme.font.display
            font.pixelSize: Math.min(root.t2 * 1.2, root.cw / 6)
            font.weight: Font.DemiBold
        }

        ThemedText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            label: true
            text: I18n.tr("themeSwitch.hint")
            font.pixelSize: root.t4
            color: root.theme.color.soft
        }
    }

    // Light / dark.
    ModuleButton {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        size: Math.max(32, Math.min(root.ch * 0.3, 44))
        icon: Themes.variant === "dark" ? "light_mode" : "dark_mode"
        onTapped: Themes.setVariant(Themes.variant === "dark" ? "light" : "dark")
    }
}
