import QtQuick
import Quickshell
import qs.components

// Options: format (Qt date format, default "HH:mm").
ThemedText {
    id: root

    property ShellScreen screen
    property var options: ({})

    readonly property string format: options.format ?? "HH:mm"

    // Qt.locale() follows the system locale (month and day names).
    text: Qt.locale().toString(clock.date, format)

    SystemClock {
        id: clock
        precision: root.format.includes("s") ? SystemClock.Seconds : SystemClock.Minutes
    }
}
