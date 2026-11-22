import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Screenshots: where they're saved, what Enter does, the editor's
// helpers, keys.
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    spacing: theme.space.s

    Section {
        title: I18n.tr("settings.shotSaving")

        Field {
            label: I18n.tr("settings.shotDir")
            hint: I18n.tr("settings.shotDirHint")
            TextField {
                width: 300
                text: Screenshot.dir
                placeholder: "~/Images/Screenshots"
                onCommitted: text => Config.set("screenshot.dir", text.trim())
            }
        }

        Field {
            label: I18n.tr("settings.shotFileName")
            hint: I18n.tr("settings.shotFileNameHint")
            TextField {
                width: 300
                text: Screenshot.fileName
                onCommitted: text => Config.set("screenshot.fileName", text.trim())
            }
        }

        Field {
            label: I18n.tr("settings.shotEnter")
            Choice {
                model: ["copy", "save", "both"].map(v => ({ value: v, label: I18n.tr(`settings.shotEnter${v[0].toUpperCase()}${v.slice(1)}`) }))
                value: Screenshot.enterAction
                onPicked: value => Config.set("screenshot.enterAction", value)
            }
        }

        Field {
            label: I18n.tr("settings.shotCopyOnSave")
            hint: I18n.tr("settings.shotCopyOnSaveHint")
            Switch {
                width: 60
                checked: Screenshot.copyOnSave
                onToggled: Config.set("screenshot.copyOnSave", !checked)
            }
        }

        Field {
            label: I18n.tr("settings.shotNotify")
            hint: I18n.tr("settings.shotNotifyHint")
            Switch {
                width: 60
                checked: Screenshot.notify
                onToggled: Config.set("screenshot.notify", !checked)
            }
        }
    }

    Section {
        title: I18n.tr("settings.shotEditor")

        Field {
            label: I18n.tr("settings.shotPickWindows")
            hint: I18n.tr("settings.shotPickWindowsHint")
            Switch {
                width: 60
                checked: Screenshot.pickWindows
                onToggled: Config.set("screenshot.pickWindows", !checked)
            }
        }

        Field {
            label: I18n.tr("settings.shotMagnifier")
            hint: I18n.tr("settings.shotMagnifierHint")
            Switch {
                width: 60
                checked: Screenshot.magnifier
                onToggled: Config.set("screenshot.magnifier", !checked)
            }
        }

        Field {
            label: I18n.tr("shortcut.screenshot")
            Button {
                icon: "screenshot_region"
                text: I18n.tr("settings.shotTry")
                onClicked: Screenshot.region()
            }
        }
    }

    Section {
        title: I18n.tr("settings.shotKeys")

        Repeater {
            model: [
                { keys: I18n.tr("settings.shotKey.enter"), hint: "enterHint" },
                { keys: "Ctrl+C", hint: "copyHint" },
                { keys: "Ctrl+S", hint: "saveHint" },
                { keys: "Ctrl+Z · Ctrl+Shift+Z", hint: "undoHint" },
                { keys: "V P H L A R E T N M", hint: "toolsHint" },
                { keys: "1 … 8", hint: "colorsHint" },
                { keys: "[ ]", hint: "strokeHint" },
                { keys: "F", hint: "fillHint" },
                { keys: "Ctrl+A", hint: "allHint" },
                { keys: "← ↑ → ↓", hint: "arrowsHint" },
                { keys: "Shift", hint: "shiftHint" },
                { keys: I18n.tr("shot.escape"), hint: "escapeHint" },
                { keys: I18n.tr("settings.shotKey.right"), hint: "rightHint" }
            ]

            Item {
                required property var modelData
                width: parent.width
                height: 26

                ThemedText {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 180
                    text: parent.modelData.keys
                    font.family: root.theme.font.mono
                    font.pixelSize: root.theme.font.sizeS
                }

                ThemedText {
                    x: 190
                    width: parent.width - x
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    text: I18n.tr(`settings.shotKey.${parent.modelData.hint}`)
                    color: root.theme.color.soft
                }
            }
        }
    }
}
