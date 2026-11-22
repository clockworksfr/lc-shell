import QtQuick
import qs.blocks

// One zone of the bar (left/center/right): a row of blocks.
// In "islands" style it draws its own background.
Item {
    id: zone

    // The Bar window this zone belongs to.
    required property var host
    property var entries: []

    readonly property var look: host.look
    readonly property var theme: host.theme
    readonly property bool islands: host.islands

    visible: row.implicitWidth > 0
    height: parent.height
    implicitWidth: row.implicitWidth + (islands ? look.padding * 2 : 0)

    Rectangle {
        anchors.fill: parent
        visible: zone.islands
        radius: zone.look.radius
        color: Qt.alpha(zone.theme.color.bg, zone.look.opacity)
        border.width: zone.look.border
        border.color: zone.theme.color.line
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: zone.look.spacing

        Repeater {
            model: zone.entries

            BlockSlot {
                required property var modelData
                entry: modelData
                screen: zone.host.screen
                anchors.verticalCenter: parent?.verticalCenter
            }
        }
    }
}
