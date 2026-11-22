import QtQuick
import Quickshell
import qs.components
import qs.i18n

// Options: format (Qt date format, default "HH:mm"); on a vertical bar
// the time is stacked (hours over minutes), `verticalFormat` to change it.
TextBlock {
    id: root

    readonly property string format: vertical ? (options.verticalFormat ?? "HH\nmm")
        : size === "compact" ? "HH:mm"
        : size === "extended" ? `${I18n.tr("format.dateLong")}  HH:mm`
        : (options.format ?? "HH:mm")

    // Month and day names follow the shell language (I18n.locale).
    fullText: I18n.locale.toString(clock.date, format)
    font.pixelSize: theme.font.sizeM
    font.weight: vertical ? Font.DemiBold : Font.Normal
    font.features: ({ "tnum": 1 })

    SystemClock {
        id: clock
        precision: root.format.includes("s") ? SystemClock.Seconds : SystemClock.Minutes
    }
}
