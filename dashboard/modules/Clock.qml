import QtQuick
import Quickshell
import qs.components
import qs.components.dashboard
import qs.i18n
import qs.theme

// Time and date, by shape: tiny = time; narrow = hours over minutes;
// wide = time left, day / date / week right (+ the week strip when tall
// enough); box / tall = time, date, the week (the month when roomy);
// strip = one line. In modulaire, the time sits in an amber LCD window.
// Big cells (tiers large / poster): the time, day, date, week, day of
// the year and the year's progress left, the month in a zone right
// (poster: the next two months under the time). Options: format ("HH:mm").
ModuleBase {
    id: root

    readonly property date now: clock.date
    readonly property string format: options.format ?? "HH:mm"
    readonly property string time: I18n.locale.toString(now, format)
    readonly property bool roomy: (shape === "box" || shape === "tall") && ch >= 360 && cw >= 520
    readonly property int dayOfYear: Math.round((new Date(now.getFullYear(), now.getMonth(), now.getDate()) - new Date(now.getFullYear(), 0, 1)) / 86400000) + 1
    readonly property int daysInYear: new Date(now.getFullYear(), 1, 29).getMonth() === 1 ? 366 : 365

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
        // Matrix counts the seconds in dots.
        precision: root.format.includes("s") || root.theme.style.module === "matrix" ? SystemClock.Seconds : SystemClock.Minutes
    }

    // tiny: the time alone, centered.
    Figure {
        visible: root.shape === "tiny" && !root.large
        anchors.centerIn: parent
        text: root.time
        inDisplay: true
        pixelSize: root.figure(0.6, root.perChar(root.time.length))
    }

    // narrow: hours over minutes, date under.
    Column {
        visible: root.shape === "narrow" && !root.large
        anchors.centerIn: parent
        spacing: root.gap / 2

        Repeater {
            model: root.time.split(":")

            Figure {
                required property string modelData
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData
                inDisplay: true
                // A display window adds its frame: smaller figures there.
                pixelSize: Math.min(root.ch * 0.3, root.cw * root.perChar(2) * ((root.theme.style.display ?? "none") === "none" ? 1 : 0.7)) * root.hk
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
        visible: (root.shape === "wide" || root.shape === "strip") && !root.large
        anchors.fill: parent

        Figure {
            id: wideTime
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.time
            inDisplay: true
            pixelSize: root.figure(0.62, (root.shape === "strip" ? 0.3 : 0.55) * root.perChar(root.time.length))
        }

        SecondDots {
            m: root
            anchors.top: wideTime.bottom
            anchors.topMargin: root.gap / 2
            anchors.horizontalCenter: wideTime.horizontalCenter
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
        visible: (root.shape === "box" || root.shape === "tall") && !root.large
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

        SecondDots {
            m: root
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

    // Big cells: the time and the date left, the month right (below when
    // the cell is tall).
    Item {
        id: big

        readonly property bool stacked: root.ratio < 1.15
        visible: root.large
        anchors.fill: parent

        Column {
            id: bigLeft

            width: big.stacked ? parent.width : Math.round(parent.width * (root.poster ? 0.44 : 0.42))
            spacing: root.gap
            // Large: centered against the month; poster: on top (the next
            // months under it).
            y: root.poster || big.stacked ? 0 : Math.max(0, (parent.height - height) / 2)

            Figure {
                text: root.time
                inDisplay: true
                pixelSize: Math.min(root.heroMax, bigLeft.width * root.perChar(root.time.length)) * root.hk
            }

            SecondDots {
                m: root
            }

            Column {
                width: parent.width
                spacing: Math.round(root.gap * 0.3)

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
                    elide: Text.ElideRight
                    label: true
                    text: `${I18n.tr("clock.week", { n: root.week(root.now) })} · ${I18n.tr("clock.dayOfYear", { n: root.dayOfYear, total: root.daysInYear })}`
                    font.pixelSize: root.t4
                    color: root.theme.color.soft
                }
            }

            // The year's progress.
            Column {
                width: parent.width
                spacing: Math.round(root.gap * 0.4)

                Rectangle {
                    width: parent.width
                    height: Math.max(6, Math.round(root.t4 * 0.45))
                    radius: height / 2
                    color: root.theme.color.surface2

                    Rectangle {
                        width: parent.width * root.dayOfYear / root.daysInYear
                        height: parent.height
                        radius: parent.radius
                        color: root.theme.color.signal ?? root.theme.color.accent
                    }
                }

                ThemedText {
                    label: true
                    text: I18n.tr("clock.yearProgress", { value: I18n.tr("format.percent", { value: Math.round(root.dayOfYear / root.daysInYear * 100) }) })
                    font.pixelSize: root.t4
                    color: root.theme.color.soft
                }
            }
        }

        // Poster: the next two months, small, under the time.
        Row {
            id: nextMonths

            visible: root.poster && !big.stacked
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: bigLeft.width
            height: Math.max(0, parent.height - bigLeft.height - root.gap * 2)
            spacing: root.gap

            Repeater {
                model: nextMonths.visible && nextMonths.height > 200 ? 2 : 0

                ModuleZone {
                    id: nextZone
                    required property int index
                    width: (nextMonths.width - nextMonths.spacing) / 2
                    height: nextMonths.height
                    label: I18n.locale.toString(new Date(root.now.getFullYear(), root.now.getMonth() + index + 1, 1), "MMMM yyyy")
                    labelSize: root.t4
                    gap: root.gap

                    MonthGrid {
                        m: root
                        offset: nextZone.index + 1
                        width: parent.width
                        height: parent.height
                    }
                }
            }
        }

        ModuleZone {
            x: big.stacked ? 0 : bigLeft.width + root.gap * 1.5
            y: big.stacked ? bigLeft.height + root.gap * 1.5 : 0
            width: parent.width - x
            height: parent.height - y
            label: I18n.locale.toString(root.now, "MMMM yyyy")
            labelSize: root.t4
            gap: root.gap

            MonthGrid {
                m: root
                boost: root.poster ? 1.3 : 1.15
                width: parent.width
                height: parent.height
            }
        }
    }

    // Matrix: 7 dots under the time, one more lit each second (mod 7).
    component SecondDots: Row {
        id: secondDots

        property var m

        visible: secondDots.m.theme.style.module === "matrix"
        spacing: 11

        Repeater {
            model: 7

            Rectangle {
                required property int index
                readonly property bool lit: index <= secondDots.m.now.getSeconds() % 7
                width: 7
                height: 7
                radius: 3.5
                color: lit ? secondDots.m.theme.color.ink : "#1A1A1A"
            }
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
                readonly property string look: strip.m.theme.style.module ?? "classic"
                // facade: display cells; constellation: today in a gradient.
                color: look === "facade" ? (today ? strip.m.theme.color.ink : (strip.m.theme.color.screen ?? "#030505")) : today ? (strip.m.theme.color.signal ?? strip.m.theme.color.accent) : strip.m.theme.color.surface2
                border.width: look === "facade" ? 1 : 0
                border.color: "#000000"
                gradient: look === "constellation" && today ? todayGradient : null

                Gradient {
                    id: todayGradient
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0
                        color: "#9FB8FF"
                    }
                    GradientStop {
                        position: 1
                        color: "#F2A7D8"
                    }
                }

                ThemedText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height * 0.12
                    label: true
                    text: I18n.locale.dayName(parent.day.getDay(), Locale.NarrowFormat)
                    font.pixelSize: strip.m.t4
                    color: parent.look === "facade" ? (parent.today ? (strip.m.theme.color.screen ?? "#030505") : Qt.alpha(strip.m.theme.color.ink, 0.6)) : parent.today ? strip.m.theme.color.onAccent : strip.m.theme.color.soft
                }

                ThemedText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: parent.height * 0.12
                    text: parent.day.getDate()
                    font.pixelSize: Math.min(strip.m.t2 * 1.2, parent.width * 0.42, parent.height * 0.4)
                    font.weight: Font.DemiBold
                    font.features: ({ "tnum": 1 })
                    color: parent.look === "facade" ? (parent.today ? (strip.m.theme.color.screen ?? "#030505") : strip.m.theme.color.ink) : parent.today ? strip.m.theme.color.onAccent : strip.m.theme.color.ink
                }
            }
        }
    }

    // The month from Monday, ISO weeks on the left.
    component MonthGrid: Grid {
        id: month

        property var m
        // Months after the current one (0: this month, today lit).
        property int offset: 0
        // Day figures bigger than t3 × 1.1 (big cells).
        property real boost: 1

        readonly property date first: new Date(month.m.now.getFullYear(), month.m.now.getMonth() + offset, 1)
        readonly property date start: month.m.monday(first)
        readonly property int weeks: Math.ceil(((first.getDay() + 6) % 7 + new Date(first.getFullYear(), first.getMonth() + 1, 0).getDate()) / 7)
        // A narrow week-number column and a short header row leave the
        // days more room.
        readonly property real weekW: Math.max(month.m.t4 * 2, width * 0.075)
        readonly property real dayW: (width - weekW) / 7
        readonly property real rowH: height / (weeks + 0.7)
        readonly property real daySize: Math.max(11, Math.min(month.m.t3 * 1.1 * boost, rowH * 0.62, dayW * 0.5))

        columns: 8

        Repeater {
            model: 8 * (month.weeks + 1)

            Item {
                id: slot

                required property int index
                readonly property int row: Math.floor(index / 8) - 1
                readonly property int col: index % 8 - 1
                readonly property date day: new Date(month.start.getTime() + (row * 7 + col) * 86400000 + 3600000)
                readonly property bool header: row < 0
                readonly property bool weekCol: col < 0
                readonly property bool inMonth: day.getMonth() === month.first.getMonth()
                readonly property bool today: !header && !weekCol && day.toDateString() === month.m.now.toDateString()

                width: weekCol ? month.weekW : month.dayW
                height: header ? month.rowH * 0.7 : month.rowH

                // Today: a pill wide enough for two digits, bold figure.
                Rectangle {
                    anchors.centerIn: parent
                    visible: slot.today
                    height: Math.min(parent.height * 0.94, month.daySize * 1.55)
                    width: Math.min(parent.width * 0.96, Math.max(height, dayLabel.implicitWidth + month.daySize * 0.9))
                    radius: height / 2
                    color: month.m.theme.color.signal ?? month.m.theme.color.accent
                }

                ThemedText {
                    id: dayLabel
                    anchors.centerIn: parent
                    label: slot.header || slot.weekCol
                    text: slot.header ? (slot.weekCol ? "" : I18n.locale.dayName((slot.col + 1) % 7, Locale.NarrowFormat))
                        : slot.weekCol ? month.m.week(new Date(month.start.getTime() + slot.row * 7 * 86400000 + 3600000))
                        : slot.day.getDate()
                    font.pixelSize: slot.header || slot.weekCol ? Math.min(month.m.t4, month.daySize * 0.75) : month.daySize
                    font.weight: slot.today ? Font.Bold : Font.Normal
                    font.features: ({ "tnum": 1 })
                    color: slot.today ? (month.m.theme.color.signal ? "white" : month.m.theme.color.onAccent) : slot.header || slot.weekCol || !slot.inMonth ? month.m.theme.color.soft : month.m.theme.color.ink
                    opacity: slot.weekCol ? 0.6 : !slot.header && !slot.inMonth ? 0.45 : 1
                }
            }
        }
    }
}
