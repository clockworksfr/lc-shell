import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.clipboard
import qs.components
import qs.i18n
import qs.launcher
import qs.settings
import qs.theme

// Clipboard manager on the focused screen (Super+Shift+V, lc:clipboard).
// Where it shows: `clipboard.position`
//   bottom | top     a strip of cards along the edge (Paste-like)
//   left | right     a column of cards along the edge
//   center           a list and a large preview
//   pointer          a compact column at the mouse pointer
// Boards: all, pinned, one per tag; kind filter; search.
// Keys: arrows, Enter (paste or copy, `clipboard.pasteOnEnter`),
// Shift+Enter (the other one), Ctrl+Enter (paste file paths as text),
// Ctrl+1…9, Ctrl+P (pin), Ctrl+T (tags), Delete, Space (preview, empty
// search), Tab / Shift+Tab (boards), Ctrl+Tab (kinds), Menu (actions),
// Escape (preview, menu, search, then close).
PanelWindow {
    id: win

    property var theme: Themes.fallback
    // Room taken by the bar / frame on each edge.
    property var edgeOffsets: ({ top: 0, bottom: 0, left: 0, right: 0 })

    readonly property string position: ["bottom", "top", "left", "right", "center", "pointer"].includes(Clipboard.position) ? Clipboard.position : "bottom"
    readonly property bool strip: position === "bottom" || position === "top"
    readonly property bool centered: position === "center"
    readonly property bool compact: !strip
    readonly property int gap: theme.space.s
    readonly property int margin: theme.space.m
    readonly property string cardSize: Clipboard.config.cardSize ?? "m"
    readonly property int stripCard: cardSize === "s" ? 180 : cardSize === "l" ? 290 : 230
    readonly property int columnCard: cardSize === "s" ? 110 : cardSize === "l" ? 200 : 150

    // --- Filters ---
    property string query
    // "all" | "pinned" | tag id
    property string board: "all"
    // "all" | kind
    property string kind: "all"

    readonly property var boards: ["all", "pinned", ...Clipboard.tags.map(t => t.id)]
    readonly property var kinds: ["all", ...ClipKinds.kinds]

    readonly property var results: {
        const words = Search.normalize(query.trim()).split(/\s+/).filter(w => w);
        return Clipboard.items.filter(e => {
            if (board === "pinned" && !e.pinned)
                return false;
            if (board !== "all" && board !== "pinned" && !(e.tags ?? []).includes(board))
                return false;
            if (kind !== "all" && e.kind !== kind)
                return false;
            if (!words.length)
                return true;
            const hay = Search.normalize(`${e.text ?? ""} ${e.app ?? ""} ${(e.tags ?? []).map(t => Clipboard.tag(t)?.name ?? "").join(" ")} ${I18n.tr(`clip.kind.${e.kind}`)}`);
            return words.every(w => hay.includes(w));
        });
    }
    readonly property var currentEntry: results[list.currentIndex] ?? null
    // Kept across result changes (pin, tag, delete keep the selection).
    property string currentId

    onResultsChanged: {
        const index = results.findIndex(e => e.id === currentId);
        list.currentIndex = index >= 0 ? index : Math.min(Math.max(0, list.currentIndex), results.length - 1);
    }

    // Deleting a pinned or tagged item asks for a second Delete.
    property string confirmDelete

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lc-clipboard"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    function activate(entry: var, mode: string): void {
        if (!entry)
            return;
        // mode: "enter" (setting), "alt" (the other one), "text", "copy", "paste"
        let paste = mode === "paste" || mode === "text" || (mode === "enter" && Clipboard.pasteOnEnter) || (mode === "alt" && !Clipboard.pasteOnEnter);
        Clipboard.close();
        Clipboard.copy(entry.id, mode === "text", paste);
    }

    // `reveal`: scrolls it into view (keyboard; not on hover, which would
    // scroll the list under the pointer).
    function select(index: int, reveal: bool): void {
        if (index < 0 || index >= results.length)
            return;
        list.currentIndex = index;
        currentId = results[index].id;
        confirmDelete = "";
        if (reveal)
            list.positionViewAtIndex(index, ListView.Contain);
    }

    function cycle(values: var, value: string, delta: int): string {
        const i = values.indexOf(value);
        return values[(Math.max(0, i) + delta + values.length) % values.length];
    }

    // `force`: no second Delete for pinned or tagged items (menu).
    function remove(entry: var, force: bool): void {
        if (!entry)
            return;
        if (!force && (entry.pinned || (entry.tags ?? []).length) && confirmDelete !== entry.id) {
            confirmDelete = entry.id;
            return;
        }
        confirmDelete = "";
        if (entry.id === currentEntry?.id) {
            const next = results[list.currentIndex + 1] ?? results[list.currentIndex - 1];
            currentId = next?.id ?? "";
        }
        Clipboard.remove(entry.id);
    }

    function openMenu(entry: var, item: Item, x: real, y: real, focusTags: bool): void {
        if (!entry)
            return;
        const p = item.mapToItem(win.contentItem, x, y);
        menu.openFor(entry, p.x, p.y, focusTags);
    }

    function openMenuForCurrent(focusTags: bool): void {
        const item = list.currentItem;
        if (item)
            openMenu(currentEntry, item, item.width / 2, item.height / 3, focusTags);
    }

    // --- Pointer position (position: pointer) ---
    property point pointer: Qt.point(-1, -1)

    Process {
        running: win.position === "pointer"
        command: ["hyprctl", "cursorpos"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split(",").map(s => parseInt(s));
                if (parts.length === 2 && !isNaN(parts[0]))
                    win.pointer = Qt.point(parts[0] - (win.screen?.x ?? 0), parts[1] - (win.screen?.y ?? 0));
                else
                    win.pointer = Qt.point(win.width / 2, win.height / 3);
            }
        }
    }

    // Backdrop: click outside closes.
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: (Clipboard.config.dim ?? true) ? 0.18 : 0

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: Clipboard.close()
        }
    }

    Rectangle {
        id: panel

        readonly property int pad: win.theme.space.m
        readonly property int availableW: win.width - win.edgeOffsets.left - win.edgeOffsets.right - win.margin * 2
        readonly property int availableH: win.height - win.edgeOffsets.top - win.edgeOffsets.bottom - win.margin * 2

        width: win.strip ? availableW : win.centered ? Math.min(1080, availableW) : Math.min(win.position === "pointer" ? 400 : 380, availableW)
        height: win.strip ? header.height + win.stripCard + pad * 3 : win.centered ? Math.min(680, availableH) : win.position === "pointer" ? Math.min(600, availableH) : availableH
        x: {
            const left = win.edgeOffsets.left + win.margin;
            switch (win.position) {
            case "right":
                return win.width - win.edgeOffsets.right - win.margin - width;
            case "center":
                return left + (panel.availableW - width) / 2;
            case "pointer":
                return Math.max(left, Math.min(win.pointer.x - width / 2, win.width - win.edgeOffsets.right - win.margin - width));
            default:
                return left;
            }
        }
        y: {
            const top = win.edgeOffsets.top + win.margin;
            switch (win.position) {
            case "bottom":
                return win.height - win.edgeOffsets.bottom - win.margin - height;
            case "center":
                return top + (panel.availableH - height) / 2;
            case "pointer":
                return Math.max(top, Math.min(win.pointer.y + 12, win.height - win.edgeOffsets.bottom - win.margin - height));
            default:
                return top;
            }
        }
        visible: win.position !== "pointer" || win.pointer.x >= 0
        radius: win.theme.radius.panel
        color: win.theme.color.surface
        border.width: 1
        border.color: win.theme.color.line

        // Entrance: from its edge (strip, column), or scale and fade.
        opacity: 0
        transform: Translate {
            id: shift
        }
        Component.onCompleted: {
            const d = Motion.travel(24);
            shift.x = win.position === "left" ? -d : win.position === "right" ? d : 0;
            shift.y = win.position === "bottom" ? d : win.position === "top" ? -d : win.centered || win.position === "pointer" ? Motion.travel(8) : 0;
            enter.start();
        }

        ParallelAnimation {
            id: enter
            NumberAnimation {
                target: panel
                property: "opacity"
                to: 1
                duration: Motion.ms(win.theme, "base", "")
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: shift
                properties: "x,y"
                to: 0
                duration: Motion.ms(win.theme, "base", "")
                easing.type: Motion.easing(win.theme)
                easing.overshoot: Motion.overshoot(win.theme)
            }
        }

        // Swallow clicks so they don't reach the backdrop.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: menu.close()
        }

        // --- Header: search, boards and kinds, buttons ---
        Item {
            id: header

            readonly property bool wide: panel.width >= 1000
            readonly property int rowH: Math.max(win.theme.hit, 34)

            x: panel.pad
            y: panel.pad
            width: panel.width - panel.pad * 2
            height: wide ? rowH : rowH * 2 + win.gap

            Rectangle {
                id: searchBox

                width: header.wide ? 320 : header.width - buttons.width - win.gap
                height: header.rowH
                radius: win.theme.radius.control
                color: win.theme.color.surface2
                border.width: input.activeFocus ? 1 : 0
                border.color: win.theme.color.accent

                Icon {
                    id: searchIcon
                    anchors.left: parent.left
                    anchors.leftMargin: win.theme.space.s
                    anchors.verticalCenter: parent.verticalCenter
                    name: "search"
                    size: 18
                    color: win.theme.color.soft
                }

                TextInput {
                    id: input

                    anchors.left: searchIcon.right
                    anchors.leftMargin: win.theme.space.s
                    anchors.right: parent.right
                    anchors.rightMargin: win.theme.space.s
                    anchors.verticalCenter: parent.verticalCenter
                    focus: true
                    clip: true
                    color: win.theme.color.ink
                    selectionColor: win.theme.color.accent
                    selectedTextColor: win.theme.color.onAccent
                    font.family: win.theme.font.family
                    font.pixelSize: win.theme.font.sizeM
                    onTextEdited: win.query = text

                    ThemedText {
                        visible: !input.text
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        elide: Text.ElideRight
                        text: Clipboard.paused ? I18n.tr("clip.pausedHint") : I18n.tr("clip.search")
                        color: Clipboard.paused ? win.theme.color.warn : win.theme.color.soft
                    }

                    Keys.onPressed: event => keys.handle(event)
                }
            }

            // Boards, then kinds (scrolls sideways when it doesn't fit).
            Flickable {
                id: chips

                x: header.wide ? searchBox.width + win.gap : 0
                y: header.wide ? 0 : header.rowH + win.gap
                width: header.wide ? header.width - searchBox.width - buttons.width - win.gap * 2 : header.width
                height: header.rowH
                contentWidth: chipRow.implicitWidth
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                Row {
                    id: chipRow

                    height: parent.height
                    spacing: win.theme.space.xs

                    Repeater {
                        model: win.boards

                        Chip {
                            required property string modelData
                            readonly property var tagData: Clipboard.tag(modelData)
                            theme: win.theme
                            selected: win.board === modelData
                            icon: modelData === "all" ? "history" : modelData === "pinned" ? "push_pin" : ""
                            dot: tagData ? (Clipboard.tagColors[tagData.color] ?? "") : ""
                            text: modelData === "all" ? I18n.tr("clip.board.all") : modelData === "pinned" ? I18n.tr("clip.board.pinned") : (tagData?.name ?? "")
                            onClicked: win.board = modelData
                        }
                    }

                    // New tag (also tags the current item when a menu is open).
                    Chip {
                        id: newTag

                        property bool editing: false

                        theme: win.theme
                        icon: "new_label"
                        text: editing ? "" : (Clipboard.tags.length ? "" : I18n.tr("clip.newTag"))
                        visible: !editing
                        onClicked: {
                            editing = true;
                            tagInput.text = "";
                            tagInput.forceActiveFocus();
                        }
                    }

                    Rectangle {
                        visible: newTag.editing
                        width: 160
                        height: chipRow.height - 4
                        anchors.verticalCenter: parent.verticalCenter
                        radius: win.theme.radius.full
                        color: win.theme.color.surface2
                        border.width: 1
                        border.color: win.theme.color.accent

                        TextInput {
                            id: tagInput

                            anchors.fill: parent
                            anchors.leftMargin: win.theme.space.m
                            anchors.rightMargin: win.theme.space.m
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            color: win.theme.color.ink
                            font.family: win.theme.font.family
                            font.pixelSize: win.theme.font.sizeS

                            ThemedText {
                                visible: !tagInput.text
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.tr("clip.tagName")
                                color: win.theme.color.soft
                                font.pixelSize: win.theme.font.sizeS
                            }

                            function finish(): void {
                                newTag.editing = false;
                                input.forceActiveFocus();
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    const id = Clipboard.createTag(text, "");
                                    if (id)
                                        win.board = id;
                                    finish();
                                } else if (event.key === Qt.Key_Escape) {
                                    finish();
                                } else {
                                    return;
                                }
                                event.accepted = true;
                            }
                            onActiveFocusChanged: if (!activeFocus) newTag.editing = false
                        }
                    }

                    Rectangle {
                        width: 1
                        height: parent.height - 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: win.theme.color.line
                    }

                    Repeater {
                        model: win.kinds

                        Chip {
                            required property string modelData
                            theme: win.theme
                            selected: win.kind === modelData
                            icon: modelData === "all" ? "filter_list" : ClipKinds.icon(modelData)
                            text: modelData === "all" ? I18n.tr("clip.kinds") : ""
                            tip: I18n.tr(`clip.kind.${modelData}`)
                            onClicked: win.kind = modelData
                        }
                    }
                }
            }

            Row {
                id: buttons

                anchors.right: parent.right
                height: header.rowH
                spacing: win.theme.space.xs

                IconButton {
                    theme: win.theme
                    icon: "visibility_off"
                    active: Clipboard.paused
                    tip: I18n.tr(Clipboard.paused ? "clip.resume" : "clip.pause")
                    onClicked: Clipboard.setPaused(!Clipboard.paused)
                }

                IconButton {
                    theme: win.theme
                    icon: "settings"
                    tip: I18n.tr("clip.settings")
                    onClicked: {
                        Clipboard.close();
                        Settings.open("clipboard");
                    }
                }

                IconButton {
                    theme: win.theme
                    icon: "close"
                    tip: I18n.tr("clip.close")
                    onClicked: Clipboard.close()
                }
            }
        }

        // --- Items ---
        ListView {
            id: list

            readonly property int cardW: win.strip ? win.stripCard : width
            readonly property int cardH: win.strip ? win.stripCard : win.columnCard

            x: panel.pad
            y: header.y + header.height + panel.pad
            width: (win.centered ? Math.min(400, panel.width * 0.4) : panel.width - panel.pad * 2)
            height: panel.height - y - panel.pad
            orientation: win.strip ? ListView.Horizontal : ListView.Vertical
            spacing: win.theme.space.m
            clip: true
            model: win.results
            currentIndex: 0
            highlightFollowsCurrentItem: false
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: 1200

            delegate: ClipCard {
                id: card

                required property var modelData
                required property int index

                entry: modelData
                width: list.cardW
                height: list.cardH
                current: ListView.isCurrentItem
                number: index < 9 ? index + 1 : 0
                compact: win.compact
                onHovered: win.select(index, false)
                onClicked: mouse => {
                    win.select(index, false);
                    if (mouse.button === Qt.RightButton)
                        win.openMenu(modelData, card, mouse.x, mouse.y, false);
                    else if (mouse.button === Qt.MiddleButton)
                        Clipboard.togglePin(modelData.id);
                    else
                        win.activate(modelData, "enter");
                }
            }

            onCurrentIndexChanged: if (win.results[currentIndex]) win.currentId = win.results[currentIndex].id
        }

        ThemedText {
            anchors.centerIn: list
            width: list.width - win.theme.space.xl * 2
            visible: list.count === 0
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            color: win.theme.color.soft
            text: Clipboard.count === 0 ? I18n.tr(Clipboard.enabled ? "clip.empty" : "clip.disabled") : I18n.tr("clip.noResults")
        }

        // Center: large preview of the current item.
        ClipPreview {
            visible: win.centered
            x: list.x + list.width + panel.pad
            y: list.y
            width: panel.width - x - panel.pad
            height: list.height
            theme: win.theme
            entry: win.currentEntry
            onDismissed: input.forceActiveFocus()
        }

        // Hint under a pinned or tagged item asked to be deleted.
        Rectangle {
            visible: !!win.confirmDelete
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: win.theme.space.xs
            width: confirmText.implicitWidth + win.theme.space.m * 2
            height: confirmText.implicitHeight + win.theme.space.xs * 2
            radius: win.theme.radius.full
            color: win.theme.color.urgent

            ThemedText {
                id: confirmText
                anchors.centerIn: parent
                text: I18n.tr("clip.confirmDelete")
                color: "#FFFFFF"
                font.pixelSize: win.theme.font.sizeS
            }
        }
    }

    // Large preview over everything (Space), text selectable.
    Rectangle {
        id: overlay

        property bool shown: false

        anchors.fill: parent
        visible: shown && !!win.currentEntry
        color: Qt.alpha("#000000", 0.35)

        MouseArea {
            anchors.fill: parent
            onClicked: {
                overlay.shown = false;
                input.forceActiveFocus();
            }
        }

        ClipPreview {
            anchors.centerIn: parent
            width: Math.min(parent.width - 96, 1100)
            height: Math.min(parent.height - 96, 760)
            theme: win.theme
            entry: overlay.visible ? win.currentEntry : null
            framed: true
            onDismissed: {
                overlay.shown = false;
                input.forceActiveFocus();
            }
        }
    }

    ClipMenu {
        id: menu
        theme: win.theme
        bounds: Qt.size(win.width, win.height)
        onPicked: (action, entry) => {
            switch (action) {
            case "paste":
                win.activate(entry, "paste");
                break;
            case "copy":
                win.activate(entry, "copy");
                break;
            case "text":
                win.activate(entry, "text");
                break;
            case "pin":
                Clipboard.togglePin(entry.id);
                break;
            case "preview":
                overlay.shown = true;
                break;
            case "open":
                Clipboard.close();
                Quickshell.execDetached(["xdg-open", entry.kind === "file" ? Clipboard.filePaths(entry)[0] : entry.kind === "image" ? Clipboard.blobPath(entry) : (entry.text ?? "").trim().replace(/^www\./i, "https://www.")]);
                break;
            case "delete":
                win.remove(entry, true);
                break;
            }
        }
        onClosed: input.forceActiveFocus()
    }

    // Key handling for the search field (which keeps the focus).
    QtObject {
        id: keys

        function handle(event: var): void {
            const ctrl = event.modifiers & Qt.ControlModifier;
            const shift = event.modifiers & Qt.ShiftModifier;
            const key = event.key;
            const empty = !input.text;

            if (menu.visible) {
                menu.handle(event);
                event.accepted = true;
                return;
            }
            if (overlay.shown && (key === Qt.Key_Escape || (key === Qt.Key_Space && empty))) {
                overlay.shown = false;
            } else if (key === Qt.Key_Escape) {
                if (input.text) {
                    input.text = "";
                    win.query = "";
                } else {
                    Clipboard.close();
                }
            } else if (key === Qt.Key_Right || key === Qt.Key_Down || (ctrl && key === Qt.Key_J)) {
                win.select(list.currentIndex + 1, true);
            } else if (key === Qt.Key_Left || key === Qt.Key_Up || (ctrl && key === Qt.Key_K)) {
                win.select(list.currentIndex - 1, true);
            } else if (key === Qt.Key_PageDown) {
                win.select(Math.min(win.results.length - 1, list.currentIndex + 5), true);
            } else if (key === Qt.Key_PageUp) {
                win.select(Math.max(0, list.currentIndex - 5), true);
            } else if (key === Qt.Key_Home && (ctrl || empty)) {
                win.select(0, true);
            } else if (key === Qt.Key_End && (ctrl || empty)) {
                win.select(win.results.length - 1, true);
            } else if (key === Qt.Key_Return || key === Qt.Key_Enter) {
                win.activate(win.currentEntry, ctrl ? "text" : shift ? "alt" : "enter");
            } else if (ctrl && key >= Qt.Key_1 && key <= Qt.Key_9) {
                win.activate(win.results[key - Qt.Key_1], shift ? "alt" : "enter");
            } else if (ctrl && (key === Qt.Key_P || key === Qt.Key_S)) {
                if (win.currentEntry)
                    Clipboard.togglePin(win.currentEntry.id);
            } else if (ctrl && key === Qt.Key_T) {
                win.openMenuForCurrent(true);
            } else if (key === Qt.Key_Menu || (shift && key === Qt.Key_F10)) {
                win.openMenuForCurrent(false);
            } else if (key === Qt.Key_Delete && (ctrl || empty)) {
                win.remove(win.currentEntry, false);
            } else if (key === Qt.Key_Space && empty) {
                overlay.shown = !overlay.shown;
            } else if (key === Qt.Key_Backtab || (key === Qt.Key_Tab && shift && !ctrl)) {
                win.board = win.cycle(win.boards, win.board, -1);
            } else if (key === Qt.Key_Tab && ctrl) {
                win.kind = win.cycle(win.kinds, win.kind, shift ? -1 : 1);
            } else if (key === Qt.Key_Tab) {
                win.board = win.cycle(win.boards, win.board, 1);
            } else if (ctrl && key === Qt.Key_I) {
                Clipboard.setPaused(!Clipboard.paused);
            } else {
                return;
            }
            event.accepted = true;
        }
    }
}
