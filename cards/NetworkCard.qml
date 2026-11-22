import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Connection, live download/upload with a 60 s curve, local address.
Column {
    id: root

    property var block
    property ShellScreen screen
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    Component.onCompleted: NetworkService.watchers++
    Component.onDestruction: NetworkService.watchers--

    spacing: theme.space.m

    Item {
        width: parent.width
        implicitHeight: title.implicitHeight

        ThemedText {
            id: title
            width: parent.width - signal.width - root.theme.space.s
            text: NetworkService.kind === "wired" ? I18n.tr("net.wired") : NetworkService.kind === "wifi" ? NetworkService.activeWifi.name : I18n.tr("net.offline")
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        ThemedText {
            id: signal
            anchors.right: parent.right
            text: NetworkService.kind === "wifi" ? I18n.percent(NetworkService.activeWifi.signalStrength) : NetworkService.kind === "wired" && NetworkService.wired?.linkSpeed ? `${NetworkService.wired.linkSpeed} Mb/s` : ""
            color: root.theme.color.soft
        }
    }

    Row {
        visible: NetworkService.kind !== "none"
        width: parent.width
        spacing: root.theme.space.s

        Repeater {
            model: [
                { label: I18n.tr("card.download"), glyph: "↓", rate: NetworkService.rxRate, history: NetworkService.rxHistory, color: root.theme.color.accent },
                { label: I18n.tr("card.upload"), glyph: "↑", rate: NetworkService.txRate, history: NetworkService.txHistory, color: root.theme.color.accent2 }
            ]

            Rectangle {
                required property var modelData

                width: (root.width - root.theme.space.s) / 2
                implicitHeight: tile.implicitHeight + root.theme.space.m * 2
                radius: root.theme.radius.tile
                color: root.theme.color.surface2

                Column {
                    id: tile

                    anchors.fill: parent
                    anchors.margins: root.theme.space.m
                    spacing: root.theme.space.xs

                    ThemedText {
                        text: `${parent.parent.modelData.glyph} ${parent.parent.modelData.label}`
                        label: true
                        color: root.theme.color.soft
                    }

                    ThemedText {
                        text: I18n.bytes(parent.parent.modelData.rate, true)
                        font.weight: Font.DemiBold
                        font.features: ({ "tnum": 1 })
                    }

                    Sparkline {
                        width: parent.width
                        height: 32
                        values: parent.parent.modelData.history
                        color: parent.parent.modelData.color
                    }
                }
            }
        }
    }

    Item {
        visible: !!NetworkService.address
        width: parent.width
        implicitHeight: addressLabel.implicitHeight

        ThemedText {
            id: addressLabel
            text: I18n.tr("card.address")
            color: root.theme.color.soft
        }

        ThemedText {
            anchors.right: parent.right
            text: NetworkService.address
            font.family: root.theme.font.mono
        }
    }

    ThemedText {
        text: I18n.tr("card.open")
        color: root.theme.color.soft
        font.pixelSize: root.theme.font.sizeS
    }
}
