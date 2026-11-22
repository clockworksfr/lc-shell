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

    readonly property var now: Weather.current
    readonly property var today: Weather.daily[0] ?? null
    readonly property real hourWidth: Math.max(56, t3 * 3.4)

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
            color: current.m.theme.color.accent
        }

        Figure {
            anchors.verticalCenter: parent.verticalCenter
            text: current.m.now ? Weather.temp(current.m.now.temp) : ""
            pixelSize: current.size
        }
    }

    // Condition, min / max, place.
    component Details: Column {
        id: details

        property var m
        property int align: Text.AlignLeft

        spacing: 2

        ThemedText {
            width: parent.width
            horizontalAlignment: details.align
            elide: Text.ElideRight
            text: details.m.now ? I18n.tr(Weather.condition(details.m.now.code)) : ""
            font.pixelSize: details.m.t2
            font.weight: Font.DemiBold
        }

        ThemedText {
            width: parent.width
            horizontalAlignment: details.align
            visible: !!details.m.today
            text: details.m.today ? `↑ ${Weather.temp(details.m.today.max)}  ↓ ${Weather.temp(details.m.today.min)}` : ""
            font.pixelSize: details.m.t3
            font.features: ({ "tnum": 1 })
            color: details.m.theme.color.soft
        }

        ThemedText {
            width: parent.width
            horizontalAlignment: details.align
            elide: Text.ElideRight
            text: Weather.location?.name ?? ""
            font.pixelSize: details.m.t4
            color: details.m.theme.color.soft
        }
    }

    // Hour columns filling their area (rain bar at the bottom).
    component Hours: Display {
        id: hours

        property var m
        property int count: 6
        readonly property var list: Weather.hourly.slice(0, count)

        Row {
            anchors.fill: parent

            Repeater {
                model: hours.list

                Item {
                    required property var modelData
                    width: parent.width / Math.max(1, hours.list.length)
                    height: parent.height

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: hours.m.gap / 3

                        ThemedText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            label: true
                            text: I18n.locale.toString(new Date(modelData.time), "HH")
                            font.pixelSize: hours.m.t4
                            color: hours.soft
                        }

                        Icon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            name: Weather.icon(modelData.code, modelData.isDay)
                            size: hours.m.t2 * 1.3
                            color: hours.ink
                        }

                        ThemedText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Weather.temp(modelData.temp)
                            font.pixelSize: hours.m.t3
                            font.features: ({ "tnum": 1 })
                            color: hours.ink
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        width: Math.min(parent.width * 0.35, 12)
                        height: Math.max(3, parent.height * 0.18 * modelData.rain / 100)
                        radius: 2
                        color: Qt.alpha(hours.ink, modelData.rain >= 50 ? 0.7 : 0.35)
                    }
                }
            }
        }
    }

    // tiny / narrow.
    Column {
        visible: Weather.ready && (root.shape === "tiny" || root.shape === "narrow")
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: root.shape === "tiny" ? parent.verticalCenter : undefined
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
                    color: root.theme.color.soft
                }

                Icon {
                    anchors.centerIn: parent
                    name: Weather.icon(modelData.code, modelData.isDay)
                    size: root.t3 * 1.4
                }

                ThemedText {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Weather.temp(modelData.temp)
                    font.pixelSize: root.t3
                }
            }
        }
    }

    // wide / strip: current left, hours right.
    Item {
        visible: Weather.ready && (root.shape === "wide" || root.shape === "strip")
        anchors.fill: parent

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
            anchors.leftMargin: root.gap
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

        Row {
            width: parent.width
            spacing: root.gap

            Current {
                id: boxCurrent
                m: root
                size: root.figure(0.24, 0.22)
            }

            Details {
                m: root
                width: parent.width - boxCurrent.width - root.gap
                anchors.verticalCenter: parent.verticalCenter
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
