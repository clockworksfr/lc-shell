import QtQuick
import Quickshell
import qs.theme

// Single-line text input; emits committed(text) on Enter or focus loss.
Rectangle {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    property string text
    property string placeholder

    signal committed(string text)

    implicitWidth: 240
    implicitHeight: Math.max(theme.hit, 32)
    radius: theme.radius.control
    color: theme.color.surface2
    border.width: input.activeFocus ? 1 : 0
    border.color: theme.color.accent

    TextInput {
        id: input

        anchors.fill: parent
        anchors.leftMargin: root.theme.space.s
        anchors.rightMargin: root.theme.space.s
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        text: root.text
        color: root.theme.color.ink
        selectionColor: root.theme.color.accent
        selectedTextColor: root.theme.color.onAccent
        font.family: root.theme.font.family
        font.pixelSize: root.theme.font.sizeM
        onAccepted: root.committed(text)
        onActiveFocusChanged: if (!activeFocus && text !== root.text) root.committed(text)

        ThemedText {
            visible: !input.text
            anchors.verticalCenter: parent.verticalCenter
            text: root.placeholder
            color: root.theme.color.soft
        }
    }
}
