import QtQuick
import Quickshell
import qs.i18n
import qs.services
import qs.theme

// Rain within the hour, step by step (the local site's umbrellas, 5–10 min;
// Open-Meteo's quarter hours): one bar per step, as long as the step and as
// tall as the rain (dry: a thin line), the times under it.
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    property color wetColor: theme.color.signal ?? theme.color.accent
    property color dryColor: Qt.alpha(theme.color.ink, 0.25)
    property color labelColor: theme.color.soft
    property string fontFamily: theme.font.family
    property real labelSize: 11

    // How far ahead (ms): the hour, or two on big weather modules.
    property real horizon: 3600 * 1000
    readonly property var steps: Weather.nowcast.filter(q => q.time - Date.now() < horizon)
    readonly property real start: steps.length ? steps[0].time : 0
    // The last step lasts as long as the one before it.
    readonly property real end: steps.length > 1 ? steps[steps.length - 1].time * 2 - steps[steps.length - 2].time : start + 900 * 1000
    readonly property real span: Math.max(1, end - start)
    readonly property real barsHeight: height - labels.height - 3

    implicitHeight: 34

    Item {
        width: parent.width
        height: root.barsHeight

        Repeater {
            model: root.steps

            Rectangle {
                required property var modelData
                required property int index
                readonly property real next: index + 1 < root.steps.length ? root.steps[index + 1].time : root.end

                x: (modelData.time - root.start) / root.span * root.width
                width: Math.max(2, (next - modelData.time) / root.span * root.width - 2)
                // Dry: a thin line; light / moderate / heavy rain: 45 / 75 / 100 %.
                height: modelData.level > 0 ? root.barsHeight * [0, 0.45, 0.75, 1][modelData.level] : 2
                anchors.bottom: parent.bottom
                radius: Math.min(2, width / 2)
                color: modelData.level > 0 ? root.wetColor : root.dryColor
            }
        }
    }

    // Start, middle, end.
    Item {
        id: labels

        anchors.bottom: parent.bottom
        width: parent.width
        height: startLabel.implicitHeight

        ThemedText {
            id: startLabel
            text: root.start ? I18n.locale.toString(new Date(root.start), "HH:mm") : ""
            font.family: root.fontFamily
            font.pixelSize: root.labelSize
            font.features: ({ "tnum": 1 })
            color: root.labelColor
        }

        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.width > 160
            text: root.start ? I18n.locale.toString(new Date(root.start + root.span / 2), "HH:mm") : ""
            font.family: root.fontFamily
            font.pixelSize: root.labelSize
            font.features: ({ "tnum": 1 })
            color: root.labelColor
        }

        ThemedText {
            anchors.right: parent.right
            text: root.start ? I18n.locale.toString(new Date(root.end), "HH:mm") : ""
            font.family: root.fontFamily
            font.pixelSize: root.labelSize
            font.features: ({ "tnum": 1 })
            color: root.labelColor
        }
    }
}
