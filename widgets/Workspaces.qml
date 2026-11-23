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
    readonly property bool dots: theme.style.workspaces === "dots" || theme.style.workspaces === "numbered" || stars
    // "numbered" (Matrix): a dot and its number per workspace, empty ones
    // in between (and up to five) shown dim; dots only on a vertical bar.
    readonly property bool numbered: theme.style.workspaces === "numbered" && !vertical
    readonly property var numberedIds: {
        const ids = workspaces.map(ws => ws.id);
        if (!ids.length)
            return [];
        const first = Math.min(...ids);
        const last = Math.max(Math.max(...ids), first + 4);
        return Array.from({ length: last - first + 1 }, (_, i) => first + i);
    }
    readonly property int cell: (crossSize > 0 ? crossSize : theme.bar.height - theme.space.s)

    columns: vertical ? 1 : Math.max(1, numbered ? numberedIds.length : workspaces.length)
    spacing: numbered ? 14 : dots ? theme.space.s : theme.space.xs
    horizontalItemAlignment: Grid.AlignHCenter
    verticalItemAlignment: Grid.AlignVCenter

    Repeater {
        model: root.numbered ? root.numberedIds : []

        Item {
            id: numberedItem

            required property int modelData
            readonly property var ws: root.workspaces.find(w => w.id === modelData) ?? null
            readonly property bool active: ws?.active ?? false
            readonly property color ink: ws?.urgent ? root.theme.color.urgent
                : active ? root.theme.color.accent
                : ws ? root.theme.color.ink
                : root.theme.color.line

            implicitWidth: numberedRow.implicitWidth
            implicitHeight: numberedRow.implicitHeight

            // Halo of the active (or urgent) dot where the theme glows
            // (Matrix in dark): a blurred copy behind it, outside the row
            // (a layer inside the row looped its layout).
            Rectangle {
                z: -1
                visible: (numberedItem.active || !!numberedItem.ws?.urgent) && Qt.color(root.theme.color.glow ?? "#00000000").a > 0
                x: numberedRow.x + dot.x
                y: numberedRow.y + dot.y
                width: dot.width
                height: dot.height
                radius: dot.radius
                color: dot.color
                layer.enabled: visible
                layer.effect: MultiEffect {
                    autoPaddingEnabled: true
                    shadowEnabled: true
                    shadowColor: numberedItem.ws?.urgent ? root.theme.color.urgent : root.theme.color.glow ?? "transparent"
                    shadowBlur: 0.9
                    blurMax: 14
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 0
                }
            }

            Row {
            id: numberedRow
            spacing: 6

            Rectangle {
                id: dot
                anchors.verticalCenter: parent.verticalCenter
                width: numberedItem.active ? 13 : 6
                height: 6
                radius: 3
                color: numberedItem.ink

                Behavior on width {
                    NumberAnimation {
                        duration: root.theme.motion.duration
                        easing.type: Easing.OutCubic
                    }
                }
            }

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                text: numberedItem.modelData
                color: numberedItem.ink
                font.family: root.theme.font.mono
                font.pixelSize: 12
                font.weight: numberedItem.active ? Font.Bold : Font.Normal
            }
            }

            MouseArea {
                width: parent.width + 12
                height: Math.max(parent.height, root.theme.hit)
                x: -6
                y: (parent.height - height) / 2
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${numberedItem.modelData} })`)
                onWheel: wheel => Hyprland.dispatch(`hl.dsp.focus({ workspace = "${wheel.angleDelta.y > 0 ? "m-1" : "m+1"}" })`)
            }
        }
    }

    Repeater {
        model: root.numbered ? [] : root.workspaces

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
                shadowBlur: 0.94
                blurMax: 18
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
