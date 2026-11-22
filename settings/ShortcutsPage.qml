import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// lc-shell's Hyprland global shortcuts (Shortcuts.qml), with a ready Lua
// line to paste in the Hyprland config. The keys bound today can't be
// shown: in a Lua config Hyprland reports binds with an opaque id.
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    // name, suggested keys
    readonly property var shortcuts: [
        { name: "launcher", keys: "SUPER + Space" },
        { name: "emoji", keys: "SUPER + period" },
        { name: "clipboard", keys: "SUPER + SHIFT + V" },
        { name: "clipboardIncognito", keys: "SUPER + CTRL + SHIFT + V" },
        { name: "files", keys: "SUPER + SHIFT + F" },
        { name: "screenshot", keys: "Print" },
        { name: "screenshotScreen", keys: "SHIFT + Print" },
        { name: "notifications", keys: "SUPER + S" },
        { name: "media", keys: "SUPER + comma" },
        { name: "settings", keys: "SUPER + I" },
        { name: "editBar", keys: "SUPER + ALT + E" },
        { name: "clearNotifs", keys: "SUPER + SHIFT + N" },
        { name: "dnd", keys: "SUPER + CTRL + N" },
        { name: "toggleVariant", keys: "SUPER + SHIFT + T" },
        { name: "nextTheme", keys: "SUPER + CTRL + T" },
        { name: "lock", keys: "SUPER + Escape" }
    ]
    property string copied: ""

    function line(s: var): string {
        return `hl.bind("${s.keys}", hl.dsp.global("lc:${s.name}"))`;
    }

    spacing: theme.space.s

    Section {
        title: I18n.tr("settings.shortcutsTitle")

        ThemedText {
            width: parent.width
            wrapMode: Text.Wrap
            text: I18n.tr("settings.shortcutsIntro")
            color: root.theme.color.soft
        }

        Repeater {
            model: root.shortcuts

            Field {
                id: field

                required property var modelData
                label: I18n.tr(`shortcut.${modelData.name}`)
                hint: root.line(modelData)

                Button {
                    icon: root.copied === field.modelData.name ? "check" : "content_copy"
                    text: root.copied === field.modelData.name ? I18n.tr("settings.copied") : I18n.tr("settings.copyLua")
                    onClicked: {
                        Quickshell.execDetached(["wl-copy", root.line(field.modelData)]);
                        root.copied = field.modelData.name;
                        copiedReset.restart();
                    }
                }
            }
        }
    }

    Timer {
        id: copiedReset
        interval: 2000
        onTriggered: root.copied = ""
    }
}
