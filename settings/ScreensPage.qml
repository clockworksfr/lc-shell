import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// One card per connected screen: bar (default, own or none), theme,
// touch, bar position, frame.
// Changes go to the screen's profile (matched by model).
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    spacing: theme.space.l

    Repeater {
        model: Quickshell.screens

        Rectangle {
            id: card

            required property ShellScreen modelData
            readonly property var profile: Config.forScreen(modelData)
            readonly property var bar: Object.assign({}, Themes.resolve(profile.theme ?? Themes.themeFor("normal"), false, "normal").bar, profile.bar ?? {})
            // "default" (the default bar), "custom" (with this screen's
            // changes), "none".
            readonly property var ownBar: Config.profileFor(modelData).bar
            readonly property string barKind: ownBar === undefined ? "default" : ownBar === false || ownBar === null ? "none" : "custom"

            function setBar(key: string, value: var): void {
                const current = Config.profileFor(modelData).bar;
                const next = Object.assign({}, current && typeof current === "object" ? current : {});
                next[key] = value;
                Config.setScreen(modelData, "bar", next);
            }

            width: root.width
            implicitHeight: fields.implicitHeight + root.theme.space.l * 2
            radius: root.theme.radius.tile
            color: root.theme.color.surface
            border.width: root.theme.border.width
            border.color: root.theme.color.line

            Column {
                id: fields

                anchors.fill: parent
                anchors.margins: root.theme.space.l
                spacing: root.theme.space.s

                ThemedText {
                    text: `${card.modelData.name} · ${card.modelData.model || "?"} · ${card.modelData.width}×${card.modelData.height}`
                    font.weight: Font.DemiBold
                }

                Field {
                    label: I18n.tr("settings.screenBar")
                    hint: I18n.tr(`settings.bar.${card.barKind}Hint`)
                    Choice {
                        model: [{ value: "default", label: I18n.tr("settings.bar.default") }, { value: "custom", label: I18n.tr("settings.bar.custom") }, { value: "none", label: I18n.tr("settings.bar.none") }]
                        value: card.barKind
                        onPicked: value => Config.setScreen(card.modelData, "bar", value === "default" ? undefined : value === "none" ? false : (card.barKind === "custom" ? card.ownBar : {}))
                    }
                }

                Field {
                    label: I18n.tr("settings.screenTheme")
                    Choice {
                        model: [{ value: "", label: I18n.tr("settings.themeDefault") }, ...Object.keys(Themes.definitions).map(id => ({ value: id, label: I18n.tr(`theme.${id}`) }))]
                        value: card.profile.theme ?? ""
                        onPicked: value => Config.setScreen(card.modelData, "theme", value || undefined)
                    }
                }

                Field {
                    label: I18n.tr("settings.touch")
                    hint: I18n.tr("settings.touchHint")
                    Switch {
                        width: 60
                        checked: card.profile.touch
                        onToggled: Config.setScreen(card.modelData, "touch", !checked)
                    }
                }

                Field {
                    visible: card.barKind !== "none"
                    label: I18n.tr("settings.barPosition")
                    Choice {
                        model: ["top", "bottom", "left", "right"].map(v => ({ value: v, label: I18n.tr(`settings.edge.${v}`) }))
                        value: card.bar.position ?? "top"
                        onPicked: value => card.setBar("position", value)
                    }
                }

                Field {
                    visible: card.barKind !== "none"
                    label: I18n.tr("settings.frame")
                    hint: I18n.tr("settings.frameHint")
                    Switch {
                        width: 60
                        checked: typeof card.bar.frame === "object" ? !!card.bar.frame.enabled : !!card.bar.frame
                        onToggled: card.setBar("frame", !checked)
                    }
                }
            }
        }
    }
}
