import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services
import qs.theme
import qs.i18n

// Volume / mic / brightness popup. Config (layout.json, module "osd"):
//   position: "bottom" | "top", margin: distance from the edge in px
PanelWindow {
    id: win

    property var theme: Themes.fallback

    property var config: ({})
    // Extra distance when the bar sits on the same edge.
    property int edgeOffset: 0

    readonly property bool atTop: config.position === "top"
    readonly property string title: Osd.kind ? I18n.tr(`osd.${Osd.kind}`) : ""

    // Only one edge anchored: layer shell centers the window horizontally.
    anchors.top: atTop
    anchors.bottom: !atTop
    margins.top: atTop ? (config.margin ?? 80) + edgeOffset : 0
    margins.bottom: atTop ? 0 : (config.margin ?? 80) + edgeOffset

    implicitWidth: 360
    implicitHeight: content.implicitHeight + win.theme.space.m * 2
    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lc-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    // Click-through: an empty input region.
    mask: Region {}

    Rectangle {
        id: osdBody

        // Entrance: from its screen edge, with a fade.
        width: parent.width
        height: parent.height
        opacity: 0
        y: win.atTop ? -Motion.travel(16) : Motion.travel(16)
        Component.onCompleted: osdEnter.start()

        ParallelAnimation {
            id: osdEnter
            NumberAnimation {
                target: osdBody
                property: "opacity"
                to: 1
                duration: Motion.ms(win.theme, "fast", win.screen?.name ?? "")
            }
            NumberAnimation {
                target: osdBody
                property: "y"
                to: 0
                duration: Motion.ms(win.theme, "base", win.screen?.name ?? "")
                easing.type: Motion.easing(win.theme)
                easing.overshoot: Motion.overshoot(win.theme)
            }
        }

        radius: win.theme.radius.panel
        color: win.theme.color.surface

        Column {
            id: content

            anchors.fill: parent
            anchors.margins: win.theme.space.m
            spacing: win.theme.space.s

            Item {
                width: parent.width
                implicitHeight: titleText.implicitHeight

                ThemedText {
                    id: titleText
                    anchors.left: parent.left
                    text: win.title
                }

                ThemedText {
                    anchors.right: parent.right
                    text: Osd.muted ? I18n.tr("common.muted") : I18n.percent(Osd.value)
                    color: Osd.muted ? win.theme.color.soft : win.theme.color.ink
                }
            }

            // Track; values above 100 % (volume boost) fill in the urgent color.
            Rectangle {
                width: parent.width
                height: 6
                radius: win.theme.radius.full
                color: win.theme.color.bg

                Rectangle {
                    width: parent.width * Math.min(Osd.value, 1)
                    height: parent.height
                    radius: parent.radius
                    color: Osd.muted ? win.theme.color.soft : Osd.value > 1 ? win.theme.color.urgent : win.theme.color.accent

                    Behavior on width {
                        NumberAnimation {
                            duration: 80
                        }
                    }
                }
            }

            ThemedText {
                width: parent.width
                text: Osd.label
                color: win.theme.color.soft
                font.pixelSize: win.theme.font.sizeS
                elide: Text.ElideRight
            }
        }
    }
}
