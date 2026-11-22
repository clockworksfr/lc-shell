import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.i18n
import qs.services
import qs.theme

// A menu in the theme's look, attached to a bar (or any window): either
// fixed `actions` ([{ id, icon, text }] → picked(id)) or an app's menu
// (`menu`, a tray item's QsMenuHandle: entries, separators, check / radio
// items, submenus opened in place with a "back" row). Closes on pick and
// on a click outside or Escape.
//
// A layer surface (like the panels): a popup only shows while its bar has
// the pointer, and a click outside it can't be caught reliably.
PanelWindow {
    id: root

    required property var host
    property var actions: []
    property QsMenuHandle menu: null
    // Open submenus (last = shown).
    property var stack: []
    readonly property var theme: host?.theme ?? Themes.fallback
    readonly property string edge: host?.edge ?? "top"

    signal picked(string id)

    // Text and icons in proportion to the rows: touch screens (the modules
    // screen: 72 px targets) get big rows, so big text too.
    // (touch: 56 px rows, still a comfortable target, text in proportion
    // with the modules, not bigger).
    readonly property real rowHeight: theme.hit >= 48 ? Math.round(theme.hit * 0.78) : Math.max(34, theme.hit + 10)
    readonly property real textSize: Math.max(theme.font.sizeM, Math.min(18, rowHeight * 0.32))
    readonly property real iconSize: Math.max(18, Math.round(textSize * 1.25))

    // Point it opens from, on its screen.
    property point origin

    // Opens at (x, y) of the host's content, away from the bar's edge,
    // kept on screen.
    function openAt(x: real, y: real): void {
        stack = [];
        const o = host.origin ? host.origin() : Qt.point(0, 0);
        origin = Qt.point(o.x + x, o.y + y);
        visible = true;
        frame.forceActiveFocus();
    }

    function close(): void {
        visible = false;
        stack = [];
        Qt.callLater(ShellState.restoreFocus);
    }

    function activate(entry: var): void {
        if (!root.menu) {
            root.picked(entry.id);
            close();
        } else if (entry.hasChildren) {
            stack = [...stack, entry];
        } else {
            entry.triggered();
            close();
        }
    }

    screen: host?.screen ?? null
    anchors {
        top: true
        left: true
    }
    margins {
        left: {
            const w = implicitWidth, sw = screen?.width ?? 0;
            const x = edge === "left" ? origin.x : edge === "right" ? origin.x - w : origin.x - w / 2;
            return Math.max(8, Math.min(x, sw - w - 8));
        }
        top: {
            const h = implicitHeight, sh = screen?.height ?? 0;
            const y = edge === "top" ? origin.y : edge === "bottom" ? origin.y - h : origin.y - h / 2;
            return Math.max(8, Math.min(y, sh - h - 8));
        }
    }
    visible: false
    color: "transparent"
    implicitWidth: Math.min(400, 280 * textSize / theme.font.sizeM)
    implicitHeight: column.implicitHeight + theme.space.xs * 2
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lc-menu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    HyprlandFocusGrab {
        active: root.visible
        windows: [root]
        onCleared: root.close()
    }

    QsMenuOpener {
        id: opener
        menu: root.stack.length ? root.stack[root.stack.length - 1] : root.menu
    }

    Rectangle {
        id: frame

        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.stack.length ? root.stack = root.stack.slice(0, -1) : root.close()
        radius: root.theme.radius.card
        color: root.theme.color.surface
        border.width: root.theme.border.width
        border.color: root.theme.color.line
        // Grows from the side it opens on.
        transformOrigin: root.edge === "bottom" ? Item.Bottom : root.edge === "left" ? Item.Left : root.edge === "right" ? Item.Right : Item.Top
        opacity: root.visible ? 1 : 0
        scale: root.visible || Motion.reduced ? 1 : 0.94

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.ms(root.theme, "fast", "")
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Motion.ms(root.theme, "base", "")
                easing.type: Motion.easing(root.theme)
                easing.overshoot: Motion.overshoot(root.theme)
            }
        }

        Column {
            id: column

            x: root.theme.space.xs
            y: root.theme.space.xs
            width: parent.width - root.theme.space.xs * 2

            // Submenu: back to the parent menu.
            MenuRow {
                visible: root.stack.length > 0
                theme: root.theme
                iconName: "chevron_left"
                text: I18n.tr("common.back")
                soft: true
                onClicked: root.stack = root.stack.slice(0, -1)
            }

            Repeater {
                model: root.menu ? [...opener.children.values] : root.actions

                MenuRow {
                    required property var modelData
                    theme: root.theme
                    separator: !!modelData.isSeparator
                    iconName: root.menu ? "" : (modelData.icon ?? "")
                    iconSource: root.menu ? (modelData.icon ?? "") : ""
                    text: modelData.text ?? ""
                    enabled: modelData.enabled ?? true
                    submenu: !!modelData.hasChildren
                    check: root.menu ? (modelData.buttonType === QsMenuButtonType.CheckBox ? "box" : modelData.buttonType === QsMenuButtonType.RadioButton ? "radio" : "") : (modelData.check ?? "")
                    checked: root.menu ? modelData.checkState === Qt.Checked : !!modelData.checked
                    onClicked: root.activate(modelData)
                }
            }
        }
    }

    component MenuRow: Item {
        id: row

        property var theme
        property bool separator: false
        property string iconName
        property string iconSource
        property string text
        property bool submenu: false
        property bool soft: false
        // "" | "box" | "radio"
        property string check
        property bool checked: false

        signal clicked

        width: parent?.width ?? 0
        height: separator ? 9 : root.rowHeight

        Rectangle {
            visible: row.separator
            anchors.verticalCenter: parent.verticalCenter
            x: row.theme.space.s
            width: parent.width - row.theme.space.s * 2
            height: 1
            color: row.theme.color.line
        }

        Rectangle {
            visible: !row.separator
            anchors.fill: parent
            radius: row.theme.radius.control
            color: hover.hovered && row.enabled ? Qt.alpha(row.theme.color.accent, 0.14) : "transparent"
        }

        Row {
            visible: !row.separator
            anchors.verticalCenter: parent.verticalCenter
            x: row.theme.space.s
            width: parent.width - row.theme.space.s * 2
            spacing: row.theme.space.s
            opacity: row.enabled ? 1 : 0.45

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                visible: !!row.check
                name: row.check === "radio" ? (row.checked ? "radio_button_checked" : "radio_button_unchecked") : (row.checked ? "check_box" : "check_box_outline_blank")
                filled: row.checked
                size: root.iconSize
                color: row.checked ? row.theme.color.accent : row.theme.color.soft
            }

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                visible: !!row.iconName
                name: row.iconName
                size: root.iconSize
                color: row.theme.color.soft
            }

            IconImage {
                anchors.verticalCenter: parent.verticalCenter
                visible: !!row.iconSource
                implicitSize: root.iconSize
                source: row.iconSource
            }

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - x - (row.submenu ? root.iconSize + 6 : 0)
                elide: Text.ElideRight
                text: row.text.replace(/_(?!_)/g, "")
                font.pixelSize: root.textSize
                color: row.soft ? row.theme.color.soft : row.theme.color.ink
            }
        }

        Icon {
            visible: row.submenu
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: row.theme.space.s
            name: "chevron_right"
            size: root.iconSize
            color: row.theme.color.soft
        }

        HoverHandler {
            id: hover
        }

        MouseArea {
            anchors.fill: parent
            enabled: !row.separator && row.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: row.clicked()
        }
    }
}
