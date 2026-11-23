pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// VPNs: NetworkManager's VPN and WireGuard connections (OpenVPN profiles,
// Proton VPN while it's connected…) and Tailscale when installed. One is
// "the" VPN of the quick settings and the network widget (`network.vpn`,
// a connection name or "tailscale"; default: the first NetworkManager
// one). Follows NetworkManager live (nmcli monitor), Tailscale every 15 s.
Singleton {
    id: root

    // [{ name, kind: "nm" | "tailscale", active }]
    property var connections: []
    property bool tailscale: false
    property bool tailscaleUp: false
    property string lastError: ""

    readonly property string chosen: Config.get("network.vpn") ?? ""
    readonly property var current: connections.find(c => c.name === chosen) ?? connections.find(c => c.kind === "nm") ?? connections[0] ?? null
    readonly property bool available: !!current
    readonly property bool active: !!current?.active
    // Any NetworkManager VPN up (shown on the network widget too).
    readonly property var activeNames: connections.filter(c => c.active && c.kind === "nm").map(c => c.name)

    function choose(name: string): void {
        Config.set("network.vpn", name);
    }

    function setActive(connection: var, on: bool): void {
        if (!connection)
            return;
        lastError = "";
        action.command = connection.kind === "tailscale" ? ["tailscale", on ? "up" : "down"] : ["nmcli", "connection", on ? "up" : "down", "id", connection.name];
        action.running = true;
        // Optimistic, the next read corrects.
        connections = connections.map(c => c.name === connection.name ? Object.assign({}, c, { active: on }) : c);
    }

    function toggle(): void {
        setActive(current, !active);
    }

    function refresh(): void {
        if (!list.running)
            list.running = true;
        if (tailscale && !tsStatus.running)
            tsStatus.running = true;
    }

    function rebuild(nm: var): void {
        const out = nm.slice();
        if (tailscale)
            out.push({ name: "Tailscale", kind: "tailscale", active: tailscaleUp });
        connections = out;
    }

    property var nmConnections: []

    Process {
        id: list
        command: ["nmcli", "-t", "-f", "NAME,TYPE,ACTIVE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    // NAME may hold escaped colons ("\:").
                    const f = line.replace(/\\:/g, "\u0001").split(":").map(s => s.replace(/\u0001/g, ":"));
                    if (f.length >= 3 && (f[1] === "vpn" || f[1] === "wireguard"))
                        out.push({ name: f[0], kind: "nm", active: f[2] === "yes" });
                }
                root.nmConnections = out;
                root.rebuild(out);
            }
        }
    }

    Process {
        id: tsStatus
        command: ["tailscale", "status", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.tailscaleUp = JSON.parse(text).BackendState === "Running";
                } catch (e) {
                    root.tailscaleUp = false;
                }
                root.rebuild(root.nmConnections);
            }
        }
    }

    Process {
        id: action
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.lastError = text.trim()
        }
        onExited: readBack.restart()
    }

    Timer {
        id: readBack
        interval: 600
        onTriggered: root.refresh()
    }

    // NetworkManager events: re-read (debounced).
    Process {
        running: true
        // Dies with the shell (no orphan after a restart).
        command: ["setpriv", "--pdeathsig", "TERM", "nmcli", "monitor"]
        stdout: SplitParser {
            onRead: debounce.restart()
        }
    }

    Timer {
        id: debounce
        interval: 400
        onTriggered: root.refresh()
    }

    Timer {
        running: root.tailscale
        interval: 15000
        repeat: true
        onTriggered: tsStatus.running = true
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v tailscale"]
        onExited: code => {
            root.tailscale = code === 0;
            root.refresh();
        }
    }
}
