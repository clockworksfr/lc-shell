import QtQuick
import Quickshell
import qs.components.dashboard
import qs.i18n
import qs.theme

// Common base of dashboard modules (design study 7): the theme's frame
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
Item {
    id: base

    property ShellScreen screen
    // The cell ({ type, x, y, w, h, ...options }).
    property var options: ({})
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    // Narrow cells take the short name when there is one ("Espaces").
    property string title: !options.type ? "" : width < 220 && I18n.has(`module.${options.type}.short`) ? I18n.tr(`module.${options.type}.short`) : I18n.tr(`module.${options.type}`)
    property bool framed: true

    readonly property real pad: Math.max(12, Math.min(24, Math.min(width, height) * 0.07))
    readonly property real gap: Math.max(8, pad * 0.6)
    readonly property real cw: Math.max(1, width - 2 * pad)
    readonly property real ch: Math.max(1, height - 2 * pad - panel.titleHeight)
    readonly property real ratio: cw / ch
    readonly property string shape: cw <= 220 && ch <= 200 ? "tiny" : cw <= 220 ? "narrow" : ratio < 0.8 ? "tall" : ratio >= 4 ? "strip" : ratio >= 1.8 ? "wide" : "box"
    readonly property real m: Math.min(cw, ch)
    readonly property real t2: Math.min(40, Math.max(17, m * 0.11))
    readonly property real t3: Math.min(24, Math.max(13, m * 0.075))
    readonly property real t4: Math.min(15, Math.max(10, m * 0.055))
    readonly property real hk: theme.font.heroScale ?? 1

    // Main figure size: the smaller of a fraction of the height and of
    // the width (never overflows).
    function figure(hFraction: real, wFraction: real): real {
        return Math.min(ch * hFraction, cw * wFraction) * hk;
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
    }

    Item {
        id: inner

        x: base.pad
        y: base.pad + panel.titleHeight
        width: base.cw
        height: base.ch
    }
}
