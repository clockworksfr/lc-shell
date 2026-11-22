import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// History: do-not-disturb switch, clear all, notification list.
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    width: 400
    spacing: theme.space.s

    Switch {
        text: I18n.tr("notif.dnd")
        checked: NotificationCenter.dnd
        onToggled: NotificationCenter.setDnd(!checked)
    }

    ListRow {
        visible: NotificationCenter.count > 0
        title: I18n.tr("notif.clear")
        trailing: `${NotificationCenter.count}`
        onClicked: NotificationCenter.clearAll()
    }

    ThemedText {
        visible: NotificationCenter.count === 0
        text: I18n.tr("notif.empty")
        color: root.theme.color.soft
    }

    ListView {
        width: parent.width
        height: Math.min(contentHeight, 640)
        clip: true
        spacing: root.theme.space.s
        boundsBehavior: Flickable.StopAtBounds
        model: NotificationCenter.history

        delegate: NotificationCard {
            required property var modelData
            width: ListView.view.width
            entry: modelData
        }
    }
}
