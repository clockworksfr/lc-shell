import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.panels
import qs.services

// Notifications: unread count, do-not-disturb state.
// Click: history panel, middle click: toggle do-not-disturb.
TextBlock {
    id: root

    fullText: NotificationCenter.dnd ? I18n.tr("bar.dnd")
        : NotificationCenter.unread > 0 ? I18n.tr("bar.notifsCount", { n: NotificationCenter.unread })
        : I18n.tr("bar.notifs")
    compactText: NotificationCenter.dnd ? I18n.tr("bar.dnd")
        : NotificationCenter.unread > 0 ? I18n.tr("bar.v.notifs", { n: NotificationCenter.unread })
        : I18n.tr("bar.notifs")
    color: NotificationCenter.unread > 0 && !NotificationCenter.dnd ? theme.color.accent : theme.color.soft

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton)
                NotificationCenter.setDnd(!NotificationCenter.dnd);
            else
                popup.toggle();
        }
    }

    function togglePanel(): void {
        popup.toggle();
    }

    BarPopup {
        id: popup
        anchorItem: root
        onVisibleChanged: if (visible) NotificationCenter.markRead()

        NotificationPanel {}
    }
}
