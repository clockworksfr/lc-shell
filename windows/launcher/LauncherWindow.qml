import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.components
import qs.launcher
import qs.theme
import qs.i18n

// Launcher overlay on the focused screen.
// Keys: Up/Down (or Ctrl+K/J), Enter, Shift+Enter (alternate action),
// Tab (next mode), Escape. Click outside to close.
PanelWindow {
    id: win

    property var theme: Themes.fallback

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    // Modulaire: black plate, the search and
    // the results in a green LCD, the current line inverted.
    readonly property bool mod: theme.style.module === "modulaire"
    readonly property color lcdInk: "#C6F37A"
    readonly property color lcdBg: "#1A2410"
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

        // Entrance: scale 0.96 → 1 and fade (theme curve).
        opacity: 0
        scale: Motion.reduced ? 1 : 0.96
        Component.onCompleted: enter.start()

        ParallelAnimation {
            id: enter
            NumberAnimation {
                target: panel
                property: "opacity"
                to: 1
                duration: Motion.ms(win.theme, "base", "")
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: panel
                property: "scale"
                to: 1
                duration: Motion.ms(win.theme, "base", "")
                easing.type: Motion.easing(win.theme)
                easing.overshoot: Motion.overshoot(win.theme)
            }
        }

        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.2
        width: 640
        height: column.implicitHeight + win.theme.space.m * 2
        radius: win.mod ? 3 : win.theme.radius.panel
        color: win.theme.color.surface
        gradient: win.mod ? blackPlate : null
        border.width: win.mod ? 1 : 0
        border.color: "#14FFFFFF"

        Gradient {
            id: blackPlate
            GradientStop {
                position: 0
                color: "#2A2B2D"
            }
            GradientStop {
                position: 1
                color: "#1F2022"
            }
        }

        // Modulaire: the LCD behind the search and the results.
        Rectangle {
            visible: win.mod
            x: win.theme.space.m - 8
            y: win.theme.space.m - 6
            width: parent.width - 2 * x
            height: parent.height - 2 * y
            radius: 4
            color: win.lcdBg
            border.width: 2
            border.color: "#80000000"
        }

        // Swallow clicks so they don't reach the close area.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: column

            anchors.fill: parent
            anchors.margins: win.theme.space.m
            spacing: win.theme.space.s

            TextInput {
                id: input

                width: parent.width
                focus: true
                text: Launcher.text
                color: win.mod ? win.lcdInk : win.theme.color.ink
                selectionColor: win.mod ? win.lcdInk : win.theme.color.accent
                selectedTextColor: win.mod ? win.lcdBg : win.theme.color.bg
                font.family: win.mod ? (win.theme.font.lcd ?? win.theme.font.mono) : win.theme.font.family
                font.capitalization: win.mod ? Font.AllUppercase : Font.MixedCase
                font.pixelSize: win.theme.font.sizeL
                // Modulaire: a "> " prompt.
                leftPadding: win.mod ? promptText.implicitWidth : 0

                Text {
                    id: promptText
                    visible: win.mod
                    text: "> "
                    font: input.font
                    color: win.lcdInk
                }
                onTextEdited: Launcher.text = text

                ThemedText {
                    visible: !input.text
                    x: input.leftPadding
                    text: I18n.tr("launcher.placeholder")
                    color: win.mod ? Qt.alpha(win.lcdInk, 0.5) : win.theme.color.soft
                    font.family: win.mod ? (win.theme.font.lcd ?? win.theme.font.mono) : win.theme.font.family
                    font.capitalization: win.mod ? Font.AllUppercase : Font.MixedCase
                    font.pixelSize: win.theme.font.sizeL
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

                spacing: win.theme.space.m

                function next(): void {
                    const all = [null, ...Launcher.modes];
                    const index = all.indexOf(Launcher.mode);
                    const nextMode = all[(index + 1) % all.length];
                    Launcher.text = (nextMode?.prefix ?? "") + Launcher.term;
                }

                Repeater {
                    model: [{ prefix: "", id: "all" }, ...Launcher.modes]

                    ThemedText {
                        required property var modelData
                        text: (modelData.prefix ? `${modelData.prefix} ` : "") + I18n.tr(`launcher.mode.${modelData.id}`)
                        font.pixelSize: win.theme.font.sizeS
                        color: win.mod ? (Launcher.modeId === modelData.id ? win.lcdInk : Qt.alpha(win.lcdInk, 0.5)) : Launcher.modeId === modelData.id ? win.theme.color.ink : win.theme.color.soft

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
                    radius: win.mod ? 2 : win.theme.radius.control
                    color: current ? (win.mod ? win.lcdInk : Qt.alpha(win.theme.color.accent, 0.14)) : "transparent"
                    readonly property color ink: win.mod ? (current ? win.lcdBg : win.lcdInk) : win.theme.color.ink

                    Item {
                        id: iconBox

                        anchors.left: parent.left
                        anchors.leftMargin: win.theme.space.s
                        anchors.verticalCenter: parent.verticalCenter
                        width: row.modelData.image ? 64 : 28
                        height: row.modelData.image ? 40 : 28

                        Image {
                            anchors.fill: parent
                            visible: !!row.modelData.image
                            source: row.modelData.image ? `file://${row.modelData.image}` : ""
                            sourceSize.width: 96
                            sourceSize.height: 96
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        IconImage {
                            anchors.fill: parent
                            visible: !row.modelData.glyph && !row.modelData.image
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
                        anchors.leftMargin: win.theme.space.m
                        anchors.right: parent.right
                        anchors.rightMargin: win.theme.space.s
                        anchors.verticalCenter: parent.verticalCenter

                        ThemedText {
                            width: parent.width
                            text: row.modelData.title
                            elide: Text.ElideRight
                            color: row.ink
                            font.family: win.mod ? (win.theme.font.lcd ?? win.theme.font.mono) : win.theme.font.family
                            font.capitalization: win.mod ? Font.AllUppercase : Font.MixedCase
                        }

                        ThemedText {
                            width: parent.width
                            visible: !!row.modelData.subtitle
                            text: row.modelData.subtitle ?? ""
                            font.pixelSize: win.theme.font.sizeS
                            font.family: win.mod ? (win.theme.font.lcd ?? win.theme.font.mono) : win.theme.font.family
                            color: row.modelData.urgent ? win.theme.color.urgent : win.mod ? Qt.alpha(row.ink, 0.65) : win.theme.color.soft
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
                text: Launcher.modeId === "files" && Launcher.term.length < 2 ? I18n.tr("launcher.minChars", { n: 2 })
                    : Launcher.modeId === "calc" && !Launcher.term ? I18n.tr("launcher.calcHint")
                    : I18n.tr("launcher.noResults")
                color: win.mod ? Qt.alpha(win.lcdInk, 0.5) : win.theme.color.soft
                font.pixelSize: win.theme.font.sizeS
            }
        }
    }
}
