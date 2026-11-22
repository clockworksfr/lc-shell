import QtQuick
import Quickshell
import qs.i18n
import qs.theme

// The lock screen in a regular window: check its look and the PAM
// password check without locking anything.
FloatingWindow {
    id: win

    property var theme: Themes.resolve(Themes.themeFor("normal"), false)

    title: I18n.tr("lock.previewTitle")
    implicitWidth: 1280
    implicitHeight: 800
    color: theme.color.bg

    onVisibleChanged: if (!visible) Lock.previewing = false

    LockContent {
        anchors.fill: parent
        screen: win.screen
        preview: true
    }
}
