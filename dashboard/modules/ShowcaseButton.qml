import QtQuick
import Quickshell
import qs.components
import qs.components.dashboard
import qs.dashboard
import qs.i18n
import qs.theme

// Showcase button: a tap shows the next module type at every cell shape
// across the dashboard (Showcase), the corner button goes back to the
// normal pages.
ModuleBase {
    id: root

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Showcase.next()
    }

    Column {
        anchors.centerIn: parent
        width: parent.width
        spacing: root.gap / 3

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: "view_quilt"
            size: Math.min(root.ch * 0.28, 48)
            color: root.theme.color.accent
        }

        ThemedText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: Showcase.type ? I18n.tr(`module.${Showcase.type}`) : I18n.tr("showcase.title")
            font.family: root.theme.font.family
            font.pixelSize: Math.min(root.t2 * 1.2, root.cw / 6)
            font.weight: Font.DemiBold
        }

        ThemedText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            label: true
            text: Showcase.type ? `${Showcase.types.indexOf(Showcase.type) + 1} / ${Showcase.types.length}` : I18n.tr("themeSwitch.hint")
            font.pixelSize: root.t4
            color: root.theme.color.soft
        }
    }

    ModuleButton {
        visible: !!Showcase.type
        anchors.right: parent.right
        anchors.top: parent.top
        size: Math.max(32, Math.min(root.ch * 0.3, 44))
        icon: "close"
        onTapped: Showcase.stop()
    }
}
