import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.i18n
import qs.services
import qs.theme

// What a lock surface shows: the wallpaper (blurred, dimmed) and a panel
// with the clock, the date, the user (~/.face, name), the password field
// (Caps Lock warning, status), the pending after-lock action; battery and
// power buttons in the corners (`lock.battery`, `lock.power`). Shared by
// the real lock and the preview.
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property var config: Lock.config

    property ShellScreen screen
    property bool preview: false

    // Panel parts (settings).
    readonly property bool showAvatar: config.avatar ?? true
    readonly property bool showPower: config.power ?? true
    readonly property bool showBattery: (config.battery ?? true) && Power.hasBattery
    readonly property bool blur: config.blur ?? true
    // Short screens (Xeneon Edge, 720 px): a tighter panel.
    readonly property bool compact: height < 820

    // Power button waiting for a second click: "" | "suspend" | "reboot" | "powerOff"
    property string confirming

    Rectangle {
        anchors.fill: parent
        color: root.theme.color.bg
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: Wallpaper.pathFor(root.screen) ? `file://${Wallpaper.pathFor(root.screen)}` : ""
        sourceSize.width: root.blur ? width / 4 : width
        sourceSize.height: root.blur ? height / 4 : height
        fillMode: Image.PreserveAspectCrop
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        visible: wallpaper.status === Image.Ready
        blurEnabled: root.blur
        blur: 1
        blurMax: 48
        brightness: root.theme.variant === "dark" ? -0.3 : 0.05
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // --- The panel ---
    Rectangle {
        id: panel

        readonly property int pad: root.compact ? root.theme.space.l : root.theme.space.xl

        anchors.centerIn: parent
        width: Math.min(420, root.width - 48)
        height: column.implicitHeight + pad * 2
        radius: root.theme.radius.panel + 8
        color: Qt.alpha(root.theme.color.surface, 0.82)
        border.width: 1
        border.color: Qt.alpha(root.theme.color.ink, 0.12)

        // Appears with a small rise.
        opacity: 0
        transform: Translate {
            id: rise
            y: 16
        }
        Component.onCompleted: appear.start()

        ParallelAnimation {
            id: appear
            NumberAnimation {
                target: panel
                property: "opacity"
                to: 1
                duration: 260
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: rise
                property: "y"
                to: 0
                duration: 320
                easing.type: Easing.OutCubic
            }
        }

        // Wrong password: a short shake.
        SequentialAnimation {
            id: shake
            NumberAnimation { target: rise; property: "x"; to: -12; duration: 50 }
            NumberAnimation { target: rise; property: "x"; to: 10; duration: 70 }
            NumberAnimation { target: rise; property: "x"; to: -6; duration: 70 }
            NumberAnimation { target: rise; property: "x"; to: 0; duration: 60 }
        }

        Connections {
            target: Lock
            function onFailuresChanged(): void {
                if (Lock.failures > 0)
                    shake.restart();
            }
        }

        Glass {}

        Column {
            id: column

            x: panel.pad
            y: panel.pad
            width: panel.width - panel.pad * 2
            spacing: root.compact ? root.theme.space.s : root.theme.space.m

            HeroText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: I18n.locale.toString(clock.date, "HH:mm")
                pixelSize: root.compact ? 64 : 84
            }

            ThemedText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    const s = I18n.locale.toString(clock.date, I18n.tr("format.dateLong"));
                    return s.charAt(0).toUpperCase() + s.slice(1);
                }
                color: root.theme.color.soft
                font.pixelSize: root.theme.font.sizeL
            }

            Item {
                width: 1
                height: root.compact ? root.theme.space.xs : root.theme.space.m
            }

            // Avatar: ~/.face, else the initial.
            ClippingRectangle {
                id: avatar

                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.showAvatar
                width: root.compact ? 64 : 84
                height: width
                radius: width / 2
                color: root.theme.color.accent

                Text {
                    anchors.centerIn: parent
                    visible: face.status !== Image.Ready
                    text: (Lock.fullName || "?").charAt(0).toUpperCase()
                    color: root.theme.color.onAccent
                    font.family: root.theme.font.family
                    font.pixelSize: parent.width * 0.45
                    font.weight: Font.DemiBold
                }

                Image {
                    id: face
                    anchors.fill: parent
                    source: `file://${Quickshell.env("HOME")}/.face`
                    sourceSize.width: 256
                    sourceSize.height: 256
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }
            }

            ThemedText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Lock.fullName
                font.weight: Font.DemiBold
                font.pixelSize: root.theme.font.sizeL
            }

            Item {
                width: 1
                height: root.theme.space.xs
            }

            // Password.
            Rectangle {
                id: field

                width: parent.width
                height: 50
                radius: root.theme.radius.full
                color: root.theme.color.surface2
                border.width: password.activeFocus || Lock.status === "failed" ? 2 : 1
                border.color: Lock.status === "failed" || Lock.status === "error" ? root.theme.color.urgent : password.activeFocus ? root.theme.color.accent : root.theme.color.line

                Icon {
                    id: lockIcon
                    anchors.left: parent.left
                    anchors.leftMargin: root.theme.space.m
                    anchors.verticalCenter: parent.verticalCenter
                    name: "lock"
                    size: 20
                    color: root.theme.color.soft
                }

                TextInput {
                    id: password

                    anchors.left: lockIcon.right
                    anchors.right: submit.left
                    anchors.leftMargin: root.theme.space.s
                    anchors.rightMargin: root.theme.space.s
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: TextInput.AlignHCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    color: root.theme.color.ink
                    font.family: root.theme.font.family
                    font.pixelSize: root.theme.font.sizeL
                    font.letterSpacing: 2
                    clip: true
                    focus: true
                    enabled: !Lock.checking
                    onAccepted: root.send()
                    onTextChanged: if (text) Lock.cancelAfterLock()
                    Keys.onEscapePressed: text = ""
                    Keys.onPressed: event => {
                        Lock.cancelAfterLock();
                        capsCheck.restart();
                        event.accepted = false;
                    }
                    // Empty field: no caret over the hint (the hint stays).
                    cursorDelegate: Rectangle {
                        width: 2
                        color: root.theme.color.ink
                        visible: password.activeFocus && password.text.length > 0
                    }

                    ThemedText {
                        anchors.centerIn: parent
                        visible: !password.text
                        text: Lock.checking ? I18n.tr("lock.checking") : I18n.tr("lock.password")
                        color: root.theme.color.soft
                    }
                }

                // Send.
                Rectangle {
                    id: submit

                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 38
                    height: 38
                    radius: 19
                    color: password.text ? root.theme.color.accent : "transparent"

                    Icon {
                        anchors.centerIn: parent
                        name: Lock.checking ? "schedule" : "chevron_right"
                        size: 22
                        color: password.text ? root.theme.color.onAccent : root.theme.color.soft
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.send()
                    }
                }
            }

            // Status line: Caps Lock, wrong password, after-lock countdown.
            ThemedText {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                font.pixelSize: root.theme.font.sizeS
                text: {
                    if (Lock.status)
                        return I18n.tr(`lock.${Lock.status}`) + (Lock.capsLock ? `  ·  ${I18n.tr("lock.capsLock")}` : "");
                    if (Lock.capsLock)
                        return I18n.tr("lock.capsLock");
                    if (!root.preview && Lock.countdown > 0)
                        return I18n.tr(Lock.afterLock === "suspend" ? "lock.suspendIn" : "lock.screensOffIn", { n: Lock.countdown });
                    return root.preview ? I18n.tr("lock.preview") : " ";
                }
                color: Lock.status === "failed" || Lock.status === "error" ? root.theme.color.urgent : Lock.capsLock ? root.theme.color.warn : root.theme.color.soft
            }
        }
    }

    // --- Corners: battery, power buttons ---
    Row {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: root.theme.space.xl
        visible: root.showBattery
        spacing: root.theme.space.xs

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: Power.charging ? "battery_charging_full" : Power.low ? "battery_alert" : Power.level > 0.95 ? "battery_full" : `battery_${Math.min(6, Math.floor(Power.level * 7))}_bar`
            size: 22
            color: Power.low ? root.theme.color.urgent : root.theme.color.ink
        }

        ThemedText {
            anchors.verticalCenter: parent.verticalCenter
            text: I18n.percent(Power.level)
        }
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.theme.space.xl
        visible: root.showPower
        spacing: root.theme.space.s

        Repeater {
            model: [
                { id: "suspend", icon: "bedtime" },
                { id: "reboot", icon: "restart_alt" },
                { id: "powerOff", icon: "power_settings_new" }
            ]

            Rectangle {
                id: power

                required property var modelData
                readonly property bool asking: root.confirming === modelData.id

                height: 44
                width: asking ? confirmText.implicitWidth + 44 + root.theme.space.m : 44
                radius: 22
                color: asking ? root.theme.color.urgent : powerArea.containsMouse ? Qt.alpha(root.theme.color.surface3, 0.9) : Qt.alpha(root.theme.color.surface, 0.7)
                border.width: 1
                border.color: Qt.alpha(root.theme.color.ink, 0.12)

                Behavior on width {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }

                Icon {
                    id: powerIcon
                    x: 11
                    anchors.verticalCenter: parent.verticalCenter
                    name: power.modelData.icon
                    size: 22
                    color: power.asking ? "#FFFFFF" : root.theme.color.ink
                }

                ThemedText {
                    id: confirmText
                    anchors.left: powerIcon.right
                    anchors.leftMargin: root.theme.space.xs
                    anchors.verticalCenter: parent.verticalCenter
                    visible: power.asking
                    text: I18n.tr(`lock.confirm.${power.modelData.id}`)
                    color: "#FFFFFF"
                }

                MouseArea {
                    id: powerArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!power.asking) {
                            root.confirming = power.modelData.id;
                            unconfirm.restart();
                            return;
                        }
                        root.confirming = "";
                        if (root.preview)
                            return;
                        if (power.modelData.id === "suspend")
                            Lock.suspend();
                        else if (power.modelData.id === "reboot")
                            Lock.reboot();
                        else
                            Lock.powerOff();
                    }
                }
            }
        }
    }

    Timer {
        id: unconfirm
        interval: 4000
        onTriggered: root.confirming = ""
    }

    Timer {
        id: capsCheck
        interval: 120
        onTriggered: Lock.checkCaps()
    }

    function send(): void {
        Lock.submit(password.text, root.preview);
        password.text = "";
    }

    // Keep the field focused whatever is clicked; a pointer that moves
    // (not just the surface showing up under it) means someone is here.
    MouseArea {
        anchors.fill: parent
        z: -1
        hoverEnabled: true
        property point first: Qt.point(-1, -1)
        onClicked: password.forceActiveFocus()
        onPositionChanged: mouse => {
            if (first.x < 0)
                first = Qt.point(mouse.x, mouse.y);
            else if (Math.abs(mouse.x - first.x) + Math.abs(mouse.y - first.y) > 24)
                Lock.cancelAfterLock();
        }
    }

    // The real lock gets the keyboard: focus the field. The preview waits
    // for a click (no stray keystrokes to PAM).
    Component.onCompleted: if (!preview) password.forceActiveFocus()
}
