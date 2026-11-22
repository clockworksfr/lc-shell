import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.panels
import qs.services

// Output volume. Left click: audio panel (volume, devices),
// middle click: mute, wheel: volume.
TextBlock {
    id: root

    fullText: Audio.muted ? I18n.tr("common.muted")
        : size === "compact" ? I18n.percent(Audio.volume)
        : size === "extended" ? `${Audio.sinkName} · ${I18n.percent(Audio.volume)}`
        : I18n.tr("bar.volume", { value: Math.round(Audio.volume * 100) })
    compactText: Audio.muted ? I18n.tr("common.muted") : I18n.tr("bar.v.volume", { value: Math.round(Audio.volume * 100) })
    color: Audio.muted ? theme.color.soft : theme.color.ink

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton)
                Audio.toggleMute();
            else
                popup.toggle();
        }
        onWheel: wheel => wheel.angleDelta.y > 0 ? Audio.increment() : Audio.decrement()
    }

    readonly property bool panelOpen: popup.visible

    function togglePanel(): void {
        popup.toggle();
    }

    BarPopup {
        id: popup
        anchorItem: root

        AudioPanel {}
    }
}
