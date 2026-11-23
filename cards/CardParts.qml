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

        // Title, then the state in a pill.
        Row {
            id: headerText
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            readonly property real room: (sw.visible ? sw.x - 8 : header.width)

            ThemedText {
                id: titleText
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, headerText.room - (pill.visible ? pill.width + 8 : 0))
                text: header.title
                font.pixelSize: 16
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Rectangle {
                id: pill
                visible: !!header.status
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(pillText.implicitWidth + 16, Math.max(40, headerText.room - titleText.implicitWidth - 8))
                height: 22
                radius: header.theme.style.module === "facade" || header.theme.style.module === "modulaire" ? 3 : 11
                color: "transparent"
                border.width: 1
                border.color: header.theme.color.line

                ThemedText {
                    id: pillText
                    anchors.centerIn: parent
                    width: Math.min(implicitWidth, parent.width - 14)
                    text: header.status
                    color: header.theme.color.soft
                    font.family: header.theme.font.mono
                    font.pixelSize: 11
                    font.capitalization: header.theme.style.module === "matrix" ? Font.AllUppercase : Font.MixedCase
                    elide: Text.ElideRight
                }
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
        // "switch" | "button" | "text" | "radio" (the whole line picks) | ""
        property string control: ""
        property bool checked: false
        property string buttonText
        property string trailing
        property color subColor: theme.color.soft
        // Battery (0–1, -1 = none): a ring around the icon, warn under 20 %.
        property real battery: -1

        signal toggled
        signal pressed

        width: parent?.width ?? 0
        implicitHeight: 44
        opacity: dimmed ? 0.55 : 1

        // Radio lines: a click anywhere picks.
        MouseArea {
            anchors.fill: parent
            enabled: line.control === "radio"
            cursorShape: Qt.PointingHandCursor
            onClicked: line.pressed()
        }

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

        Canvas {
            id: ring
            visible: line.battery >= 0
            anchors.centerIn: bubble
            width: bubble.width + 8
            height: width
            readonly property real level: Math.max(0, Math.min(1, line.battery))
            readonly property color track: line.theme.color.line
            readonly property color fill: level < 0.2 ? (line.theme.color.warn ?? line.theme.color.urgent) : line.theme.color.ok
            onLevelChanged: requestPaint()
            onFillChanged: requestPaint()
            onTrackChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const c = width / 2;
                const r = c - 1.5;
                ctx.lineWidth = 2.5;
                ctx.lineCap = "round";
                ctx.strokeStyle = track;
                ctx.beginPath();
                ctx.arc(c, c, r, 0, Math.PI * 2);
                ctx.stroke();
                if (level > 0) {
                    ctx.strokeStyle = fill;
                    ctx.beginPath();
                    ctx.arc(c, c, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * level);
                    ctx.stroke();
                }
            }
        }

        Column {
            anchors.left: bubble.right
            anchors.leftMargin: line.battery >= 0 ? 14 : 10
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

            Rectangle {
                visible: line.control === "radio"
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                height: 18
                radius: 9
                color: "transparent"
                border.width: 1.5
                border.color: line.checked ? (line.look === "matrix" ? line.theme.color.ink : line.theme.color.accent) : line.theme.color.line

                Rectangle {
                    visible: line.checked
                    anchors.centerIn: parent
                    width: 8
                    height: 8
                    radius: 4
                    color: line.look === "matrix" ? line.theme.color.ink : line.theme.color.accent
                }
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

    // A small section title (mono capitals).
    component Sub: ThemedText {
        readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
        topPadding: 6
        font.family: theme.font.mono
        font.pixelSize: 10
        font.letterSpacing: 0.8
        font.capitalization: Font.AllUppercase
        color: theme.color.soft
    }

    // A level: round icon (click: `iconTapped`), optional name, the theme's
    // slider, the value.
    component Level: Item {
        id: level

        readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
        property string icon
        property string name
        property real value: 0
        property real to: 1
        property bool muted: false
        property string valueText: muted ? I18n.tr("common.muted") : I18n.percent(value)

        signal moved(real value)
        signal iconTapped

        width: parent?.width ?? 0
        implicitHeight: 40

        Rectangle {
            id: levelIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 30
            height: 30
            radius: level.theme.style.module === "facade" || level.theme.style.module === "modulaire" ? 5 : 15
            color: level.theme.color.surface2

            Icon {
                anchors.centerIn: parent
                name: level.icon
                size: 18
                color: level.muted ? level.theme.color.soft : level.theme.color.ink
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: level.iconTapped()
            }
        }

        ThemedText {
            id: levelName
            visible: !!level.name
            anchors.left: levelIcon.right
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: visible ? Math.round(level.width * 0.28) : 0
            text: level.name
            font.pixelSize: 12
            elide: Text.ElideRight
        }

        Slider {
            anchors.left: levelName.visible ? levelName.right : levelIcon.right
            anchors.leftMargin: 10
            anchors.right: levelValue.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            value: level.value
            to: level.to
            dimmed: level.muted
            onMoved: v => level.moved(v)
        }

        ThemedText {
            id: levelValue
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            horizontalAlignment: Text.AlignRight
            text: level.valueText
            color: level.muted ? level.theme.color.soft : level.theme.color.ink
            font.pixelSize: 12
            font.features: ({ "tnum": 1 })
        }
    }

    component Footer: Item {
        id: footer

        readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
        // Settings page id (settings/Settings.qml pages), "" = no link.
        property string page
        property string pageName
        // What the mouse does, mono capitals on the left.
        property string hints

        width: parent?.width ?? 0
        implicitHeight: 30

        Rectangle {
            width: parent.width
            height: 1
            color: footer.theme.color.line
        }

        ThemedText {
            anchors.left: parent.left
            anchors.right: link.visible ? link.left : parent.right
            anchors.rightMargin: 10
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
            text: footer.hints
            color: footer.theme.color.soft
            font.family: footer.theme.font.mono
            font.pixelSize: 10
            font.letterSpacing: 0.5
            font.capitalization: Font.AllUppercase
            elide: Text.ElideRight
        }

        ThemedText {
            id: link
            visible: !!footer.page
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            text: `${I18n.tr("card.settings")} › ${footer.pageName}`
            color: footer.theme.color.accent
            font.pixelSize: 12
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
