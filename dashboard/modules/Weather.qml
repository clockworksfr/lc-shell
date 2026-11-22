import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Temperature, sky and place; next hours when there is room.
Item {
    id: root

    property ShellScreen screen
    property var options: ({})
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property var now: Weather.current
    readonly property bool roomy: width > height * 1.6

    ThemedText {
        anchors.centerIn: parent
        visible: !Weather.ready
        width: parent.width - root.theme.space.l * 2
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: Weather.enabled ? I18n.tr("weather.loading") : I18n.tr("weather.noPlace")
        color: root.theme.color.soft
    }

    Row {
        visible: Weather.ready
        anchors.centerIn: parent
        spacing: root.theme.space.l

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.theme.space.xs

            Row {
                spacing: root.theme.space.s

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.now ? Weather.icon(root.now.code, root.now.isDay) : ""
                    filled: true
                    size: Math.min(root.height * 0.4, 72)
                    color: root.theme.color.accent
                }

                ThemedText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.now ? Weather.temp(root.now.temp) : ""
                    font.family: root.theme.font.display
                    font.weight: root.theme.font.displayWeight
                    font.pixelSize: Math.min(root.height * 0.42, 80)
                    font.features: ({ "tnum": 1 })
                }
            }

            ThemedText {
                label: true
                text: root.now ? `${I18n.tr(Weather.condition(root.now.code))} · ${Weather.location?.name ?? ""}` : ""
                color: root.theme.color.soft
            }
        }

        Row {
            visible: root.roomy
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.theme.space.m

            Repeater {
                model: Weather.hourly.slice(0, 4)

                Column {
                    required property var modelData
                    spacing: root.theme.space.xs

                    ThemedText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        label: true
                        text: I18n.locale.toString(new Date(parent.modelData.time), "HH")
                        color: root.theme.color.soft
                    }

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: Weather.icon(parent.modelData.code, parent.modelData.isDay)
                        size: 24
                    }

                    ThemedText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Weather.temp(parent.modelData.temp)
                    }
                }
            }
        }
    }
}
