import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.components
import qs.launcher
import qs.theme

// Launcher overlay on the focused screen.
// Keys: Up/Down (or Ctrl+K/J), Enter, Shift+Enter (alternate action),
// Tab (next mode), Escape. Click outside to close.
PanelWindow {
    id: win

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lc-launcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    readonly property int rowHeight: 44
    readonly property int visibleRows: 9

    MouseArea {
        anchors.fill: parent
        onClicked: Launcher.close()
    }

    Rectangle {
        id: panel

        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.2
        width: 640
        height: column.implicitHeight + Theme.space.m * 2
        radius: Theme.radius.m
        color: Theme.color.surface

        // Swallow clicks so they don't reach the close area.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: column

            anchors.fill: parent
            anchors.margins: Theme.space.m
            spacing: Theme.space.s

            TextInput {
                id: input

                width: parent.width
                focus: true
                text: Launcher.text
                color: Theme.color.fg
                selectionColor: Theme.color.accent
                selectedTextColor: Theme.color.bg
                font.family: Theme.font.family
                font.pixelSize: Theme.font.sizeL
                onTextEdited: Launcher.text = text

                ThemedText {
                    visible: !input.text
                    text: "Rechercher…"
                    color: Theme.color.fgMuted
                    font.pixelSize: Theme.font.sizeL
                }

                Keys.onPressed: event => {
                    const ctrl = event.modifiers & Qt.ControlModifier;
                    if (event.key === Qt.Key_Escape) {
                        Launcher.close();
                    } else if (event.key === Qt.Key_Down || (ctrl && event.key === Qt.Key_J)) {
                        list.incrementCurrentIndex();
                    } else if (event.key === Qt.Key_Up || (ctrl && event.key === Qt.Key_K)) {
                        list.decrementCurrentIndex();
                    } else if (event.key === Qt.Key_PageDown) {
                        list.currentIndex = Math.min(list.count - 1, list.currentIndex + win.visibleRows);
                    } else if (event.key === Qt.Key_PageUp) {
                        list.currentIndex = Math.max(0, list.currentIndex - win.visibleRows);
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        Launcher.activate(Launcher.results[list.currentIndex], event.modifiers & Qt.ShiftModifier);
                    } else if (event.key === Qt.Key_Tab) {
                        modes.next();
                    } else {
                        return;
                    }
                    event.accepted = true;
                }
            }

            // Mode chips: click or Tab to switch.
            Row {
                id: modes

                spacing: Theme.space.m

                function next(): void {
                    const all = [null, ...Launcher.modes];
                    const index = all.indexOf(Launcher.mode);
                    const nextMode = all[(index + 1) % all.length];
                    Launcher.text = (nextMode?.prefix ?? "") + Launcher.term;
                }

                Repeater {
                    model: [{ prefix: "", id: "all", label: "tout" }, ...Launcher.modes]

                    ThemedText {
                        required property var modelData
                        text: modelData.prefix ? `${modelData.prefix} ${modelData.label}` : modelData.label
                        font.pixelSize: Theme.font.sizeS
                        color: Launcher.modeId === modelData.id ? Theme.color.fg : Theme.color.fgMuted

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Launcher.text = parent.modelData.prefix + Launcher.term;
                                input.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            ListView {
                id: list

                width: parent.width
                height: Math.min(count, win.visibleRows) * win.rowHeight
                clip: true
                model: Launcher.results
                currentIndex: 0
                highlightMoveDuration: 0
                boundsBehavior: Flickable.StopAtBounds

                onModelChanged: currentIndex = 0

                delegate: Rectangle {
                    id: row

                    required property var modelData
                    required property int index
                    readonly property bool current: ListView.isCurrentItem

                    width: list.width
                    height: win.rowHeight
                    radius: Theme.radius.s
                    color: current ? Theme.color.bg : "transparent"

                    Item {
                        id: iconBox

                        anchors.left: parent.left
                        anchors.leftMargin: Theme.space.s
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28

                        IconImage {
                            anchors.fill: parent
                            visible: !row.modelData.glyph
                            source: row.modelData.icon ? Quickshell.iconPath(row.modelData.icon, "application-x-executable") : ""
                        }

                        ThemedText {
                            anchors.centerIn: parent
                            visible: !!row.modelData.glyph
                            text: row.modelData.glyph ?? ""
                            font.pixelSize: 22
                        }
                    }

                    Column {
                        anchors.left: iconBox.right
                        anchors.leftMargin: Theme.space.m
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.space.s
                        anchors.verticalCenter: parent.verticalCenter

                        ThemedText {
                            width: parent.width
                            text: row.modelData.title
                            elide: Text.ElideRight
                        }

                        ThemedText {
                            width: parent.width
                            visible: !!row.modelData.subtitle
                            text: row.modelData.subtitle ?? ""
                            font.pixelSize: Theme.font.sizeS
                            color: row.modelData.urgent ? Theme.color.urgent : Theme.color.fgMuted
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onEntered: list.currentIndex = row.index
                        // Right click = alternate action (like Shift+Enter).
                        onClicked: mouse => Launcher.activate(row.modelData, mouse.button === Qt.RightButton)
                    }
                }
            }

            ThemedText {
                visible: list.count === 0
                text: Launcher.modeId === "files" && Launcher.term.length < 2 ? "Tape au moins 2 caractères" : "Aucun résultat"
                color: Theme.color.fgMuted
                font.pixelSize: Theme.font.sizeS
            }
        }
    }
}
