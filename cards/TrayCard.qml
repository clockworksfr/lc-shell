import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.components
import qs.i18n
import qs.theme

// Tray items: icon, title, tooltip.
Column {
    id: root

    property var block
    property ShellScreen screen
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    spacing: theme.space.s

    ThemedText {
        visible: SystemTray.items.values.length === 0
        text: I18n.tr("card.noTray")
        color: root.theme.color.soft
    }

    Repeater {
        model: SystemTray.items.values

        Row {
            required property SystemTrayItem modelData

            width: root.width
            spacing: root.theme.space.s

            IconImage {
                anchors.verticalCenter: parent.verticalCenter
                width: 20
                height: 20
                source: parent.modelData.icon
            }

            Column {
                width: parent.width - 20 - parent.spacing
                anchors.verticalCenter: parent.verticalCenter

                ThemedText {
                    width: parent.width
                    text: parent.parent.modelData.tooltipTitle || parent.parent.modelData.title || parent.parent.modelData.id
                    elide: Text.ElideRight
                }

                ThemedText {
                    width: parent.width
                    visible: !!text
                    text: (parent.parent.modelData.tooltipDescription ?? "").replace(/<[^>]*>/g, "")
                    color: root.theme.color.soft
                    font.pixelSize: root.theme.font.sizeS
                    elide: Text.ElideRight
                }
            }
        }
    }
}
