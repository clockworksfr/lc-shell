pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Default output (sink) and input (source) through PipeWire.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    // Hardware devices (streams and sink monitors excluded).
    readonly property list<PwNode> sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property list<PwNode> sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property string sinkName: nodeName(sink)

    readonly property real sourceVolume: source?.audio?.volume ?? 0
    readonly property bool sourceMuted: source?.audio?.muted ?? false
    readonly property string sourceName: nodeName(source)

    // Same ceiling as the wpctl key binds (-l 1.5).
    readonly property real maxVolume: 1.5
    readonly property real step: 0.05

    // Emitted when the volume/mute of the current device actually changes,
    // whoever changed it (shell, wpctl, pavucontrol...). Not emitted while
    // a device is being (re)bound, so startup and device switches stay quiet.
    signal sinkTouched
    signal sourceTouched

    function nodeName(node: PwNode): string {
        return node?.description || node?.nickname || node?.name || "";
    }

    function setDefaultSink(node: PwNode): void {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setDefaultSource(node: PwNode): void {
        Pipewire.preferredDefaultAudioSource = node;
    }

    function setVolume(value: real): void {
        if (!sink?.audio)
            return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(maxVolume, value));
    }

    function increment(): void {
        setVolume(volume + step);
    }

    function decrement(): void {
        setVolume(volume - step);
    }

    function setSourceVolume(value: real): void {
        if (!source?.audio)
            return;
        source.audio.muted = false;
        source.audio.volume = Math.max(0, Math.min(1, value));
    }

    function toggleMute(): void {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    function toggleSourceMute(): void {
        if (source?.audio)
            source.audio.muted = !source.audio.muted;
    }

    // Binds the nodes so their audio properties are populated.
    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    onSinkChanged: settle.restart()
    onSourceChanged: settle.restart()

    Timer {
        id: settle
        interval: 800
        running: true
    }

    Connections {
        target: root.sink?.audio ?? null

        function onVolumesChanged(): void {
            if (!settle.running)
                root.sinkTouched();
        }
        function onMutedChanged(): void {
            if (!settle.running)
                root.sinkTouched();
        }
    }

    Connections {
        target: root.source?.audio ?? null

        function onVolumesChanged(): void {
            if (!settle.running)
                root.sourceTouched();
        }
        function onMutedChanged(): void {
            if (!settle.running)
                root.sourceTouched();
        }
    }
}
