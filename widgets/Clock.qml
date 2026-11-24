import QtQuick
import QtQuick.Effects
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Options: format (Qt date format, default "HH:mm"); on a vertical bar
// the time is stacked (hours over minutes), `verticalFormat` to change it.
TextWidget {
    id: root

    // Themes whose bar clock is a figure (Matrix: Doto, the time alone).
    // Extended there: the date in the theme's mono capitals before it.
    readonly property bool figure: theme.style.barClock === "display" && !vertical
    // The date part of the chosen format (shown before the figure).
    readonly property string userFormat: size === "extended" ? `${I18n.tr("format.dateLong")}  HH:mm` : (options.format ?? I18n.tr("format.clockNormal"))
    readonly property string datePart: userFormat.replace(/\s*HH:mm(:ss)?\s*/, " ").trim()
    readonly property string format: vertical ? (options.verticalFormat ?? "HH\nmm")
        : figure ? (userFormat.includes(":ss") ? "HH:mm:ss" : "HH:mm")
        : size === "compact" ? "HH:mm"
        : size === "extended" ? `${I18n.tr("format.dateLong")}  HH:mm`
        : (options.format ?? I18n.tr("format.clockNormal"))

    // Month and day names follow the shell language (I18n.locale).
    // Matrix with a date: two texts side by side in the dots font, the
    // date smaller and soft, the time big (rich text can't reach the
    // shell's own fonts). The widget's own text is empty, its padding the
    // pair's width.
    // Modulaire: the time in a Nixie window (design "Barre"): dark glass,
    // orange glowing digits, no colon.
    readonly property bool nixie: figure && theme.style.module === "modulaire"
    readonly property bool pair: figure && (!!datePart || nixie)
    fullText: pair ? "" : I18n.locale.toString(clock.date, format)
    leftPadding: pair ? pairRow.implicitWidth : 0

    Row {
        id: pairRow
        visible: root.pair
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.figureSize * 0.45

        ThemedText {
            visible: !!root.datePart
            // On the time's baseline (Matrix), centered by the Nixie window.
            y: root.nixie ? (timeBox.height - height) / 2 + timeBox.y : timeBox.y + timeText.y + timeText.baselineOffset - baselineOffset
            text: I18n.locale.toString(clock.date, root.datePart)
            font.family: root.theme.font.display
            font.pixelSize: Math.round(root.figureSize * 0.6)
            color: root.theme.color.soft
        }

        Item {
            id: timeBox
            implicitWidth: timeText.implicitWidth + (root.nixie ? 16 : 0)
            implicitHeight: timeText.implicitHeight + (root.nixie ? 6 : 0)
            width: implicitWidth
            height: implicitHeight

            // The Nixie window.
            Rectangle {
                visible: root.nixie
                anchors.fill: parent
                radius: 5
                color: "#120C09"
                border.width: 2
                border.color: "#000000"
            }

            ThemedText {
                id: timeText
                anchors.centerIn: parent
                text: root.nixie ? I18n.locale.toString(clock.date, root.format).replace(/:/g, "") : I18n.locale.toString(clock.date, root.format)
                font.family: root.theme.font.display
                font.weight: root.theme.font.displayWeight ?? Font.Normal
                font.pixelSize: root.nixie ? Math.round(root.figureSize * 0.82) : root.figureSize
                font.letterSpacing: root.nixie ? root.figureSize * 0.12 : root.figureSize * 0.02
                font.features: ({ "tnum": 1 })
                color: root.nixie ? "#FF8A2A" : root.theme.color.ink

                layer.enabled: root.nixie
                layer.effect: MultiEffect {
                    autoPaddingEnabled: true
                    shadowEnabled: true
                    shadowColor: "#FF6A00"
                    shadowBlur: 0.6
                    blurMax: 16
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 0
                }
            }
        }
    }
    // --- OSD in the clock (animations mockup) ---
    // Volume, mic or brightness changing on this screen: the clock widens
    // for a gauge (fast), which follows the value (80 ms, linear), then
    // retracts 1.2 s after the last change (base). No popup on this screen.
    readonly property string screenName: screen?.name ?? ""
    readonly property bool hostsOsd: !vertical && !!screenName
    onHostsOsdChanged: Osd.setInline(screenName, hostsOsd)
    onScreenNameChanged: Osd.setInline(screenName, hostsOsd)
    Component.onCompleted: Osd.setInline(screenName, hostsOsd)
    Component.onDestruction: Osd.setInline(screenName, false)

    readonly property bool osdHere: hostsOsd && Osd.shown && Osd.screenName === screenName
    readonly property real osdGauge: 120
    property real osdWidth: osdHere ? osdRow.implicitWidth + 14 : 0
    Behavior on osdWidth {
        NumberAnimation {
            duration: Motion.ms(root.theme, root.osdHere ? "fast" : "base", root.screenName)
            easing.type: Easing.OutCubic
        }
    }
    rightPadding: osdWidth

    Item {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: root.osdWidth
        height: parent.height
        clip: true
        visible: width > 0

        Row {
            id: osdRow
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: Osd.kind === "brightness" ? "light_mode" : Osd.kind === "mic" ? (Osd.muted ? "mic_off" : "mic") : Osd.muted ? "volume_off" : "volume_up"
                size: 16
                color: root.theme.color.soft
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: root.osdGauge
                height: 6
                radius: 3
                color: root.theme.color.line

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, Osd.value))
                    height: parent.height
                    radius: parent.radius
                    color: Osd.muted ? root.theme.color.soft : root.theme.color.accent

                    Behavior on width {
                        NumberAnimation {
                            duration: 80
                            easing.type: Easing.Linear
                        }
                    }
                }
            }
        }
    }

    // ~2/3 of the bar's thickness (27 px in a 40 px bar, the mockup).
    readonly property int figureSize: Math.round(Math.max(18, theme.bar.height * 0.68))

    font.family: figure ? theme.font.display : theme.font.family
    font.pixelSize: figure ? figureSize : theme.font.sizeM
    font.weight: figure ? (theme.font.displayWeight ?? Font.Normal) : vertical ? Font.DemiBold : Font.Normal
    font.letterSpacing: figure ? figureSize * 0.02 : 0
    font.features: ({ "tnum": 1 })

    // Click: the card (calendar) pinned, to browse the months; wheel: the
    // card's month.
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: ShellState.pinCard(root)
        onWheel: wheel => {
            ShellState.calendarOffset += wheel.angleDelta.y > 0 ? -1 : 1;
            if (!(ShellState.card.visible && ShellState.card.type === "clock"))
                ShellState.cardRequested("clock", root.screen?.name ?? "");
        }
    }

    function togglePanel(): void {
        ShellState.pinCard(root);
    }

    SystemClock {
        id: clock
        precision: root.format.includes("s") ? SystemClock.Seconds : SystemClock.Minutes
    }
}
