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
                // Day cells about as tall as wide.
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
            // Day cells about as tall as wide.
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

            width: big.stacked ? parent.width : Math.round(parent.width * (root.poster ? 0.5 : 0.53) - root.gap * 1.5)
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

                    // The theme's progress: accent; Matrix ink with only its
                    // head in the signal red.
                    Rectangle {
                        width: parent.width * root.dayOfYear / root.daysInYear
                        height: parent.height
                        radius: parent.radius
                        color: root.theme.style.module === "matrix" ? root.theme.color.ink : root.theme.color.accent
                    }
                    Rectangle {
                        visible: root.theme.style.module === "matrix"
                        x: parent.width * root.dayOfYear / root.daysInYear - width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.height * 2
                        height: width
                        radius: width / 2
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
                    // The year only when it changes.
                    readonly property date shown: new Date(root.now.getFullYear(), root.now.getMonth() + index + 1, 1)
                    label: I18n.locale.toString(shown, shown.getFullYear() === root.now.getFullYear() ? "MMMM" : "MMMM yyyy")
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
        spacing: 18

        Repeater {
            model: 7

            Rectangle {
                required property int index
                readonly property bool lit: index <= secondDots.m.now.getSeconds() % 7
                width: 7
                height: 7
                radius: 3.5
                color: lit ? secondDots.m.theme.color.ink : secondDots.m.theme.color.surface3
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

    // 7 equal cells, today lit: matrix outlined pills,
    // today in the signal color; classic surface cells, today accent;
    // constellation today in the accent gradient; facade display cells,
    // today ink; modulaire dark cells with light digits (both variants),
    // today accent.
    component WeekStrip: Row {
        id: strip

        property var m

        spacing: 6

        Repeater {
            model: 7

            Rectangle {
                id: cellDay
                required property int index
                readonly property date day: new Date(strip.m.monday(strip.m.now).getTime() + index * 86400000 + 3600000)
                readonly property bool today: day.toDateString() === strip.m.now.toDateString()
                readonly property string look: strip.m.theme.style.module ?? "classic"
                readonly property color todayFill: look === "facade" ? strip.m.theme.color.ink : look === "matrix" ? (strip.m.theme.color.signal ?? strip.m.theme.color.accent) : strip.m.theme.color.accent
                readonly property color todayInk: look === "facade" ? "#030505" : look === "modulaire" ? "#111111" : look === "matrix" ? "white" : strip.m.theme.color.onAccent
                readonly property color dayInk: look === "modulaire" ? "#E9E7E1" : strip.m.theme.color.ink

                width: (strip.width - strip.spacing * 6) / 7
                height: strip.height
                radius: look === "matrix" ? width / 2 : look === "facade" || look === "modulaire" ? 3 : strip.m.theme.radius.tile
                color: today ? todayFill : look === "matrix" ? "transparent" : look === "facade" ? strip.m.theme.color.surface2 : look === "modulaire" ? "#1A1B1C" : strip.m.theme.color.surface2
                border.width: look === "matrix" && !today ? 1 : look === "facade" ? 1 : 0
                border.color: look === "matrix" ? strip.m.theme.color.line : "#000000"
                gradient: look === "constellation" && today ? todayGradient : null

                Gradient {
                    id: todayGradient
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0
                        color: strip.m.theme.color.accent
                    }
                    GradientStop {
                        position: 1
                        color: strip.m.theme.color.accent2 ?? strip.m.theme.color.accent
                    }
                }

                ThemedText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 6
                    label: true
                    text: I18n.locale.dayName(cellDay.day.getDay(), Locale.NarrowFormat)
                    font.pixelSize: strip.m.t4
                    color: cellDay.today ? cellDay.todayInk : cellDay.look === "modulaire" ? Qt.alpha(cellDay.dayInk, 0.6) : strip.m.theme.color.soft
                }

                ThemedText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    text: cellDay.day.getDate()
                    font.family: cellDay.look === "facade" || cellDay.look === "modulaire" ? "IBM Plex Mono" : cellDay.look === "matrix" ? "Space Mono" : strip.m.theme.font.family
                    font.pixelSize: Math.min(strip.m.t3, parent.width * 0.42, parent.height * 0.4)
                    font.weight: Font.Bold
                    font.features: ({ "tnum": 1 })
                    color: cellDay.today ? cellDay.todayInk : cellDay.dayInk
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
        readonly property string look: month.m.theme.style.module ?? "classic"
        // Small months (the next ones): no days of other months.
        readonly property bool small: offset > 0
        readonly property int thisWeek: month.m.week(month.m.now)
        readonly property string digits: look === "facade" || look === "modulaire" ? "IBM Plex Mono" : look === "matrix" ? "Space Mono" : month.m.theme.font.family

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

                readonly property int weekNumber: month.m.week(new Date(month.start.getTime() + slot.row * 7 * 86400000 + 3600000))
                readonly property bool weekend: slot.col >= 5

                // Today: a circle (classic accent, constellation gradient
                // with a halo, matrix signal), a square (facade ink,
                // modulaire accent).
                Rectangle {
                    anchors.centerIn: parent
                    visible: slot.today && month.look === "constellation"
                    width: todayMark.width + 16
                    height: width
                    radius: width / 2
                    color: Qt.alpha(month.m.theme.color.accent, 0.2)
                }
                Rectangle {
                    id: todayMark
                    anchors.centerIn: parent
                    visible: slot.today
                    height: Math.min(parent.height * 0.94, month.daySize * 1.6)
                    width: height
                    radius: month.look === "facade" || month.look === "modulaire" ? 3 : height / 2
                    color: month.look === "facade" ? month.m.theme.color.ink : month.look === "matrix" ? (month.m.theme.color.signal ?? month.m.theme.color.accent) : month.m.theme.color.accent
                    gradient: month.look === "constellation" ? markGradient : null

                    Gradient {
                        id: markGradient
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0
                            color: month.m.theme.color.accent
                        }
                        GradientStop {
                            position: 1
                            color: month.m.theme.color.accent2 ?? month.m.theme.color.accent
                        }
                    }
                }

                ThemedText {
                    id: dayLabel
                    anchors.centerIn: parent
                    label: slot.header || slot.weekCol
                    // Week numbers (and their "Sem." header) in the mono.
                    text: slot.header ? (slot.weekCol ? I18n.tr("clock.weekShort") : I18n.locale.dayName((slot.col + 1) % 7, Locale.NarrowFormat))
                        : slot.weekCol ? slot.weekNumber
                        : !slot.inMonth && month.small ? ""
                        : slot.day.getDate()
                    font.family: slot.header || slot.weekCol ? month.m.theme.font.mono : month.digits
                    font.pixelSize: slot.header || slot.weekCol ? Math.min(month.m.t4, month.daySize * 0.62) : month.daySize
                    font.weight: slot.today ? Font.Bold : Font.Normal
                    font.features: ({ "tnum": 1 })
                    color: slot.today ? (month.look === "facade" ? "#030505" : month.look === "modulaire" ? "#111111" : month.look === "matrix" ? "white" : month.m.theme.color.onAccent)
                        : slot.weekCol && slot.weekNumber === month.thisWeek && month.offset === 0 ? month.m.theme.color.ink
                        : slot.header || slot.weekCol || !slot.inMonth || slot.weekend ? month.m.theme.color.soft : month.m.theme.color.ink
                    opacity: slot.weekCol ? (slot.weekNumber === month.thisWeek && month.offset === 0 ? 1 : 0.75) : !slot.header && !slot.inMonth ? 0.28 : 1
                }
            }
        }
    }
}
