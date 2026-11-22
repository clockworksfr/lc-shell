import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Count, do-not-disturb, the 3 latest (grouped by app), clear all.
Column {
    id: root

    property var block
    property ShellScreen screen
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    // The notifications' language (as their cards): mono capitals label
    // (Matrix: a red dot), spaced capitals (Constellation).
    readonly property string look: theme.style.module ?? "classic"
    readonly property bool capsLabel: look !== "classic"

    // Latest per app, with how many that app sent: [{ entry, count }]
    readonly property var groups: {
        const out = [];
        for (const entry of NotificationCenter.history) {
            const group = out.find(g => g.entry.appName === entry.appName);
            if (group)
                group.count++;
            else
                out.push({ entry: entry, count: 1 });
        }
        return out.slice(0, 3);
    }

    spacing: theme.space.s

    Switch {
        text: `${I18n.tr("notif.title")} · ${NotificationCenter.count}`
        checked: !NotificationCenter.dnd
        onToggled: NotificationCenter.setDnd(checked)
    }

    ThemedText {
        visible: NotificationCenter.dnd
        text: I18n.tr("notif.dnd")
        color: root.theme.color.warn
        font.pixelSize: root.theme.font.sizeS
    }

    ThemedText {
        visible: NotificationCenter.count === 0
        text: I18n.tr("notif.empty")
        color: root.theme.color.soft
    }

    Repeater {
        model: root.groups

        Rectangle {
            required property var modelData

            width: root.width
            implicitHeight: texts.implicitHeight + root.theme.space.s * 2
            radius: root.look === "matrix" ? 16 : root.theme.radius.control
            color: root.look === "constellation" ? Qt.alpha(root.theme.color.accent, 0.08) : root.theme.color.surface2
            border.width: root.look === "matrix" ? 1 : 0
            border.color: root.theme.color.line

            Column {
                id: texts

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: root.theme.space.s

                Row {
                    width: parent.width
                    spacing: 6

                    Rectangle {
                        visible: root.look === "matrix"
                        anchors.verticalCenter: parent.verticalCenter
                        width: 7
                        height: 7
                        radius: 3.5
                        color: root.theme.color.signal ?? root.theme.color.urgent
                    }

                    ThemedText {
                        width: parent.width - (root.look === "matrix" ? 13 : 0)
                        text: [parent.parent.parent.modelData.entry.appName, parent.parent.parent.modelData.count > 1 ? `×${parent.parent.parent.modelData.count}` : "", I18n.relativeTime(parent.parent.parent.modelData.entry.time)].filter(s => !!s).join(" · ")
                        color: root.theme.color.soft
                        font.family: root.capsLabel && root.look !== "constellation" ? root.theme.font.mono : root.theme.font.family
                        font.capitalization: root.capsLabel ? Font.AllUppercase : Font.MixedCase
                        font.letterSpacing: root.look === "constellation" ? 1.4 : root.capsLabel ? 0.5 : 0
                        font.pixelSize: root.theme.font.sizeS
                        elide: Text.ElideRight
                    }
                }

                ThemedText {
                    width: parent.width
                    text: parent.parent.modelData.entry.summary
                    elide: Text.ElideRight
                }
            }
        }
    }

    ListRow {
        visible: NotificationCenter.count > 0
        title: I18n.tr("notif.clear")
        onClicked: NotificationCenter.clearAll()
    }
}
