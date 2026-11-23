import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.lock
import qs.services
import qs.theme

// Modes: caffeine (idle actions held) and do-not-disturb, with their
// durations; do-not-disturb on a daily schedule.
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property var schedule: Config.get("notifications.dndSchedule") ?? {}

    spacing: theme.space.s

    Section {
        title: I18n.tr("toggles.caffeine")

        Field {
            label: I18n.tr("toggles.caffeine")
            hint: I18n.tr("modesset.caffeineHint")
            Switch {
                width: 60
                checked: Idle.caffeine
                onToggled: Idle.setCaffeine(!checked, 0)
            }
        }

        Field {
            label: I18n.tr("modesset.duration")
            Choice {
                model: [{ value: 30, label: I18n.tr("modes.min", { n: 30 }) }, { value: 60, label: I18n.tr("modes.hours", { n: 1 }) }, { value: 120, label: I18n.tr("modes.hours", { n: 2 }) }, { value: 0, label: I18n.tr("modes.always") }]
                value: Idle.caffeine && Idle.caffeineUntil > 0 ? Idle.caffeineMinutes : 0
                onPicked: value => Idle.setCaffeine(true, value)
            }
        }
    }

    Section {
        title: I18n.tr("ctx.dnd")

        Field {
            label: I18n.tr("ctx.dnd")
            hint: NotificationCenter.dnd && NotificationCenter.dndUntil > 0 ? I18n.tr("modes.until", { time: I18n.locale.toString(new Date(NotificationCenter.dndUntil), "HH:mm") }) : I18n.tr("settings.dndHint")
            Switch {
                width: 60
                checked: NotificationCenter.dnd
                onToggled: NotificationCenter.setDnd(!checked)
            }
        }

        Field {
            label: I18n.tr("modesset.schedule")
            hint: I18n.tr("modesset.scheduleHint")
            Switch {
                width: 60
                checked: root.schedule.enabled ?? false
                onToggled: Config.set("notifications.dndSchedule", Object.assign({ from: "22:00", to: "08:00" }, root.schedule, { enabled: !checked }))
            }
        }

        Field {
            visible: root.schedule.enabled ?? false
            label: I18n.tr("modesset.from")
            TextField {
                width: 100
                text: root.schedule.from ?? "22:00"
                placeholder: "22:00"
                onCommitted: text => /^\d{1,2}:\d{2}$/.test(text.trim()) && Config.set("notifications.dndSchedule", Object.assign({}, root.schedule, { from: text.trim() }))
            }
        }

        Field {
            visible: root.schedule.enabled ?? false
            label: I18n.tr("modesset.to")
            TextField {
                width: 100
                text: root.schedule.to ?? "08:00"
                placeholder: "08:00"
                onCommitted: text => /^\d{1,2}:\d{2}$/.test(text.trim()) && Config.set("notifications.dndSchedule", Object.assign({}, root.schedule, { to: text.trim() }))
            }
        }
    }
}
