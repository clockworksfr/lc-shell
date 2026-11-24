import QtQuick
import Quickshell
import qs.theme

// Small line chart: `values` (numbers), scaled to `max` (auto when 0),
// stroked in `color` with a soft fill under it.
Canvas {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    property var values: []
    property real max: 0
    property color color: theme.color.accent
    property real lineWidth: 2
    property real fillAlpha: 0.15
    // Dashed continuation from the last value (projection), optional.
    property var projection: []

    implicitHeight: 40
    onValuesChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const all = [...values, ...projection];
        if (values.length < 2)
            return;
        const top = max > 0 ? max : Math.max(...all, 1e-9);
        const step = width / Math.max(1, all.length - 1);
        const y = v => height - 2 - (Math.min(v, top) / top) * (height - 4);

        ctx.beginPath();
        values.forEach((v, i) => i === 0 ? ctx.moveTo(0, y(v)) : ctx.lineTo(i * step, y(v)));
        ctx.lineWidth = lineWidth;
        ctx.lineJoin = "round";
        ctx.strokeStyle = color;
        ctx.stroke();

        ctx.lineTo((values.length - 1) * step, height);
        ctx.lineTo(0, height);
        ctx.closePath();
        ctx.fillStyle = Qt.alpha(color, fillAlpha);
        ctx.fill();

        if (projection.length > 0) {
            ctx.beginPath();
            ctx.setLineDash([4, 4]);
            const start = values.length - 1;
            ctx.moveTo(start * step, y(values[start]));
            projection.forEach((v, i) => ctx.lineTo((start + i + 1) * step, y(v)));
            ctx.strokeStyle = Qt.alpha(color, 0.6);
            ctx.stroke();
        }
    }
}
