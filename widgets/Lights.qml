import QtQuick
import Quickshell
import qs.components
import qs.dashboard.modules
import qs.i18n
import qs.services

// Philips Hue: a bulb and the rooms on. Click (or Super+U): the lights
// drawer (rooms, the selected room, its lights), the Hue module at
// pointer sizes. Hidden without huectl.
TextWidget {
    id: root

    // Right-click menu (the bar's widget menu).
    readonly property var contextActions: HueBridge.roomsOn > 0 ? [{ id: "allOff", icon: "power_settings_new", text: I18n.tr("hue.allOff") }] : []
    function contextAction(id: string): void {
        if (id === "allOff")
            HueBridge.allOff();
    }

    readonly property bool shown: HueBridge.available

    fullText: HueBridge.roomsOn > 0 ? I18n.tr("bar.lightsOn", { n: HueBridge.roomsOn }) : I18n.tr("bar.lightsOff")
    compactText: `${HueBridge.roomsOn}`
    color: HueBridge.roomsOn > 0 ? theme.color.ink : theme.color.soft

    icon: "lightbulb"
    iconFilled: HueBridge.roomsOn > 0
    iconText: size === "compact" || HueBridge.roomsOn === 0 ? "" : `${HueBridge.roomsOn}`

    // The state for the count, without keeping the drawer's refresh on.
    Component.onCompleted: HueBridge.refresh()

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.toggle()
    }

    readonly property bool panelOpen: popup.visible

    function togglePanel(): void {
        popup.toggle();
    }

    BarPopup {
        id: popup
        anchorItem: root

        Loader {
            width: 780
            height: 470
            active: popup.visible

            sourceComponent: Hue {
                drawer: true
                framed: false
                options: ({ type: "hue" })
            }
        }
    }
}
