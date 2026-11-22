import QtQuick
import qs.blocks
import qs.components

// One zone of the bar: blocks in a row (horizontal bar) or a column
// (vertical bar). In "islands" style it draws its own background.
Item {
    id: zone

    // The Bar window this zone belongs to.
    required property var host
    property var entries: []

    readonly property var look: host.look
    readonly property var theme: host.theme
    readonly property bool islands: host.islands
    readonly property bool vertical: host.vertical
    readonly property bool empty: grid.implicitWidth === 0 || grid.implicitHeight === 0

    visible: !empty
    width: vertical ? host.thickness : grid.implicitWidth + (islands ? look.padding * 2 : 0)
    height: vertical ? grid.implicitHeight + (islands ? look.padding * 2 : 0) : host.thickness

    Rectangle {
        anchors.fill: parent
        visible: zone.islands
        radius: zone.look.radius
        color: Qt.alpha(zone.theme.color.bg, zone.look.opacity)
        border.width: zone.look.border
        border.color: zone.theme.color.line

        Glass {}
    }

    Grid {
        id: grid

        anchors.centerIn: parent
        // Only `columns` is set: one column, or one per block (a single row).
        columns: zone.vertical ? 1 : Math.max(1, zone.entries.length)
        spacing: zone.look.spacing
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        Repeater {
            model: zone.entries

            BlockSlot {
                required property var modelData
                entry: modelData
                screen: zone.host.screen
                vertical: zone.vertical
                host: zone.host
                // Room a block may use across the bar.
                crossSize: zone.host.thickness - zone.theme.space.s * 2
            }
        }
    }
}
