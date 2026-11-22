import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import qs.components
import qs.theme

// Workspaces of the screen the block is on (special workspaces excluded).
// Click to focus, wheel to move to the previous/next one.
// Look follows theme.style.workspaces: "labels" | "dots" (the active dot
// is a pill, lying on a horizontal bar, standing on a vertical one).
Grid {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    property ShellScreen screen
    property var options: ({})
    property bool vertical: false
    property int crossSize: 0

    readonly property var workspaces: Hyprland.workspaces.values
        .filter(ws => ws.id > 0 && ws.monitor?.name === root.screen?.name)
        .sort((a, b) => a.id - b.id)

    // "stars" draws like "dots", with a star for the active workspace.
    readonly property bool stars: theme.style.workspaces === "stars"
    readonly property bool dots: theme.style.workspaces === "dots" || stars
    readonly property int cell: (crossSize > 0 ? crossSize : theme.bar.height - theme.space.s)

    columns: vertical ? 1 : Math.max(1, workspaces.length)
    spacing: dots ? theme.space.s : theme.space.xs
    horizontalItemAlignment: Grid.AlignHCenter
    verticalItemAlignment: Grid.AlignVCenter

    Repeater {
        model: root.workspaces

        Rectangle {
            id: item

            required property HyprlandWorkspace modelData

            readonly property color dotColor: modelData.urgent ? root.theme.color.urgent
                : modelData.active ? root.theme.color.accent
                : root.theme.color.soft
            readonly property int pill: modelData.active ? 27 : 8

            readonly property bool star: root.stars && modelData.active

            implicitWidth: star ? 16 : root.dots ? (root.vertical ? 8 : pill) : Math.max(root.cell, label.implicitWidth + root.theme.space.s * 2)
            implicitHeight: star ? 16 : root.dots ? (root.vertical ? pill : 8) : Math.min(root.cell, 32)
            radius: root.dots ? root.theme.radius.full : root.theme.radius.control
            color: star ? "transparent" : root.dots ? dotColor : modelData.active ? root.theme.color.surface2 : "transparent"

            // The active dot glows where the theme glows (Matrix in dark).
            layer.enabled: root.dots && modelData.active && Qt.color(root.theme.color.glow ?? "#00000000").a > 0
            layer.effect: MultiEffect {
                autoPaddingEnabled: true
                shadowEnabled: true
                shadowColor: root.theme.color.glow ?? "transparent"
                shadowBlur: 0.7
                blurMax: 12
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
            }

            // Four-pointed star for the active workspace ("stars" style).
            ThemedText {
                anchors.centerIn: parent
                visible: item.star
                text: "✦"
                color: item.modelData.urgent ? root.theme.color.urgent : root.theme.color.accent
                font.pixelSize: 18
            }

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: root.theme.motion.duration
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on implicitHeight {
                NumberAnimation {
                    duration: root.theme.motion.duration
                    easing.type: Easing.OutCubic
                }
            }

            ThemedText {
                id: label
                visible: !root.dots
                anchors.centerIn: parent
                text: item.modelData.name
                color: item.modelData.urgent ? root.theme.color.urgent
                     : item.modelData.active ? root.theme.color.ink
                     : root.theme.color.soft
            }

            MouseArea {
                // Dots are small: keep a comfortable hit area.
                anchors.centerIn: parent
                width: Math.max(parent.width, root.theme.hit)
                height: Math.max(parent.height, root.theme.hit)
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${item.modelData.id} })`)
                onWheel: wheel => Hyprland.dispatch(`hl.dsp.focus({ workspace = "${wheel.angleDelta.y > 0 ? "m-1" : "m+1"}" })`)
            }
        }
    }
}
