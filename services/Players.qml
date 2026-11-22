pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// MPRIS players and the "active" one the shell controls.
//
// The active player is the one that most recently started playing.
// cycle() pins another player by hand, until some player starts playing;
// choose() pins one for good (the source no longer follows the players)
// until auto().
Singleton {
    id: root

    readonly property list<MprisPlayer> list: Mpris.players.values

    property MprisPlayer pinned
    // Pinned by hand from the source menu: kept when another player starts.
    property bool locked: false
    property MprisPlayer lastStarted

    readonly property MprisPlayer active: pinned ?? lastStarted ?? list.find(p => p.isPlaying) ?? list[0] ?? null

    function togglePlaying(): void {
        if (active?.canTogglePlaying)
            active.togglePlaying();
    }

    function next(): void {
        if (active?.canGoNext)
            active.next();
    }

    function previous(): void {
        if (active?.canGoPrevious)
            active.previous();
    }

    function choose(player: MprisPlayer): void {
        pinned = player;
        locked = true;
    }

    function auto(): void {
        locked = false;
        pinned = null;
    }

    // A pinned player that went away: back to automatic.
    onListChanged: if (pinned && !list.includes(pinned)) auto()

    function cycle(): void {
        if (list.length < 2)
            return;
        const index = list.indexOf(active);
        pinned = list[(index + 1) % list.length];
    }

    Instantiator {
        model: Mpris.players

        Connections {
            required property MprisPlayer modelData
            target: modelData

            // Only real transitions count: some players re-signal "playing"
            // without having stopped, and streams flap while buffering (a
            // resume within a few seconds of a stop isn't a new start).
            property bool wasPlaying: false
            property real stoppedAt: 0

            Component.onCompleted: wasPlaying = modelData.isPlaying

            function onIsPlayingChanged(): void {
                const playing = modelData.isPlaying;
                if (playing === wasPlaying)
                    return;
                wasPlaying = playing;
                if (!playing) {
                    stoppedAt = Date.now();
                    return;
                }
                if (Date.now() - stoppedAt < 3000)
                    return;
                root.lastStarted = modelData;
                if (!root.locked)
                    root.pinned = null;
            }
        }
    }
}
