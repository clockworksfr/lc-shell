import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Lights (Philips Hue): the paired bridge, or pairing a new one —
// discovery (discovery.meethue.com) or an address typed by hand, then the
// bridge's link button pressed within 30 s. Credentials stay in
// $XDG_CONFIG_HOME/lc/hue.json, never shown here.
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    // The address to pair with: picked from the list or typed.
    property string address: HueBridge.discovered[0] ?? ""

    spacing: theme.space.s

    Section {
        title: I18n.tr("hue.settings.bridge")

        Field {
            label: I18n.tr("hue.settings.status")
            hint: !HueBridge.available ? I18n.tr("hue.settings.statusHint")
                : HueBridge.lastError === "unauthorized" ? I18n.tr("hue.settings.unauthorized")
                : HueBridge.lastError ? I18n.tr("hue.noBridge")
                : HueBridge.loaded ? I18n.tr("hue.settings.summary", { rooms: HueBridge.rooms.length, lights: Object.keys(HueBridge.lights).length })
                : I18n.tr("hue.loading")
            ThemedText {
                text: HueBridge.available ? I18n.tr("hue.settings.paired", { ip: HueBridge.bridgeIp }) : I18n.tr("hue.settings.notPaired")
                color: HueBridge.available && !HueBridge.lastError ? root.theme.color.ink : root.theme.color.soft
            }
        }

        Field {
            visible: HueBridge.available
            label: I18n.tr("hue.settings.forget")
            hint: I18n.tr("hue.settings.forgetHint")
            Button {
                icon: "link_off"
                text: I18n.tr("hue.settings.forget")
                onClicked: HueBridge.forget()
            }
        }
    }

    // Pairing: until a bridge answers (and again when it no longer knows
    // this computer).
    Section {
        visible: !HueBridge.available || HueBridge.lastError === "unauthorized"
        title: I18n.tr("hue.settings.pairTitle")

        Field {
            label: I18n.tr("hue.settings.discover")
            hint: HueBridge.discovering ? I18n.tr("hue.settings.searching")
                : HueBridge.discoverError === "none" ? I18n.tr("hue.settings.noneFound")
                : HueBridge.discoverError === "failed" ? I18n.tr("hue.settings.discoverFailed")
                : I18n.tr("hue.settings.discoverHint")
            Button {
                icon: "search"
                text: I18n.tr("hue.settings.discover")
                onClicked: HueBridge.discover()
            }
        }

        // Bridges found: pick one.
        Column {
            visible: HueBridge.discovered.length > 0
            width: parent.width
            spacing: 2

            Repeater {
                model: HueBridge.discovered

                ListRow {
                    required property string modelData
                    width: parent.width
                    title: modelData
                    selected: modelData === root.address
                    onClicked: root.address = modelData
                }
            }
        }

        Field {
            label: I18n.tr("hue.settings.address")
            hint: I18n.tr("hue.settings.addressHint")
            TextField {
                width: 200
                text: root.address
                placeholder: "192.168.1.2"
                onEdited: text => root.address = text.trim()
                onCommitted: text => root.address = text.trim()
            }
        }

        Field {
            label: I18n.tr("hue.settings.pair")
            hint: HueBridge.pairing ? I18n.tr("hue.settings.pressButton", { s: HueBridge.pairRemaining })
                : HueBridge.pairError ? I18n.tr(`hue.settings.pairError.${HueBridge.pairError}`)
                : I18n.tr("hue.settings.pairHint")
            Button {
                primary: !HueBridge.pairing
                icon: HueBridge.pairing ? "close" : "link"
                text: HueBridge.pairing ? I18n.tr("hue.settings.cancel") : I18n.tr("hue.settings.pair")
                enabled: HueBridge.pairing || /^[A-Za-z0-9.:\[\]-]+$/.test(root.address)
                onClicked: HueBridge.pairing ? HueBridge.cancelPairing() : HueBridge.pair(root.address)
            }
        }
    }
}
