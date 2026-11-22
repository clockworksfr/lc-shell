import QtQuick
import QtQuick.Effects
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// What a lock surface shows: dimmed, blurred wallpaper, clock, date, user,
// password field and status. Shared by the real lock and the preview.
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    property ShellScreen screen
    property bool preview: false

    Rectangle {
        anchors.fill: parent
        color: root.theme.color.bg
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: Wallpaper.pathFor(root.screen) ? `file://${Wallpaper.pathFor(root.screen)}` : ""
        sourceSize.width: width / 4
        sourceSize.height: height / 4
        fillMode: Image.PreserveAspectCrop
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        visible: wallpaper.status === Image.Ready
        blurEnabled: true
        blur: 1
        blurMax: 48
        brightness: root.theme.variant === "dark" ? -0.25 : 0.05
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        anchors.centerIn: parent
        spacing: root.theme.space.l
        width: 360

        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: I18n.locale.toString(clock.date, "HH:mm")
            font.family: root.theme.font.display
            font.pixelSize: 96
            font.weight: root.theme.font.displayWeight
            font.features: ({ "tnum": 1 })
        }

        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: I18n.locale.toString(clock.date, I18n.tr("format.dateLong"))
            color: root.theme.color.soft
            font.pixelSize: root.theme.font.sizeL
        }

        Item {
            width: 1
            height: root.theme.space.xl
        }

        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Quickshell.env("USER") ?? ""
            font.weight: Font.DemiBold
        }

        Rectangle {
            width: parent.width
            height: 48
            radius: root.theme.radius.full
            color: root.theme.color.surface
            border.width: 1
            border.color: Lock.status === "failed" ? root.theme.color.urgent : password.activeFocus ? root.theme.color.accent : root.theme.color.line

            TextInput {
                id: password

                anchors.fill: parent
                anchors.leftMargin: root.theme.space.l
                anchors.rightMargin: root.theme.space.l
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                echoMode: TextInput.Password
                passwordCharacter: "•"
                color: root.theme.color.ink
                font.family: root.theme.font.family
                font.pixelSize: root.theme.font.sizeL
                focus: true
                enabled: !Lock.checking
                onAccepted: {
                    Lock.submit(text, root.preview);
                    text = "";
                }
                Keys.onEscapePressed: text = ""

                ThemedText {
                    anchors.centerIn: parent
                    visible: !password.text && !password.activeFocus
                    text: Lock.checking ? I18n.tr("lock.checking") : I18n.tr("lock.password")
                    color: root.theme.color.soft
                }
            }
        }

        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !!Lock.status || root.preview
            text: Lock.status ? I18n.tr(`lock.${Lock.status}`) : I18n.tr("lock.preview")
            color: Lock.status === "failed" || Lock.status === "error" ? root.theme.color.urgent : root.theme.color.soft
            font.pixelSize: root.theme.font.sizeS
        }
    }

    // Keep the field focused whatever is clicked.
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: password.forceActiveFocus()
    }

    // The real lock gets the keyboard: focus the field. The preview waits
    // for a click (no stray keystrokes to PAM).
    Component.onCompleted: if (!preview) password.forceActiveFocus()
}
