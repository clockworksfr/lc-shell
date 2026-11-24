import QtQuick
import Quickshell
import qs.components
import qs.components.dashboard
import qs.i18n
import qs.services
import qs.theme

// Weather by shape: tiny = icon + temperature; narrow = + hours as rows;
// wide = current conditions left, hour columns right (as many as fit);
// box / tall = current on top, hour columns filling the rest (and the
// next days when tall); strip = one line. Hours sit in the theme's display
// (VFD, green LCD) where it has one. Big cells (tiers large / poster):
// zones — now, the six details, the next 12 hours (temperature curve,
// rain bars), the next 6 days (poster: rain in the next 2 h, the days in
// rows on a common min–max scale).
ModuleBase {
    id: root

    readonly property var now: Weather.now
    readonly property var today: Weather.daily[0] ?? null
    readonly property real hourWidth: Math.max(56, t3 * 3.4)
    // modulaire: everything on its green LCD; facade: the current block in
    // its VFD (the hours are in one too). Text there: screen font, caps.
    readonly property bool onLcd: theme.style.module === "modulaire"
    readonly property bool vfdBlock: (theme.style.display ?? "none") === "vfd"
    readonly property color inkColor: onLcd ? (theme.color.lcdInk ?? "#1A2410") : theme.color.ink
    readonly property color softColor: onLcd ? Qt.alpha(theme.color.lcdInk ?? "#1A2410", 0.65) : theme.color.soft
    readonly property string screenFont: theme.font.lcd ?? theme.font.mono
    readonly property bool screenText: onLcd || vfdBlock

    // modulaire: the green LCD under everything.
    Display {
        visible: root.onLcd && Weather.ready && !root.large
        anchors.fill: parent
        anchors.margins: -4
        tint: "green"
    }

    ThemedText {
        anchors.centerIn: parent
        visible: !Weather.ready
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: Weather.enabled ? I18n.tr("weather.loading") : I18n.tr("weather.noPlace")
        font.pixelSize: root.t3
        color: root.theme.color.soft
    }

    // Icon + temperature.
    component Current: Row {
        id: current

        property var m
        property real size: 64

        spacing: current.size * 0.12

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: current.m.now ? Weather.icon(current.m.now.code, current.m.now.isDay) : ""
            filled: true
            size: current.size * 0.85
            color: current.m.onLcd ? current.m.inkColor : current.m.theme.color.accent
        }

        Figure {
            visible: !current.m.onLcd
            anchors.verticalCenter: parent.verticalCenter
            text: current.m.now ? Weather.temp(current.m.now.temp) : ""
            pixelSize: current.size
        }

        // On the LCD: the figure in the LCD font.
        Text {
            visible: current.m.onLcd
            anchors.verticalCenter: parent.verticalCenter
            text: current.m.now ? Weather.temp(current.m.now.temp) : ""
            // Big figure: Nixie One in the green LCD's ink (like the page).
            color: current.m.inkColor
            font.family: current.m.theme.font.display
            font.pixelSize: current.size
        }
    }

    // Condition, min / max, place.
    component Details: Column {
        id: details

        property var m
        property int align: Text.AlignLeft
        // Wind and next-hour rain lines (where there's room).
        property bool extended: m.ch >= 150

        spacing: 2

        ThemedText {
            width: parent.width
            horizontalAlignment: details.align
            elide: Text.ElideRight
            text: details.m.now ? I18n.tr(Weather.condition(details.m.now.code)) : ""
            font.family: details.m.screenText ? details.m.screenFont : details.m.theme.font.family
            font.capitalization: details.m.screenText ? Font.AllUppercase : Font.MixedCase
            font.pixelSize: details.m.t2
            font.weight: Font.DemiBold
            color: details.m.inkColor
        }

        ThemedText {
            width: parent.width
            horizontalAlignment: details.align
            visible: !!details.m.today
            // Compact, shrinking a little before eliding: both ends stay.
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: 10
            elide: Text.ElideRight
            text: details.m.today ? `↑${Weather.temp(details.m.today.max)}  ↓${Weather.temp(details.m.today.min)}` : ""
            font.family: details.m.screenText ? details.m.screenFont : details.m.theme.font.family
            font.pixelSize: details.m.t3
            font.features: ({ "tnum": 1 })
            color: details.m.softColor
        }

        // Wind, gusts, pressure.
        ThemedText {
            width: parent.width
            horizontalAlignment: details.align
            visible: details.extended && !!Weather.windLine
            elide: Text.ElideRight
            text: Weather.windLine
            font.family: details.m.screenText ? details.m.screenFont : details.m.theme.font.family
            font.pixelSize: details.m.t4 * 1.1
            font.features: ({ "tnum": 1 })
            color: details.m.softColor
        }

        // Rain in the next hour (signal color when it rains or will).
        Row {
            visible: details.extended && !!Weather.rainSoon
            width: parent.width
            spacing: 4

            Icon {
                id: rainIcon
                anchors.top: parent.top
                name: "water_drop"
                filled: Weather.rainSoon !== "dry"
                size: details.m.t4 * 1.3
                color: rainText.color
            }

            ThemedText {
                id: rainText
                width: parent.width - rainIcon.width - parent.spacing
                // The whole sentence (intensity, start, end), on two lines.
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                text: Weather.rainText()
                font.family: details.m.screenText ? details.m.screenFont : details.m.theme.font.family
                font.pixelSize: details.m.t4 * 1.1
                font.weight: Weather.rainSoon === "dry" ? Font.Normal : Font.DemiBold
                color: Weather.rainSoon === "dry" ? details.m.softColor : details.m.onLcd ? details.m.inkColor : (details.m.theme.color.signal ?? details.m.theme.color.accent)
            }
        }

        // The hour step by step (when it rains or will, and there's room).
        RainStrip {
            visible: details.extended && details.m.ch >= 200 && !!Weather.rainEpisode
            width: parent.width
            height: Math.max(30, details.m.t4 * 3)
            wetColor: details.m.onLcd ? details.m.inkColor : (details.m.theme.color.signal ?? details.m.theme.color.accent)
            dryColor: Qt.alpha(details.m.onLcd ? details.m.inkColor : details.m.theme.color.ink, 0.25)
            labelColor: details.m.softColor
            fontFamily: details.m.screenText ? details.m.screenFont : details.m.theme.font.family
            labelSize: details.m.t4 * 0.9
        }

        // Place, and the station's reading time when it's live.
        ThemedText {
            width: parent.width
            horizontalAlignment: details.align
            elide: Text.ElideRight
            text: (Weather.location?.name ?? "") + (details.m.now?.station ? ` · ${I18n.tr("weather.stationAt", { time: I18n.locale.toString(new Date(details.m.now.stationTime), "HH:mm") })}` : "")
            font.family: details.m.screenText ? details.m.screenFont : details.m.theme.font.family
            font.capitalization: details.m.screenText ? Font.AllUppercase : Font.MixedCase
            font.pixelSize: details.m.t4
            color: details.m.softColor
        }
    }

    // Hour columns filling their area (rain bar at the bottom).
    component Hours: Display {
        id: hours

        property var m
        // On modulaire's LCD already: no window of its own.
        screen: !m.onLcd
        property int count: 6
        readonly property var list: Weather.hourly.slice(0, count)

        Row {
            anchors.fill: parent

            Repeater {
                model: hours.list

                Item {
                    id: hour

                    required property var modelData
                    required property int index
                    // The coming hour stands out (signal: Matrix red).
                    readonly property bool now: index === 0
                    readonly property bool wet: modelData.rain >= 50
                    readonly property color ink: hours.m.onLcd ? hours.m.inkColor : hours.ink
                    readonly property color signal: hours.kind === "none" && !hours.m.onLcd ? (hours.m.theme.color.signal ?? hours.m.theme.color.accent) : ink

                    width: parent.width / Math.max(1, hours.list.length)
                    height: parent.height

                    // Compact: hour, sky, temperature, rain chance — centered.
                    Column {
                        anchors.centerIn: parent
                        spacing: hours.m.gap / 4

                        ThemedText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            label: true
                            text: I18n.locale.toString(new Date(hour.modelData.time), "HH")
                            font.pixelSize: hours.m.t4
                            font.weight: hour.now ? Font.Bold : Font.Normal
                            color: hour.now ? hour.signal : (hours.m.onLcd ? hours.m.softColor : hours.soft)
                        }

                        Icon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            name: Weather.icon(hour.modelData.code, hour.modelData.isDay)
                            size: hours.m.t2 * 1.15
                            color: hour.ink
                        }

                        ThemedText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Weather.temp(hour.modelData.temp)
                            font.pixelSize: hours.m.t3
                            font.features: ({ "tnum": 1 })
                            color: hour.ink
                        }

                        // Chance of rain, spelled out (a drop and "40 %").
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: hour.modelData.rain > 0
                            spacing: 2

                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: "water_drop"
                                filled: hour.wet
                                size: hours.m.t4 * 1.1
                                color: hour.wet ? hour.signal : (hours.m.onLcd ? hours.m.softColor : hours.soft)
                            }

                            ThemedText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.percent(hour.modelData.rain / 100)
                                font.pixelSize: hours.m.t4
                                color: hour.wet ? hour.signal : (hours.m.onLcd ? hours.m.softColor : hours.soft)
                            }
                        }
                    }
                }
            }
        }
    }

    // tiny / narrow.
    Column {
        visible: Weather.ready && !root.large && (root.shape === "tiny" || root.shape === "narrow")
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        spacing: root.gap

        Current {
            m: root
            anchors.horizontalCenter: parent.horizontalCenter
            size: Math.min(root.ch * (root.shape === "tiny" ? 0.5 : 0.18), root.cw * 0.3) * root.hk
        }

        Details {
            m: root
            visible: root.shape === "narrow"
            width: parent.width
            align: Text.AlignHCenter
        }

        // Hours as rows.
        Repeater {
            model: root.shape === "narrow" ? Weather.hourly.slice(0, root.fit(root.t3 * 1.8, 8) - 3) : []

            Item {
                required property var modelData
                width: parent.width
                height: root.t3 * 1.8

                ThemedText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.locale.toString(new Date(modelData.time), "HH")
                    font.pixelSize: root.t3
                    color: root.softColor
                }

                Icon {
                    anchors.centerIn: parent
                    name: Weather.icon(modelData.code, modelData.isDay)
                    size: root.t3 * 1.4
                    color: root.inkColor
                }

                ThemedText {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Weather.temp(modelData.temp)
                    font.pixelSize: root.t3
                    color: root.inkColor
                }
            }
        }
    }

    // wide / strip: current left, hours right.
    Item {
        visible: Weather.ready && !root.large && (root.shape === "wide" || root.shape === "strip")
        anchors.fill: parent

        // facade: the current block in its VFD.
        Display {
            visible: root.vfdBlock
            x: wideCurrent.x - 10
            y: Math.min(wideCurrent.y, wideDetails.y) - 10
            width: wideDetails.x + wideDetails.width - wideCurrent.x + 20
            height: Math.max(wideCurrent.height, wideDetails.height) + 20
        }

        Current {
            id: wideCurrent
            m: root
            anchors.verticalCenter: parent.verticalCenter
            size: root.figure(root.shape === "strip" ? 0.7 : 0.5, 0.16)
        }

        Details {
            id: wideDetails
            m: root
            anchors.left: wideCurrent.right
            // Slanted figures (facade) lean past their box.
            anchors.leftMargin: root.gap + (root.theme.font.displayItalic ? wideCurrent.height * 0.25 : 0)
            anchors.verticalCenter: parent.verticalCenter
            // Room for the wind and rain lines.
            width: Math.min(root.cw * (extended ? 0.3 : 0.22), extended ? 340 : 260)
        }

        Hours {
            m: root
            anchors.left: wideDetails.right
            anchors.leftMargin: root.gap
            anchors.right: parent.right
            height: parent.height
            count: Math.max(1, Math.min(12, Math.floor(width / root.hourWidth)))
        }
    }

    // box / tall: current on top, hours under, days when tall.
    Column {
        visible: Weather.ready && !root.large && (root.shape === "box" || root.shape === "tall")
        anchors.fill: parent
        spacing: root.gap

        Item {
            width: parent.width
            height: boxTop.implicitHeight

            // facade: the current block in its VFD.
            Display {
                visible: root.vfdBlock
                anchors.fill: parent
                anchors.margins: -8
            }

        Row {
            id: boxTop

            width: parent.width
            spacing: root.gap + (root.theme.font.displayItalic ? boxCurrent.height * 0.2 : 0)

            Current {
                id: boxCurrent
                m: root
                size: root.figure(0.24, 0.22)
            }

            Details {
                m: root
                width: parent.width - boxCurrent.width - boxTop.spacing
                anchors.verticalCenter: parent.verticalCenter
            }
            }
        }

        Hours {
            m: root
            width: parent.width
            height: root.shape === "tall" ? root.inner.height * 0.36 : root.inner.height - y
            count: Math.max(3, Math.min(8, Math.floor(width / root.hourWidth)))
        }

        // Next days (tall).
        Repeater {
            model: root.shape === "tall" ? Weather.daily.slice(1, 1 + root.fit(root.t3 * 2.2, 5)) : []

            Item {
                required property var modelData
                width: parent.width
                height: root.t3 * 2

                ThemedText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.3
                    text: I18n.locale.dayName(new Date(modelData.time).getDay(), Locale.ShortFormat)
                    font.pixelSize: root.t3
                    color: root.theme.color.soft
                }

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    x: parent.width * 0.32
                    name: Weather.icon(modelData.code, true)
                    size: root.t3 * 1.4
                }

                ThemedText {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: `${Weather.temp(modelData.min)} / ${Weather.temp(modelData.max)}`
                    font.pixelSize: root.t3
                    font.features: ({ "tnum": 1 })
                }
            }
        }
    }

    // --- Big cells ---

    readonly property var days: Weather.daily.slice(1, 7)
    readonly property real weekMin: Math.min(...days.map(d => d.min), today?.min ?? 99)
    readonly property real weekMax: Math.max(...days.map(d => d.max), today?.max ?? -99)
    readonly property color signalColor: onLcd ? inkColor : (theme.color.signal ?? theme.color.accent)
    readonly property string zoneFont: screenText ? screenFont : theme.font.family
    readonly property var detailList: !now ? [] : [
        { label: I18n.tr("weather.d.feels"), value: Weather.temp(now.feels) },
        { label: I18n.tr("weather.d.wind"), value: `${now.windDir ?? ""} ${Math.round(now.wind ?? 0)} ${Weather.windUnit}`.trim() },
        { label: I18n.tr("weather.d.gusts"), value: `${Math.round(now.gusts ?? 0)} ${Weather.windUnit}` },
        { label: I18n.tr("weather.d.humidity"), value: I18n.percent((now.humidity ?? 0) / 100) },
        { label: I18n.tr("weather.d.pressure"), value: `${Math.round(now.pressure ?? 0)} hPa` },
        { label: I18n.tr("weather.d.rain"), value: I18n.percent((Weather.hourly[0]?.rain ?? 0) / 100) }
    ]

    // The six details, `columns` wide.
    component DetailGrid: Grid {
        id: dg

        property var m
        rowSpacing: dg.m.gap
        columnSpacing: dg.m.gap

        Repeater {
            model: dg.m.detailList

            Column {
                required property var modelData
                width: (dg.width - (dg.columns - 1) * dg.columnSpacing) / dg.columns
                spacing: 2

                ThemedText {
                    width: parent.width
                    elide: Text.ElideRight
                    label: true
                    text: dg.m.screenText ? modelData.label.toUpperCase() : modelData.label
                    font.family: dg.m.zoneFont
                    font.pixelSize: dg.m.t4
                    color: dg.m.softColor
                }

                ThemedText {
                    width: parent.width
                    elide: Text.ElideRight
                    text: modelData.value
                    font.family: dg.m.zoneFont
                    font.pixelSize: dg.m.t3 * 1.15
                    font.weight: Font.DemiBold
                    font.features: ({ "tnum": 1 })
                    color: dg.m.inkColor
                }
            }
        }
    }

    // 12 hours: hour, sky, temperature on a curve, rain bars at the bottom.
    component HourChart: Item {
        id: chart

        property var m
        readonly property var list: Weather.hourly.slice(0, 12)
        readonly property real step: width / Math.max(1, list.length)
        readonly property real lo: Math.min(...list.map(h => h.temp))
        readonly property real hi: Math.max(...list.map(h => h.temp))
        readonly property real headH: chart.m.t4 * 1.4 + chart.m.t2 * 1.1 + 8
        readonly property real rainH: Math.max(24, height * 0.16)
        // The curve's band, between the icons and the rain bars.
        readonly property real bandTop: headH + chart.m.t3 * 1.6
        readonly property real bandBottom: height - rainH - chart.m.t4 * 1.6
        function yOf(t: real): real {
            return hi - lo < 0.5 ? (bandTop + bandBottom) / 2 : bandBottom - (t - lo) / (hi - lo) * (bandBottom - bandTop);
        }

        Canvas {
            id: curve
            anchors.fill: parent
            property color ink: chart.m.signalColor
            property bool dotted: chart.m.theme.style.module === "matrix"
            onInkChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Connections {
                target: Weather
                function onHourlyChanged(): void {
                    curve.requestPaint();
                }
            }
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const pts = chart.list.map((h, i) => [chart.step * (i + 0.5), chart.yOf(h.temp)]);
                if (pts.length < 2)
                    return;
                ctx.strokeStyle = ink;
                ctx.fillStyle = ink;
                if (dotted) {
                    // Matrix: the curve in dots.
                    for (let i = 0; i + 1 < pts.length; i++) {
                        const [x0, y0] = pts[i], [x1, y1] = pts[i + 1];
                        const n = Math.max(2, Math.round(Math.hypot(x1 - x0, y1 - y0) / 12));
                        for (let k = 0; k < n; k++) {
                            ctx.beginPath();
                            ctx.arc(x0 + (x1 - x0) * k / n, y0 + (y1 - y0) * k / n, 2.2, 0, Math.PI * 2);
                            ctx.fill();
                        }
                    }
                } else {
                    ctx.lineWidth = 3;
                    ctx.lineJoin = "round";
                    ctx.beginPath();
                    ctx.moveTo(pts[0][0], pts[0][1]);
                    for (let i = 1; i < pts.length; i++)
                        ctx.lineTo(pts[i][0], pts[i][1]);
                    ctx.stroke();
                }
                for (const [x, y] of pts) {
                    ctx.beginPath();
                    ctx.arc(x, y, 5, 0, Math.PI * 2);
                    ctx.fill();
                }
            }
        }

        Repeater {
            model: chart.list

            Item {
                id: col
                required property var modelData
                required property int index
                readonly property bool wet: modelData.rain >= 50
                x: chart.step * index
                width: chart.step
                height: chart.height

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4

                    ThemedText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        label: true
                        text: I18n.locale.toString(new Date(col.modelData.time), "HH")
                        font.family: chart.m.zoneFont
                        font.pixelSize: chart.m.t4
                        font.weight: col.index === 0 ? Font.Bold : Font.Normal
                        color: col.index === 0 ? chart.m.signalColor : chart.m.softColor
                    }

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: Weather.icon(col.modelData.code, col.modelData.isDay)
                        size: chart.m.t2 * 1.1
                        color: chart.m.inkColor
                    }
                }

                ThemedText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: chart.yOf(col.modelData.temp) - height - 8
                    text: Weather.temp(col.modelData.temp)
                    font.family: chart.m.zoneFont
                    font.pixelSize: chart.m.t3
                    font.features: ({ "tnum": 1 })
                    color: chart.m.inkColor
                }

                // Rain chance: a bar from the bottom, its figure under it.
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: rainLabel.top
                    anchors.bottomMargin: 4
                    width: Math.min(chart.step * 0.5, 40)
                    height: Math.max(2, chart.rainH * col.modelData.rain / 100)
                    radius: 2
                    color: col.wet ? chart.m.signalColor : Qt.alpha(chart.m.inkColor, 0.3)
                }

                ThemedText {
                    id: rainLabel
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    text: col.modelData.rain > 0 ? I18n.percent(col.modelData.rain / 100) : "–"
                    font.family: chart.m.zoneFont
                    font.pixelSize: chart.m.t4
                    color: col.wet ? chart.m.signalColor : chart.m.softColor
                }
            }
        }
    }

    // The next days as columns (large).
    component DayColumns: Row {
        id: dcol

        property var m

        Repeater {
            model: dcol.m.days

            Column {
                required property var modelData
                required property int index
                width: dcol.width / Math.max(1, dcol.m.days.length)
                anchors.verticalCenter: parent.verticalCenter
                spacing: dcol.m.gap * 0.25

                ThemedText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: I18n.locale.dayName(new Date(modelData.time).getDay(), Locale.ShortFormat)
                    font.family: dcol.m.zoneFont
                    font.capitalization: dcol.m.screenText ? Font.AllUppercase : Font.Capitalize
                    font.pixelSize: dcol.m.t3
                    color: dcol.m.softColor
                }

                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: Weather.icon(modelData.code, true)
                    size: Math.min(dcol.m.t2 * 1.2, dcol.height * 0.24)
                    color: dcol.m.inkColor
                }

                ThemedText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Weather.temp(modelData.max)
                    font.family: dcol.m.zoneFont
                    font.pixelSize: dcol.m.t3 * 1.15
                    font.weight: Font.DemiBold
                    font.features: ({ "tnum": 1 })
                    color: dcol.m.inkColor
                }

                ThemedText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Weather.temp(modelData.min)
                    font.family: dcol.m.zoneFont
                    font.pixelSize: dcol.m.t3
                    font.features: ({ "tnum": 1 })
                    color: dcol.m.softColor
                }

                Row {
                    id: dayRain
                    readonly property color tone: parent.modelData.rain >= 50 ? dcol.m.signalColor : dcol.m.softColor
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: parent.modelData.rain > 0 ? 1 : 0
                    spacing: 2

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "water_drop"
                        filled: dayRain.parent.modelData.rain >= 50
                        size: dcol.m.t4 * 1.1
                        color: dayRain.tone
                    }

                    ThemedText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: I18n.percent(dayRain.parent.modelData.rain / 100)
                        font.family: dcol.m.zoneFont
                        font.pixelSize: dcol.m.t4
                        color: dayRain.tone
                    }
                }
            }
        }
    }

    // The next days as rows, min–max bars on the week's scale (poster).
    component DayRows: Column {
        id: drow

        property var m
        readonly property real rowH: height / Math.max(1, drow.m.days.length)

        Repeater {
            model: drow.m.days

            Item {
                id: dayRow
                required property var modelData
                width: drow.width
                height: drow.rowH
                readonly property real span: Math.max(1, drow.m.weekMax - drow.m.weekMin)

                ThemedText {
                    id: dayName
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.16
                    elide: Text.ElideRight
                    text: I18n.locale.dayName(new Date(dayRow.modelData.time).getDay(), Locale.LongFormat)
                    font.family: drow.m.zoneFont
                    font.capitalization: drow.m.screenText ? Font.AllUppercase : Font.Capitalize
                    font.pixelSize: drow.m.t3
                    color: drow.m.inkColor
                }

                Icon {
                    id: dayIcon
                    anchors.verticalCenter: parent.verticalCenter
                    x: dayName.width + drow.m.gap * 0.5
                    name: Weather.icon(dayRow.modelData.code, true)
                    size: drow.m.t2
                    color: drow.m.inkColor
                }

                ThemedText {
                    id: dayRain
                    anchors.verticalCenter: parent.verticalCenter
                    x: dayIcon.x + dayIcon.width + drow.m.gap * 0.5
                    width: drow.m.t3 * 3.4
                    text: dayRow.modelData.rain > 0 ? I18n.percent(dayRow.modelData.rain / 100) : ""
                    font.family: drow.m.zoneFont
                    font.pixelSize: drow.m.t4 * 1.1
                    color: dayRow.modelData.rain >= 50 ? drow.m.signalColor : drow.m.softColor
                }

                ThemedText {
                    id: dayMin
                    anchors.verticalCenter: parent.verticalCenter
                    x: dayRain.x + dayRain.width
                    width: drow.m.t3 * 2.6
                    horizontalAlignment: Text.AlignRight
                    text: Weather.temp(dayRow.modelData.min)
                    font.family: drow.m.zoneFont
                    font.pixelSize: drow.m.t3
                    font.features: ({ "tnum": 1 })
                    color: drow.m.softColor
                }

                // The week's scale, this day's range on it.
                Rectangle {
                    id: track
                    anchors.verticalCenter: parent.verticalCenter
                    x: dayMin.x + dayMin.width + drow.m.gap * 0.6
                    width: parent.width - x - dayMax.width - drow.m.gap * 0.6
                    height: Math.max(6, drow.m.t4 * 0.5)
                    radius: height / 2
                    color: Qt.alpha(drow.m.inkColor, 0.15)

                    Rectangle {
                        x: track.width * (dayRow.modelData.min - drow.m.weekMin) / dayRow.span
                        width: Math.max(track.height, track.width * (dayRow.modelData.max - dayRow.modelData.min) / dayRow.span)
                        height: track.height
                        radius: track.radius
                        color: drow.m.signalColor
                    }
                }

                ThemedText {
                    id: dayMax
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    width: drow.m.t3 * 2.6
                    horizontalAlignment: Text.AlignRight
                    text: Weather.temp(dayRow.modelData.max)
                    font.family: drow.m.zoneFont
                    font.pixelSize: drow.m.t3
                    font.weight: Font.DemiBold
                    font.features: ({ "tnum": 1 })
                    color: drow.m.inkColor
                }
            }
        }
    }

    Item {
        id: big

        visible: Weather.ready && root.large
        anchors.fill: parent
        readonly property real leftW: root.poster ? Math.round(width * 0.34) : width

        // Now: icon + temperature, condition and range, place.
        ModuleZone {
            id: nowZone
            width: root.poster ? big.leftW : Math.round(big.width * 0.42)
            height: Math.round(big.height * (root.poster ? 0.3 : 0.26))
            label: I18n.tr("weather.zone.now")
            labelSize: root.t4
            gap: root.gap

            Row {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                spacing: root.gap

                Current {
                    id: bigCurrent
                    m: root
                    anchors.verticalCenter: parent.verticalCenter
                    size: Math.min(root.heroMax * 0.8, nowZone.body.height * 0.7, nowZone.body.width * 0.24)
                }

                Details {
                    m: root
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - bigCurrent.width - parent.spacing
                    extended: false
                }
            }
        }

        ModuleZone {
            id: detailZone
            x: root.poster ? 0 : nowZone.width + root.gap
            y: root.poster ? nowZone.height + root.gap : 0
            width: root.poster ? big.leftW : big.width - x
            height: root.poster ? Math.round(big.height * 0.3) : nowZone.height
            label: I18n.tr("weather.zone.details")
            labelSize: root.t4
            gap: root.gap

            DetailGrid {
                m: root
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                columns: root.poster ? 2 : 3
            }
        }

        // Poster: rain in the next two hours.
        ModuleZone {
            visible: root.poster
            y: detailZone.y + detailZone.height + root.gap
            width: big.leftW
            height: big.height - y
            label: I18n.tr("weather.zone.rain")
            labelSize: root.t4
            gap: root.gap

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                spacing: root.gap * 0.6

                ThemedText {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    text: Weather.rainText()
                    font.family: root.zoneFont
                    font.pixelSize: root.t3
                    color: Weather.rainSoon === "dry" ? root.softColor : root.signalColor
                }

                RainStrip {
                    width: parent.width
                    height: Math.max(60, Math.min(parent.parent.height * 0.5, root.t3 * 5))
                    horizon: 2 * 3600 * 1000
                    wetColor: root.signalColor
                    dryColor: Qt.alpha(root.inkColor, 0.25)
                    labelColor: root.softColor
                    fontFamily: root.zoneFont
                    labelSize: root.t4
                }
            }
        }

        ModuleZone {
            id: hoursZone
            x: root.poster ? big.leftW + root.gap : 0
            y: root.poster ? 0 : nowZone.height + root.gap
            width: big.width - x
            height: Math.round(big.height * (root.poster ? 0.5 : 0.36))
            label: I18n.tr("weather.zone.hours")
            labelSize: root.t4
            gap: root.gap

            HourChart {
                m: root
                anchors.fill: parent
            }
        }

        ModuleZone {
            x: hoursZone.x
            y: hoursZone.y + hoursZone.height + root.gap
            width: hoursZone.width
            height: big.height - y
            label: I18n.tr("weather.zone.days")
            labelSize: root.t4
            gap: root.gap

            DayColumns {
                m: root
                visible: !root.poster
                anchors.fill: parent
            }

            DayRows {
                m: root
                visible: root.poster
                anchors.fill: parent
            }
        }
    }
}
