import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Sound (status widgets mockup): volume, outputs (radio lines),
// per-application volumes, input (level, live meter, devices).
Column {
    id: root

    property var block
    property ShellScreen screen
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    // "Bluetooth", "HDMI", "USB" from the node's name.
    function kindOf(node: PwNode): string {
        const n = (node?.name ?? "").toLowerCase();
        return n.includes("bluez") ? "Bluetooth" : n.includes("hdmi") ? "HDMI" : n.includes("usb") ? "USB" : "";
    }
    function iconOf(node: PwNode): string {
        const n = `${node?.name ?? ""} ${Audio.nodeName(node)}`.toLowerCase();
        return n.includes("head") || n.includes("casque") || n.includes("bluez") ? "headphones" : n.includes("hdmi") ? "monitor" : "speaker";
    }

    // The other devices fold under a line (the card stays short).
    property bool moreOutputs: false
    property bool moreInputs: false
    Connections {
        target: root.QsWindow.window
        function onPhaseChanged(): void {
            if (root.QsWindow.window?.phase === "") {
                root.moreOutputs = false;
                root.moreInputs = false;
            }
        }
    }

    spacing: 4

    CardParts.Header {
        title: I18n.tr("settings.page.sound")
        status: Audio.muted ? I18n.tr("common.muted") : `${Audio.sinkName} · ${I18n.percent(Audio.volume)}`
        switchShown: false
    }

    CardParts.Level {
        icon: Audio.muted ? "volume_off" : "volume_up"
        value: Audio.volume
        to: Audio.maxVolume
        muted: Audio.muted
        onMoved: v => Audio.setVolume(v)
        onIconTapped: Audio.toggleMute()
    }

    CardParts.Sub {
        text: I18n.tr("soundset.output")
    }

    Repeater {
        model: root.moreOutputs ? Audio.sinks : Audio.sinks.filter(n => n === Audio.sink)

        CardParts.Line {
            required property PwNode modelData

            icon: root.iconOf(modelData)
            title: Audio.nodeName(modelData)
            sub: root.kindOf(modelData)
            active: modelData === Audio.sink
            control: "radio"
            checked: modelData === Audio.sink
            onPressed: Audio.setDefaultSink(modelData)
        }
    }

    CardParts.More {
        visible: Audio.sinks.length > 1
        open: root.moreOutputs
        text: I18n.tr(root.moreOutputs ? "card.lessDevices" : "card.moreOutputs", { n: Audio.sinks.length - 1 })
        onToggled: root.moreOutputs = !root.moreOutputs
    }

    CardParts.Sub {
        visible: Audio.appStreams.length > 0
        text: I18n.tr("card.apps")
    }

    Repeater {
        model: Audio.appStreams

        CardParts.Level {
            required property PwNode modelData

            icon: "music_note"
            name: Audio.streamName(modelData)
            value: modelData.audio?.volume ?? 0
            muted: modelData.audio?.muted ?? false
            onMoved: v => {
                if (modelData.audio)
                    modelData.audio.volume = v;
            }
            onIconTapped: {
                if (modelData.audio)
                    modelData.audio.muted = !modelData.audio.muted;
            }
        }
    }

    CardParts.Sub {
        text: I18n.tr("soundset.input")
    }

    CardParts.Level {
        icon: Audio.sourceMuted ? "mic_off" : "mic"
        value: Audio.sourceVolume
        muted: Audio.sourceMuted
        onMoved: v => Audio.setSourceVolume(v)
        onIconTapped: Audio.toggleSourceMute()
    }

    // Live input level, under the slider.
    Item {
        width: parent.width
        height: 10

        Rectangle {
            x: 40
            width: parent.width - 40 - 54
            height: 4
            radius: 2
            anchors.verticalCenter: parent.verticalCenter
            color: root.theme.color.surface2

            Rectangle {
                readonly property real peak: mic.peak > 0 ? Math.max(0, Math.min(1, (20 * Math.log10(mic.peak) + 60) / 60)) : 0
                width: parent.width * peak
                height: parent.height
                radius: parent.radius
                color: root.theme.color.ok

                Behavior on width {
                    NumberAnimation {
                        duration: 80
                    }
                }
            }
        }
    }

    // Other inputs, when there is a choice (folded).
    CardParts.More {
        visible: Audio.sources.length > 1
        open: root.moreInputs
        text: I18n.tr(root.moreInputs ? "card.lessDevices" : "card.moreInputs", { n: Audio.sources.length - 1 })
        onToggled: root.moreInputs = !root.moreInputs
    }

    Repeater {
        model: root.moreInputs && Audio.sources.length > 1 ? Audio.sources : []

        CardParts.Line {
            required property PwNode modelData

            icon: "mic"
            title: Audio.nodeName(modelData)
            sub: root.kindOf(modelData)
            active: modelData === Audio.source
            control: "radio"
            checked: modelData === Audio.source
            onPressed: Audio.setDefaultSource(modelData)
        }
    }

    PwNodePeakMonitor {
        id: mic
        node: Audio.sourceMuted ? null : Audio.source
        enabled: !Audio.sourceMuted
    }

    Item {
        width: 1
        height: 4
    }

    CardParts.Footer {
        page: "sound"
        pageName: I18n.tr("settings.page.sound")
        hints: I18n.tr("card.hintsVolume").replace("5", Math.round(Audio.step * 100))
    }
}
