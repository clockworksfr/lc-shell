import QtQuick
import Quickshell
import qs.components
import qs.components.dashboard
import qs.i18n
import qs.services
import qs.settings
import qs.theme

// Building blocks of the status cards (design-status-widgets, width 380):
//   Header   title 16 px, state in soft, the master switch on the right
//   Line     44 px: round icon (30 px), name and sub-label, a control on
//            the right (the theme's switch, a small button or a text)
//   Chips    a row of choices (durations), one current
//   Gauge    a battery gauge (22 × 9, red under 20 %)
//   Footer   "Settings › Page" in the accent, opens that settings page
QtObject {
    component Header: Item {
        id: header

        readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
        property string title
        property string status
        property bool switchShown: true
        property bool checked: false
        property bool available: true

        signal toggled

        width: parent?.width ?? 0
        implicitHeight: Math.max(headerText.implicitHeight, sw.implicitHeight * 0.8)

        Column {
            id: headerText
            anchors.left: parent.left
            anchors.right: sw.visible ? sw.left : parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            ThemedText {
                width: parent.width
                text: header.title
                font.pixelSize: 16
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            ThemedText {
                visible: !!header.status
                width: parent.width
                text: header.status
                color: header.theme.color.soft
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }

        HueParts.Switch {
            id: sw
            visible: header.switchShown
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 56
            implicitHeight: 32
            on: header.checked
            enabled: header.available
            onToggled: header.toggled()
        }
    }

    component Line: Item {
        id: line

        readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
        readonly property string look: theme.style.module ?? "classic"
        property string icon
        property string title
        property string sub
        property bool active: false
        property bool dimmed: false
        // "switch" | "button" | "text" | ""
        property string control: ""
        property bool checked: false
        property string buttonText
        property string trailing
        property color subColor: theme.color.soft
        // A battery gauge left of the control (0–1, -1 = none).
        property real battery: -1

        signal toggled
        signal pressed

        width: parent?.width ?? 0
        implicitHeight: 44
        opacity: dimmed ? 0.55 : 1

        Rectangle {
            id: bubble
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 30
            height: 30
            radius: line.look === "facade" || line.look === "modulaire" ? 5 : 15
            color: line.active ? (line.look === "matrix" ? line.theme.color.ink : line.theme.color.accent) : line.theme.color.surface2
            border.width: line.look === "matrix" && !line.active ? 1 : 0
            border.color: line.theme.color.line

            Icon {
                anchors.centerIn: parent
                name: line.icon
                size: 18
                filled: line.active
                color: line.active ? (line.look === "matrix" ? line.theme.color.bg : line.theme.color.onAccent) : line.theme.color.soft
            }
        }

        Column {
            anchors.left: bubble.right
            anchors.leftMargin: 10
            anchors.right: right.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            ThemedText {
                width: parent.width
                text: line.title
                font.pixelSize: 14
                font.weight: line.active ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
            }

            ThemedText {
                visible: !!line.sub
                width: parent.width
                text: line.sub
                color: line.subColor
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }

        Row {
            id: right
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Gauge {
                visible: line.battery >= 0
                anchors.verticalCenter: parent.verticalCenter
                level: Math.max(0, line.battery)
            }

            ThemedText {
                visible: line.control === "text" && !!line.trailing
                anchors.verticalCenter: parent.verticalCenter
                text: line.trailing
                color: line.theme.color.soft
                font.pixelSize: 12
                font.features: ({ "tnum": 1 })
            }

            SmallButton {
                visible: line.control === "button"
                anchors.verticalCenter: parent.verticalCenter
                text: line.buttonText
                onTapped: line.pressed()
            }

            HueParts.Switch {
                visible: line.control === "switch"
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 56
                implicitHeight: 30
                on: line.checked
                onToggled: line.toggled()
            }
        }
    }

    component SmallButton: Rectangle {
        id: button

        readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
        readonly property string look: theme.style.module ?? "classic"
        property string text
        property bool current: false

        signal tapped

        implicitWidth: label.implicitWidth + 20
        implicitHeight: 26
        radius: look === "facade" || look === "modulaire" ? 4 : height / 2
        color: current ? (look === "matrix" ? theme.color.ink : theme.color.accent) : area.containsMouse ? theme.color.surface3 : "transparent"
        border.width: current ? 0 : 1
        border.color: look === "matrix" ? theme.color.ink : theme.color.line

        ThemedText {
            id: label
            anchors.centerIn: parent
            text: button.text
            font.pixelSize: 12
            font.weight: Font.DemiBold
            font.family: button.look === "matrix" || button.look === "modulaire" ? button.theme.font.mono : button.theme.font.family
            font.capitalization: button.look === "classic" || button.look === "constellation" ? Font.MixedCase : Font.AllUppercase
            color: button.current ? (button.look === "matrix" ? button.theme.color.bg : button.theme.color.onAccent) : button.theme.color.ink
        }

        MouseArea {
            id: area
            anchors.fill: parent
            anchors.margins: -3
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.tapped()
        }
    }

    // Choices under a line (durations): [{ id, text }], `current` an id.
    component Chips: Flow {
        id: chips

        property var choices: []
        property string current

        signal picked(string id)

        width: parent?.width ?? 0
        leftPadding: 40
        spacing: 6

        Repeater {
            model: chips.choices

            SmallButton {
                required property var modelData
                text: modelData.text
                current: modelData.id === chips.current
                onTapped: chips.picked(modelData.id)
            }
        }
    }

    component Gauge: Row {
        id: gauge

        readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
        property real level: 0
        readonly property bool low: level < 0.2

        spacing: 5

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: 9
            radius: 2
            color: "transparent"
            border.width: 1
            border.color: gauge.low ? gauge.theme.color.urgent : gauge.theme.color.soft

            Rectangle {
                x: 2
                y: 2
                width: Math.max(1, (parent.width - 4) * gauge.level)
                height: parent.height - 4
                radius: 1
                color: gauge.low ? gauge.theme.color.urgent : gauge.theme.color.ink
            }
        }

        ThemedText {
            anchors.verticalCenter: parent.verticalCenter
            text: I18n.percent(gauge.level)
            color: gauge.low ? gauge.theme.color.urgent : gauge.theme.color.soft
            font.pixelSize: 12
            font.features: ({ "tnum": 1 })
        }
    }

    component Footer: Item {
        id: footer

        readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
        // Settings page id (settings/Settings.qml pages).
        property string page
        property string pageName

        width: parent?.width ?? 0
        implicitHeight: 30

        Rectangle {
            width: parent.width
            height: 1
            color: footer.theme.color.line
        }

        ThemedText {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            text: `${I18n.tr("card.settings")} › ${footer.pageName}`
            color: footer.theme.color.accent
            font.pixelSize: 13
            font.weight: Font.DemiBold

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    ShellState.cardRequested("", "");
                    Settings.open(footer.page);
                }
            }
        }
    }
}
