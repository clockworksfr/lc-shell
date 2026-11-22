pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.i18n

// Calculator through qalc: "=" prefix (anything qalc understands: units,
// currencies, "10 EUR to USD"...), or automatically in the default mode
// when the input looks like arithmetic. Enter copies the result.
Singleton {
    id: root

    readonly property bool looksLikeMath: /\d/.test(Launcher.term) && /[+\-*\/^%]/.test(Launcher.term) && /^[\d\s.,()+\-*\/^%]+$/.test(Launcher.term)
    readonly property bool active: Launcher.term.length > 0 && (Launcher.modeId === "calc" || (Launcher.modeId === "all" && looksLikeMath))

    property string result
    property string computedTerm
    property bool dirty: false

    readonly property var results: active && result && computedTerm === Launcher.term ? [{
            key: "calc",
            title: result,
            subtitle: `${computedTerm} · ${I18n.tr("launcher.calc.copy")}`,
            icon: "accessories-calculator",
            score: 1000,
            activate: () => Quickshell.execDetached(["wl-copy", "--", root.result])
        }] : []

    Connections {
        target: Launcher

        function onTermChanged(): void {
            if (root.active)
                debounce.restart();
        }
    }

    Timer {
        id: debounce
        interval: 100
        onTriggered: root.compute()
    }

    function compute(): void {
        if (!active)
            return;
        if (qalc.running) {
            dirty = true;
            return;
        }
        qalc.pendingTerm = Launcher.term;
        qalc.command = ["qalc", "-t", "--", Launcher.term];
        qalc.running = true;
    }

    Process {
        id: qalc

        property string pendingTerm

        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim();
                // qalc echoes unknown input back: not a result.
                root.result = value && value !== qalc.pendingTerm ? value : "";
                root.computedTerm = qalc.pendingTerm;
            }
        }

        onExited: {
            if (root.dirty) {
                root.dirty = false;
                root.compute();
            }
        }
    }
}
