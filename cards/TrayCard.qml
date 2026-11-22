import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.components
import qs.i18n
import qs.theme

// Tray card. For the hovered icon: its icon, name, state, tooltip and its
// menu's first actions as chips (click runs one), "Open" and "Menu".
// Without one (card opened by IPC…): every item, one line each.
Column {
    id: root

    property var block
    property ShellScreen screen
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property SystemTrayItem item: block?.hovered ?? null

    function plain(text: string): string {
        return (text ?? "").replace(/<[^>]*>/g, "").trim();
    }

    spacing: theme.space.m

    // --- One item ---

    Row {
        visible: !!root.item
        width: parent.width
        spacing: root.theme.space.m

        AppIcon {
            anchors.verticalCenter: parent.verticalCenter
            size: 40
            source: root.item?.icon ?? ""
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 40 - parent.spacing

            ThemedText {
                width: parent.width
                elide: Text.ElideRight
                text: root.item ? (root.plain(root.item.tooltipTitle) || root.item.title || root.item.id) : ""
                font.weight: Font.DemiBold
                font.pixelSize: root.theme.font.sizeL
            }

            ThemedText {
                width: parent.width
                elide: Text.ElideRight
                text: !root.item ? "" : root.item.status === Status.NeedsAttention ? I18n.tr("tray.attention") : root.item.status === Status.Passive ? I18n.tr("tray.passive") : I18n.tr("tray.active")
                color: root.item?.status === Status.NeedsAttention ? root.theme.color.urgent : root.theme.color.soft
                font.pixelSize: root.theme.font.sizeS
            }
        }
    }

    ThemedText {
        visible: !!root.item && !!text
        width: parent.width
        wrapMode: Text.WordWrap
        maximumLineCount: 4
        elide: Text.ElideRight
        text: root.item ? root.plain(root.item.tooltipDescription) : ""
        color: root.theme.color.soft
    }

    // The menu's first plain actions.
    QsMenuOpener {
        id: opener
        menu: root.item?.hasMenu ? root.item.menu : null
    }

    Flow {
        visible: !!root.item && actions.count > 0
        width: parent.width
        spacing: root.theme.space.xs

        Repeater {
            id: actions
            model: [...opener.children.values].filter(e => !e.isSeparator && !e.hasChildren && e.enabled && !!e.text).slice(0, 6)

            Button {
                required property var modelData
                text: modelData.text.replace(/_(?!_)/g, "")
                onClicked: modelData.triggered()
            }
        }
    }

    Row {
        visible: !!root.item
        spacing: root.theme.space.s

        Button {
            primary: true
            icon: "open_in_new"
            text: I18n.tr("tray.open")
            onClicked: root.item.activate()
        }

        Button {
            visible: root.item?.hasMenu ?? false
            icon: "menu"
            text: I18n.tr("tray.menu")
            onClicked: root.block?.menuFor(root.item)
        }
    }

    // --- Every item ---

    ThemedText {
        visible: !root.item && SystemTray.items.values.length === 0
        text: I18n.tr("card.noTray")
        color: root.theme.color.soft
    }

    Repeater {
        model: root.item ? [] : SystemTray.items.values

        Row {
            id: line

            required property SystemTrayItem modelData

            width: root.width
            spacing: root.theme.space.s

            AppIcon {
                anchors.verticalCenter: parent.verticalCenter
                size: 20
                source: line.modelData.icon
            }

            Column {
                width: parent.width - 20 - parent.spacing
                anchors.verticalCenter: parent.verticalCenter

                ThemedText {
                    width: parent.width
                    text: root.plain(line.modelData.tooltipTitle) || line.modelData.title || line.modelData.id
                    elide: Text.ElideRight
                }

                ThemedText {
                    width: parent.width
                    visible: !!text
                    text: root.plain(line.modelData.tooltipDescription)
                    color: root.theme.color.soft
                    font.pixelSize: root.theme.font.sizeS
                    elide: Text.ElideRight
                }
            }
        }
    }
}
