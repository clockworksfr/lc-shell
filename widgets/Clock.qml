import QtQuick
import Quickshell
import qs.components
import qs.i18n

// Options: format (Qt date format, default "HH:mm"); on a vertical bar
// the time is stacked (hours over minutes), `verticalFormat` to change it.
TextWidget {
    id: root

    // Themes whose bar clock is a figure (Matrix: Doto, the time alone).
    // Extended there: the date in the theme's mono capitals before it.
    readonly property bool figure: theme.style.barClock === "display" && !vertical
    // The date part of the chosen format (shown before the figure).
    readonly property string userFormat: size === "extended" ? `${I18n.tr("format.dateLong")}  HH:mm` : (options.format ?? I18n.tr("format.clockNormal"))
    readonly property string datePart: userFormat.replace(/\s*HH:mm(:ss)?\s*/, " ").trim()
    readonly property string format: vertical ? (options.verticalFormat ?? "HH\nmm")
        : figure ? (userFormat.includes(":ss") ? "HH:mm:ss" : "HH:mm")
        : size === "compact" ? "HH:mm"
        : size === "extended" ? `${I18n.tr("format.dateLong")}  HH:mm`
        : (options.format ?? I18n.tr("format.clockNormal"))

    // Month and day names follow the shell language (I18n.locale).
    // Matrix: one rich text, the date part smaller and soft, the time big,
    // both in the display font (dots), one width, one baseline.
    fullText: figure && datePart
        ? `<span style="font-size:${Math.round(figureSize * 0.6)}px; color:${theme.color.soft}">${I18n.locale.toString(clock.date, datePart)}</span>&nbsp;&nbsp;${I18n.locale.toString(clock.date, format)}`
        : I18n.locale.toString(clock.date, format)
    textFormat: figure && datePart ? Text.RichText : Text.PlainText
    // ~2/3 of the bar's thickness (27 px in a 40 px bar, the mockup).
    readonly property int figureSize: Math.round(Math.max(18, theme.bar.height * 0.68))

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
