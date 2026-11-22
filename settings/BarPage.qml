import QtQuick
import Quickshell
import qs.widgets
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Bar of normal screens (mode defaults): look and blocks per zone.
// Per-screen overrides (Screens page, settings.json) still apply on top.
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property var bar: Config.get("modes.normal.bar") ?? {}
    readonly property var themeBar: Themes.resolve(Themes.themeFor("normal"), false, "normal").bar
    readonly property var look: Object.assign({}, themeBar, bar)
    readonly property var zones: ["left", "center", "right"]
    readonly property var blockTypes: Object.keys(Registry.widgets)

    function setLook(key: string, value: var): void {
        Config.set(`modes.normal.bar.${key}`, value);
    }

    function entries(zone: string): var {
        return (bar[zone] ?? []).slice();
    }

    function setEntries(zone: string, list: var): void {
        Config.set(`modes.normal.bar.${zone}`, list);
    }

    function move(zone: string, index: int, delta: int): void {
        const list = entries(zone);
        const target = index + delta;
        if (target < 0 || target >= list.length)
            return;
        [list[index], list[target]] = [list[target], list[index]];
        setEntries(zone, list);
    }

    function moveToZone(zone: string, index: int, other: string): void {
        const list = entries(zone);
        const [entry] = list.splice(index, 1);
        setEntries(zone, list);
        setEntries(other, [...entries(other), entry]);
    }

    function remove(zone: string, index: int): void {
        const list = entries(zone);
        list.splice(index, 1);
        setEntries(zone, list);
    }

    spacing: theme.space.s

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
                model: [0, 1600, 2560, 3200].map(v => ({ value: v, label: v ? `${v} px` : I18n.tr("settings.fullWidth") }))
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

    Repeater {
        model: root.zones

        Section {
            id: zoneSection

            required property string modelData
            readonly property string zone: modelData

            title: I18n.tr(`settings.zone.${zone}`)

            Repeater {
                model: root.entries(zoneSection.zone)

                Rectangle {
                    id: entryRow

                    required property var modelData
                    required property int index
                    readonly property string type: Registry.typeOf(modelData)

                    width: zoneSection.width
                    implicitHeight: Math.max(root.theme.hit, 36)
                    radius: root.theme.radius.control
                    color: root.theme.color.surface2

                    ThemedText {
                        anchors.left: parent.left
                        anchors.leftMargin: root.theme.space.m
                        anchors.verticalCenter: parent.verticalCenter
                        text: I18n.tr(`widget.${entryRow.type}`)
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: root.theme.space.s
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: root.theme.space.xs

                        Repeater {
                            model: [
                                { glyph: "↑", run: () => root.move(zoneSection.zone, entryRow.index, -1) },
                                { glyph: "↓", run: () => root.move(zoneSection.zone, entryRow.index, 1) },
                                ...root.zones.filter(z => z !== zoneSection.zone).map(z => ({ glyph: I18n.tr(`settings.zoneShort.${z}`), run: () => root.moveToZone(zoneSection.zone, entryRow.index, z) })),
                                { glyph: "✕", run: () => root.remove(zoneSection.zone, entryRow.index) }
                            ]

                            Rectangle {
                                required property var modelData
                                width: Math.max(32, glyph.implicitWidth + root.theme.space.m)
                                height: 28
                                radius: root.theme.radius.control
                                color: buttonArea.containsMouse ? root.theme.color.surface3 : "transparent"

                                ThemedText {
                                    id: glyph
                                    anchors.centerIn: parent
                                    text: parent.modelData.glyph
                                    font.pixelSize: root.theme.font.sizeS
                                }

                                MouseArea {
                                    id: buttonArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: parent.modelData.run()
                                }
                            }
                        }
                    }
                }
            }

            // Add a block to this zone.
            Flow {
                width: zoneSection.width
                spacing: root.theme.space.xs

                ThemedText {
                    text: I18n.tr("settings.addBlock")
                    color: root.theme.color.soft
                    height: 28
                }

                Repeater {
                    model: root.blockTypes

                    Rectangle {
                        required property string modelData
                        width: addLabel.implicitWidth + root.theme.space.m
                        height: 28
                        radius: root.theme.radius.full
                        color: addArea.containsMouse ? root.theme.color.surface3 : root.theme.color.surface2

                        ThemedText {
                            id: addLabel
                            anchors.centerIn: parent
                            text: `+ ${I18n.tr(`widget.${parent.modelData}`)}`
                            font.pixelSize: root.theme.font.sizeS
                        }

                        MouseArea {
                            id: addArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setEntries(zoneSection.zone, [...root.entries(zoneSection.zone), parent.modelData])
                        }
                    }
                }
            }
        }
    }
}
