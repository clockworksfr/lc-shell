import QtQuick
import Quickshell
import qs.theme

// Common base of dashboard modules (design study 6): the cell's size tier
// (S 2 × 1, M 4 × 2, L 6 × 3 and up) and a type scale in proportion to the
// cell's height, so a module fills its cell and reads from afar:
//   t1 main figure, t2 title, t3 text, t4 label.
// Children go in `inner` (padded in proportion too).
Item {
    id: base

    property ShellScreen screen
    // The cell ({ type, x, y, w, h, ...options }).
    property var options: ({})
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    readonly property int cols: options.w ?? 2
    readonly property int rows: options.h ?? 1
    // Tier from the smaller side, in S units (2 × 1): a 2 × 4 cell is S.
    readonly property real units: Math.min(cols / 2, rows)
    readonly property string tier: units >= 3 ? "L" : units >= 2 ? "M" : "S"
    readonly property var k: ({ S: [0.58, 0.17, 0.125, 0.10], M: [0.44, 0.10, 0.076, 0.058], L: [0.36, 0.078, 0.054, 0.042] })[tier]
    readonly property real hk: theme.font.heroScale ?? 1
    // Height the scale is computed on: a tall, narrow cell reads like the
    // tier's own shape (about 2.5 : 1), not like its full height.
    readonly property real span: Math.min(height, width / 2.5)
    readonly property real t1: span * k[0] * hk
    readonly property real t2: Math.max(16, span * k[1])
    readonly property real t3: Math.max(14, span * k[2])
    readonly property real t4: Math.max(11, span * k[3])
    readonly property real pad: tier === "S" ? span * 0.09 : Math.min(span * 0.07, 24)
    readonly property real gap: Math.max(8, pad * 0.6)

    default property alias content: inner.data
    readonly property alias inner: inner

    Item {
        id: inner

        anchors.fill: parent
        anchors.margins: base.pad
    }
}
