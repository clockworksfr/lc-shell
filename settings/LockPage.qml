import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.lock
import qs.services
import qs.theme

// Lock screen and idle: the shortcut and what follows a lock, what the
// panel shows, idle delays and what holds them, PAM.
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property var lock: Lock.config
    readonly property var idle: Idle.config

    spacing: theme.space.s

    // 930 → "15 min 30 s", 0 → "Never".
    function duration(seconds: int): string {
        if (seconds <= 0)
            return I18n.tr("settings.lockNever");
        if (seconds < 60)
            return I18n.tr("settings.lockSeconds", { n: seconds });
        if (seconds % 3600 === 0)
            return I18n.tr("settings.lockHours", { n: seconds / 3600 });
        const m = Math.floor(seconds / 60), s = seconds % 60;
        return s ? `${I18n.tr("settings.minutes", { n: m })} ${I18n.tr("settings.lockSeconds", { n: s })}` : I18n.tr("settings.minutes", { n: m });
    }

    // "super+escape" → "SUPER + escape": modifiers in capitals, the key as
    // typed (Hyprland reads key names in any case).
    function keys(text: string): string {
        const parts = text.split("+").map(p => p.trim()).filter(p => p);
        if (!parts.length)
            return "";
        const key = parts.pop();
        return [...parts.map(p => p.toUpperCase()), key].join(" + ");
    }

    // A choice of delays, with the current one even if set by hand.
    function delays(values: var, current: int): var {
        const all = values.includes(current) ? values : [...values, current].sort((a, b) => (a || 1e9) - (b || 1e9));
        return all.map(v => ({ value: v, label: duration(v) }));
    }

    Section {
        title: I18n.tr("settings.lockSection")

        Field {
            label: I18n.tr("settings.lockShortcut")
            hint: I18n.tr("settings.lockShortcutHint")
            TextField {
                width: 240
                text: Lock.shortcut
                placeholder: "SUPER + Escape"
                onCommitted: text => Config.set("lock.shortcut", root.keys(text))
            }
        }

        Field {
            label: I18n.tr("settings.lockAfter")
            hint: I18n.tr("settings.lockAfterHint")
            Choice {
                model: ["screensOff", "suspend", "none"].map(v => ({ value: v, label: I18n.tr(`settings.lockAfter.${v}`) }))
                value: Lock.afterLock
                onPicked: value => Config.set("lock.afterLock", value)
            }
        }

        Field {
            label: I18n.tr("settings.lockAfterDelay")
            visible: Lock.afterLock !== "none"
            Choice {
                model: root.delays([3, 5, 10, 30], Lock.afterLockDelay)
                value: Lock.afterLockDelay
                onPicked: value => Config.set("lock.afterLockDelay", value)
            }
        }

        Field {
            label: I18n.tr("settings.lockBeforeSleep")
            hint: I18n.tr("settings.lockBeforeSleepHint")
            Switch {
                width: 60
                checked: Lock.beforeSleep
                onToggled: Config.set("lock.beforeSleep", !checked)
            }
        }

        Field {
            label: I18n.tr("settings.lockPreview")
            hint: I18n.tr("settings.lockPreviewHint")
            Row {
                spacing: root.theme.space.s

                Button {
                    icon: "monitor"
                    text: I18n.tr("settings.lockPreviewOpen")
                    onClicked: {
                        Lock.status = "";
                        Lock.previewing = true;
                    }
                }

                Button {
                    icon: "lock"
                    text: I18n.tr("settings.lockNow")
                    onClicked: Lock.lock()
                }
            }
        }
    }

    Section {
        title: I18n.tr("settings.lockPanel")

        Field {
            label: I18n.tr("settings.lockAvatar")
            hint: I18n.tr("settings.lockAvatarHint")
            Switch {
                width: 60
                checked: root.lock.avatar ?? true
                onToggled: Config.set("lock.avatar", !checked)
            }
        }

        Field {
            label: I18n.tr("settings.lockBlur")
            Switch {
                width: 60
                checked: root.lock.blur ?? true
                onToggled: Config.set("lock.blur", !checked)
            }
        }

        Field {
            label: I18n.tr("settings.lockBattery")
            hint: Power.hasBattery ? "" : I18n.tr("settings.lockBatteryHint")
            Switch {
                width: 60
                checked: root.lock.battery ?? true
                onToggled: Config.set("lock.battery", !checked)
            }
        }

        Field {
            label: I18n.tr("settings.lockPower")
            hint: I18n.tr("settings.lockPowerHint")
            Switch {
                width: 60
                checked: root.lock.power ?? true
                onToggled: Config.set("lock.power", !checked)
            }
        }
    }

    Section {
        title: I18n.tr("settings.idleSection")

        Field {
            label: I18n.tr("settings.idleEnabled")
            hint: Idle.enabled && Idle.inhibitedBy ? I18n.tr(`settings.idleHeld.${Idle.inhibitedBy}`) : I18n.tr("settings.idleEnabledHint")
            Switch {
                width: 60
                checked: Idle.enabled
                onToggled: Config.set("idle.enabled", !checked)
            }
        }

        Field {
            label: I18n.tr("settings.idleLock")
            Choice {
                model: root.delays([300, 600, 900, 1800, 0], Idle.lockAfter)
                value: Idle.lockAfter
                onPicked: value => Config.set("idle.lock", value)
            }
        }

        Field {
            label: I18n.tr("settings.idleScreenOff")
            Choice {
                model: root.delays([600, 930, 1800, 3600, 0], Idle.screenOffAfter)
                value: Idle.screenOffAfter
                onPicked: value => Config.set("idle.screenOff", value)
            }
        }

        Field {
            label: I18n.tr("settings.idleLockedScreenOff")
            hint: I18n.tr("settings.idleLockedScreenOffHint")
            Choice {
                model: root.delays([10, 30, 60, 300, 0], Idle.lockedScreenOffAfter)
                value: Idle.lockedScreenOffAfter
                onPicked: value => Config.set("idle.lockedScreenOff", value)
            }
        }

        Field {
            label: I18n.tr("settings.idleSuspend")
            Choice {
                model: root.delays([900, 1800, 3600, 0], Idle.suspendAfter)
                value: Idle.suspendAfter
                onPicked: value => Config.set("idle.suspend", value)
            }
        }

        Field {
            label: I18n.tr("settings.idleAudio")
            hint: I18n.tr("settings.idleAudioHint")
            Switch {
                width: 60
                checked: Idle.inhibitWhenAudio
                onToggled: Config.set("idle.inhibitWhenAudio", !checked)
            }
        }

        Field {
            label: I18n.tr("settings.idleCharging")
            hint: I18n.tr("settings.idleChargingHint")
            Switch {
                width: 60
                checked: Idle.inhibitWhenCharging
                onToggled: Config.set("idle.inhibitWhenCharging", !checked)
            }
        }
    }

    Section {
        title: I18n.tr("settings.lockAdvanced")

        Field {
            label: I18n.tr("settings.lockPam")
            hint: I18n.tr("settings.lockPamHint")
            TextField {
                width: 200
                text: root.lock.pamService ?? "hyprlock"
                onCommitted: text => {
                    if (text.trim())
                        Config.set("lock.pamService", text.trim());
                }
            }
        }
    }
}
