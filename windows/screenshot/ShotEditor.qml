import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Screenshot editor of one screen (Print, lc:screenshot), in ShotWindow.
// Freeze mode:
// the screen shows a still of itself; drag a zone or click a window
// (highlighted under the pointer), Ctrl+A for the whole screen. File mode
// (Screenshot.edit): an image on a dark backdrop, selected whole.
// Then annotate in place with the toolbar's tools; the shot is the
// selection with its annotations, at the image's full resolution.
// Keys: Enter (Screenshot.enterAction), Ctrl+C copy, Ctrl+S save,
// Ctrl+Z / Ctrl+Shift+Z undo / redo, tools V P H L A R E T N M, colors
// 1-8, [ ] stroke, F fill, arrows move the zone (Shift ×10, Alt resizes),
// right click resets the zone, Escape closes.
Item {
    id: win

    property var theme: Themes.fallback

    // The screen's name.
    property string name
    readonly property bool fileMode: Screenshot.mode === "file"
    // This screen holds the selection (and the keyboard).
    readonly property bool holder: Screenshot.screenName === name
    readonly property string source: fileMode ? `file://${Screenshot.file}` : (Screenshot.stills[name] ? `file://${Screenshot.stills[name]}` : "")
    readonly property bool ready: still.status === Image.Ready

    // Where the image shows, and its pixels per logical pixel (export).
    readonly property real nativeW: still.implicitWidth
    readonly property real nativeH: still.implicitHeight
    readonly property rect imageRect: {
        if (!fileMode || !nativeW)
            return Qt.rect(0, 0, width, height);
        const f = Math.min(1, width * 0.9 / nativeW, (height - 160) / nativeH);
        const w = Math.round(nativeW * f), h = Math.round(nativeH * f);
        return Qt.rect(Math.round((width - w) / 2), Math.round((height - h) / 2), w, h);
    }
    readonly property real k: nativeW && imageRect.width ? nativeW / imageRect.width : 1
    readonly property var view: ({
            source: source,
            x: imageRect.x,
            y: imageRect.y,
            w: imageRect.width,
            h: imageRect.height
        })

    // --- Selection ---
    property rect sel: Qt.rect(0, 0, 0, 0)
    readonly property bool hasSel: holder && sel.width >= 2 && sel.height >= 2
    // Window under the pointer while nothing is selected.
    property var hovered: null
    readonly property rect shown: hasSel ? sel : hovered ? clampRect(Qt.rect(hovered.x, hovered.y, hovered.w, hovered.h)) : Qt.rect(0, 0, 0, 0)

    // --- Annotations ---
    property var items: []
    property var undone: []
    property var draft: null
    readonly property int nextCounter: items.filter(i => i.type === "counter").length + 1

    // --- Pointer ---
    // "" | "new" | "move" | "resize" | "draw"
    property string op: ""
    property string handle
    property point pressPos
    property rect pressSel
    property bool moved: false
    property point pointer: Qt.point(-1, -1)

    // Text being typed (text tool).
    property bool typing: false
    property point typingAt

    readonly property var strokes: [3, 5, 9]
    readonly property var fontSizes: [18, 26, 40]

    Component.onCompleted: if (fileMode) Qt.callLater(() => win.sel = win.imageRect)
    onImageRectChanged: if (fileMode && holder && items.length === 0) sel = imageRect
    // Another screen took the selection.
    onHolderChanged: if (!holder) reset()

    function reset(): void {
        commitText();
        sel = Qt.rect(0, 0, 0, 0);
        items = [];
        undone = [];
        draft = null;
        op = "";
    }

    function clampRect(r: rect): rect {
        const x1 = Math.max(imageRect.x, r.x), y1 = Math.max(imageRect.y, r.y);
        const x2 = Math.min(imageRect.x + imageRect.width, r.x + r.width), y2 = Math.min(imageRect.y + imageRect.height, r.y + r.height);
        return Qt.rect(x1, y1, Math.max(0, x2 - x1), Math.max(0, y2 - y1));
    }

    // On the image's pixel grid (sharp export at any scale).
    function snap(v: real, origin: real): real {
        return origin + Math.round((v - origin) * k) / k;
    }

    function rectFrom(a: point, b: point): rect {
        const x1 = snap(Math.min(a.x, b.x), imageRect.x), y1 = snap(Math.min(a.y, b.y), imageRect.y);
        const x2 = snap(Math.max(a.x, b.x), imageRect.x), y2 = snap(Math.max(a.y, b.y), imageRect.y);
        return clampRect(Qt.rect(x1, y1, x2 - x1, y2 - y1));
    }

    function inside(r: rect, p: point, margin: real): bool {
        return p.x >= r.x - margin && p.x <= r.x + r.width + margin && p.y >= r.y - margin && p.y <= r.y + r.height + margin;
    }

    function windowAt(p: point): var {
        if (fileMode || !Screenshot.pickWindows)
            return null;
        return (Screenshot.windows[name] ?? []).find(w => p.x >= w.x && p.x < w.x + w.w && p.y >= w.y && p.y < w.y + w.h) ?? null;
    }

    // Resize handle under p: "tl", "t", "tr", "r", "br", "b", "bl", "l" or "".
    function handleAt(p: point): string {
        if (!hasSel)
            return "";
        const r = sel, m = 10;
        const left = Math.abs(p.x - r.x) <= m, right = Math.abs(p.x - r.x - r.width) <= m;
        const top = Math.abs(p.y - r.y) <= m, bottom = Math.abs(p.y - r.y - r.height) <= m;
        const inX = p.x > r.x - m && p.x < r.x + r.width + m, inY = p.y > r.y - m && p.y < r.y + r.height + m;
        if (top && left)
            return "tl";
        if (top && right)
            return "tr";
        if (bottom && left)
            return "bl";
        if (bottom && right)
            return "br";
        if (top && inX)
            return "t";
        if (bottom && inX)
            return "b";
        if (left && inY)
            return "l";
        if (right && inY)
            return "r";
        return "";
    }

    function cursorFor(h: string): int {
        return ({
                tl: Qt.SizeFDiagCursor,
                br: Qt.SizeFDiagCursor,
                tr: Qt.SizeBDiagCursor,
                bl: Qt.SizeBDiagCursor,
                t: Qt.SizeVerCursor,
                b: Qt.SizeVerCursor,
                l: Qt.SizeHorCursor,
                r: Qt.SizeHorCursor
            })[h] ?? Qt.ArrowCursor;
    }

    // Shift: lines at 45° steps, square boxes.
    function constrain(a: point, b: point, type: string, shift: bool): point {
        if (!shift)
            return b;
        const dx = b.x - a.x, dy = b.y - a.y;
        if (type === "line" || type === "arrow") {
            const angle = Math.round(Math.atan2(dy, dx) / (Math.PI / 4)) * (Math.PI / 4);
            const length = Math.hypot(dx, dy);
            return Qt.point(a.x + Math.cos(angle) * length, a.y + Math.sin(angle) * length);
        }
        const side = Math.max(Math.abs(dx), Math.abs(dy));
        return Qt.point(a.x + Math.sign(dx || 1) * side, a.y + Math.sign(dy || 1) * side);
    }

    function push(item: var): void {
        items = [...items, item];
        undone = [];
    }

    function undo(): void {
        if (typing)
            return;
        if (!items.length)
            return;
        undone = [...undone, items[items.length - 1]];
        items = items.slice(0, -1);
    }

    function redo(): void {
        if (!undone.length)
            return;
        items = [...items, undone[undone.length - 1]];
        undone = undone.slice(0, -1);
    }

    function startText(p: point): void {
        commitText();
        typingAt = p;
        editor.text = "";
        typing = true;
        editor.forceActiveFocus();
    }

    function commitText(): void {
        if (!typing)
            return;
        typing = false;
        if (editor.text.trim())
            push({
                type: "text",
                color: Screenshot.palette[Screenshot.color],
                x1: typingAt.x,
                y1: typingAt.y,
                text: editor.text,
                fontSize: fontSizes[Screenshot.stroke]
            });
        editor.text = "";
        keys.forceActiveFocus();
    }

    function cancelText(): void {
        typing = false;
        editor.text = "";
        keys.forceActiveFocus();
    }

    // Renders the selection with its annotations at full resolution, then
    // copies and/or saves it (Screenshot.deliver).
    function finish(action: string): void {
        commitText();
        if (!hasSel || exporting)
            return;
        exporting = true;
        const size = Qt.size(Math.round(sel.width * k), Math.round(sel.height * k));
        crop.grabToImage(result => {
            const file = Screenshot.cacheFile();
            if (result.saveToFile(file))
                Screenshot.deliver(file, action);
            else
                console.warn(`screenshot: could not write ${file}`);
            Screenshot.close();
        }, size);
    }
    property bool exporting: false
    // What gets exported: the zone with its annotations.
    readonly property Item shot: crop

    // --- Backdrop ---
    Rectangle {
        anchors.fill: parent
        visible: win.fileMode
        color: Qt.alpha("#000000", 0.78)
    }

    // The still (or the file).
    Image {
        id: still

        x: win.imageRect.x
        y: win.imageRect.y
        width: win.imageRect.width
        height: win.imageRect.height
        source: win.source
        smooth: win.k !== 1
        mipmap: win.fileMode
    }

    // Everything outside the zone is dimmed.
    Item {
        anchors.fill: parent
        visible: win.ready

        readonly property rect r: win.shown
        readonly property color dim: Qt.alpha("#000000", win.fileMode ? 0.55 : 0.45)

        Rectangle {
            width: parent.width
            height: parent.r.y
            color: parent.dim
        }
        Rectangle {
            y: parent.r.y + parent.r.height
            width: parent.width
            height: parent.height - y
            color: parent.dim
        }
        Rectangle {
            y: parent.r.y
            width: parent.r.x
            height: parent.r.height
            color: parent.dim
        }
        Rectangle {
            x: parent.r.x + parent.r.width
            y: parent.r.y
            width: parent.width - x
            height: parent.r.height
            color: parent.dim
        }
    }

    // --- The shot: the zone, its image and annotations (what is exported) ---
    Item {
        id: crop

        x: win.shown.x
        y: win.shown.y
        width: win.shown.width
        height: win.shown.height
        clip: true

        Item {
            x: -crop.x
            y: -crop.y
            width: win.width
            height: win.height

            Image {
                x: win.imageRect.x
                y: win.imageRect.y
                width: win.imageRect.width
                height: win.imageRect.height
                source: win.source
                smooth: win.k !== 1
                mipmap: win.fileMode
            }

            Repeater {
                model: win.items

                ShotItem {
                    required property var modelData

                    anchors.fill: parent
                    data_: modelData
                    view: win.view
                }
            }

            ShotItem {
                anchors.fill: parent
                visible: !!win.draft
                data_: win.draft ?? ({})
                view: win.view
            }
        }
    }

    // --- Zone frame, size, handles ---
    Rectangle {
        visible: win.shown.width > 0 && win.ready
        x: win.shown.x - 1
        y: win.shown.y - 1
        width: win.shown.width + 2
        height: win.shown.height + 2
        color: "transparent"
        border.width: win.hasSel ? 2 : 3
        border.color: win.theme.color.accent
        opacity: win.hasSel ? 1 : 0.8
    }

    Repeater {
        model: win.hasSel && Screenshot.tool === "select" && !win.typing ? ["tl", "t", "tr", "r", "br", "b", "bl", "l"] : []

        Rectangle {
            required property string modelData

            readonly property real cx: modelData.includes("l") ? win.sel.x : modelData.includes("r") ? win.sel.x + win.sel.width : win.sel.x + win.sel.width / 2
            readonly property real cy: modelData.includes("t") ? win.sel.y : modelData.includes("b") ? win.sel.y + win.sel.height : win.sel.y + win.sel.height / 2

            x: cx - width / 2
            y: cy - height / 2
            width: 10
            height: 10
            radius: 5
            color: win.theme.color.accent
            border.width: 2
            border.color: win.theme.color.onAccent
        }
    }

    // Size in pixels (and the window's name when one is hovered).
    Rectangle {
        visible: win.shown.width > 0 && win.ready && win.op !== "draw"
        x: Math.max(4, Math.min(win.shown.x, win.width - width - 4))
        y: win.shown.y - height - 8 >= 4 ? win.shown.y - height - 8 : win.shown.y + 8
        width: sizeText.implicitWidth + win.theme.space.s * 2
        height: sizeText.implicitHeight + win.theme.space.xs * 2
        radius: win.theme.radius.control
        color: Qt.alpha(win.theme.color.surface, 0.92)

        ThemedText {
            id: sizeText

            anchors.centerIn: parent
            readonly property string size: `${Math.round(win.shown.width * win.k)} × ${Math.round(win.shown.height * win.k)}`
            text: !win.hasSel && win.hovered ? `${win.hovered.cls || win.hovered.title}  ·  ${size}` : size
            font.family: win.theme.font.mono
            font.pixelSize: win.theme.font.sizeS
        }
    }

    // --- Pointer ---
    MouseArea {
        id: mouse

        anchors.fill: parent
        enabled: win.ready && !win.exporting
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: {
            if (win.op === "move")
                return Qt.ClosedHandCursor;
            if (win.op === "resize")
                return win.cursorFor(win.handle);
            if (!win.hasSel)
                return Qt.CrossCursor;
            if (Screenshot.tool === "select") {
                const h = win.handleAt(win.pointer);
                return h ? win.cursorFor(h) : win.inside(win.sel, win.pointer, 0) ? Qt.OpenHandCursor : Qt.CrossCursor;
            }
            return Screenshot.tool === "text" ? Qt.IBeamCursor : Qt.CrossCursor;
        }

        onExited: {
            win.hovered = null;
            win.pointer = Qt.point(-1, -1);
        }

        onPressed: event => {
            const p = Qt.point(event.x, event.y);
            if (event.button === Qt.RightButton) {
                // Back to picking a zone (unless something is drawn).
                if (win.op === "draw") {
                    win.draft = null;
                    win.op = "";
                } else if (!win.fileMode && win.items.length === 0) {
                    win.commitText();
                    win.sel = Qt.rect(0, 0, 0, 0);
                }
                return;
            }
            if (!win.holder) {
                Screenshot.screenName = win.name;
            }
            win.pressPos = p;
            win.pressSel = win.sel;
            win.moved = false;
            const tool = Screenshot.tool;
            if (win.hasSel && tool === "select") {
                win.commitText();
                const h = win.handleAt(p);
                if (h) {
                    win.op = "resize";
                    win.handle = h;
                    return;
                }
                if (win.inside(win.sel, p, 0)) {
                    win.op = "move";
                    return;
                }
            }
            if (!win.hasSel || tool === "select" || (!win.inside(win.sel, p, 0) && win.items.length === 0 && !win.fileMode)) {
                win.commitText();
                win.op = "new";
                return;
            }
            if (!win.inside(win.sel, p, 0))
                return;
            // Drawing tools.
            const color = Screenshot.palette[Screenshot.color];
            const size = win.strokes[Screenshot.stroke];
            if (tool === "text") {
                win.startText(p);
                return;
            }
            win.commitText();
            if (tool === "counter") {
                win.push({
                    type: "counter",
                    color: color,
                    size: size,
                    x1: p.x,
                    y1: p.y,
                    n: win.nextCounter
                });
                return;
            }
            win.draft = {
                type: tool,
                color: color,
                size: size,
                fill: Screenshot.fill,
                points: [{
                        x: p.x,
                        y: p.y
                    }],
                x1: p.x,
                y1: p.y,
                x2: p.x,
                y2: p.y
            };
            win.op = "draw";
        }

        onPositionChanged: event => {
            const p = Qt.point(event.x, event.y);
            win.pointer = p;
            if (!win.op) {
                win.hovered = win.hasSel ? null : win.windowAt(p);
                return;
            }
            if (Math.abs(p.x - win.pressPos.x) > 3 || Math.abs(p.y - win.pressPos.y) > 3)
                win.moved = true;
            const s = win.pressSel;
            switch (win.op) {
            case "new":
                if (win.moved) {
                    win.hovered = null;
                    win.sel = win.rectFrom(win.pressPos, p);
                }
                break;
            case "move":
                {
                    const dx = Math.max(win.imageRect.x - s.x, Math.min(p.x - win.pressPos.x, win.imageRect.x + win.imageRect.width - s.x - s.width));
                    const dy = Math.max(win.imageRect.y - s.y, Math.min(p.y - win.pressPos.y, win.imageRect.y + win.imageRect.height - s.y - s.height));
                    win.sel = Qt.rect(win.snap(s.x + dx, win.imageRect.x), win.snap(s.y + dy, win.imageRect.y), s.width, s.height);
                    break;
                }
            case "resize":
                {
                    const h = win.handle;
                    let x1 = s.x, y1 = s.y, x2 = s.x + s.width, y2 = s.y + s.height;
                    if (h.includes("l"))
                        x1 = p.x;
                    if (h.includes("r"))
                        x2 = p.x;
                    if (h.includes("t"))
                        y1 = p.y;
                    if (h.includes("b"))
                        y2 = p.y;
                    win.sel = win.rectFrom(Qt.point(x1, y1), Qt.point(x2, y2));
                    break;
                }
            case "draw":
                {
                    const d = win.draft;
                    if (!d)
                        break;
                    if (d.type === "pen" || d.type === "highlighter") {
                        const last = d.points[d.points.length - 1];
                        if (Math.hypot(p.x - last.x, p.y - last.y) < 1.5)
                            break;
                        win.draft = Object.assign({}, d, {
                            points: [...d.points, {
                                    x: p.x,
                                    y: p.y
                                }]
                        });
                    } else {
                        const q = win.constrain(Qt.point(d.x1, d.y1), p, d.type, !!(event.modifiers & Qt.ShiftModifier));
                        win.draft = Object.assign({}, d, {
                            x2: q.x,
                            y2: q.y
                        });
                    }
                    break;
                }
            }
        }

        onReleased: event => {
            if (event.button === Qt.RightButton)
                return;
            const op = win.op;
            win.op = "";
            if (op === "new" && !win.moved) {
                // A click: the window under it.
                const w = win.windowAt(win.pressPos);
                if (w) {
                    win.sel = win.clampRect(Qt.rect(w.x, w.y, w.w, w.h));
                    win.hovered = null;
                } else {
                    win.sel = win.pressSel;
                }
            } else if (op === "draw") {
                const d = win.draft;
                win.draft = null;
                if (!d)
                    return;
                const big = d.type === "pen" || d.type === "highlighter" ? d.points.length > 1 : Math.hypot(d.x2 - d.x1, d.y2 - d.y1) > 3;
                if (big)
                    win.push(d);
            }
        }

        onDoubleClicked: event => {
            if (win.hasSel && Screenshot.tool === "select" && win.inside(win.sel, Qt.point(event.x, event.y), 0))
                win.finish(Screenshot.enterAction);
        }

        onWheel: wheel => Screenshot.stroke = Math.max(0, Math.min(2, Screenshot.stroke + (wheel.angleDelta.y > 0 ? 1 : -1)))
    }

    // --- Text being typed ---
    TextEdit {
        id: editor

        visible: win.typing
        x: win.typingAt.x
        y: win.typingAt.y
        width: Math.max(40, contentWidth + 4)
        color: Screenshot.palette[Screenshot.color]
        font.pixelSize: win.fontSizes[Screenshot.stroke]
        font.weight: Font.DemiBold
        selectByMouse: true

        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            z: -1
            color: "transparent"
            border.width: 1
            border.color: Qt.alpha(win.theme.color.accent, 0.8)
            radius: 3
        }

        Keys.onPressed: event => {
            if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !(event.modifiers & Qt.ShiftModifier)) {
                win.commitText();
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape) {
                win.cancelText();
                event.accepted = true;
            }
        }
    }

    // --- Magnifier: pixels around the pointer while picking ---
    Item {
        id: loupe

        readonly property real span: 15
        readonly property bool wanted: Screenshot.magnifier && win.ready && win.pointer.x >= 0 && (!win.hasSel || win.op === "new" || win.op === "resize")

        visible: wanted
        width: 140
        height: 140 + coords.height
        x: win.pointer.x + 24 + width > win.width ? win.pointer.x - 24 - width : win.pointer.x + 24
        y: win.pointer.y + 24 + height > win.height ? win.pointer.y - 24 - height : win.pointer.y + 24

        Rectangle {
            id: lens

            width: 140
            height: 140
            radius: win.theme.radius.tile
            color: "black"
            border.width: 2
            border.color: win.theme.color.accent
            clip: true

            ShaderEffectSource {
                anchors.fill: parent
                anchors.margins: 2
                sourceItem: still
                live: loupe.wanted
                smooth: false
                sourceRect: Qt.rect(win.pointer.x - still.x - loupe.span / 2, win.pointer.y - still.y - loupe.span / 2, loupe.span, loupe.span)
                textureSize: Qt.size(Math.round(loupe.span * win.k), Math.round(loupe.span * win.k))
            }

            // Crosshair on the pointed pixel.
            Rectangle {
                anchors.centerIn: parent
                width: Math.max(4, 136 / (loupe.span * win.k))
                height: width
                color: "transparent"
                border.width: 1
                border.color: "white"
            }
        }

        Rectangle {
            id: coords

            anchors.top: lens.bottom
            anchors.topMargin: 4
            anchors.horizontalCenter: lens.horizontalCenter
            width: coordsText.implicitWidth + win.theme.space.s * 2
            height: coordsText.implicitHeight + win.theme.space.xs * 2
            radius: win.theme.radius.control
            color: Qt.alpha(win.theme.color.surface, 0.92)

            ThemedText {
                id: coordsText

                anchors.centerIn: parent
                text: `${Math.round((win.pointer.x - win.imageRect.x) * win.k)}, ${Math.round((win.pointer.y - win.imageRect.y) * win.k)}`
                font.family: win.theme.font.mono
                font.pixelSize: win.theme.font.sizeS
            }
        }
    }

    // --- Toolbar, under the zone (or above, or inside) ---
    ShotToolbar {
        id: toolbar

        theme: win.theme
        visible: win.hasSel && win.op === "" && !win.exporting
        canUndo: win.items.length > 0
        canRedo: win.undone.length > 0
        x: Math.max(8, Math.min(win.sel.x + win.sel.width / 2 - width / 2, win.width - width - 8))
        y: {
            const gap = 12;
            if (win.sel.y + win.sel.height + gap + height + 8 <= win.height)
                return win.sel.y + win.sel.height + gap;
            if (win.sel.y - gap - height - 40 >= 0)
                return win.sel.y - gap - height;
            return win.sel.y + win.sel.height - height - gap;
        }

        onUndo: win.undo()
        onRedo: win.redo()
        onSave: win.finish(Screenshot.copyOnSave ? "both" : "save")
        onCopy: win.finish("copy")
        onCancel: Screenshot.close()
    }

    // --- How to pick, while nothing is selected ---
    Rectangle {
        visible: win.holder && !win.hasSel && win.ready && win.op === ""
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 48
        width: hint.implicitWidth + win.theme.space.l * 2
        height: hint.implicitHeight + win.theme.space.s * 2
        radius: win.theme.radius.full
        color: Qt.alpha(win.theme.color.surface, 0.92)
        border.width: 1
        border.color: win.theme.color.line

        ThemedText {
            id: hint

            anchors.centerIn: parent
            text: I18n.tr(Screenshot.pickWindows ? "shot.hint" : "shot.hintNoWindows")
        }
    }

    // --- Keys ---
    Item {
        id: keys

        focus: true

        Keys.onPressed: event => {
            const ctrl = event.modifiers & Qt.ControlModifier;
            const shift = event.modifiers & Qt.ShiftModifier;
            const alt = event.modifiers & Qt.AltModifier;
            const key = event.key;
            event.accepted = true;
            if (key === Qt.Key_Escape) {
                if (win.op === "draw") {
                    win.draft = null;
                    win.op = "";
                } else {
                    Screenshot.close();
                }
            } else if (key === Qt.Key_Return || key === Qt.Key_Enter) {
                win.finish(Screenshot.enterAction);
            } else if (ctrl && key === Qt.Key_C) {
                win.finish("copy");
            } else if (ctrl && key === Qt.Key_S) {
                win.finish(Screenshot.copyOnSave ? "both" : "save");
            } else if (ctrl && (key === Qt.Key_Y || (shift && key === Qt.Key_Z))) {
                win.redo();
            } else if (ctrl && key === Qt.Key_Z) {
                win.undo();
            } else if (ctrl && key === Qt.Key_A) {
                win.sel = win.imageRect;
                win.hovered = null;
            } else if (key === Qt.Key_Left || key === Qt.Key_Right || key === Qt.Key_Up || key === Qt.Key_Down) {
                if (!win.hasSel)
                    return;
                const step = (shift ? 10 : 1) / win.k;
                const dx = key === Qt.Key_Left ? -step : key === Qt.Key_Right ? step : 0;
                const dy = key === Qt.Key_Up ? -step : key === Qt.Key_Down ? step : 0;
                const s = win.sel;
                if (alt)
                    win.sel = win.clampRect(Qt.rect(s.x, s.y, Math.max(2, s.width + dx), Math.max(2, s.height + dy)));
                else
                    win.sel = Qt.rect(Math.max(win.imageRect.x, Math.min(s.x + dx, win.imageRect.x + win.imageRect.width - s.width)), Math.max(win.imageRect.y, Math.min(s.y + dy, win.imageRect.y + win.imageRect.height - s.height)), s.width, s.height);
            } else if (ctrl || alt) {
                event.accepted = false;
            } else if (key >= Qt.Key_1 && key <= Qt.Key_8) {
                Screenshot.color = Screenshot.colors[key - Qt.Key_1];
            } else if (key === Qt.Key_BracketLeft) {
                Screenshot.stroke = Math.max(0, Screenshot.stroke - 1);
            } else if (key === Qt.Key_BracketRight) {
                Screenshot.stroke = Math.min(2, Screenshot.stroke + 1);
            } else if (key === Qt.Key_F) {
                Screenshot.fill = !Screenshot.fill;
            } else {
                const letter = event.text.toUpperCase();
                const tool = Screenshot.tools.find(t => Screenshot.toolKeys[t] === letter);
                if (tool)
                    Screenshot.tool = tool;
                else
                    event.accepted = false;
            }
        }
    }
}
