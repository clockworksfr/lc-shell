import QtQuick
import Quickshell
import qs.components
import qs.theme

// Big time and date. Options: format (default "HH:mm").
Item {
    id: root

    property ShellScreen screen
    property var options: ({})
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    SystemClock {
        id: clock
        precision: (root.options.format ?? "").includes("s") ? SystemClock.Seconds : SystemClock.Minutes
    }

    Column {
        anchors.centerIn: parent
        spacing: root.theme.space.xs

        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.locale().toString(clock.date, root.options.format ?? "HH:mm")
            font.family: root.theme.font.display
            font.pixelSize: Math.min(root.height * 0.5, root.width * 0.3)
        }

        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            label: true
            text: Qt.locale().toString(clock.date, "dddd d MMMM")
            color: root.theme.color.fgMuted
        }
    }
}
