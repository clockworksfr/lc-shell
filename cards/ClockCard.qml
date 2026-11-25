import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Date and week, time with seconds, month calendar:
// arrows or wheel for other months, a click on the month back to today.
// (Events: later, with an agenda.)
Column {
    id: root

    property var block
    property ShellScreen screen
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property string look: theme.style.module ?? "classic"
    readonly property bool squared: look === "facade" || look === "modulaire"

    // Months away from the current one (shared with the bar clock's wheel).
    property int monthOffset: ShellState.calendarOffset
    onMonthOffsetChanged: ShellState.calendarOffset = monthOffset

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

    spacing: 12

    // Wheel anywhere on the card: other months (under the controls: their
    // clicks stay theirs).
    MouseArea {
        parent: root.parent
        x: root.x
        y: root.y
        width: root.width
        height: root.height
        z: -1
        acceptedButtons: Qt.NoButton
        onWheel: wheel => root.monthOffset += wheel.angleDelta.y > 0 ? -1 : 1
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // Header: long date · week, mono capitals.
    ThemedText {
        width: parent.width
        text: `${I18n.locale.toString(clock.date, I18n.tr("format.dateLong"))} · ${I18n.tr("card.week", { n: root.isoWeek(clock.date) })}`
        font.family: root.theme.font.mono
        font.pixelSize: 11
        font.letterSpacing: 0.9
        font.capitalization: Font.AllUppercase
        color: root.theme.color.soft
        elide: Text.ElideRight
    }

    // The time, seconds smaller.
    Row {
        spacing: 2

        HeroText {
            id: hero
            text: I18n.locale.toString(clock.date, "HH:mm")
            pixelSize: 40
        }

        ThemedText {
            anchors.baseline: hero.baseline
            text: `:${I18n.locale.toString(clock.date, "ss")}`
            color: root.theme.color.ink
            opacity: 0.6
            font.family: root.theme.font.display
            font.pixelSize: 20
            font.features: ({ "tnum": 1 })
        }
    }

    // Month: title (click: back to today), previous / next.
    Item {
        width: parent.width
        implicitHeight: 28

        ThemedText {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: I18n.locale.toString(root.shownMonth, "MMMM yyyy")
            font.weight: Font.DemiBold
            font.pixelSize: 14
            color: root.monthOffset === 0 ? root.theme.color.ink : root.theme.color.accent

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                enabled: root.monthOffset !== 0
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.monthOffset = 0
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            CardParts.SmallButton {
                visible: root.monthOffset !== 0
                text: I18n.tr("card.today")
                onTapped: root.monthOffset = 0
            }

            Repeater {
                model: [{ icon: "chevron_left", step: -1 }, { icon: "chevron_right", step: 1 }]

                Rectangle {
                    required property var modelData

                    width: 28
                    height: 26
                    radius: root.squared ? 4 : 13
                    color: arrow.containsMouse ? root.theme.color.surface3 : "transparent"
                    border.width: 1
                    border.color: root.theme.color.line

                    Icon {
                        anchors.centerIn: parent
                        name: parent.modelData.icon
                        size: 18
                        color: root.theme.color.ink
                    }

                    MouseArea {
                        id: arrow
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.monthOffset += parent.modelData.step
                    }
                }
            }
        }
    }

    Grid {
        id: calendar

        readonly property real cell: (width - 7 * columnSpacing) / 8

        width: parent.width
        columns: 8
        columnSpacing: 2
        rowSpacing: 2

        // Header: week column, then day names.
        Item {
            width: calendar.cell
            height: 20
        }

        Repeater {
            model: 7

            ThemedText {
                required property int index
                width: calendar.cell
                height: 20
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: I18n.locale.dayName((1 + index) % 7, Locale.NarrowFormat).toUpperCase()
                font.family: root.theme.font.mono
                font.pixelSize: 10
                font.letterSpacing: 0.6
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

                Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool day: index > 0
                    readonly property bool today: !!modelData.today

                    width: calendar.cell
                    height: 26
                    radius: root.squared ? 2 : height / 2
                    // The current week tinted, today filled.
                    color: today ? root.theme.color.accent
                        : day && weekRow.current ? Qt.alpha(root.theme.color.accent, 0.12)
                        : "transparent"

                    ThemedText {
                        anchors.centerIn: parent
                        text: parent.day ? `${parent.modelData.date.getDate()}` : `${parent.modelData.week}`
                        font.family: root.theme.font.mono
                        font.pixelSize: parent.day ? 12 : 10
                        font.weight: parent.today ? Font.Bold : Font.Medium
                        font.features: ({ "tnum": 1 })
                        color: parent.today ? root.theme.color.onAccent
                            : parent.day ? root.theme.color.ink
                            : root.theme.color.soft
                        opacity: !parent.day ? 0.7 : parent.modelData.inMonth ? 1 : 0.35
                    }
                }
            }
        }
    }

    CardParts.Footer {
        hints: I18n.tr("card.wheelMonths")
    }


    // Back to the current month when the card closes.
    Connections {
        target: root.QsWindow.window
        function onPhaseChanged(): void {
            if (root.QsWindow.window?.phase === "")
                ShellState.calendarOffset = 0;
        }
    }
}
