import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Sound: output and input devices, the wheel and keys step.
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    spacing: theme.space.s

    Section {
        title: I18n.tr("soundset.devices")

        Field {
            label: I18n.tr("soundset.output")
            DevicePicker {
                width: 300
                icon: "speaker"
                devices: Audio.sinks
                current: Audio.sink
                trailing: Audio.muted ? I18n.tr("common.muted") : I18n.percent(Audio.volume)
                onPicked: node => Audio.setDefaultSink(node)
            }
        }

        Field {
            label: I18n.tr("soundset.input")
            DevicePicker {
                width: 300
                icon: Audio.sourceMuted ? "mic_off" : "mic"
                devices: Audio.sources
                current: Audio.source
                trailing: Audio.sourceMuted ? I18n.tr("common.muted") : I18n.percent(Audio.sourceVolume)
                onPicked: node => Audio.setDefaultSource(node)
            }
        }
    }

    Section {
        title: I18n.tr("soundset.control")

        Field {
            label: I18n.tr("soundset.step")
            hint: I18n.tr("soundset.stepHint")
            Choice {
                model: [{ value: 0.02, label: "2 %" }, { value: 0.05, label: "5 %" }, { value: 0.1, label: "10 %" }]
                value: Audio.step
                onPicked: value => Config.set("audio.step", value)
            }
        }
    }
}
