import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.components
import qs.components.dashboard
import qs.i18n
import qs.services
import qs.theme

// One notification (popups and the notification panel), in the theme's
// language:
//   classic        panel card: app icon, app name (bold), text soft
//   constellation  glass card with an accent rim; spaced capitals label
//   facade         VFD window: "MSG ▸ APP" in dots, glowing phosphor text
//   modulaire      black plate, silk "TRIG · APP" and a Trig LED (red,
//                  blinking when critical), the text in an amber LCD,
//                  keys under it, the time left in LED segments
//   matrix         dark card: red dot + mono "APP · 21:46", Doto title,
//                  soft text, outlined pills (the first filled)
// Click: default action; × dismisses. `popup`: hovering pauses its expiry,
// and a strip on the bottom edge shrinks toward its middle until it goes
// (glowing where the theme glows; red when critical, which never expires).
Rectangle {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property string look: theme.style.module ?? "classic"
    readonly property bool onScreen: look === "facade" || look === "modulaire"
    readonly property bool mod: look === "modulaire"

    required property var entry
    property bool popup: false

    readonly property var notification: NotificationCenter.live[entry.uid] ?? null
    // Reviews (showcase): actions shown without a live notification.
    property var sampleActions: []
    readonly property var actions: notification ? (notification.actions ?? []).filter(a => a.identifier !== "default") : sampleActions
    readonly property bool critical: entry.urgency === NotificationUrgency.Critical
    readonly property string app: entry.appName || I18n.tr("notifications.app")
    readonly property string clock: entry.time ? I18n.locale.toString(new Date(entry.time), "HH:mm") : ""

    // Text colors and fonts per look (the screens have their own ink).
    readonly property color ink: onScreen ? screen.ink : theme.color.ink
    readonly property color soft: onScreen ? screen.soft : theme.color.soft
    readonly property string textFont: onScreen ? screen.textFont : look === "matrix" ? "Space Grotesk" : theme.font.family

    width: parent?.width ?? 0
    // Modulaire: title band (38), LCD padding (12), the time left under.
    implicitHeight: mod ? content.implicitHeight + 38 + 12 + 14 + (ledStrip.visible ? 17 : 0) : content.implicitHeight + pad * 2
    readonly property real pad: look === "matrix" ? 20 : theme.space.m
    radius: look === "matrix" ? 28 : look === "constellation" ? 24 : mod ? 3 : onScreen ? 6 : theme.radius.panel
    color: look === "matrix" ? theme.color.surface2 : look === "constellation" ? Qt.alpha(theme.color.surface2, 0.94) : theme.color.surface
    gradient: mod ? blackPlate : null
    // Modulaire critical: no red border (the LED and the LEDs carry it).
    border.width: critical && !mod ? 3 : mod ? 1 : onScreen ? 0 : 1
    border.color: critical && !mod ? theme.color.urgent : mod ? "#14FFFFFF" : look === "constellation" ? Qt.alpha(theme.color.accent, 0.16) : theme.color.line

    Gradient {
        id: blackPlate
        GradientStop {
            position: 0
            color: "#2A2B2D"
        }
        GradientStop {
            position: 1
            color: "#1F2022"
        }
    }

    // Modulaire: the silk title and the Trig LED.
    Text {
        visible: root.mod
        x: 40
        width: parent.width - 80
        y: 12
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: `TRIG · ${root.app}`.toUpperCase()
        font.family: root.theme.font.mono
        font.pixelSize: 12
        font.letterSpacing: 1.7
        color: "#E9E7E1"
    }
    Rectangle {
        visible: root.mod
        x: parent.width - 14 - width
        y: 11
        width: 12
        height: 12
        radius: 6
        color: root.critical ? "#FF3B30" : "#3B2A24"
        border.width: 1
        border.color: "#66000000"

        Rectangle {
            visible: root.critical
            anchors.centerIn: parent
            width: 28
            height: 28
            radius: 14
            color: Qt.alpha("#FF3B30", 0.25)
        }

        SequentialAnimation on opacity {
            running: root.mod && root.critical
            loops: Animation.Infinite
            PropertyAction {
                value: 1
            }
            PauseAnimation {
                duration: 550
            }
            PropertyAction {
                value: 0.25
            }
            PauseAnimation {
                duration: 550
            }
        }
    }

    // Constellation: the glass's light on top.
    Rectangle {
        visible: root.look === "constellation"
        anchors.fill: parent
        radius: parent.radius
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Qt.alpha("white", 0.06)
            }
            GradientStop {
                position: 0.4
                color: "transparent"
            }
        }
    }

    // Facade / modulaire: the card is their screen (VFD, amber LCD).
    // Modulaire: an amber LCD around the texts only (keys under it).
    Display {
        id: screen
        visible: root.onScreen
        x: root.mod ? 16 : 0
        y: root.mod ? 38 : 0
        width: root.mod ? parent.width - 32 : parent.width
        height: root.mod ? content.y + textColumn.y + bodyText.y + bodyText.height + 12 - y : parent.height
        tint: "amber"
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: root.popup
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: if (root.popup) NotificationCenter.hold(root.entry.uid, containsMouse)
        onClicked: NotificationCenter.activate(root.entry.uid)
    }

    Row {
        id: content

        // The screens' text glows (VFD phosphor, LCD).
        layer.enabled: root.onScreen
        layer.effect: MultiEffect {
            autoPaddingEnabled: true
            shadowEnabled: true
            shadowColor: root.look === "facade" ? (root.theme.color.glow ?? Qt.alpha(root.ink, 0.5)) : Qt.alpha(root.ink, 0.4)
            shadowBlur: 0.45
            blurMax: 10
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
        }

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: root.mod ? 30 : root.pad
        anchors.rightMargin: root.mod ? 30 : root.pad
        anchors.topMargin: root.mod ? 50 : root.pad
        spacing: root.theme.space.m

        // Classic / constellation: the app's icon (or the image).
        Item {
            id: iconBox

            readonly property string source: root.entry.image || (root.entry.appIcon ? Quickshell.iconPath(root.entry.appIcon, true) : "")

            visible: root.look === "classic" || root.look === "constellation"
            width: visible ? 36 : 0
            height: 36

            IconImage {
                visible: !!iconBox.source
                anchors.fill: parent
                source: iconBox.source
                asynchronous: true
            }

            Icon {
                visible: !iconBox.source
                anchors.centerIn: parent
                name: "notifications"
                size: 30
                color: root.theme.color.accent
            }
        }

        Column {
            id: textColumn
            width: parent.width - iconBox.width - (iconBox.visible ? parent.spacing : 0) - (close.visible ? close.width + parent.spacing : 0)
            spacing: root.look === "matrix" ? 8 : root.theme.space.xs

            // Header: who and when, in the theme's way (modulaire: the silk
            // title on the plate instead).
            Row {
                visible: !root.mod
                width: parent.width
                spacing: 8

                // Matrix: the red dot.
                Rectangle {
                    visible: root.look === "matrix"
                    anchors.verticalCenter: parent.verticalCenter
                    width: 8
                    height: 8
                    radius: 4
                    color: root.theme.color.signal ?? root.theme.color.urgent
                }

                ThemedText {
                    width: parent.width - (root.look === "matrix" ? 16 : 0)
                    elide: Text.ElideRight
                    text: root.look === "facade" ? `MSG ▸ ${root.app}`
                        : root.look === "modulaire" ? `TRIG ▸ ${root.app}`
                        : root.look === "classic" ? root.app
                        : [root.app, root.clock].filter(s => !!s).join(" · ")
                    font.family: root.onScreen ? root.textFont : root.look === "matrix" ? "Space Mono" : root.theme.font.family
                    font.capitalization: root.look === "classic" ? Font.MixedCase : Font.AllUppercase
                    font.letterSpacing: root.look === "constellation" ? 1.6 : root.look === "matrix" ? 0.5 : 0.4
                    font.pixelSize: root.onScreen ? 18 : root.look === "classic" ? root.theme.font.sizeM : 12
                    font.weight: root.look === "classic" || root.onScreen ? Font.DemiBold : Font.Medium
                    color: root.onScreen || root.look === "classic" ? root.ink : root.soft
                }
            }

            // The summary (often the sender): about the body's size, told
            // apart by its weight (Matrix: the dots font, a notch bigger, the
            // dots stay readable); the message is what matters.
            ThemedText {
                width: parent.width
                visible: !!root.entry.summary
                text: root.entry.summary
                font.family: root.look === "matrix" ? root.theme.font.display : root.textFont
                font.capitalization: root.onScreen ? Font.AllUppercase : Font.MixedCase
                font.pixelSize: root.look === "matrix" ? 18 : root.mod ? 20 : root.onScreen ? 15 : root.theme.font.sizeM + 1
                font.weight: root.look === "matrix" ? (root.theme.font.displayWeight ?? Font.Normal) : Font.DemiBold
                color: root.ink
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            // The text (screens: with the age, as on the panel's display).
            ThemedText {
                id: bodyText
                width: parent.width
                visible: !!root.entry.body || root.onScreen
                text: root.onScreen ? [root.entry.body, I18n.relativeTime(root.entry.time)].filter(s => !!s).join(" · ") : root.entry.body
                font.family: root.textFont
                font.capitalization: root.look === "modulaire" ? Font.AllUppercase : Font.MixedCase
                font.pixelSize: root.mod ? 15 : root.onScreen ? 14 : root.theme.font.sizeM + 1
                // Full ink: the message reads first.
                color: root.ink
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                maximumLineCount: root.popup ? 4 : 8
                elide: Text.ElideRight
            }

            // Classic: when, under.
            ThemedText {
                visible: root.look === "classic"
                text: I18n.relativeTime(root.entry.time)
                font.pixelSize: root.theme.font.sizeS
                color: root.soft
            }

            Flow {
                width: parent.width
                visible: root.actions.length > 0 || root.mod
                // Modulaire: keys 12 px under the LCD (out of its padding).
                topPadding: root.look === "matrix" ? 6 : root.mod ? 24 : 0
                x: root.mod ? -14 : 0
                spacing: root.look === "matrix" ? 10 : root.theme.space.s

                Repeater {
                    model: root.actions

                    Rectangle {
                        id: action

                        required property var modelData
                        required property int index
                        // Matrix: the first one filled with ink.
                        readonly property bool filled: root.look === "matrix" && index === 0

                        // Pills (a touch target of 56 px high on the modules
                        // screen: 72 made them discs).
                        height: root.mod ? 40 : root.theme.hit >= 48 ? 56 : Math.max(root.theme.hit, root.look === "matrix" ? 34 : 30)
                        width: root.mod ? Math.max(96, actionText.implicitWidth + 32) : Math.max(height * 1.8, actionText.implicitWidth + (root.look === "matrix" ? 36 : root.theme.space.m * 2) + 16)
                        radius: root.mod ? 8 : root.onScreen ? 3 : height / 2
                        gradient: !root.mod ? null : index === 0 ? orangeKey : blackKey

                        Gradient {
                            id: blackKey
                            GradientStop {
                                position: 0
                                color: "#3A3B3D"
                            }
                            GradientStop {
                                position: 1
                                color: "#202123"
                            }
                        }
                        Gradient {
                            id: orangeKey
                            GradientStop {
                                position: 0
                                color: "#F08A43"
                            }
                            GradientStop {
                                position: 1
                                color: "#C95B1B"
                            }
                        }
                        color: filled ? root.theme.color.ink
                            : root.look === "matrix" ? (actionArea.pressed ? Qt.alpha(root.theme.color.ink, 0.12) : "transparent")
                            : root.onScreen ? Qt.alpha(root.ink, actionArea.pressed ? 0.25 : 0.12)
                            : root.look === "constellation" ? Qt.alpha(root.theme.color.accent, actionArea.pressed ? 0.28 : 0.16)
                            : actionArea.pressed ? root.theme.color.surface3 : root.theme.color.surface2
                        border.width: root.look === "matrix" ? 1 : 0
                        border.color: root.theme.color.line

                        ThemedText {
                            id: actionText
                            anchors.centerIn: parent
                            text: action.modelData.text
                            font.family: root.look === "matrix" ? "Space Mono" : root.mod ? root.theme.font.family : root.textFont
                            font.capitalization: root.look === "classic" || root.look === "constellation" ? Font.MixedCase : Font.AllUppercase
                            font.letterSpacing: root.look === "matrix" ? 0.6 : root.mod ? 1.1 : 0
                            font.pixelSize: root.look === "matrix" ? 12 : root.mod ? 14 : root.theme.font.sizeM
                            font.weight: root.mod ? Font.DemiBold : Font.Normal
                            color: root.mod ? (action.index === 0 ? "white" : "#EFEDE6") : action.filled ? root.theme.color.bg : root.ink
                        }

                        MouseArea {
                            id: actionArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NotificationCenter.invoke(root.entry.uid, action.modelData.identifier)
                        }
                    }
                }

                // Modulaire: the close key, last.
                Rectangle {
                    visible: root.mod
                    width: 40
                    height: 40
                    radius: 8
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: "#3A3B3D"
                        }
                        GradientStop {
                            position: 1
                            color: "#202123"
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        font.pixelSize: 20
                        color: "#EFEDE6"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationCenter.dismiss(root.entry.uid)
                    }
                }
            }
        }

        // Close: dismiss (removes it from history too).
        Item {
            id: close

            visible: !root.mod
            width: Math.max(root.theme.hit, 24)
            height: width

            ThemedText {
                anchors.centerIn: parent
                text: "×"
                color: root.soft
                font.pixelSize: root.theme.font.sizeL
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: NotificationCenter.dismiss(root.entry.uid)
            }
        }
    }

    // Time left (popups that expire).
    property real now: Date.now()
    readonly property real remaining: root.entry.expiresAt > 0 && root.entry.duration > 0 ? Math.max(0, Math.min(1, (root.entry.expiresAt - now) / root.entry.duration)) : 0

    Timer {
        interval: 50
        repeat: true
        running: root.popup && root.entry.expiresAt > 0 && NotificationCenter.heldUid !== root.entry.uid
        onTriggered: root.now = Date.now()
    }

    // Modulaire: the time left in 24 LED segments (all red when critical).
    Row {
        id: ledStrip

        visible: root.mod && root.popup && (root.entry.expiresAt > 0 || root.critical)
        x: 16
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14
        spacing: 3

        Repeater {
            model: 24

            Rectangle {
                required property int index
                readonly property bool lit: root.critical || (index + 0.5) / 24 <= root.remaining
                width: (root.width - 32 - 23 * 3) / 24
                height: 5
                radius: 2
                color: root.critical ? "#FF3B30" : lit ? "#FFB35A" : "#3A2C22"
            }
        }
    }

    Rectangle {
        id: strip

        visible: !root.mod && root.popup && (root.entry.expiresAt > 0 || root.critical)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.max(root.look === "matrix" ? 6 : 2, root.border.width)
        // Matrix: a short centered strip (40 % at the start).
        readonly property real full: root.look === "matrix" ? parent.width * 0.4 : parent.width - root.radius * 2
        width: full * (root.critical ? 1 : root.remaining)
        height: 3
        radius: 1.5
        color: root.critical ? root.theme.color.urgent : root.look === "matrix" ? root.theme.color.ink : root.onScreen ? root.ink : root.theme.color.accent
        opacity: root.look === "matrix" ? 0.85 : 1

        layer.enabled: Qt.color(root.theme.color.glow ?? "#00000000").a > 0
        layer.effect: MultiEffect {
            autoPaddingEnabled: true
            shadowEnabled: true
            shadowColor: root.critical ? root.theme.color.urgent : (root.theme.color.glow ?? "transparent")
            shadowBlur: 0.81
            blurMax: 18
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
        }
    }
}
