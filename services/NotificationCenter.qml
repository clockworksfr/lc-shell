pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Notification server (org.freedesktop.Notifications), popups, history,
// do-not-disturb.
//
// Only one process can own the D-Bus name: while another shell runs its
// own server, this one fails to register (warning in the log).
//
// A record (what the UI shows) is a plain object:
//   uid, appName, appIcon, summary, body, image, urgency, time (ms),
//   notification (live object for actions, null once closed)
// History is kept in the state dir (without live objects) across restarts.
//
// Popups never go over a fullscreen window: they go to a "modules" screen
// or wait in `pending` until a screen is free (Screens.popupTarget).
Singleton {
    id: root

    readonly property int historyLimit: 100
    readonly property int defaultTimeout: 6000

    // Newest first.
    property var history: []
    // Records currently shown as popups, newest first.
    property var popups: []
    // Waiting for a screen without a fullscreen window.
    property var pending: []
    property string popupScreen

    property bool dnd: false
    // Records arrived since the panel was last opened.
    property int unread: 0

    // Live objects by uid (QObjects can't be persisted).
    property var live: ({})

    readonly property int count: history.length

    function record(notification: Notification): var {
        const image = notification.image ?? "";
        return {
            uid: `${Date.now()}-${notification.id}`,
            appName: notification.appName || notification.desktopEntry || "",
            appIcon: notification.appIcon ?? "",
            summary: plain(notification.summary),
            body: plain(notification.body),
            image: image,
            urgency: notification.urgency,
            time: Date.now()
        };
    }

    // Bodies may carry markup even when not advertised: show plain text
    // (no remote images or links loaded behind the user's back).
    function plain(text: string): string {
        return (text ?? "").replace(/<br\s*\/?>/gi, "\n").replace(/<[^>]*>/g, "").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"").replace(/&#39;/g, "'").replace(/&amp;/g, "&").trim();
    }

    function notificationFor(uid: string): Notification {
        return live[uid] ?? null;
    }

    function add(notification: Notification): void {
        notification.tracked = true;
        const entry = record(notification);
        const nextLive = Object.assign({}, live);
        nextLive[entry.uid] = notification;
        live = nextLive;

        notification.closed.connect(reason => root.onClosed(entry.uid, reason));

        if (!notification.transient)
            setHistory([entry, ...history].slice(0, historyLimit));
        unread += 1;

        const critical = notification.urgency === NotificationUrgency.Critical;
        if (dnd && !critical)
            return;
        showPopup(entry, notification);
    }

    function showPopup(entry: var, notification: Notification): void {
        const target = Screens.popupTarget("");
        if (!target) {
            pending = [...pending, entry];
            return;
        }
        popupScreen = target;
        const critical = entry.urgency === NotificationUrgency.Critical;
        const timeout = notification?.expireTimeout > 0 ? notification.expireTimeout : defaultTimeout;
        // Critical popups stay until dismissed (expiresAt 0).
        const popup = Object.assign({}, entry, { expiresAt: critical ? 0 : Date.now() + timeout });
        popups = [popup, ...popups.filter(p => p.uid !== entry.uid)];
    }

    // Hovered popups don't expire; they get a short grace period after.
    property string heldUid

    function hold(uid: string, held: bool): void {
        if (held) {
            heldUid = uid;
        } else if (heldUid === uid) {
            heldUid = "";
            popups = popups.map(p => p.uid === uid && p.expiresAt > 0 ? Object.assign({}, p, { expiresAt: Math.max(p.expiresAt, Date.now() + 2000) }) : p);
        }
    }

    function hidePopup(uid: string): void {
        popups = popups.filter(p => p.uid !== uid);
    }

    function onClosed(uid: string, reason: int): void {
        const nextLive = Object.assign({}, live);
        delete nextLive[uid];
        live = nextLive;
        // The app withdrew it: it's no longer relevant anywhere.
        if (reason === NotificationCloseReason.CloseRequested) {
            hidePopup(uid);
            pending = pending.filter(p => p.uid !== uid);
            setHistory(history.filter(h => h.uid !== uid));
        }
    }

    // Default action (click on the notification body).
    function activate(uid: string): void {
        const notification = notificationFor(uid);
        const action = notification?.actions.find(a => a.identifier === "default");
        if (action)
            action.invoke();
        hidePopup(uid);
    }

    function invoke(uid: string, identifier: string): void {
        notificationFor(uid)?.actions.find(a => a.identifier === identifier)?.invoke();
        hidePopup(uid);
    }

    function dismiss(uid: string): void {
        notificationFor(uid)?.dismiss();
        hidePopup(uid);
        pending = pending.filter(p => p.uid !== uid);
        setHistory(history.filter(h => h.uid !== uid));
    }

    function clearAll(): void {
        for (const uid in live)
            live[uid]?.dismiss();
        popups = [];
        pending = [];
        setHistory([]);
        unread = 0;
    }

    function markRead(): void {
        unread = 0;
    }

    function setDnd(value: bool): void {
        dnd = value;
        saveState();
        // Leaving DND doesn't replay what arrived meanwhile: it's in history.
    }

    function setHistory(next: var): void {
        history = next;
        saveState();
    }

    function saveState(): void {
        stateFile.setText(JSON.stringify({
            dnd: dnd,
            // image://qsimage/ URLs only live with their notification.
            history: history.map(h => Object.assign({}, h, { image: h.image.startsWith("image://") ? "" : h.image }))
        }));
    }

    NotificationServer {
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notification => root.add(notification)
    }

    Timer {
        interval: 250
        repeat: true
        running: root.popups.some(p => p.expiresAt > 0)
        onTriggered: {
            const now = Date.now();
            const kept = root.popups.filter(p => p.expiresAt === 0 || p.uid === root.heldUid || p.expiresAt > now);
            if (kept.length !== root.popups.length)
                root.popups = kept;
        }
    }

    // Flush popups that waited for a screen without fullscreen.
    Timer {
        interval: 1500
        repeat: true
        running: root.pending.length > 0
        onTriggered: {
            if (!Screens.popupTarget(""))
                return;
            const waiting = root.pending;
            root.pending = [];
            for (const entry of waiting.slice().reverse())
                root.showPopup(entry, root.notificationFor(entry.uid));
        }
    }

    FileView {
        id: stateFile
        path: Quickshell.statePath("notifications.json")
        printErrors: false
        onLoaded: {
            try {
                const saved = JSON.parse(text());
                root.dnd = saved.dnd ?? false;
                root.history = saved.history ?? [];
            } catch (e) {
                root.history = [];
            }
        }
    }
}
