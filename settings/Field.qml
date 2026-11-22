import QtQuick
import Quickshell
import qs.components
import qs.theme

// One setting: label (and optional hint) on the left, control on the right.
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    property string label
    property string hint
    default property alias control: slot.data

    width: parent?.width ?? 0
    implicitHeight: Math.max(texts.implicitHeight, slot.childrenRect.height, theme.hit)

    Column {
        id: texts

        anchors.left: parent.left
        anchors.right: slot.left
        anchors.rightMargin: root.theme.space.l
        anchors.verticalCenter: parent.verticalCenter

        ThemedText {
            width: parent.width
            text: root.label
            wrapMode: Text.Wrap
        }

        ThemedText {
            width: parent.width
            visible: !!root.hint
            text: root.hint
            color: root.theme.color.soft
            font.pixelSize: root.theme.font.sizeS
            wrapMode: Text.Wrap
        }
    }

    Item {
        id: slot

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
}
