import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.theme

// One setting: label (and optional hint) on the left, control on the right;
// the control goes under the label when the row is too narrow for both.
// Pointed out (search result) when Settings.highlight is its label's key.
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    property string label
    property string hint
    default property alias control: slot.data

    readonly property bool stacked: slot.width + theme.space.l + Math.min(labelText.implicitWidth, 200) > width
    readonly property bool flagged: !!Settings.highlight && I18n.tr(Settings.highlight) === label

    width: parent?.width ?? 0
    implicitHeight: stacked ? texts.implicitHeight + theme.space.xs + slot.height + theme.space.xs : Math.max(texts.implicitHeight, slot.height, theme.hit)

    onFlaggedChanged: if (flagged) Settings.reveal(root)

    // Search highlight.
    Rectangle {
        anchors.fill: parent
        anchors.margins: -root.theme.space.xs
        radius: root.theme.radius.control
        color: root.theme.color.accent
        opacity: root.flagged ? 0.16 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 400
            }
        }
    }

    Column {
        id: texts

        x: 0
        y: root.stacked ? 0 : (root.height - height) / 2
        width: root.stacked ? root.width : root.width - slot.width - root.theme.space.l

        ThemedText {
            id: labelText
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

        x: root.stacked ? 0 : root.width - width
        y: root.stacked ? texts.implicitHeight + root.theme.space.xs : (root.height - height) / 2
        width: childrenRect.width
        height: childrenRect.height
    }
}
