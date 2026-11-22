import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.components
import qs.theme

// System tray (StatusNotifierItem). Left click: activate (or menu for
// menu-only items), right click: menu, middle click: secondary action,
// wheel: scroll. Options: showPassive (default false). Stacks on a
// vertical bar.
Grid {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    property ShellScreen screen
    property var options: ({})
    property bool vertical: false
    property int crossSize: 0

    readonly property var items: SystemTray.items.values.filter(item => root.options.showPassive || item.status !== Status.Passive)
    readonly property bool shown: items.length > 0

    columns: vertical ? 1 : Math.max(1, items.length)
    spacing: theme.space.s

    Repeater {
        model: root.items

        Item {
            id: slot

            required property SystemTrayItem modelData
            readonly property int size: Math.round(root.theme.font.sizeL * 1.1)

            implicitWidth: size
            implicitHeight: size

            AppIcon {
                anchors.fill: parent
                size: slot.size
                source: slot.modelData.icon
            }

            // The app's menu, drawn in the theme's look (not a platform menu).
            function openMenu(): void {
                const window = QsWindow.window;
                const point = slot.mapToItem(window.contentItem, slot.width / 2, slot.height / 2);
                const edge = window.edge ?? "top";
                const x = edge === "left" ? window.width : edge === "right" ? 0 : point.x;
                const y = edge === "top" ? window.height : edge === "bottom" ? 0 : point.y;
                menu.menu = slot.modelData.menu;
                menu.openAt(x, y);
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    const item = slot.modelData;
                    if (mouse.button === Qt.MiddleButton)
                        item.secondaryActivate();
                    else if (mouse.button === Qt.RightButton || item.onlyMenu)
                        item.hasMenu ? slot.openMenu() : item.activate();
                    else
                        item.activate();
                }
                onWheel: wheel => slot.modelData.scroll(wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x, wheel.angleDelta.y === 0)
            }
        }
    }

    MenuPopup {
        id: menu
        host: QsWindow.window
    }
}
