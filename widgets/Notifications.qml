import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.panels
import qs.services

// Notifications: unread count, do-not-disturb state.
// Click: history panel, middle click: toggle do-not-disturb.
TextWidget {
    id: root

    // Right-click menu (the bar's widget menu).
    readonly property var contextActions: [
        { id: "dnd", icon: "do_not_disturb_on", text: I18n.tr("ctx.dnd"), check: "box", checked: NotificationCenter.dnd },
        ...(NotificationCenter.count > 0 ? [{ id: "clear", icon: "delete", text: I18n.tr("notif.clear") }] : [])
    ]
    function contextAction(id: string): void {
        if (id === "dnd")
            NotificationCenter.setDnd(!NotificationCenter.dnd);
        else if (id === "clear")
            NotificationCenter.clearAll();
    }

    fullText: size === "compact" ? (NotificationCenter.dnd ? "∅" : `${NotificationCenter.unread}`)
        : NotificationCenter.dnd ? I18n.tr("bar.dnd")
        : NotificationCenter.unread > 0 ? I18n.tr("bar.notifsCount", { n: NotificationCenter.unread })
        : I18n.tr("bar.notifs")
    // Matrix (micro labels): the red dot and the count, nothing else.
    compactText: theme.style.statusStack === true && size !== "compact" ? (NotificationCenter.dnd ? "∅" : NotificationCenter.unread > 0 ? `● ${NotificationCenter.unread}` : "0")
        : NotificationCenter.dnd ? I18n.tr("bar.dnd")
        : NotificationCenter.unread > 0 ? I18n.tr("bar.v.notifs", { n: NotificationCenter.unread })
        : I18n.tr("bar.notifs")
    color: NotificationCenter.unread > 0 && !NotificationCenter.dnd ? theme.color.accent : theme.color.soft

    icon: NotificationCenter.dnd ? "notifications_off" : NotificationCenter.unread > 0 ? "notifications_active" : "notifications"
    iconFilled: NotificationCenter.unread > 0
    iconText: NotificationCenter.unread > 0 && !NotificationCenter.dnd ? `${NotificationCenter.unread}` : ""

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

    readonly property bool panelOpen: popup.visible

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
