import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Wallpaper: on/off, directory, picker grid (applies to every screen).
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    spacing: theme.space.s

    Component.onCompleted: Wallpaper.rescan()

    Section {
        title: I18n.tr("settings.wallpaper")

        Field {
            label: I18n.tr("settings.wallpaperEnabled")
            hint: I18n.tr("settings.wallpaperEnabledHint")
            Switch {
                width: 60
                checked: Wallpaper.enabled
                onToggled: Config.set("wallpaper.enabled", !checked)
            }
        }

        Field {
            label: I18n.tr("settings.wallpaperDirectory")
            hint: I18n.tr("settings.wallpaperCount", { n: Wallpaper.images.length })
            TextField {
                implicitWidth: 320
                text: Config.get("wallpaper.directory") ?? ""
                onCommitted: text => Config.set("wallpaper.directory", text)
            }
        }

        ListRow {
            title: I18n.tr("settings.wallpaperRandom")
            onClicked: Wallpaper.random(null)
        }
    }

    GridView {
        width: parent.width
        height: Math.min(contentHeight, 420)
        clip: true
        cellWidth: Math.floor(width / 5)
        cellHeight: cellWidth * 0.6
        model: Wallpaper.images

        delegate: Item {
            required property string modelData

            width: GridView.view.cellWidth
            height: GridView.view.cellHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                // Thumbnails stay rectangular (pill-shaped controls in Matrix).
                radius: Math.min(root.theme.radius.control, 8)
                color: root.theme.color.surface2
                clip: true
                border.width: Wallpaper.state.all === parent.modelData ? 2 : 0
                border.color: root.theme.color.accent

                Image {
                    anchors.fill: parent
                    anchors.margins: parent.border.width
                    source: `file://${parent.parent.modelData}`
                    sourceSize.width: 256
                    sourceSize.height: 160
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Wallpaper.set(parent.parent.modelData, null)
                }
            }
        }
    }
}
