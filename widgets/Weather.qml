import QtQuick
import qs.i18n
import qs.services

// Temperature and sky (hidden until a place is set in Settings ›
// General). Compact: temperature; normal: + icon; extended: + condition.
// Detail in the hover card.
TextWidget {
    id: root

    readonly property bool shown: Weather.ready
    readonly property var now: Weather.now

    fullText: !now ? "" : size === "extended" ? `${Weather.temp(now.temp)} · ${I18n.tr(Weather.condition(now.code))}` : Weather.temp(now.temp)
    compactText: now ? Weather.temp(now.temp) : ""
    color: Weather.stale ? theme.color.soft : theme.color.ink

    icon: now ? Weather.icon(now.code, now.isDay) : ""
    iconText: !now ? "" : size === "extended" && !vertical ? `${Weather.temp(now.temp)} · ${I18n.tr(Weather.condition(now.code))}` : Weather.temp(now.temp)
}
