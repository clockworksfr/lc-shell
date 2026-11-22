import QtQuick
import Quickshell
import qs.components
import qs.components.dashboard
import qs.i18n
import qs.theme

// Time and date, by shape: tiny = time; narrow = hours over minutes;
// wide = time left, day / date / week right (+ the week strip when tall
// enough); box / tall = time, date, the week (the month when roomy);
// strip = one line. In modulaire, the time sits in an amber LCD window. Options: format ("HH:mm").
ModuleBase {
    id: root

    readonly property date now: clock.date
    readonly property string format: options.format ?? "HH:mm"
    readonly property string time: I18n.locale.toString(now, format)
    readonly property bool roomy: (shape === "box" || shape === "tall") && ch >= 360 && cw >= 520

    // Width of a figure of `n` characters at size 1 (display fonts ~0.62).
    function perChar(n: int): real {
        return 1 / (n * 0.62);
    }

    function week(date: date): int {
        const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
        const day = d.getUTCDay() || 7;
        d.setUTCDate(d.getUTCDate() + 4 - day);
        const start = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
        return Math.ceil(((d - start) / 86400000 + 1) / 7);
    }

    function monday(date: date): date {
        const d = new Date(date.getFullYear(), date.getMonth(), date.getDate());
        d.setDate(d.getDate() - ((d.getDay() + 6) % 7));
        return d;
    }

    SystemClock {
        id: clock
        precision: root.format.includes("s") ? SystemClock.Seconds : SystemClock.Minutes
    }

    // tiny: the time alone, centered.
    Figure {
        visible: root.shape === "tiny"
        anchors.centerIn: parent
        text: root.time
        inDisplay: true
        pixelSize: root.figure(0.6, root.perChar(root.time.length))
    }

    // narrow: hours over minutes, date under.
    Column {
        visible: root.shape === "narrow"
        anchors.centerIn: parent
        spacing: root.gap / 2

        Repeater {
            model: root.time.split(":")

            Figure {
                required property string modelData
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData
                inDisplay: true
                pixelSize: Math.min(root.ch * 0.3, root.cw * root.perChar(2)) * root.hk
            }
        }

        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: I18n.locale.toString(root.now, "d MMM")
            font.pixelSize: root.t3
            color: root.theme.color.soft
        }
    }

    // wide / strip: time left, the rest right (strip: on one line).
    Item {
        visible: root.shape === "wide" || root.shape === "strip"
        anchors.fill: parent

        Figure {
            id: wideTime
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.time
            inDisplay: true
            pixelSize: root.figure(0.62, (root.shape === "strip" ? 0.3 : 0.55) * root.perChar(root.time.length))
        }

        Column {
            id: wideDate

            anchors.left: wideTime.right
            anchors.leftMargin: root.gap * 1.5
            // strip: natural width, the week fills the rest of the line.
            width: root.shape === "strip" ? Math.min(root.cw * 0.2, 300) : parent.width - x
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            DayName {

                m: root
                width: parent.width
            }

            ThemedText {
                width: parent.width
                elide: Text.ElideRight
                text: I18n.locale.toString(root.now, I18n.tr("format.dateNoDay"))
                font.pixelSize: root.t3
                color: root.theme.color.soft
            }

            ThemedText {
                width: parent.width
                label: true
                text: I18n.tr("clock.week", { n: root.week(root.now) })
                font.pixelSize: root.t4
                color: root.theme.color.soft
            }

            WeekStrip {

                m: root
                visible: root.shape === "wide" && root.ch >= 240 && wideDate.width >= 230
                width: parent.width
                // Day cells about as tall as wide (design study).
                height: Math.min(root.ch * 0.4, (width - 6 * spacing) / 7 * 1.3)
            }
        }
        // strip: the week on the rest of the line.
        WeekStrip {
            m: root
            visible: root.shape === "strip" && width >= 200
            anchors.left: wideDate.right
            anchors.leftMargin: root.gap * 1.5
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: Math.min(root.ch * 0.8, (width - 6 * spacing) / 7 * 1.3)
        }
    }


    // box / tall: time, date, the week (or the month when roomy).
    Column {
        visible: root.shape === "box" || root.shape === "tall"
        // Centered when its content is shorter than the cell (no empty
        // band on top); the month fills the rest when roomy.
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: root.roomy ? parent.top : undefined
        anchors.verticalCenter: root.roomy ? undefined : parent.verticalCenter
        spacing: root.gap

        Figure {
            text: root.time
            inDisplay: true
            pixelSize: root.figure(root.roomy ? 0.32 : 0.42, root.perChar(root.time.length))
        }

        Column {
            width: parent.width
            spacing: 2

            DayName {

                m: root
                width: parent.width
            }

            ThemedText {
                width: parent.width
                elide: Text.ElideRight
                text: `${I18n.locale.toString(root.now, I18n.tr("format.dateNoDay"))} · ${I18n.tr("clock.week", { n: root.week(root.now) })}`
                font.pixelSize: root.t3
                color: root.theme.color.soft
            }
        }

        WeekStrip {

            m: root
            visible: !root.roomy
            width: parent.width
            // Day cells about as tall as wide (design study).
            height: Math.max(48, Math.min(root.inner.height * 0.45, (width - 6 * spacing) / 7 * 1.3))
        }

        MonthGrid {

            m: root
            visible: root.roomy
            width: parent.width
            height: Math.max(120, root.inner.height - y)
        }
    }

    component DayName: ThemedText {
        id: dayName

        property var m
        elide: Text.ElideRight
        text: I18n.locale.dayName(dayName.m.now.getDay(), Locale.LongFormat)
        font.pixelSize: dayName.m.t2
        font.weight: Font.DemiBold
        font.capitalization: Font.Capitalize
    }

    // 7 equal cells, today lit.
    component WeekStrip: Row {
        id: strip

        property var m

        spacing: Math.max(3, strip.m.gap / 3)

        Repeater {
            model: 7

            Rectangle {
                required property int index
                readonly property date day: new Date(strip.m.monday(strip.m.now).getTime() + index * 86400000 + 3600000)
                readonly property bool today: day.toDateString() === strip.m.now.toDateString()

                width: (strip.width - strip.spacing * 6) / 7
                height: strip.height
                radius: strip.m.theme.radius.tile
                color: today ? strip.m.theme.color.accent : strip.m.theme.color.surface2

                ThemedText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height * 0.12
                    label: true
                    text: I18n.locale.dayName(parent.day.getDay(), Locale.NarrowFormat)
                    font.pixelSize: strip.m.t4
                    color: parent.today ? strip.m.theme.color.onAccent : strip.m.theme.color.soft
                }

                ThemedText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: parent.height * 0.12
                    text: parent.day.getDate()
                    font.pixelSize: Math.min(strip.m.t2 * 1.2, parent.width * 0.42, parent.height * 0.4)
                    font.weight: Font.DemiBold
                    font.features: ({ "tnum": 1 })
                    color: parent.today ? strip.m.theme.color.onAccent : strip.m.theme.color.ink
                }
            }
        }
    }

    // The month from Monday, ISO weeks on the left.
    component MonthGrid: Grid {
        id: month

        property var m

        readonly property date first: new Date(month.m.now.getFullYear(), month.m.now.getMonth(), 1)
        readonly property date start: month.m.monday(first)
        readonly property int weeks: Math.ceil(((first.getDay() + 6) % 7 + new Date(month.m.now.getFullYear(), month.m.now.getMonth() + 1, 0).getDate()) / 7)

        columns: 8

        Repeater {
            model: 8 * (month.weeks + 1)

            Item {
                required property int index
                readonly property int row: Math.floor(index / 8) - 1
                readonly property int col: index % 8 - 1
                readonly property date day: new Date(month.start.getTime() + (row * 7 + col) * 86400000 + 3600000)
                readonly property bool header: row < 0
                readonly property bool weekCol: col < 0
                readonly property bool inMonth: day.getMonth() === month.m.now.getMonth()
                readonly property bool today: !header && !weekCol && day.toDateString() === month.m.now.toDateString()

                width: month.width / 8
                height: month.height / (month.weeks + 1)

                Rectangle {
                    anchors.centerIn: parent
                    visible: parent.today
                    width: Math.min(parent.width, parent.height) * 0.86
                    height: width
                    radius: month.m.theme.radius.full
                    color: month.m.theme.color.accent
                }

                ThemedText {
                    anchors.centerIn: parent
                    label: parent.header || parent.weekCol
                    text: parent.header ? (parent.weekCol ? "" : I18n.locale.dayName((parent.col + 1) % 7, Locale.NarrowFormat))
                        : parent.weekCol ? month.m.week(new Date(month.start.getTime() + parent.row * 7 * 86400000 + 3600000))
                        : parent.day.getDate()
                    font.pixelSize: parent.header || parent.weekCol ? month.m.t4 : month.m.t3
                    font.features: ({ "tnum": 1 })
                    color: parent.today ? month.m.theme.color.onAccent : parent.header || parent.weekCol || !parent.inMonth ? month.m.theme.color.soft : month.m.theme.color.ink
                    opacity: !parent.header && !parent.weekCol && !parent.inMonth ? 0.45 : 1
                }
            }
        }
    }
}
