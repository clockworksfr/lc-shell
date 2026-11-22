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

// Dashboard of a "modules" screen: the page of its active workspace, drawn
// on the bottom layer (under windows, which CellTiler floats into the
// window cells).
PanelWindow {
    id: win

    property var config: ({})
    property var theme

    readonly property var grid: Dashboard.grid(config)
    readonly property string workspace: Hyprland.monitorFor(screen)?.activeWorkspace?.name ?? ""
    // The showcase (tests) replaces the page while it's on.
    readonly property var cells: Showcase.type ? Showcase.cells : Dashboard.page(config, workspace)

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
                if (!DashboardEditor.editing)
                    menu.openAt(mouse.x, mouse.y);
            }
        }
    }

    MenuPopup {
        id: menu

        host: win
        actions: [
            { id: "edit", icon: "edit", text: I18n.tr("dashboard.menu.edit") },
            { id: "dashboard", icon: "tune", text: I18n.tr("dashboard.menu.settings") },
            { id: "settings", icon: "settings", text: I18n.tr("bar.menu.settings") }
        ]
        onPicked: id => {
            if (id === "edit")
                DashboardEditor.start(win.screen.name);
            else if (id === "dashboard")
                Settings.open("dashboard");
            else
                Settings.open("appearance");
        }
    }

    // Everything drawn (also what `snapshot` renders).
    Item {
        id: canvas

        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            color: win.theme.color.bg
        }

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
