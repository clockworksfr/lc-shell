import QtQuick
import Quickshell
import qs.components
import qs.i18n

// Options: format (Qt date format, default "HH:mm").
ThemedText {
    id: root

    property ShellScreen screen
    property var options: ({})

    readonly property string format: options.format ?? "HH:mm"

    // Month and day names follow the shell language (I18n.locale).
    text: I18n.locale.toString(clock.date, format)

    SystemClock {
        id: clock
        precision: root.format.includes("s") ? SystemClock.Seconds : SystemClock.Minutes
    }
}
