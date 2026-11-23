import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.lock
import qs.services
import qs.theme

// Modes: caffeine and do-not-disturb (a switch each, durations under the
// active one), presentation (both at once).
Column {
    id: root

    property var block
    property ShellScreen screen
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    readonly property int activeCount: (Idle.caffeine ? 1 : 0) + (NotificationCenter.dnd ? 1 : 0)

    function untilText(until: real): string {
        return I18n.tr("modes.until", { time: I18n.locale.toString(new Date(until), "HH:mm") });
    }

    // Next 08:00 (ms since epoch).
    function nextMorning(): real {
        const d = new Date();
        d.setHours(8, 0, 0, 0);
        if (d.getTime() <= Date.now())
            d.setDate(d.getDate() + 1);
        return d.getTime();
    }

    spacing: 4

    CardParts.Header {
        title: I18n.tr("widget.modes")
        status: root.activeCount === 0 ? I18n.tr("modes.none") : I18n.tr("modes.active", { n: root.activeCount })
        switchShown: false
    }

    Item {
        width: 1
        height: 4
    }

    CardParts.Line {
        icon: "coffee"
        title: I18n.tr("toggles.caffeine")
        sub: !Idle.caffeine ? I18n.tr("modes.caffeineOff") : Idle.caffeineUntil > 0 ? root.untilText(Idle.caffeineUntil) : I18n.tr("modes.untilOff")
        active: Idle.caffeine
        control: "switch"
        checked: Idle.caffeine
        onToggled: Idle.setCaffeine(!Idle.caffeine, 0)
    }

    CardParts.Chips {
        visible: Idle.caffeine
        choices: [
            { id: "30", text: I18n.tr("modes.min", { n: 30 }) },
            { id: "60", text: I18n.tr("modes.hours", { n: 1 }) },
            { id: "120", text: I18n.tr("modes.hours", { n: 2 }) },
            { id: "0", text: I18n.tr("modes.always") }
        ]
        current: Idle.caffeineUntil > 0 ? String(Idle.caffeineMinutes) : "0"
        onPicked: id => Idle.setCaffeine(true, Number(id))
    }

    CardParts.Line {
        icon: "do_not_disturb_on"
        title: I18n.tr("ctx.dnd")
        sub: !NotificationCenter.dnd ? I18n.tr("modes.dndOff") : NotificationCenter.dndUntil > 0 ? root.untilText(NotificationCenter.dndUntil) : I18n.tr("modes.untilOff")
        active: NotificationCenter.dnd
        control: "switch"
        checked: NotificationCenter.dnd
        onToggled: NotificationCenter.setDnd(!NotificationCenter.dnd)
    }

    CardParts.Chips {
        visible: NotificationCenter.dnd
        choices: [
            { id: "60", text: I18n.tr("modes.hours", { n: 1 }) },
            { id: "morning", text: I18n.tr("modes.untilMorning") },
            { id: "0", text: I18n.tr("modes.always") }
        ]
        current: NotificationCenter.dndUntil === 0 ? "0" : new Date(NotificationCenter.dndUntil).getHours() === 8 && new Date(NotificationCenter.dndUntil).getMinutes() === 0 ? "morning" : "60"
        onPicked: id => NotificationCenter.setDndUntil(true, id === "0" ? 0 : id === "morning" ? root.nextMorning() : Date.now() + 3600000)
    }

    // Presentation: both at once.
    CardParts.Line {
        icon: "slideshow"
        title: I18n.tr("modes.presentation")
        sub: I18n.tr("modes.presentationSub")
        active: Idle.caffeine && NotificationCenter.dnd
        control: "switch"
        checked: active
        onToggled: {
            const on = !checked;
            Idle.setCaffeine(on, 0);
            NotificationCenter.setDnd(on);
        }
    }

    Item {
        width: 1
        height: 6
    }

    CardParts.Footer {
        page: "modes"
        pageName: I18n.tr("settings.modes")
    }
}
