import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.panels

// Reviews only (showcase "notificationSample"): a notification card with
// sample content, as popups and the panel show them, in the cell's theme.
ModuleBase {
    id: root

    framed: false

    NotificationCard {
        anchors.centerIn: parent
        width: Math.min(parent.width, 420)
        popup: true
        entry: ({
            uid: -1,
            appName: "Thunderbird",
            appIcon: "",
            image: "",
            summary: "Facture",
            body: "Votre facture fibre de novembre est disponible.",
            time: Date.now() - 60000,
            urgency: NotificationUrgency.Normal,
            expiresAt: Date.now() + 4000,
            duration: 8000
        })
        sampleActions: [
            { identifier: "open", text: "Ouvrir" },
            { identifier: "later", text: "Ignorer" }
        ]
    }
}
