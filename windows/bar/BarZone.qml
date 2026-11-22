import QtQuick
import qs.widgets
import qs.components
import qs.services

// One zone of the bar (left/start, center, right/end): a row (horizontal
// bar) or column (vertical bar) of groups; each group is an island in
// "islands" style. Entries: a list of blocks (one group) or a list of
// lists (several groups). In edit mode the zone is outlined and ends with a
// "+" target that opens a new group.
Item {
    id: zone

    // The Bar window this zone belongs to.
    required property var host
    // "left" | "center" | "right"
    required property string name
    property var entries: []

    readonly property var look: host.look
    readonly property var theme: host.theme
    readonly property bool islands: host.islands
    readonly property bool vertical: host.vertical
    readonly property bool editing: BarEditor.editing
    readonly property var groups: BarEditor.groups(entries)
    readonly property bool empty: groups.every(g => g.length === 0)
    // Gap between islands (or between groups of a full bar).
    readonly property int groupGap: islands ? look.margin || theme.space.s : look.spacing * 2
    readonly property Item plus: plusTarget

    visible: !empty || editing
    width: vertical ? host.thickness : row.implicitWidth
    height: vertical ? row.implicitHeight : host.thickness

    // Edit mode: tinted, outlined zone.
    Rectangle {
        anchors.fill: parent
        anchors.margins: zone.vertical ? 2 : 0
        visible: zone.editing
        radius: zone.theme.radius.control
        color: Qt.alpha(zone.theme.color.accent, 0.07)
        border.width: 1
        border.color: Qt.alpha(zone.theme.color.accent, 0.55)
    }

    Grid {
        id: row

        anchors.centerIn: parent
        columns: zone.vertical ? 1 : zone.groups.length + 1
        spacing: zone.groupGap
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        Repeater {
            model: zone.groups

            Item {
                id: group

                required property var modelData
                required property int index
                readonly property bool hasBlocks: blocks.implicitWidth > 0 && blocks.implicitHeight > 0

                visible: hasBlocks
                implicitWidth: zone.vertical ? zone.host.thickness : blocks.implicitWidth + (zone.islands ? zone.look.padding * 2 : 0)
                implicitHeight: zone.vertical ? blocks.implicitHeight + (zone.islands ? zone.look.padding * 2 : 0) : zone.host.thickness

                // Under an open drawer coming out of this island, its
                // background grows (not its content) so the drawer and its
                // fillets hang from a straight edge: one shape.
                readonly property var span: zone.host.drawerSpan
                readonly property bool carries: !!span && span.slot?.zoneName === zone.name && span.slot?.groupIndex === group.index
                // mapToItem isn't reactive: reading span and the positions makes
                // it recompute when a drawer opens or the layout moves.
                readonly property real startOnBar: {
                    void [span, group.x, group.y, zone.x, zone.y, zone.width, zone.height];
                    const p = group.mapToItem(zone.host.contentItem, 0, 0);
                    return zone.vertical ? p.y : p.x;
                }
                readonly property real length: zone.vertical ? group.height : group.width
                property real growStart: carries ? Math.max(0, startOnBar - (span.start - zone.look.radius)) : 0
                property real growEnd: carries ? Math.max(0, (span.end + zone.look.radius) - (startOnBar + length)) : 0

                Behavior on growStart {
                    NumberAnimation {
                        duration: zone.theme.motion.duration
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on growEnd {
                    NumberAnimation {
                        duration: zone.theme.motion.duration
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: zone.vertical ? 0 : -group.growStart
                    anchors.rightMargin: zone.vertical ? 0 : -group.growEnd
                    anchors.topMargin: zone.vertical ? -group.growStart : 0
                    anchors.bottomMargin: zone.vertical ? -group.growEnd : 0
                    visible: zone.islands
                    radius: zone.look.radius
                    color: Qt.alpha(zone.theme.color.surface, zone.look.opacity)
                    border.width: zone.look.border
                    border.color: zone.theme.color.line

                    Glass {}
                }

                Grid {
                    id: blocks

                    anchors.centerIn: parent
                    columns: zone.vertical ? 1 : Math.max(1, group.modelData.length)
                    spacing: zone.look.spacing
                    horizontalItemAlignment: Grid.AlignHCenter
                    verticalItemAlignment: Grid.AlignVCenter

                    Repeater {
                        model: group.modelData

                        WidgetSlot {
                            required property var modelData
                            required property int index
                            entry: modelData
                            screen: zone.host.screen
                            vertical: zone.vertical
                            host: zone.host
                            zoneName: zone.name
                            groupIndex: group.index
                            widgetIndex: index
                            // Room a block may use across the bar.
                            crossSize: zone.host.thickness - zone.theme.space.s * 2
                        }
                    }
                }
            }
        }

        // Edit mode: drop here to start a new group (island).
        Rectangle {
            id: plusTarget

            visible: zone.editing
            implicitWidth: 28
            implicitHeight: 28
            radius: zone.theme.radius.full
            color: zone.host.dropTarget?.zone === zone.name && zone.host.dropTarget?.group === -1 ? zone.theme.color.accent : Qt.alpha(zone.theme.color.accent, 0.15)

            ThemedText {
                anchors.centerIn: parent
                text: "+"
                color: zone.host.dropTarget?.zone === zone.name && zone.host.dropTarget?.group === -1 ? zone.theme.color.onAccent : zone.theme.color.accent
                font.weight: Font.DemiBold
            }
        }
    }
}
