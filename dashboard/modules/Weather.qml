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
// (VFD, green LCD) where it has one.
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
        visible: root.onLcd && Weather.ready
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
                anchors.verticalCenter: parent.verticalCenter
                name: "water_drop"
                filled: Weather.rainSoon !== "dry"
                size: details.m.t4 * 1.3
                color: rainText.color
            }

            ThemedText {
                id: rainText
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - rainIcon.width - parent.spacing
                elide: Text.ElideRight
                text: Weather.rainText()
                font.family: details.m.screenText ? details.m.screenFont : details.m.theme.font.family
                font.pixelSize: details.m.t4 * 1.1
                font.weight: Weather.rainSoon === "dry" ? Font.Normal : Font.DemiBold
                color: Weather.rainSoon === "dry" ? details.m.softColor : details.m.onLcd ? details.m.inkColor : (details.m.theme.color.signal ?? details.m.theme.color.accent)
            }
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
        visible: Weather.ready && (root.shape === "tiny" || root.shape === "narrow")
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
        visible: Weather.ready && (root.shape === "wide" || root.shape === "strip")
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
            width: Math.min(root.cw * 0.22, 260)
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
        visible: Weather.ready && (root.shape === "box" || root.shape === "tall")
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
}
