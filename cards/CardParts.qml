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
                // Façade: condensed capitals (design "Survol").
                font.capitalization: header.theme.style.module === "facade" ? Font.AllUppercase : Font.MixedCase
                font.letterSpacing: header.theme.style.module === "facade" ? 1 : 0
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
                    // Modulaire: Barlow Condensed caps (Michroma is for eyebrows).
                    font.family: header.theme.style.module === "modulaire" ? header.theme.font.family : header.theme.font.mono
                    font.pixelSize: header.theme.style.module === "modulaire" ? 13 : 11
                    font.letterSpacing: header.theme.style.module === "modulaire" ? 1 : 0
                    font.capitalization: header.theme.style.module === "matrix" || header.theme.style.module === "modulaire" ? Font.AllUppercase : Font.MixedCase
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

        // Radio lines: a click anywhere picks (a tint under the pointer).
        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: -6
            anchors.rightMargin: -6
            radius: 8
            visible: line.control === "radio" && lineArea.containsMouse
            color: line.theme.color.surface2
        }

        MouseArea {
            id: lineArea
            anchors.fill: parent
            enabled: line.control === "radio"
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: line.pressed()
        }

        Rectangle {
            id: bubble
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            // Modulaire: a 34 px square bubble (design review).
            width: line.look === "modulaire" || line.look === "facade" ? 34 : 30
            height: width
            radius: line.look === "modulaire" || line.look === "facade" ? 3 : 15
            color: line.active ? (line.look === "matrix" ? line.theme.color.ink : line.theme.color.accent) : line.look === "modulaire" ? (line.theme.variant === "light" ? "#24000000" : "#1AFFFFFF") : line.theme.color.surface2
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
        border.width: current || look === "modulaire" || look === "facade" ? 0 : 1
        border.color: look === "matrix" ? theme.color.ink : theme.color.line
        // Modulaire: a key (dark, or orange when current), both variants;
        // Façade: a metal key (light keys in the light variant), the
        // current one ringed in the VFD color.
        gradient: look === "facade" ? (theme.variant === "light" ? lightKey : greyKey) : look !== "modulaire" ? null : current ? orangeKey : greyKey

        Gradient {
            id: lightKey
            GradientStop {
                position: 0
                color: "#F2F3EF"
            }
            GradientStop {
                position: 1
                color: "#C9CAC6"
            }
        }
        Rectangle {
            visible: button.look === "facade" && button.current
            anchors.fill: parent
            anchors.margins: 2
            radius: 3
            color: "transparent"
            border.width: 2
            border.color: button.theme.color.vfd ?? button.theme.color.accent
        }

        Gradient {
            id: greyKey
            GradientStop {
                position: 0
                color: area.pressed ? "#4A4F52" : "#5E6366"
            }
            GradientStop {
                position: 1
                color: "#34383B"
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
        // Its light top edge and the black edge under it.
        Rectangle {
            visible: button.look === "modulaire" || button.look === "facade"
            x: 2
            y: 1
            width: parent.width - 4
            height: 1
            color: button.look === "facade" && button.theme.variant === "light" ? "white" : "#30FFFFFF"
        }
        Rectangle {
            visible: button.look === "modulaire" || button.look === "facade"
            x: 1
            y: parent.height
            width: parent.width - 2
            height: 2
            color: button.look === "facade" && button.theme.variant === "light" ? "#7D8083" : "black"
        }

        ThemedText {
            id: label
            anchors.centerIn: parent
            text: button.text
            font.pixelSize: 12
            font.weight: Font.DemiBold
            font.family: button.look === "matrix" ? button.theme.font.mono : button.theme.font.family
            font.letterSpacing: button.look === "modulaire" ? 1 : 0
            font.capitalization: button.look === "classic" || button.look === "constellation" ? Font.MixedCase : Font.AllUppercase
            color: button.look === "modulaire" ? (button.current ? "white" : "#E5E8E1") : button.look === "facade" ? (button.theme.variant === "light" ? "#1E2022" : "#E5E8E1") : button.current ? (button.look === "matrix" ? button.theme.color.bg : button.theme.color.onAccent) : button.theme.color.ink
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

        // Modulaire: LED segments (green, yellow when low).
        Row {
            visible: gauge.theme.style.module === "modulaire"
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Repeater {
                model: gauge.theme.style.module === "modulaire" ? 6 : 0

                Rectangle {
                    required property int index
                    width: 8
                    height: 10
                    color: (index + 0.5) / 6 <= gauge.level ? (gauge.low ? "#E5C230" : "#46C46A") : "#3A2C22"
                }
            }
        }

        Rectangle {
            visible: gauge.theme.style.module !== "modulaire"
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

    // A fold line: "Other outputs (5)" with a chevron.
    component More: Item {
        id: more

        readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
        property string text
        property bool open: false

        signal toggled

        width: parent?.width ?? 0
        implicitHeight: 30

        Rectangle {
            anchors.fill: parent
            radius: 6
            color: moreArea.containsMouse ? more.theme.color.surface2 : "transparent"
        }

        Icon {
            id: chevron
            x: 6
            anchors.verticalCenter: parent.verticalCenter
            name: more.open ? "expand_less" : "expand_more"
            size: 18
            color: more.theme.color.soft
        }

        ThemedText {
            anchors.left: chevron.right
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: more.text
            color: more.theme.color.soft
            font.pixelSize: 12
        }

        MouseArea {
            id: moreArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: more.toggled()
        }
    }

    // A small section title (mono capitals).
    component Sub: ThemedText {
        readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
        readonly property bool silk: theme.style.module === "modulaire"
        readonly property bool facade: theme.style.module === "facade"
        topPadding: 6
        // Façade: condensed 700 11 px (design "Survol").
        font.family: facade ? theme.font.family : theme.font.mono
        font.weight: facade ? Font.Bold : Font.Normal
        // Modulaire: a Michroma eyebrow, silk at 62 %.
        font.pixelSize: silk ? 9 : facade ? 11 : 10
        font.letterSpacing: silk ? 1.3 : facade ? 2 : 0.8
        font.capitalization: Font.AllUppercase
        color: silk ? Qt.alpha(theme.color.ink, 0.62) : theme.color.soft
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
            // Modulaire: Barlow Condensed caps (Michroma is for eyebrows).
            font.family: footer.theme.style.module === "modulaire" ? footer.theme.font.family : footer.theme.font.mono
            font.pixelSize: footer.theme.style.module === "modulaire" ? 12 : 10
            font.letterSpacing: footer.theme.style.module === "modulaire" ? 1 : 0.5
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
