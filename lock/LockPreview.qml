import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.i18n
import qs.theme

// The lock screen in a regular window: check its look and the PAM
// password check without locking anything.
FloatingWindow {
    id: win

    property var theme: Themes.resolve(Themes.themeFor("normal"), false, "normal")

    title: `lc-shell · ${I18n.tr("lock.previewTitle")}`
    implicitWidth: 1280
    implicitHeight: 800
    color: theme.color.bg

    onVisibleChanged: {
        if (!visible)
            Lock.previewing = false;
        else
            floatIt.restart();
    }

    Timer {
        id: floatIt
        interval: 150
        onTriggered: {
            const target = `window = "title:^lc-shell · "`;
            Hyprland.dispatch(`hl.dsp.window.float({ action = "set", ${target} })`);
            Hyprland.dispatch(`hl.dsp.window.resize({ x = ${win.implicitWidth}, y = ${win.implicitHeight}, ${target} })`);
            Hyprland.dispatch(`hl.dsp.window.center({ ${target} })`);
        }
    }

    LockContent {
        anchors.fill: parent
        screen: win.screen
        preview: true
    }
}
