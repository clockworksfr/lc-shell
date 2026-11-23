import QtQuick
import Quickshell
import qs.theme
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.dashboard
import qs.dashboard.modules
import qs.components
import qs.i18n
import qs.settings

// Dashboard of a screen: the preset of its active workspace (if it has
// one), on the bottom layer, under windows (which go over it, or into the
// window cells: CellTiler), over the wallpaper, inside the bar's room.
// Another workspace: it fades out and its modules go (they come back,
// column by column, on return).
PanelWindow {
    id: win

    property var theme

    readonly property string workspace: Hyprland.monitorFor(screen)?.activeWorkspace?.name ?? ""
    readonly property var preset: Dashboard.presetFor(workspace)
    readonly property bool shown: !!preset
    readonly property var grid: Dashboard.grid(preset)
    // The showcase (tests) replaces the page while it's on.
    readonly property var target: !shown ? [] : Showcase.type ? Showcase.cells : Dashboard.cells(preset)
    property var cells: []
    onTargetChanged: {
        if (shown) {
            fadeOut.stop();
            canvas.opacity = 1;
            cells = target;
            visible = true;
        } else if (visible) {
            fadeOut.restart();
        }
    }
    Component.onCompleted: {
        cells = target;
        visible = shown;
    }

    NumberAnimation {
        id: fadeOut
        target: canvas
        property: "opacity"
        to: 0
        duration: Motion.exitMs(win.theme, "base", win.screen?.name ?? "")
        easing.type: Easing.InCubic
        onFinished: {
            win.cells = [];
            win.visible = false;
            canvas.opacity = 1;
        }
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    // Inside the room left by the bar (if the screen has one).
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "lc-dashboard"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Connections {
        target: Showcase

        function onSnapshotRequested(path: string): void {
            canvas.grabToImage(result => result.saveToFile(`${path}-${win.screen.name}.png`));
        }
    }

    // Long press anywhere on the dashboard: edit it. Right click on an
    // empty spot or between modules: a menu (edit, settings).
    Item {
        anchors.fill: parent

        TapHandler {
            longPressThreshold: 0.6
            onLongPressed: DashboardEditor.start(win.screen.name)
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: mouse => {
                if (!DashboardEditor.editing) {
                    menu.actions = DashboardMenu.actions(win.workspace);
                    menu.openAt(mouse.x, mouse.y);
                }
            }
        }
    }

    MenuPopup {
        id: menu

        host: win
        onPicked: id => DashboardMenu.pick(id, win.workspace, win.screen.name)
    }

    // Everything drawn (also what `snapshot` renders).
    Item {
        id: canvas

        anchors.fill: parent

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

                // Modules draw their own frame (ModuleBase / ModulePanel).
                Loader {
                    anchors.fill: parent
                    // Modules pad themselves (ModuleBase: in proportion to the cell).
                    anchors.margins: 0
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
}
