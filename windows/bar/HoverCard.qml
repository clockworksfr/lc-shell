import QtQuick
import Quickshell
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
// while closed): mapping a new one at each opening cost frames. Its depth
// follows the drawer's (not the 60 % maximum), so each animation frame
// redraws and recomposites only that band of the screen. The card's
// content stays loaded between openings of the same type.
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

    function fitDepth(grow: bool): void {
        const need = Math.ceil(bodyHeight + overlap + 2);
        depth = grow ? Math.max(depth, need) : need;
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
        probe.start("open");
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
        enter.easing.type = Motion.easing(theme);
        enter.easing.overshoot = Motion.overshoot(theme);
        enter.restart();
    }

    function hide(): void {
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
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
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
        }

        HoverHandler {
            id: hover
        }
    }

    // TEMPORARY (perf measurement): the process's animation tick at rest.
    FrameAnimation {
        property var d: []
        running: root.screenName === "DP-1"
        onTriggered: {
            d.push(frameTime * 1000);
            if (d.length % 120 === 0) {
                const x = d.slice(-110);
                console.warn(`cardperf idle tick: avg ${(x.reduce((a, b) => a + b, 0) / x.length).toFixed(1)} ms, max ${Math.max(...x).toFixed(1)} ms`);
            }
        }
    }

    // TEMPORARY (perf measurement): frame times while the drawer opens.
    FrameAnimation {
        id: probe

        property string label
        property real t0
        property real first: -1
        property var deltas: []

        function start(what: string): void {
            label = what;
            t0 = Date.now();
            first = -1;
            deltas = [];
            restart();
        }
        function report(): void {
            stop();
            const d = deltas.slice(1);
            if (!d.length)
                return;
            const avg = d.reduce((a, b) => a + b, 0) / d.length;
            console.warn(`cardperf ${label} ${root.screenName} ${root.width}x${root.height}: first frame ${first} ms, ${d.length} frames, avg ${avg.toFixed(1)} ms, max ${Math.max(...d).toFixed(1)} ms, >25ms ${d.filter(x => x > 25).length}`);
        }

        onTriggered: {
            if (first < 0)
                first = Date.now() - t0;
            deltas.push(frameTime * 1000);
        }
    }

    // Opening: slides out of the bar.
    NumberAnimation {
        id: enter
        target: frame
        property: "progress"
        to: 1
        onFinished: {
            probe.report();
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
            // A 1 px band while closed: no invisible layer over the windows.
            root.depth = 1;
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
