import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Active window: app, workspace and screen, full title, the app's other
// windows (click to go), actions (float, fullscreen, pin, move to a
// workspace, close — close asks twice). Titles hidden while sharing.
Column {
    id: root

    property var block
    property ShellScreen screen
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    readonly property var window: block?.current ?? null
    readonly property string appClass: block?.appClass ?? ""
    readonly property var siblings: Hyprland.toplevels.values.filter(t => t !== window && (t.lastIpcObject?.class ?? "") === appClass && appClass)
    readonly property var workspaces: Hyprland.workspaces.values.filter(ws => ws.id > 0).sort((a, b) => a.id - b.id)
    property bool confirmClose: false

    function selector(toplevel: var): string {
        const address = toplevel?.address ?? "";
        return `window = "address:${address.startsWith("0x") ? address : "0x" + address}"`;
    }

    function act(command: string): void {
        if (root.window)
            Hyprland.dispatch(command);
    }

    spacing: theme.space.m

    // App, workspace, screen.
    Row {
        width: parent.width
        spacing: root.theme.space.m

        AppIcon {
            anchors.verticalCenter: parent.verticalCenter
            size: 36
            name: root.block?.entry?.icon ?? ""
            visible: !!root.block?.entry?.icon
            source: root.block?.entry?.icon ? Quickshell.iconPath(root.block.entry.icon, true) : ""
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 48

            ThemedText {
                width: parent.width
                text: root.block?.appName ?? ""
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            ThemedText {
                text: [I18n.tr("card.workspace", { n: root.window?.workspace?.name ?? "?" }), root.screen?.name ?? ""].join(" · ")
                color: root.theme.color.soft
                font.pixelSize: root.theme.font.sizeS
            }
        }
    }

    ThemedText {
        width: parent.width
        visible: !Screens.sharing && !!root.window?.title
        text: root.window?.title ?? ""
        wrapMode: Text.Wrap
        maximumLineCount: 3
        elide: Text.ElideRight
    }

    ThemedText {
        visible: Screens.sharing
        text: I18n.tr("card.titleHidden")
        color: root.theme.color.warn
        font.pixelSize: root.theme.font.sizeS
    }

    // Other windows of the same app.
    Column {
        visible: root.siblings.length > 0
        width: parent.width
        spacing: root.theme.space.xs

        ThemedText {
            text: I18n.plural("card.otherWindows", root.siblings.length)
            label: true
            color: root.theme.color.soft
        }

        Repeater {
            model: root.siblings.slice(0, 5)

            ListRow {
                required property var modelData
                title: Screens.sharing ? (root.block?.appName ?? "") : (modelData.title || modelData.lastIpcObject?.class || "")
                trailing: I18n.tr("card.workspace", { n: modelData.workspace?.name ?? "?" })
                onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${modelData.workspace?.id ?? 1} })`)
            }
        }
    }

    // Actions.
    Flow {
        width: parent.width
        spacing: root.theme.space.xs

        Repeater {
            model: [
                { icon: "tune", key: "card.float", run: () => root.act(`hl.dsp.window.float({ action = "toggle", ${root.selector(root.window)} })`) },
                { icon: "desktop_windows", key: "card.fullscreen", run: () => root.act(`hl.dsp.window.fullscreen({ ${root.selector(root.window)} })`) },
                { icon: "lock", key: "card.pin", run: () => root.act(`hl.dsp.window.pin({ ${root.selector(root.window)} })`) }
            ]

            ActionChip {
                required property var modelData
                icon: modelData.icon
                text: I18n.tr(modelData.key)
                onActivated: modelData.run()
            }
        }

        ActionChip {
            icon: "close"
            text: root.confirmClose ? I18n.tr("card.closeConfirm") : I18n.tr("card.close")
            danger: root.confirmClose
            onActivated: {
                if (!root.confirmClose) {
                    root.confirmClose = true;
                    return;
                }
                root.act(`hl.dsp.window.close({ ${root.selector(root.window)} })`);
                root.confirmClose = false;
            }
        }
    }

    // Move to a workspace.
    Flow {
        width: parent.width
        spacing: root.theme.space.xs

        ThemedText {
            height: 26
            text: I18n.tr("card.moveTo")
            color: root.theme.color.soft
            font.pixelSize: root.theme.font.sizeS
        }

        Repeater {
            model: root.workspaces

            Rectangle {
                required property HyprlandWorkspace modelData
                readonly property bool here: modelData === root.window?.workspace

                width: wsLabel.implicitWidth + root.theme.space.m
                height: 26
                radius: root.theme.radius.full
                color: here ? root.theme.color.accent : wsArea.containsMouse ? root.theme.color.surface3 : root.theme.color.surface2

                ThemedText {
                    id: wsLabel
                    anchors.centerIn: parent
                    text: parent.modelData.name
                    color: parent.here ? root.theme.color.onAccent : root.theme.color.ink
                    font.pixelSize: root.theme.font.sizeS
                }

                MouseArea {
                    id: wsArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !parent.here
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.act(`hl.dsp.window.move({ workspace = ${parent.modelData.id}, ${root.selector(root.window)} })`)
                }
            }
        }
    }

    component ActionChip: Rectangle {
        id: chip

        property string icon
        property string text
        property bool danger: false
        signal activated

        readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

        width: row.implicitWidth + theme.space.m * 2
        height: Math.max(30, theme.hit)
        radius: theme.radius.full
        color: danger ? theme.color.urgent : chipArea.containsMouse ? theme.color.surface3 : theme.color.surface2

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 6

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: chip.icon
                size: 16
                color: chip.danger ? chip.theme.color.onAccent : chip.theme.color.ink
            }

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.text
                font.pixelSize: chip.theme.font.sizeS
                color: chip.danger ? chip.theme.color.onAccent : chip.theme.color.ink
            }
        }

        MouseArea {
            id: chipArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.activated()
        }
    }
}
