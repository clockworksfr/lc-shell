import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.theme

// Time and date. S: time, day and date on the right; M: + the week (7
// days); L: + the month. Options: format (default "HH:mm").
ModuleBase {
    id: root

    readonly property date now: clock.date
    readonly property string format: options.format ?? "HH:mm"

    // ISO week number.
    function week(date: date): int {
        const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
        const day = d.getUTCDay() || 7;
        d.setUTCDate(d.getUTCDate() + 4 - day);
        const start = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
        return Math.ceil(((d - start) / 86400000 + 1) / 7);
    }

    // Monday of the week of `date`.
    function monday(date: date): date {
        const d = new Date(date.getFullYear(), date.getMonth(), date.getDate());
        d.setDate(d.getDate() - ((d.getDay() + 6) % 7));
        return d;
    }

    SystemClock {
        id: clock
        precision: root.format.includes("s") ? SystemClock.Seconds : SystemClock.Minutes
    }

    // Time, day and date: one block, bottom-left in M / L, centered row in S.
    Item {
        id: main

        width: root.tier === "S" ? parent.width : parent.width * (root.tier === "L" ? 0.42 : 0.5)
        height: parent.height

        ThemedText {
            id: time

            anchors.left: parent.left
            anchors.verticalCenter: root.tier === "S" ? parent.verticalCenter : undefined
            anchors.bottom: root.tier === "S" ? undefined : dateCol.top
            text: I18n.locale.toString(root.now, root.format)
            font.family: root.theme.font.display
            font.weight: root.theme.font.displayWeight
            font.pixelSize: Math.min(root.t1, (root.tier === "S" ? parent.width * 0.58 : parent.width) / (root.format.length * 0.62))
            font.features: ({ "tnum": 1 })
        }

        Column {
            id: dateCol

            readonly property int align: root.tier === "S" ? Text.AlignRight : Text.AlignLeft

            anchors.right: parent.right
            anchors.verticalCenter: root.tier === "S" ? parent.verticalCenter : undefined
            anchors.bottom: root.tier === "S" ? undefined : parent.bottom
            width: root.tier === "S" ? parent.width - time.width - root.gap : parent.width
            spacing: 2

            ThemedText {
                width: parent.width
                horizontalAlignment: dateCol.align
                elide: Text.ElideRight
                text: I18n.locale.dayName(root.now.getDay(), Locale.LongFormat)
                font.pixelSize: root.t2
                font.weight: Font.DemiBold
                font.capitalization: Font.Capitalize
            }

            ThemedText {
                width: parent.width
                horizontalAlignment: dateCol.align
                elide: Text.ElideRight
                text: I18n.locale.toString(root.now, I18n.tr("format.dateNoDay"))
                font.pixelSize: root.t3
                color: root.theme.color.soft
            }

            ThemedText {
                width: parent.width
                horizontalAlignment: dateCol.align
                label: true
                text: I18n.tr("clock.week", { n: root.week(root.now) })
                font.pixelSize: root.t4
                color: root.theme.color.soft
            }
        }
    }

    // M: the week, 7 equal cells filling the right half.
    Row {
        visible: root.tier === "M"
        anchors.right: parent.right
        width: parent.width * 0.46
        height: parent.height
        spacing: root.gap / 2

        Repeater {
            model: 7

            Rectangle {
                required property int index
                readonly property date day: new Date(root.monday(root.now).getTime() + index * 86400000)
                readonly property bool today: day.toDateString() === root.now.toDateString()

                width: (parent.width - parent.spacing * 6) / 7
                height: parent.height
                radius: root.theme.radius.tile
                color: today ? root.theme.color.accent : root.theme.color.surface2

                ThemedText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height * 0.14
                    label: true
                    text: I18n.locale.dayName(parent.day.getDay(), Locale.NarrowFormat)
                    font.pixelSize: root.t4
                    color: parent.today ? root.theme.color.onAccent : root.theme.color.soft
                }

                ThemedText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: parent.height * 0.14
                    text: parent.day.getDate()
                    font.pixelSize: Math.min(root.t2 * 1.3, parent.width * 0.42)
                    font.weight: Font.DemiBold
                    font.features: ({ "tnum": 1 })
                    color: parent.today ? root.theme.color.onAccent : root.theme.color.ink
                }
            }
        }
    }

    // L: the month (weeks from Monday, ISO week numbers).
    Grid {
        id: month

        readonly property date first: new Date(root.now.getFullYear(), root.now.getMonth(), 1)
        readonly property date start: root.monday(first)
        readonly property int weeks: Math.ceil(((first.getDay() + 6) % 7 + new Date(root.now.getFullYear(), root.now.getMonth() + 1, 0).getDate()) / 7)

        visible: root.tier === "L"
        anchors.right: parent.right
        width: parent.width * 0.54
        height: parent.height
        columns: 8
        rowSpacing: 0
        columnSpacing: 0

        Repeater {
            model: 8 * (month.weeks + 1)

            Item {
                required property int index
                readonly property int row: Math.floor(index / 8) - 1
                readonly property int col: index % 8 - 1
                readonly property date day: new Date(month.start.getTime() + (row * 7 + col) * 86400000 + 3600000)
                readonly property bool header: row < 0
                readonly property bool weekCol: col < 0
                readonly property bool inMonth: day.getMonth() === root.now.getMonth()
                readonly property bool today: !header && !weekCol && day.toDateString() === root.now.toDateString()

                width: month.width / 8
                height: month.height / (month.weeks + 1)

                Rectangle {
                    anchors.centerIn: parent
                    visible: parent.today
                    width: Math.min(parent.width, parent.height) * 0.86
                    height: width
                    radius: root.theme.radius.full
                    color: root.theme.color.accent
                }

                ThemedText {
                    anchors.centerIn: parent
                    label: parent.header || parent.weekCol
                    text: parent.header ? (parent.weekCol ? "" : I18n.locale.dayName((parent.col + 1) % 7, Locale.NarrowFormat))
                        : parent.weekCol ? root.week(new Date(month.start.getTime() + parent.row * 7 * 86400000 + 3600000))
                        : parent.day.getDate()
                    font.pixelSize: parent.header || parent.weekCol ? root.t4 : root.t3
                    font.features: ({ "tnum": 1 })
                    color: parent.today ? root.theme.color.onAccent : parent.header || parent.weekCol || !parent.inMonth ? root.theme.color.soft : root.theme.color.ink
                    opacity: !parent.header && !parent.weekCol && !parent.inMonth ? 0.45 : 1
                }
            }
        }
    }
}
