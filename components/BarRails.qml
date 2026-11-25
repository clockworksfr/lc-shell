import QtQuick

// Two perforated metal rails along a bar case's long edges (Modulaire):
// 6 px, a brushed gradient, holes every 20 px. Inset by
// the case's corner radius along the bar.
Item {
    id: root

    property bool vertical: false
    property real radius: 0
    readonly property real rail: 6

    Repeater {
        model: 2

        Rectangle {
            required property int index
            x: root.vertical ? (index === 0 ? 0 : root.width - width) : root.radius
            y: root.vertical ? root.radius : (index === 0 ? 0 : root.height - height)
            width: root.vertical ? root.rail : root.width - 2 * root.radius
            height: root.vertical ? root.height - 2 * root.radius : root.rail
            gradient: Gradient {
                orientation: root.vertical ? Gradient.Horizontal : Gradient.Vertical
                GradientStop {
                    position: 0
                    color: "#C3C6C8"
                }
                GradientStop {
                    position: 1
                    color: "#7D8083"
                }
            }

            Canvas {
                anchors.fill: parent
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const along = root.vertical ? height : width;
                    const across = root.vertical ? width : height;
                    for (let p = 10; p < along - 4; p += 20) {
                        const x = root.vertical ? across / 2 : p;
                        const y = root.vertical ? p : across / 2;
                        ctx.beginPath();
                        ctx.arc(x, y, 2.6, 0, Math.PI * 2);
                        ctx.fillStyle = "rgba(42,43,44,0.45)";
                        ctx.fill();
                        ctx.beginPath();
                        ctx.arc(x, y, 2, 0, Math.PI * 2);
                        ctx.fillStyle = "#2A2B2C";
                        ctx.fill();
                    }
                }
            }
        }
    }
}
