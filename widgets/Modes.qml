import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.lock
import qs.services

// Active modes: caffeine (idle actions held) and do-not-disturb. Hidden
// while neither is on. Left click: the card (durations), middle click:
// caffeine, right click: turn either on or off.
TextWidget {
    id: root

    readonly property bool caffeine: Idle.caffeine
    readonly property bool dnd: NotificationCenter.dnd
    // Always there (to turn a mode on), unless `autoHide` (then only while
    // a mode is on).
    readonly property bool shown: !options.autoHide || caffeine || dnd
    readonly property var names: [caffeine ? I18n.tr("bar.modeCaffeine") : "", dnd ? I18n.tr("bar.dnd") : ""].filter(s => !!s)

    // Right-click menu (the bar's widget menu).
    readonly property var contextActions: [
        { id: "caffeine", icon: "coffee", text: I18n.tr("toggles.caffeine"), check: "box", checked: Idle.caffeine },
        { id: "dnd", icon: "do_not_disturb_on", text: I18n.tr("ctx.dnd"), check: "box", checked: NotificationCenter.dnd }
    ]
    function contextAction(id: string): void {
        if (id === "caffeine")
            Idle.setCaffeine(!Idle.caffeine, 0);
        else if (id === "dnd")
            NotificationCenter.setDnd(!NotificationCenter.dnd);
    }

    fullText: names.join(" · ") || I18n.tr("bar.modesNone")
    compactText: I18n.tr("bar.v.modes", { value: names.join(" · ") || "–" })
    microLabel: I18n.tr("bar.v.modes", { value: "" }).split("\n")[0]
    color: shown ? theme.color.accent : theme.color.soft

    // Icons: the first active mode, the second beside it.
    icon: caffeine || !dnd ? "coffee" : "do_not_disturb_on"
    iconFilled: true
    iconText: ""
    readonly property real iconSize: theme.font.sizeL + 3
    leftPadding: useIcon && !vertical ? (caffeine && dnd ? iconSize * 2 + 4 : iconSize) : 0

    Icon {
        visible: root.useIcon && root.caffeine && root.dnd
        name: "do_not_disturb_on"
        filled: true
        color: root.color
        size: root.iconSize
        x: root.vertical ? (root.width - width) / 2 : root.iconSize + 4
        y: root.vertical ? root.iconSize + 2 : (root.height - height) / 2
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => mouse.button === Qt.MiddleButton ? Idle.setCaffeine(!Idle.caffeine, 0) : ShellState.pinCard(root)
    }

    readonly property bool panelOpen: false

    function togglePanel(): void {
        ShellState.pinCard(root);
    }
}
