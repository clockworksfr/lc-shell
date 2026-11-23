import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.cards
import qs.components
import qs.services
import qs.theme

// The bar's hover card: one per bar, a drawer coming out of the bar
// (merged with the widget's island), centered on the widget. Moving to
// another widget while it's open doesn't close it: the drawer slides and
// resizes to the new widget while its content cross-fades. Doesn't take
// the keyboard. Content comes from cards/<Type>Card.qml.
//
// A layer surface along the whole bar side (input limited to the drawer):
// a popup can't move while shown, and only shows while the bar has the
// pointer. The surface stays mapped (empty input region and nothing drawn
// while closed) and only grows (deepest card so far, not the 60 %
// maximum): no compositor animation or stretched frame at each opening.
// The card's content stays loaded between openings of the same type.
PanelWindow {
    id: root

    required property var host
    // WidgetSlot the card is (or is being) shown for.
    property Item slot: null
    // WidgetSlot whose content is shown (changes mid-switch).
    property Item shown: null
    readonly property bool hovered: hover.hovered
    readonly property bool open: phase === "open"
    // "" (closed) | "opening" | "open" | "closing"
    property string phase: ""
    // Pinned (a click on the widget or the card): stays open until a click
    // outside, Escape or another click on the widget, and takes the
    // keyboard on demand.
    property bool pinned: false

    function pin(target: Item): void {
        showFor(target);
        pinned = true;
    }

    readonly property var theme: host?.theme ?? Themes.fallback
    readonly property string edge: host?.edge ?? "top"
    readonly property bool sideways: edge === "left" || edge === "right"
    readonly property real fillet: theme.drawer.fillet
    // Reaches over the bar's inner border: no line at the junction.
    readonly property real overlap: Math.max(1, host?.look?.border ?? 0)
    readonly property real cardWidth: 380
    readonly property real maxBody: (host?.screen?.height ?? 1000) * 0.6
    readonly property real bodyHeight: Math.min(loader.implicitHeight + theme.space.l * 2, maxBody)
    readonly property string screenName: host?.screen?.name ?? ""

    // Drawer geometry on this surface (along the bar / away from it).
    property real along: 0
    property real length: 0
    property real filletLow: fillet
    property real filletHigh: fillet
    // Animate geometry only while switching (not on the first frame).
    property bool morph: false
    // Depth of the surface (away from the bar): the drawer's, grown as
    // needed, set back to the drawer's at each opening.
    property real depth: 0
    // Card type whose content is loaded (kept after closing).
    property string cardType

    // Only grows: resizing the surface as it opens would show a frame at
    // the old size (stretched by the compositor).
    function fitDepth(grow: bool): void {
        depth = Math.max(depth, Math.ceil(bodyHeight + overlap + 2));
    }

    function showFor(target: Item): void {
        if (!target)
            return;
        if (slot === target && (phase === "open" || phase === "opening"))
            return;
        slot = target;
        if (phase === "open" || phase === "opening") {
            // Switch: content fades out, then the drawer moves to the new
            // widget while the new content fades in.
            swap.restart();
            return;
        }
        // Reopening while closing continues from where the drawer is.
        const reopening = phase === "closing";
        close.stop();
        shown = target;
        cardType = target.type;
        morph = false;
        fitDepth(reopening);
        place();
        if (!reopening)
            frame.progress = 0;
        phase = "opening";
        enter.duration = Motion.ms(theme, "base", screenName);
        // A zone that grows: no overshoot (it would grow past its size).
        enter.easing.type = Easing.OutCubic;
        enter.restart();
    }

    // Reviews: the drawer's rectangle on its screen (null while closed).
    function frameRect(): var {
        if (phase !== "open")
            return null;
        const ox = edge === "right" ? (screen.width - width - margins.right) : margins.left;
        const oy = edge === "bottom" ? (screen.height - height - margins.bottom) : margins.top;
        return Qt.rect(ox + frame.x, oy + frame.y, frame.width, frame.height);
    }

    function hide(): void {
        if (pinned) {
            pinned = false;
            Qt.callLater(ShellState.restoreFocus);
        }
        if (phase === "" || phase === "closing")
            return;
        swap.stop();
        enter.stop();
        phase = "closing";
        close.duration = Motion.exitMs(theme, "base", screenName);
        close.restart();
    }

    function place(): void {
        if (!shown || !host)
            return;
        const d = host.drawerPlace(shown, sideways ? bodyHeight : cardWidth, fillet);
        const o = host.origin();
        filletLow = d.low;
        filletHigh = d.high;
        along = d.start + (sideways ? o.y : o.x);
        length = d.end - d.start;
        host.drawerSpan = { slot: shown, start: d.start, end: d.end, squareLow: d.squareLow, squareHigh: d.squareHigh };
    }

    onPhaseChanged: ShellState.card = { visible: phase !== "", type: shown?.type ?? "", screen: screenName }
    // Content size changes (lists loading…): follow.
    onBodyHeightChanged: {
        if (phase === "")
            return;
        fitDepth(true);
        place();
    }

    screen: host?.screen ?? null
    anchors {
        top: edge !== "bottom"
        bottom: edge !== "top"
        left: edge !== "right"
        right: edge !== "left"
    }
    margins {
        // The bar's inner edge, minus the overlap.
        top: edge === "top" ? (host ? host.origin().y + host.height - overlap : 0) : 0
        bottom: edge === "bottom" ? (host ? (host.screen.height - host.origin().y) - overlap : 0) : 0
        left: edge === "left" ? (host ? host.origin().x + host.width - overlap : 0) : 0
        right: edge === "right" ? (host ? (host.screen.width - host.origin().x) - overlap : 0) : 0
    }
    implicitWidth: sideways ? Math.max(1, depth) : 0
    implicitHeight: sideways ? 0 : Math.max(1, depth)

    visible: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "lc-card"
    WlrLayershell.keyboardFocus: pinned ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Pinned: a click outside (the bar included: its widgets toggle the
    // pin themselves) closes it.
    HyprlandFocusGrab {
        active: root.pinned && root.phase !== "closing"
        windows: [root, root.host]
        onCleared: root.hide()
    }
    // Only the drawer takes the pointer (nothing while closed).
    mask: Region {
        item: root.phase !== "" ? frame : null
    }

    DrawerFrame {
        id: frame

        visible: root.phase !== ""
        edge: root.edge
        fillet: root.fillet
        filletLow: root.filletLow
        filletHigh: root.filletHigh
        overlap: root.overlap
        color: root.theme.color.surface
        lineWidth: root.host?.look?.border ?? 0

        x: root.sideways ? (root.edge === "left" ? 0 : root.width - width) : root.along
        y: root.sideways ? root.along : (root.edge === "top" ? 0 : root.height - height)
        width: root.sideways ? root.cardWidth + root.overlap : root.length
        height: root.sideways ? root.length : root.bodyHeight + root.overlap

        Behavior on x {
            enabled: root.morph
            NumberAnimation {
                duration: Motion.ms(root.theme, "base", root.screenName)
                easing.type: Easing.OutCubic
            }
        }
        Behavior on y {
            enabled: root.morph
            NumberAnimation {
                duration: Motion.ms(root.theme, "base", root.screenName)
                easing.type: Easing.OutCubic
            }
        }
        Behavior on width {
            enabled: root.morph
            NumberAnimation {
                duration: Motion.ms(root.theme, "base", root.screenName)
                easing.type: Easing.OutCubic
            }
        }
        Behavior on height {
            enabled: root.morph
            NumberAnimation {
                duration: Motion.ms(root.theme, "base", root.screenName)
                easing.type: Easing.OutCubic
            }
        }
        Behavior on filletLow {
            enabled: root.morph
            NumberAnimation {
                duration: Motion.ms(root.theme, "base", root.screenName)
            }
        }
        Behavior on filletHigh {
            enabled: root.morph
            NumberAnimation {
                duration: Motion.ms(root.theme, "base", root.screenName)
            }
        }

        Item {
            id: content

            anchors.fill: parent
            clip: true

            Loader {
                id: loader

                x: root.theme.space.l
                y: root.theme.space.l
                width: root.cardWidth - root.theme.space.l * 2
                source: root.cardType ? Registry.url(root.cardType) : ""

                onLoaded: {
                    item.block = Qt.binding(() => root.shown?.item ?? null);
                    item.screen = Qt.binding(() => root.shown?.screen ?? null);
                }
            }

            // A click on the card (not on its controls) pins it.
            TapHandler {
                onTapped: root.pinned = true
            }

            focus: root.pinned
            Keys.onEscapePressed: root.hide()
        }

        HoverHandler {
            id: hover
        }
    }

    // Opening: slides out of the bar.
    NumberAnimation {
        id: enter
        target: frame
        property: "progress"
        to: 1
        onFinished: {
            root.phase = "open";
            root.morph = true;
        }
    }

    // Closing: back into the bar, then hidden.
    NumberAnimation {
        id: close
        target: frame
        property: "progress"
        to: 0
        easing.type: Easing.InCubic
        onFinished: {
            root.phase = "";
            root.morph = false;
            root.shown = null;
            root.slot = null;
            if (root.host?.drawerSpan)
                root.host.drawerSpan = null;
        }
    }

    // Switching widgets: fade out, move + resize, fade in.
    SequentialAnimation {
        id: swap

        NumberAnimation {
            target: content
            property: "opacity"
            to: 0
            duration: Motion.reduced ? 0 : Math.round(Motion.ms(root.theme, "fast", root.screenName) / 2)
        }
        ScriptAction {
            script: {
                root.morph = !Motion.reduced;
                root.shown = root.slot;
                root.cardType = root.slot?.type ?? root.cardType;
                root.fitDepth(true);
                root.place();
            }
        }
        NumberAnimation {
            target: content
            property: "opacity"
            to: 1
            duration: Motion.ms(root.theme, "base", root.screenName)
            easing.type: Easing.OutCubic
        }
    }
}
