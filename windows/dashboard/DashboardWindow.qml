import QtQuick
import Quickshell
import qs.theme
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.dashboard
import qs.dashboard.modules

// Dashboard of a "modules" screen: the page of its active workspace, drawn
// on the bottom layer (under windows, which CellTiler floats into the
// window cells).
PanelWindow {
    id: win

    property var config: ({})
    property var theme

    readonly property var grid: Dashboard.grid(config)
    readonly property string workspace: Hyprland.monitorFor(screen)?.activeWorkspace?.name ?? ""
    readonly property var cells: Dashboard.page(config, workspace)

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: theme.color.bg
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "lc-dashboard"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Repeater {
        model: win.cells

        Item {
            id: cell

            required property var modelData
            readonly property var rect: Dashboard.rect(modelData, win.grid, win.width, win.height)
            readonly property bool framed: !Registry.frameless.includes(modelData.type)

            x: rect.x
            y: rect.y
            width: rect.width
            height: rect.height

            // Page change: modules fade in, column by column.
            opacity: 0
            Component.onCompleted: cellEnter.start()

            SequentialAnimation {
                id: cellEnter
                PauseAnimation {
                    duration: Motion.reduced ? 0 : (cell.modelData.x ?? 0) * (win.theme.motion.stagger ?? 20)
                }
                NumberAnimation {
                    target: cell
                    property: "opacity"
                    to: 1
                    duration: Motion.ms(win.theme, "slow", win.screen?.name ?? "")
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                anchors.fill: parent
                visible: cell.framed
                radius: win.theme.radius.card
                color: win.theme.color.surface
                border.width: win.theme.border.width
                border.color: win.theme.color.line
            }

            Loader {
                anchors.fill: parent
                anchors.margins: cell.framed ? win.theme.space.l : 0
                source: Registry.url(cell.modelData.type)
                onLoaded: {
                    item.screen = Qt.binding(() => win.screen);
                    item.options = Qt.binding(() => cell.modelData);
                    if ("type" in item)
                        item.type = Qt.binding(() => cell.modelData.type);
                }
            }
        }
    }
}
