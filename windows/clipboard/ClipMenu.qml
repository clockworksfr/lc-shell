import QtQuick
import qs.clipboard
import qs.components
import qs.i18n

// Actions of one item (right click, Menu key, Ctrl+T for its tags):
// paste, copy, paste as text, preview, open, pin, tags (checkable, new
// tag inline), delete. Keyboard: Up/Down, Enter or Space, Escape.
Item {
    id: root

    property var theme
    property size bounds
    property var entry: null
    property int index: 0

    signal picked(string action, var entry)
    signal closed

    readonly property var rows: {
        if (!entry)
            return [];
        const out = [
            { type: "action", id: "paste", icon: "content_paste", text: I18n.tr("clip.paste") },
            { type: "action", id: "copy", icon: "content_copy", text: I18n.tr("clip.copy") }
        ];
        if (entry.kind === "file")
            out.push({ type: "action", id: "text", icon: "notes", text: I18n.tr("clip.pasteText") });
        out.push({ type: "action", id: "preview", icon: "open_in_full", text: I18n.tr("clip.preview") });
        if (["link", "file", "image"].includes(entry.kind))
            out.push({ type: "action", id: "open", icon: "open_in_new", text: I18n.tr("clip.open") });
        out.push({ type: "action", id: "pin", icon: "push_pin", text: I18n.tr(entry.pinned ? "clip.unpin" : "clip.pin") });
        out.push({ type: "label", text: I18n.tr("clip.tags") });
        for (const t of Clipboard.tags)
            out.push({ type: "tag", tag: t });
        out.push({ type: "newTag" });
        out.push({ type: "action", id: "delete", icon: "delete", text: I18n.tr("clip.delete"), danger: true });
        return out;
    }
    readonly property var live: entry ? (Clipboard.item(entry.id) ?? entry) : null

    visible: false
    z: 10
    x: 0
    y: 0
    width: frame.width
    height: frame.height

    function openFor(item: var, px: real, py: real, focusTags: bool): void {
        entry = item;
        index = 0;
        if (focusTags) {
            const first = rows.findIndex(r => r.type === "tag" || r.type === "newTag");
            index = Math.max(0, first);
        }
        x = Math.max(8, Math.min(px, bounds.width - frame.width - 8));
        y = Math.max(8, Math.min(py, bounds.height - frame.height - 8));
        visible = true;
    }

    function close(): void {
        if (!visible)
            return;
        visible = false;
        naming.editing = false;
        closed();
    }

    function selectable(i: int): bool {
        return rows[i] && rows[i].type !== "label";
    }

    function move(delta: int): void {
        let i = index;
        for (let n = 0; n < rows.length; n++) {
            i = (i + delta + rows.length) % rows.length;
            if (selectable(i)) {
                index = i;
                return;
            }
        }
    }

    function trigger(i: int): void {
        const row = rows[i];
        if (!row)
            return;
        if (row.type === "tag") {
            Clipboard.toggleTag(entry.id, row.tag.id);
        } else if (row.type === "newTag") {
            naming.editing = true;
            naming.forceActiveFocus();
        } else if (row.type === "action") {
            const e = live;
            const keepOpen = row.id === "pin";
            if (!keepOpen)
                close();
            picked(row.id, e);
        }
    }

    function handle(event: var): void {
        switch (event.key) {
        case Qt.Key_Escape:
            close();
            break;
        case Qt.Key_Up:
        case Qt.Key_Backtab:
            move(-1);
            break;
        case Qt.Key_Down:
        case Qt.Key_Tab:
            move(1);
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
        case Qt.Key_Space:
            trigger(index);
            break;
        case Qt.Key_Menu:
            close();
            break;
        }
    }

    Rectangle {
        id: frame

        width: 240
        height: column.implicitHeight + root.theme.space.xs * 2
        radius: root.theme.radius.control + 4
        color: root.theme.color.surface
        border.width: 1
        border.color: root.theme.color.line

        // Clicks inside don't close it.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: column

            x: root.theme.space.xs
            y: root.theme.space.xs
            width: parent.width - root.theme.space.xs * 2

            Repeater {
                model: root.rows

                Rectangle {
                    id: row

                    required property var modelData
                    required property int index
                    readonly property bool current: root.index === index && modelData.type !== "label"
                    readonly property bool checked: modelData.type === "tag" && (root.live?.tags ?? []).includes(modelData.tag.id)

                    width: column.width
                    height: modelData.type === "label" ? 26 : 32
                    radius: root.theme.radius.control
                    color: current ? Qt.alpha(root.theme.color.accent, 0.16) : "transparent"

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: root.theme.space.s
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: root.theme.space.s
                        visible: row.modelData.type !== "newTag" || !naming.editing

                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: row.modelData.type === "action" || row.modelData.type === "newTag"
                            name: row.modelData.type === "newTag" ? "new_label" : (row.modelData.icon ?? "")
                            filled: row.modelData.id === "pin" && !!root.live?.pinned
                            size: 18
                            color: row.modelData.danger ? root.theme.color.urgent : root.theme.color.ink
                        }

                        // Tag: its color, filled when the item has it.
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: row.modelData.type === "tag"
                            width: 14
                            height: 14
                            radius: 7
                            color: row.checked ? (Clipboard.tagColors[row.modelData.tag?.color] ?? root.theme.color.soft) : "transparent"
                            border.width: 2
                            border.color: Clipboard.tagColors[row.modelData.tag?.color] ?? root.theme.color.soft

                            Icon {
                                anchors.centerIn: parent
                                visible: row.checked
                                name: "check"
                                size: 12
                                color: "#FFFFFF"
                            }
                        }

                        ThemedText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.type === "tag" ? row.modelData.tag.name : row.modelData.type === "newTag" ? I18n.tr("clip.newTag") : row.modelData.text
                            label: row.modelData.type === "label"
                            color: row.modelData.type === "label" ? root.theme.color.soft : row.modelData.danger ? root.theme.color.urgent : root.theme.color.ink
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: row.modelData.type !== "label"
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.index = row.index
                        onClicked: root.trigger(row.index)
                    }

                    // New tag name, typed in place.
                    TextInput {
                        id: field

                        visible: row.modelData.type === "newTag" && naming.editing
                        anchors.fill: parent
                        anchors.leftMargin: root.theme.space.s
                        anchors.rightMargin: root.theme.space.s
                        verticalAlignment: TextInput.AlignVCenter
                        color: root.theme.color.ink
                        font.family: root.theme.font.family
                        font.pixelSize: root.theme.font.sizeM
                        clip: true

                        Component.onCompleted: if (row.modelData.type === "newTag") naming.field = field

                        ThemedText {
                            visible: !field.text
                            anchors.verticalCenter: parent.verticalCenter
                            text: I18n.tr("clip.tagName")
                            color: root.theme.color.soft
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                const id = Clipboard.createTag(text, "");
                                if (id && !(root.live?.tags ?? []).includes(id))
                                    Clipboard.toggleTag(root.entry.id, id);
                                text = "";
                                naming.editing = false;
                                root.close();
                            } else if (event.key === Qt.Key_Escape) {
                                text = "";
                                naming.editing = false;
                                root.close();
                            } else {
                                return;
                            }
                            event.accepted = true;
                        }
                    }
                }
            }
        }
    }

    // State of the inline "new tag" field.
    QtObject {
        id: naming

        property bool editing: false
        property var field: null

        function forceActiveFocus(): void {
            field?.forceActiveFocus();
        }
    }
}
