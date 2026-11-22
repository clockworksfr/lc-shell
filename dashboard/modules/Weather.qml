import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Weather. S: icon, temperature, condition and today's min / max; M: +
// the next 6 hours in full-height columns with a rain bar; L: current
// details, next 12 hours and 5 days with their min-max range.
ModuleBase {
    id: root

    readonly property var now: Weather.current
    readonly property var today: Weather.daily[0] ?? null
    readonly property var hours: Weather.hourly.slice(0, tier === "L" ? 12 : 6)
    readonly property var days: Weather.daily.slice(1, 6)

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

    // Current conditions.
    Item {
        id: current

        visible: Weather.ready
        width: root.tier === "S" ? parent.width : parent.width * (root.tier === "L" ? 0.3 : 0.38)
        height: root.tier === "L" ? parent.height * 0.55 : parent.height

        Row {
            id: big

            anchors.left: parent.left
            anchors.verticalCenter: root.tier === "S" ? parent.verticalCenter : undefined
            anchors.top: root.tier === "S" ? undefined : parent.top
            spacing: root.gap / 2
            // L: the block holds the figure and two lines under it.
            readonly property real figure: root.tier === "L" ? Math.min(root.t1, current.height * 0.5) : root.t1

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: root.now ? Weather.icon(root.now.code, root.now.isDay) : ""
                filled: true
                size: big.figure * 0.9
                color: root.theme.color.accent
            }

            HeroText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.now ? Weather.temp(root.now.temp) : ""
                pixelSize: big.figure
            }
        }

        Column {
            anchors.right: root.tier === "S" ? parent.right : undefined
            anchors.left: root.tier === "S" ? undefined : parent.left
            anchors.verticalCenter: root.tier === "S" ? parent.verticalCenter : undefined
            anchors.top: root.tier === "S" ? undefined : big.bottom
            anchors.topMargin: root.tier === "S" ? 0 : root.gap / 2
            width: root.tier === "S" ? parent.width - big.width - root.gap : parent.width
            spacing: 2

            ThemedText {
                width: parent.width
                horizontalAlignment: root.tier === "S" ? Text.AlignRight : Text.AlignLeft
                elide: Text.ElideRight
                text: root.now ? I18n.tr(Weather.condition(root.now.code)) : ""
                font.pixelSize: root.t2
                font.weight: Font.DemiBold
            }

            ThemedText {
                width: parent.width
                horizontalAlignment: root.tier === "S" ? Text.AlignRight : Text.AlignLeft
                visible: !!root.today
                text: root.today ? `↑ ${Weather.temp(root.today.max)}  ↓ ${Weather.temp(root.today.min)}` : ""
                font.pixelSize: root.t3
                font.features: ({ "tnum": 1 })
                color: root.theme.color.soft
            }

            ThemedText {
                width: parent.width
                horizontalAlignment: root.tier === "S" ? Text.AlignRight : Text.AlignLeft
                elide: Text.ElideRight
                visible: root.tier === "M"
                text: root.tier === "L" && root.now
                    ? I18n.tr("weather.feels", { value: Weather.temp(root.now.feels), wind: Math.round(root.now.wind), unit: Weather.windUnit })
                    : (Weather.location?.name ?? "")
                font.pixelSize: root.t3
                color: root.theme.color.soft
            }

            ThemedText {
                visible: root.tier === "L"
                width: parent.width
                elide: Text.ElideRight
                text: root.now ? `${Weather.location?.name ?? ""} · ${I18n.tr("weather.feels", { value: Weather.temp(root.now.feels), wind: Math.round(root.now.wind), unit: Weather.windUnit })}` : ""
                font.pixelSize: root.t4
                color: root.theme.color.soft
            }
        }
    }

    // M / L: next hours, columns filling the height (rain bar at the bottom).
    Row {
        id: hourRow

        visible: Weather.ready && root.tier !== "S"
        anchors.right: parent.right
        width: parent.width - current.width - root.gap
        height: root.tier === "L" ? parent.height * 0.55 : parent.height

        Repeater {
            model: root.hours

            Item {
                required property var modelData
                width: hourRow.width / Math.max(1, root.hours.length)
                height: hourRow.height

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: root.gap / 3

                    ThemedText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        label: true
                        text: I18n.locale.toString(new Date(modelData.time), "HH")
                        font.pixelSize: root.t4
                        color: root.theme.color.soft
                    }

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: Weather.icon(modelData.code, modelData.isDay)
                        size: root.t2 * 1.5
                    }

                    ThemedText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Weather.temp(modelData.temp)
                        font.pixelSize: root.t3
                        font.features: ({ "tnum": 1 })
                    }
                }

                // Rain probability.
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    width: Math.min(parent.width * 0.4, 14)
                    height: Math.max(3, parent.height * 0.3 * modelData.rain / 100)
                    radius: root.theme.radius.control / 2
                    color: modelData.rain >= 50 ? root.theme.color.accent : Qt.alpha(root.theme.color.accent, 0.4)
                }
            }
        }
    }

    // L: next 5 days, min-max range on a shared scale.
    Row {
        id: dayRow

        readonly property real lo: Math.min(...root.days.map(d => d.min))
        readonly property real hi: Math.max(...root.days.map(d => d.max))

        visible: Weather.ready && root.tier === "L" && root.days.length > 0
        anchors.bottom: parent.bottom
        width: parent.width
        height: parent.height * 0.4
        spacing: root.gap

        Repeater {
            model: root.days

            Rectangle {
                required property var modelData
                width: (dayRow.width - dayRow.spacing * (root.days.length - 1)) / root.days.length
                height: dayRow.height
                radius: root.theme.radius.tile
                color: root.theme.color.surface2

                ThemedText {
                    x: root.gap
                    y: root.gap / 2
                    label: true
                    text: I18n.locale.dayName(new Date(modelData.time).getDay(), Locale.ShortFormat)
                    font.pixelSize: root.t4
                    color: root.theme.color.soft
                }

                Icon {
                    anchors.right: parent.right
                    anchors.rightMargin: root.gap
                    y: root.gap / 2
                    name: Weather.icon(modelData.code, true)
                    size: root.t2 * 1.4
                }

                // Range bar.
                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: root.gap
                    height: root.t3 * 1.6

                    ThemedText {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        text: Weather.temp(modelData.min)
                        font.pixelSize: root.t3
                        color: root.theme.color.soft
                    }

                    ThemedText {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        text: Weather.temp(modelData.max)
                        font.pixelSize: root.t3
                        font.weight: Font.DemiBold
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 5
                        radius: 3
                        color: root.theme.color.surface3

                        Rectangle {
                            readonly property real span: Math.max(1, dayRow.hi - dayRow.lo)
                            x: parent.width * (modelData.min - dayRow.lo) / span
                            width: Math.max(6, parent.width * (modelData.max - modelData.min) / span)
                            height: parent.height
                            radius: parent.radius
                            color: root.theme.color.accent
                        }
                    }
                }
            }
        }
    }
}
