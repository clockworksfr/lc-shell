pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// MPRIS players and the "active" one the shell controls.
//
// The active player is the one that most recently started playing.
// cycle() pins another player by hand, until some player starts playing.
Singleton {
    id: root

    readonly property list<MprisPlayer> list: Mpris.players.values

    property MprisPlayer pinned
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

            function onIsPlayingChanged(): void {
                if (modelData.isPlaying) {
                    root.lastStarted = modelData;
                    root.pinned = null;
                }
            }
        }
    }
}
