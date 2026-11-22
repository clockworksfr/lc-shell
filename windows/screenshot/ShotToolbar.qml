import QtQuick
import qs.components
import qs.i18n
import qs.services

// Tools of the screenshot editor: tools, colors, stroke, fill, undo /
// redo, save / copy / close. The hovered button's name (and key) shows
// above it.
Rectangle {
    id: root

    property var theme
    property bool canUndo: false
    property bool canRedo: false

    signal undo
    signal redo
    signal save
    signal copy
    signal cancel

    readonly property int button: 34
    property string tip

    width: row.implicitWidth + theme.space.xs * 2
    height: button + theme.space.xs * 2
    radius: theme.radius.panel
    color: theme.color.surface
    border.width: 1
    border.color: theme.color.line

    // Clicks between buttons stay in the toolbar.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
    }

    component Separator: Rectangle {
        width: 1
        height: root.button - 10
        anchors.verticalCenter: parent?.verticalCenter
        color: root.theme.color.line
    }

    component ToolButton: Rectangle {
        id: btn

        property string icon
        property string label
        property bool active: false
        property bool enabledButton: true
        property bool filledIcon: false
        property color iconColor: root.theme.color.ink

        signal clicked

        width: root.button
        height: root.button
        radius: root.theme.radius.control
        opacity: enabledButton ? 1 : 0.35
        color: active ? Qt.alpha(root.theme.color.accent, 0.22) : area.containsMouse && enabledButton ? root.theme.color.surface3 : "transparent"
        Accessible.name: label

        Icon {
            anchors.centerIn: parent
            name: btn.icon
            filled: btn.filledIcon || btn.active
            size: 20
            color: btn.active ? root.theme.color.accent : btn.iconColor
        }

        MouseArea {
            id: area

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onContainsMouseChanged: {
                if (containsMouse)
                    root.tip = btn.label;
                else if (root.tip === btn.label)
                    root.tip = "";
            }
            onClicked: if (btn.enabledButton) btn.clicked()
        }
    }

    Row {
        id: row

        x: root.theme.space.xs
        y: root.theme.space.xs
        spacing: 2

        Repeater {
            model: Screenshot.tools

            ToolButton {
                required property string modelData

                icon: Screenshot.toolIcons[modelData]
                label: `${I18n.tr(`shot.tool.${modelData}`)}  ·  ${Screenshot.toolKeys[modelData]}`
                active: Screenshot.tool === modelData
                onClicked: Screenshot.tool = modelData
            }
        }

        Item {
            width: root.theme.space.xs
            height: 1
        }
        Separator {}
        Item {
            width: root.theme.space.xs
            height: 1
        }

        // Colors.
        Repeater {
            model: Screenshot.colors

            Item {
                id: swatch

                required property string modelData
                required property int index

                width: 26
                height: root.button

                Rectangle {
                    anchors.centerIn: parent
                    width: Screenshot.color === swatch.modelData ? 22 : 18
                    height: width
                    radius: width / 2
                    color: Screenshot.palette[swatch.modelData]
                    border.width: Screenshot.color === swatch.modelData ? 3 : 1
                    border.color: Screenshot.color === swatch.modelData ? root.theme.color.ink : Qt.alpha(root.theme.color.ink, 0.25)
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onContainsMouseChanged: {
                        const label = `${I18n.tr(`shot.color.${swatch.modelData}`)}  ·  ${swatch.index + 1}`;
                        if (containsMouse)
                            root.tip = label;
                        else if (root.tip === label)
                            root.tip = "";
                    }
                    onClicked: Screenshot.color = swatch.modelData
                }
            }
        }

        // Stroke size: three dots, the current one filled.
        Rectangle {
            id: strokeButton

            width: root.button + 8
            height: root.button
            radius: root.theme.radius.control
            color: strokeArea.containsMouse ? root.theme.color.surface3 : "transparent"

            Row {
                anchors.centerIn: parent
                spacing: 4

                Repeater {
                    model: 3

                    Rectangle {
                        required property int index

                        anchors.verticalCenter: parent.verticalCenter
                        width: 5 + index * 3
                        height: width
                        radius: width / 2
                        color: Screenshot.stroke === index ? root.theme.color.ink : Qt.alpha(root.theme.color.ink, 0.3)
                    }
                }
            }

            MouseArea {
                id: strokeArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onContainsMouseChanged: {
                    const label = `${I18n.tr("shot.stroke")}  ·  [ ]`;
                    if (containsMouse)
                        root.tip = label;
                    else if (root.tip === label)
                        root.tip = "";
                }
                onClicked: mouse => Screenshot.stroke = (Screenshot.stroke + (mouse.button === Qt.RightButton ? 2 : 1)) % 3
                onWheel: wheel => Screenshot.stroke = Math.max(0, Math.min(2, Screenshot.stroke + (wheel.angleDelta.y > 0 ? 1 : -1)))
            }
        }

        ToolButton {
            icon: "format_color_fill"
            label: `${I18n.tr("shot.fill")}  ·  F`
            active: Screenshot.fill
            onClicked: Screenshot.fill = !Screenshot.fill
        }

        Item {
            width: root.theme.space.xs
            height: 1
        }
        Separator {}
        Item {
            width: root.theme.space.xs
            height: 1
        }

        ToolButton {
            icon: "undo"
            label: `${I18n.tr("shot.undo")}  ·  Ctrl+Z`
            enabledButton: root.canUndo
            onClicked: root.undo()
        }

        ToolButton {
            icon: "redo"
            label: `${I18n.tr("shot.redo")}  ·  Ctrl+Shift+Z`
            enabledButton: root.canRedo
            onClicked: root.redo()
        }

        Item {
            width: root.theme.space.xs
            height: 1
        }
        Separator {}
        Item {
            width: root.theme.space.xs
            height: 1
        }

        ToolButton {
            icon: "save"
            label: `${I18n.tr("shot.save")}  ·  Ctrl+S`
            onClicked: root.save()
        }

        ToolButton {
            icon: "content_copy"
            label: `${I18n.tr("shot.copy")}  ·  ${Screenshot.enterAction === "copy" ? I18n.tr("shot.enter") : "Ctrl+C"}`
            onClicked: root.copy()
        }

        ToolButton {
            icon: "close"
            label: `${I18n.tr("shot.cancel")}  ·  ${I18n.tr("shot.escape")}`
            onClicked: root.cancel()
        }
    }

    // Name of the hovered button.
    Rectangle {
        visible: root.tip !== ""
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: root.theme.space.xs
        width: tipText.implicitWidth + root.theme.space.m * 2
        height: tipText.implicitHeight + root.theme.space.xs * 2
        radius: root.theme.radius.control
        color: root.theme.color.surface
        border.width: 1
        border.color: root.theme.color.line

        ThemedText {
            id: tipText

            anchors.centerIn: parent
            text: root.tip
        }
    }
}
