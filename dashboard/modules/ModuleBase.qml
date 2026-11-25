import QtQuick
import Quickshell
import qs.components.dashboard
import qs.i18n
import qs.theme

// Common base of dashboard modules: the theme's frame
// (ModulePanel, with its title when the cell is tall enough), and the
// content area's shape, which picks the layout:
//   tiny   (≤ 220 × 200)  the main figure alone
//   narrow (≤ 220 wide)   stacked
//   tall   (ratio < 0.8)  a column: main figure on top, the rest under it
//   box    (< 1.8)        main figure, then the rest in a grid
//   wide   (< 4)          main figure left, the rest right
//   strip  (≥ 4)          one line, items added while they fit
// Type scale from the content's smaller side: t2 title, t3 text, t4
// label; the main figure is sized per shape with figure(hk, wk).
// Size tier on top of the shape, from the
// cell's smaller outer side: normal (< 760, the Xeneon), large (760 to
// 1239, e.g. 8 × 6 on a 5K screen), poster (≥ 1240, e.g. 12 × 8). Body
// text grows a little, the main figure a lot; the room goes to content
// (ModuleZone sections).
Item {
    id: base

    property ShellScreen screen
    // The cell ({ type, x, y, w, h, ...options }).
    property var options: ({})
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    // Narrow cells take the short name when there is one ("Workspaces").
    property string title: !options.type ? "" : width < 220 && I18n.has(`module.${options.type}.short`) ? I18n.tr(`module.${options.type}.short`) : I18n.tr(`module.${options.type}`)
    property bool framed: true
    // Room on the right of the title row (Media / Network chips).
    property real titleReserve: 0

    readonly property real side: Math.min(width, height)
    readonly property string tier: side >= 1240 ? "poster" : side >= 760 ? "large" : "normal"
    readonly property bool large: tier !== "normal"
    readonly property bool poster: tier === "poster"
    readonly property real pad: poster ? 44 : large ? 32 : Math.max(12, Math.min(24, side * 0.07))
    readonly property real gap: poster ? 28 : large ? 20 : Math.max(8, pad * 0.6)
    readonly property real cw: Math.max(1, width - 2 * pad)
    readonly property real ch: Math.max(1, height - 2 * pad - panel.titleHeight)
    readonly property real ratio: cw / ch
    readonly property string shape: cw <= 220 && ch <= 200 ? "tiny" : cw <= 220 ? "narrow" : ratio < 0.8 ? "tall" : ratio >= 4 ? "strip" : ratio >= 1.8 ? "wide" : "box"
    readonly property real m: Math.min(cw, ch)
    function clamp(low: real, value: real, high: real): real {
        return Math.max(low, Math.min(high, value));
    }
    readonly property real t2: poster ? clamp(60, m * 0.048, 84) : large ? clamp(44, m * 0.055, 60) : clamp(17, m * 0.11, 40)
    readonly property real t3: poster ? clamp(28, m * 0.021, 32) : large ? clamp(24, m * 0.026, 28) : clamp(13, m * 0.075, 24)
    readonly property real t4: poster ? clamp(17, m * 0.014, 20) : large ? clamp(15, m * 0.017, 17) : clamp(10, m * 0.055, 15)
    readonly property real hk: theme.font.heroScale ?? 1
    // The main figure's cap on big cells (else it would fill them).
    readonly property real heroMax: poster ? clamp(240, m * 0.24, 440) : large ? clamp(140, m * 0.22, 280) : Infinity
    // Pointer / touch target size.
    readonly property real hit: poster ? (theme.touch ? 88 : 64) : large ? (theme.touch ? 76 : 56) : theme.hit

    // Main figure size: the smaller of a fraction of the height and of
    // the width (never overflows), within heroMax on big cells.
    function figure(hFraction: real, wFraction: real): real {
        return Math.min(ch * hFraction, cw * wFraction, heroMax) * hk;
    }

    // How many items of height `h` fit (lines, gauges, hours), at most `max`.
    function fit(h: real, max: int): int {
        return Math.max(1, Math.min(max, Math.floor((ch + gap) / (h + gap))));
    }

    // Columns × rows showing as many of `nMax` square items as fit at
    // `minSize` or more (all of them whenever they fit: the same count at
    // any nearby cell size, editor or not), as big as possible for that
    // count: { n, columns, rows, size }.
    function bestGrid(nMax: int, minSize: real): var {
        for (let n = nMax; n >= 1; n--) {
            let best = null;
            for (let c = 1; c <= n; c++) {
                const r = Math.ceil(n / c);
                const size = Math.min((cw - (c - 1) * gap) / c, (ch - (r - 1) * gap) / r);
                if (size >= minSize && (!best || size > best.size))
                    best = { n: n, columns: c, rows: r, size: size };
            }
            if (best)
                return best;
        }
        return { n: 1, columns: 1, rows: 1, size: Math.min(cw, ch) };
    }

    default property alias content: inner.data
    readonly property alias inner: inner

    ModulePanel {
        id: panel
        anchors.fill: parent
        visible: base.framed
        title: base.framed ? base.title : ""
        titleReserve: base.titleReserve
        tier: base.tier
        // Screen modules wear Modulaire's black finish.
        finish: ["vu", "system", "network", "notificationSample"].includes(base.options.type ?? "") ? "black" : "normal"
    }

    Item {
        id: inner

        x: base.pad
        y: base.pad + panel.titleHeight
        width: base.cw
        height: base.ch
    }
}
