import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Bar of normal screens: look, for all normal screens (mode defaults) or
// one screen (its profile overrides them). Widgets are arranged in the
// bar's edit mode ("Edit the bar").
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    // "" = all normal screens, else a screen name.
    property string target: ""
    readonly property var normalScreens: Quickshell.screens.filter(s => (Config.forScreen(s).mode ?? "normal") === "normal")
    readonly property ShellScreen targetScreen: target ? (Quickshell.screens.find(s => s.name === target) ?? null) : null
    readonly property var modeBar: Config.get("modes.normal.bar") ?? {}
    readonly property var themeBar: Themes.resolve(Themes.themeFor("normal"), false, "normal").bar
    readonly property var screenBar: {
        if (!targetScreen)
            return {};
        const bar = Config.profileFor(targetScreen).bar;
        return bar && typeof bar === "object" ? bar : {};
    }
    readonly property var look: targetScreen
        ? Object.assign({}, Themes.resolve(Config.forScreen(targetScreen).theme ?? Themes.themeFor("normal"), false, "normal").bar, modeBar, screenBar)
        : Object.assign({}, themeBar, modeBar)
    // Orientations the bar takes: length choices fit all of them.
    readonly property var orientations: {
        const positions = targetScreen ? [look.position ?? "top"] : [look.position ?? "top", ...(Config.get("screens") ?? []).map(s => s.bar?.position).filter(p => !!p)];
        return [...new Set(positions.map(p => p === "left" || p === "right" ? "vertical" : "horizontal"))];
    }

    function setLook(key: string, value: var): void {
        if (!targetScreen) {
            Config.set(`modes.normal.bar.${key}`, value);
            return;
        }
        const next = Object.assign({}, screenBar);
        next[key] = value;
        Config.setScreen(targetScreen, "bar", next);
    }

    spacing: theme.space.s

    Section {
        title: I18n.tr("settings.barTarget")

        Field {
            label: I18n.tr("settings.barTargetLabel")
            hint: root.target ? I18n.tr("settings.barTargetScreenHint") : I18n.tr("settings.barTargetAllHint")
            Choice {
                model: [{ value: "", label: I18n.tr("settings.barTargetAll") }, ...root.normalScreens.map(s => ({ value: s.name, label: s.name }))]
                value: root.target
                onPicked: value => root.target = value
            }
        }

        Field {
            label: I18n.tr("settings.barWidgets")
            hint: I18n.tr("settings.barWidgetsHint")
            Button {
                primary: true
                icon: "edit"
                text: I18n.tr("bar.menu.edit")
                onClicked: {
                    Settings.opened = false;
                    ShellState.editing = true;
                }
            }
        }
    }

    Section {
        title: I18n.tr("settings.barLook")

        Field {
            label: I18n.tr("settings.barStyle")
            Choice {
                model: [{ value: "islands", label: I18n.tr("settings.barStyle.islands") }, { value: "full", label: I18n.tr("settings.barStyle.full") }]
                value: root.look.style
                onPicked: value => root.setLook("style", value)
            }
        }

        Field {
            label: I18n.tr("settings.barFloating")
            Switch {
                width: 60
                checked: !!root.look.floating
                onToggled: root.setLook("floating", !checked)
            }
        }

        Field {
            label: I18n.tr("settings.barOpacity")
            hint: I18n.percent(root.look.opacity ?? 1)
            Slider {
                width: 220
                from: 0.4
                to: 1
                value: root.look.opacity ?? 1
                onMoved: value => root.setLook("opacity", Math.round(value * 100) / 100)
            }
        }

        Field {
            label: I18n.tr("settings.barLength")
            hint: I18n.tr("settings.barLengthHint")
            Choice {
                // Lengths that fit the bar's orientation.
                model: (root.orientations.length > 1 ? [0, 800, 1200, 1600, 2560, 3200] : root.orientations[0] === "vertical" ? [0, 800, 1200, 1600] : [0, 1600, 2560, 3200]).map(v => ({ value: v, label: v ? `${v} px` : I18n.tr("settings.fullWidth") }))
                value: root.look.length ?? 0
                onPicked: value => root.setLook("length", value)
            }
        }

        Field {
            label: I18n.tr("settings.barPosition")
            Choice {
                model: ["top", "bottom", "left", "right"].map(v => ({ value: v, label: I18n.tr(`settings.edge.${v}`) }))
                value: root.look.position ?? "top"
                onPicked: value => root.setLook("position", value)
            }
        }

        Field {
            label: I18n.tr("settings.frame")
            hint: I18n.tr("settings.frameHint")
            Switch {
                width: 60
                checked: typeof root.look.frame === "object" ? !!root.look.frame.enabled : !!root.look.frame
                onToggled: root.setLook("frame", !checked)
            }
        }
    }

}
