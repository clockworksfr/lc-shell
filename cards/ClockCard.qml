import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.theme

// Date, week, time with seconds, month calendar (wheel: other months).
Column {
    id: root

    property var block
    property ShellScreen screen
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    // Months away from the current one (wheel).
    property int monthOffset: 0

    function isoWeek(date: date): int {
        const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
        const day = d.getUTCDay() || 7;
        d.setUTCDate(d.getUTCDate() + 4 - day);
        const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
        return Math.ceil(((d - yearStart) / 86400000 + 1) / 7);
    }

    readonly property date shownMonth: new Date(clock.date.getFullYear(), clock.date.getMonth() + monthOffset, 1)
    // Weeks of the shown month: [{ week, days: [{ date, inMonth, today }] }]
    readonly property var weeks: {
        // Weeks start on Monday: the ISO week numbers shown beside each row
        // only make sense that way (whatever the locale's first day).
        const first = 1;
        const start = new Date(shownMonth);
        start.setDate(1 - ((start.getDay() - first + 7) % 7));
        const today = clock.date.toDateString();
        const out = [];
        for (let w = 0; w < 6; w++) {
            const days = [];
            for (let d = 0; d < 7; d++) {
                const day = new Date(start.getFullYear(), start.getMonth(), start.getDate() + w * 7 + d);
                days.push({ date: day, inMonth: day.getMonth() === shownMonth.getMonth(), today: day.toDateString() === today });
            }
            if (w === 5 && !days.some(d => d.inMonth))
                break;
            // ISO week of the row = week of its Thursday (rows may start on Sunday).
            const thursday = days.find(d => d.date.getDay() === 4) ?? days[3];
            out.push({ week: isoWeek(thursday.date), days: days });
        }
        return out;
    }

    spacing: theme.space.m

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Item {
        width: parent.width
        implicitHeight: dateText.implicitHeight

        ThemedText {
            id: dateText
            text: I18n.locale.toString(clock.date, I18n.tr("format.dateLong"))
            font.weight: Font.DemiBold
        }

        ThemedText {
            anchors.right: parent.right
            text: I18n.tr("card.week", { n: root.isoWeek(clock.date) })
            label: true
            color: root.theme.color.soft
        }
    }

    Row {
        spacing: root.theme.space.xs

        HeroText {
            text: I18n.locale.toString(clock.date, "HH:mm")
            pixelSize: 44
        }

        ThemedText {
            anchors.baseline: parent.children[0].baseline
            text: I18n.locale.toString(clock.date, "ss")
            color: root.theme.color.soft
            font.pixelSize: 20
            font.features: ({ "tnum": 1 })
        }
    }

    // Month title.
    ThemedText {
        text: I18n.locale.toString(root.shownMonth, "MMMM yyyy")
        font.weight: Font.DemiBold
        color: root.monthOffset === 0 ? root.theme.color.ink : root.theme.color.accent
    }

    Grid {
        id: calendar

        readonly property int cell: Math.floor(width / 8)

        width: parent.width
        columns: 8
        rowSpacing: 2

        // Header: week column, then day names.
        ThemedText {
            width: calendar.cell
            horizontalAlignment: Text.AlignHCenter
            text: ""
        }

        Repeater {
            model: 7

            ThemedText {
                required property int index
                width: calendar.cell
                horizontalAlignment: Text.AlignHCenter
                text: I18n.locale.dayName((1 + index) % 7, Locale.NarrowFormat)
                label: true
                color: root.theme.color.soft
            }
        }

        Repeater {
            model: root.weeks

            Repeater {
                id: weekRow

                required property var modelData
                readonly property bool current: modelData.days.some(d => d.today)

                model: [{ week: modelData.week }, ...modelData.days]

                Item {
                    required property var modelData
                    required property int index

                    width: calendar.cell
                    height: calendar.cell * 0.8

                    // Current week tint.
                    Rectangle {
                        anchors.fill: parent
                        visible: weekRow.current && parent.index > 0
                        color: Qt.alpha(root.theme.color.accent, 0.08)
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height) - 2
                        height: width
                        radius: width / 2
                        visible: !!parent.modelData.today
                        color: root.theme.color.accent
                    }

                    ThemedText {
                        anchors.centerIn: parent
                        text: parent.index === 0 ? `${parent.modelData.week}` : `${parent.modelData.date.getDate()}`
                        font.pixelSize: parent.index === 0 ? root.theme.font.sizeS : root.theme.font.sizeM
                        font.features: ({ "tnum": 1 })
                        color: parent.modelData.today ? root.theme.color.onAccent
                            : parent.index === 0 || !parent.modelData.inMonth ? root.theme.color.soft
                            : root.theme.color.ink
                        opacity: parent.index > 0 && !parent.modelData.inMonth ? 0.5 : 1
                    }
                }
            }
        }
    }

    WheelHandler {
        onWheel: event => root.monthOffset += event.angleDelta.y > 0 ? -1 : 1
    }
}
