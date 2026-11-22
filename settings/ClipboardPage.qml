import QtQuick
import Quickshell
import qs.clipboard
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Clipboard manager: recording and retention, where it shows, paste,
// privacy, tags, keys.
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property var conf: Clipboard.config

    // "Clear everything" asks for a second click.
    property bool confirmAll: false

    spacing: theme.space.s

    function list(text: string): var {
        return text.split(",").map(s => s.trim()).filter(s => s);
    }

    Section {
        title: I18n.tr("settings.clipHistory")

        Field {
            label: I18n.tr("settings.clipEnabled")
            hint: I18n.tr("settings.clipEnabledHint")
            Switch {
                width: 60
                checked: Clipboard.enabled
                onToggled: Config.set("clipboard.enabled", !checked)
            }
        }

        Field {
            label: I18n.tr("settings.clipPause")
            hint: I18n.tr("settings.clipPauseHint")
            Switch {
                width: 60
                checked: Clipboard.paused
                available: Clipboard.enabled
                onToggled: Clipboard.setPaused(!checked)
            }
        }

        Field {
            label: I18n.tr("settings.clipMaxItems")
            hint: I18n.tr("settings.clipMaxItemsHint")
            Choice {
                model: [100, 250, 500, 1000, 2500].map(v => ({ value: v, label: I18n.number(v, 0) }))
                value: Clipboard.maxItems
                onPicked: value => Config.set("clipboard.maxItems", value)
            }
        }

        Field {
            label: I18n.tr("settings.clipMaxDays")
            Choice {
                model: [1, 7, 30, 90, 0].map(v => ({ value: v, label: v === 0 ? I18n.tr("settings.clipForever") : I18n.plural("settings.clipDays", v) }))
                value: Clipboard.maxDays
                onPicked: value => Config.set("clipboard.maxDays", value)
            }
        }

        Field {
            label: I18n.tr("settings.clipKeepTagged")
            hint: I18n.tr("settings.clipKeepTaggedHint")
            Switch {
                width: 60
                checked: Clipboard.keepTagged
                onToggled: Config.set("clipboard.keepTagged", !checked)
            }
        }

        Field {
            label: I18n.tr("settings.clipImages")
            hint: I18n.tr("settings.clipImagesHint")
            Row {
                spacing: root.theme.space.m

                Choice {
                    visible: Clipboard.images
                    model: [5, 20, 50].map(v => ({ value: v, label: `${v} Mo` }))
                    value: Clipboard.maxImageMB
                    onPicked: value => Config.set("clipboard.maxImageMB", value)
                }

                Switch {
                    width: 60
                    anchors.verticalCenter: parent.verticalCenter
                    checked: Clipboard.images
                    onToggled: Config.set("clipboard.images", !checked)
                }
            }
        }

        Field {
            label: I18n.tr("settings.clipStored")
            hint: I18n.tr("settings.clipStoredHint", { n: Clipboard.count, pinned: Clipboard.pinnedCount, dir: Clipboard.dir })
            Row {
                spacing: root.theme.space.s

                Button {
                    icon: "delete"
                    text: I18n.tr("settings.clipClear")
                    onClicked: Clipboard.clear(false)
                }

                Button {
                    icon: "delete"
                    text: root.confirmAll ? I18n.tr("settings.clipClearAllConfirm") : I18n.tr("settings.clipClearAll")
                    primary: root.confirmAll
                    onClicked: {
                        if (root.confirmAll) {
                            Clipboard.clear(true);
                            root.confirmAll = false;
                        } else {
                            root.confirmAll = true;
                            disarm.restart();
                        }
                    }

                    Timer {
                        id: disarm
                        interval: 4000
                        onTriggered: root.confirmAll = false
                    }
                }
            }
        }
    }

    Section {
        title: I18n.tr("settings.clipLook")

        Field {
            label: I18n.tr("settings.clipPosition")
            hint: I18n.tr(`settings.clipPosition.${Clipboard.position}Hint`)

            Column {
                spacing: root.theme.space.s

                // Where the manager shows, on a small screen.
                Rectangle {
                    anchors.right: parent.right
                    width: 180
                    height: 104
                    radius: Math.min(root.theme.radius.control, 10)
                    color: root.theme.color.surface
                    border.width: 1
                    border.color: root.theme.color.line

                    Rectangle {
                        readonly property string p: Clipboard.position
                        x: p === "right" ? parent.width - width - 6 : p === "center" ? 30 : p === "pointer" ? 96 : 6
                        y: p === "bottom" ? parent.height - height - 6 : p === "center" ? 20 : p === "pointer" ? 40 : 6
                        width: p === "top" || p === "bottom" ? parent.width - 12 : p === "center" ? parent.width - 60 : p === "pointer" ? 44 : 40
                        height: p === "top" || p === "bottom" ? 30 : p === "center" ? parent.height - 40 : p === "pointer" ? 54 : parent.height - 12
                        radius: 4
                        color: root.theme.color.accent

                        Behavior on x {
                            NumberAnimation {
                                duration: root.theme.motion.duration
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on y {
                            NumberAnimation {
                                duration: root.theme.motion.duration
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on width {
                            NumberAnimation {
                                duration: root.theme.motion.duration
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on height {
                            NumberAnimation {
                                duration: root.theme.motion.duration
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    // Mouse pointer.
                    Icon {
                        visible: Clipboard.position === "pointer"
                        x: 88
                        y: 26
                        name: "mouse"
                        size: 14
                        color: root.theme.color.ink
                    }
                }

                Choice {
                    model: ["bottom", "top", "left", "right", "center", "pointer"].map(v => ({ value: v, label: I18n.tr(`settings.clipPosition.${v}`) }))
                    value: Clipboard.position
                    onPicked: value => Config.set("clipboard.position", value)
                }
            }
        }

        Field {
            label: I18n.tr("settings.clipCardSize")
            Choice {
                model: ["s", "m", "l"].map(v => ({ value: v, label: I18n.tr(`settings.clipCardSize.${v}`) }))
                value: root.conf.cardSize ?? "m"
                onPicked: value => Config.set("clipboard.cardSize", value)
            }
        }

        Field {
            label: I18n.tr("settings.clipDim")
            Switch {
                width: 60
                checked: root.conf.dim ?? true
                onToggled: Config.set("clipboard.dim", !checked)
            }
        }

        Field {
            label: I18n.tr("settings.clipOpen")
            hint: I18n.tr("settings.clipOpenHint")
            Button {
                icon: "content_paste"
                text: I18n.tr("settings.clipOpenButton")
                onClicked: {
                    Settings.opened = false;
                    Clipboard.open();
                }
            }
        }
    }

    Section {
        title: I18n.tr("settings.clipPaste")

        Field {
            label: I18n.tr("settings.clipPasteOnEnter")
            hint: I18n.tr("settings.clipPasteOnEnterHint")
            Switch {
                width: 60
                checked: Clipboard.pasteOnEnter
                onToggled: Config.set("clipboard.pasteOnEnter", !checked)
            }
        }

        Field {
            label: I18n.tr("settings.clipTerminals")
            hint: I18n.tr("settings.clipTerminalsHint")
            TextField {
                width: 300
                text: (root.conf.terminals ?? []).join(", ")
                onCommitted: text => Config.set("clipboard.terminals", root.list(text))
            }
        }
    }

    Section {
        title: I18n.tr("settings.clipPrivacy")

        Field {
            label: I18n.tr("settings.clipSensitive")
            hint: I18n.tr("settings.clipSensitiveHint")
            Switch {
                width: 60
                checked: Clipboard.ignoreSensitive
                onToggled: Config.set("clipboard.ignoreSensitive", !checked)
            }
        }

        Field {
            label: I18n.tr("settings.clipIgnoreApps")
            hint: I18n.tr("settings.clipIgnoreAppsHint")
            TextField {
                width: 300
                text: (root.conf.ignoreApps ?? []).join(", ")
                onCommitted: text => Config.set("clipboard.ignoreApps", root.list(text))
            }
        }
    }

    Section {
        title: I18n.tr("settings.clipTags")

        ThemedText {
            width: parent.width
            visible: !Clipboard.tags.length
            wrapMode: Text.Wrap
            text: I18n.tr("settings.clipNoTags")
            color: root.theme.color.soft
        }

        Repeater {
            model: Clipboard.tags

            Item {
                id: tagRow

                required property var modelData
                required property int index
                readonly property int uses: Clipboard.items.filter(i => (i.tags ?? []).includes(modelData.id)).length

                width: parent.width
                height: Math.max(root.theme.hit, 36)

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.theme.space.s

                    TextField {
                        width: 200
                        text: tagRow.modelData.name
                        onCommitted: text => {
                            if (text.trim())
                                Clipboard.updateTag(tagRow.modelData.id, { name: text.trim() });
                        }
                    }

                    // Color: one of the fixed swatches.
                    Repeater {
                        model: Clipboard.tagColorNames

                        Rectangle {
                            required property string modelData
                            readonly property bool chosen: tagRow.modelData.color === modelData
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            height: 18
                            radius: 9
                            color: Clipboard.tagColors[modelData]
                            border.width: chosen ? 2 : 0
                            border.color: root.theme.color.ink

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -2
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Clipboard.updateTag(tagRow.modelData.id, { color: parent.modelData })
                            }
                        }
                    }

                    ThemedText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: I18n.plural("settings.clipTagUses", tagRow.uses)
                        color: root.theme.color.soft
                        font.pixelSize: root.theme.font.sizeS
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.theme.space.xs

                    Button {
                        icon: "expand_more"
                        rotation: 180
                        enabled: tagRow.index > 0
                        onClicked: Clipboard.moveTag(tagRow.modelData.id, -1)
                    }

                    Button {
                        icon: "expand_more"
                        enabled: tagRow.index < Clipboard.tags.length - 1
                        onClicked: Clipboard.moveTag(tagRow.modelData.id, 1)
                    }

                    Button {
                        icon: "delete"
                        onClicked: Clipboard.deleteTag(tagRow.modelData.id)
                    }
                }
            }
        }

        Field {
            label: I18n.tr("settings.clipNewTag")
            hint: I18n.tr("settings.clipNewTagHint")
            TextField {
                id: newTag
                width: 200
                placeholder: I18n.tr("clip.tagName")
                onCommitted: text => {
                    if (text.trim()) {
                        Clipboard.createTag(text, "");
                        // Back to empty (the field only follows `text` changes).
                        newTag.text = " ";
                        newTag.text = "";
                    }
                }
            }
        }
    }

    Section {
        title: I18n.tr("settings.clipKeys")

        Repeater {
            model: ["enter", "shiftEnter", "ctrlEnter", "number", "pin", "tags", "delete", "preview", "boards", "kinds", "menu", "pause"]

            Item {
                required property string modelData
                width: parent.width
                height: 26

                ThemedText {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 180
                    text: I18n.tr(`settings.clipKey.${parent.modelData}`)
                    font.family: root.theme.font.mono
                    font.pixelSize: root.theme.font.sizeS
                }

                ThemedText {
                    x: 190
                    width: parent.width - x
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    text: I18n.tr(`settings.clipKey.${parent.modelData}Hint`)
                    color: root.theme.color.soft
                }
            }
        }
    }
}
