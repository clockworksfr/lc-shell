import QtQuick
import Quickshell
import qs.components
import qs.i18n

// Options: format (Qt date format, default "HH:mm"); on a vertical bar
// the time is stacked (hours over minutes), `verticalFormat` to change it.
TextWidget {
    id: root

    // Themes whose bar clock is a figure (Matrix: Doto, the time alone).
    readonly property bool figure: theme.style.barClock === "display" && !vertical && size !== "extended"
    readonly property string format: vertical ? (options.verticalFormat ?? "HH\nmm")
        : figure ? (options.format ?? "HH:mm")
        : size === "compact" ? "HH:mm"
        : size === "extended" ? `${I18n.tr("format.dateLong")}  HH:mm`
        : (options.format ?? I18n.tr("format.clockNormal"))

    // Month and day names follow the shell language (I18n.locale).
    fullText: I18n.locale.toString(clock.date, format)
    readonly property int figureSize: Math.round(Math.max(18, (crossSize || theme.bar.height) * 0.68))

    font.family: figure ? theme.font.display : theme.font.family
    font.pixelSize: figure ? figureSize : theme.font.sizeM
    font.weight: figure ? (theme.font.displayWeight ?? Font.Normal) : vertical ? Font.DemiBold : Font.Normal
    font.letterSpacing: figure ? figureSize * 0.02 : 0
    font.features: ({ "tnum": 1 })

    SystemClock {
        id: clock
        precision: root.format.includes("s") ? SystemClock.Seconds : SystemClock.Minutes
    }
}
