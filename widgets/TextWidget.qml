import QtQuick
import Quickshell
import qs.components

// Base of text blocks. `fullText` on a horizontal bar, `compactText` on a
// vertical one (short, usually two lines: label then value), centered and
// clipped to the bar's width. Never rotated. Blocks pick their text by
// `size` too (compact: the value alone, extended: with context).
ThemedText {
    property ShellScreen screen
    property var options: ({})
    property bool vertical: false
    property int crossSize: 0

    // "compact" | "normal" | "extended" (edit mode, options.size).
    // Extended doesn't fit across a vertical bar: shown as normal there.
    readonly property string size: vertical && options.size === "extended" ? "normal" : (options.size ?? "normal")

    property string fullText
    property string compactText: fullText

    // Icon mode (theme.style.statusIcons): `icon` + `iconText` (usually the
    // value alone; empty = icon only). Vertical: icon over the value.
    property string icon
    property string iconText
    property bool iconFilled: false
    readonly property bool useIcon: !!icon && theme.style.statusIcons !== false

    // Text mode: compact = label over value (e.g. VOL / 64), like vertical.
    readonly property bool stacked: !useIcon && (vertical || size === "compact")
    // Themes with micro labels (Matrix, style.statusStack): statuses as a
    // small soft label over the value, mono capitals ("VOL / 64"); a
    // leading "●" is the signal dot. Extended keeps its full line, under
    // `microLabel` when the widget gives one (its value alone isn't clear).
    property string microLabel
    readonly property bool microStatus: theme.style.statusStack === true && !useIcon && !!icon
    // Sigils (style.statusSigil): the label and value on one line, mono
    // capitals ("BT 2", "NET ↓1,3M"): "phosphor" (Façade: VFD ink, off at
    // 22 %), "led" (Modulaire: a LED before, on / off / alert).
    readonly property string sigilStyle: theme.style.statusSigil ?? ""
    readonly property bool sigil: !!sigilStyle && !useIcon && !!icon && !vertical && (size !== "extended" || !!microLabel)
    // Statuses as label + value (micro stacks or sigils).
    readonly property bool labelled: theme.style.statusStack === true || !!sigilStyle
    readonly property string level: Qt.colorEqual(color, theme.color.urgent) || Qt.colorEqual(color, theme.color.warn ?? "#00000000") ? "alert" : Qt.colorEqual(color, theme.color.soft) ? "off" : "on"
    readonly property bool microStack: microStatus && !vertical && (size !== "extended" || !!microLabel)

    function micro(value: string): string {
        const esc = t => t.replace(/&/g, "&amp;").replace(/</g, "&lt;");
        let rest = value;
        let dot = "";
        if (rest.startsWith("●")) {
            dot = `<span style="color:${theme.color.signal ?? theme.color.urgent}">●</span> `;
            rest = rest.slice(1).trim();
        }
        const parts = rest.split("\n");
        if (parts.length < 2)
            return dot + esc(rest);
        // A "●" leading the value: the signal dot there.
        if (parts[1].startsWith("●")) {
            dot = `<span style="color:${theme.color.signal ?? theme.color.urgent}">●</span> `;
            parts[1] = parts[1].slice(1).trim();
        }
        return `<span style="font-size:${Math.round(theme.font.sizeS * 0.82)}px; color:${theme.color.soft}">${esc(parts[0])}</span><br>${dot}${esc(parts.slice(1).join(" "))}`;
    }

    label: stacked && !microStack
    text: useIcon ? iconText : sigil ? (size === "extended" ? `${microLabel} ${fullText}` : compactText.replace(/\n/g, " ")) : microStack ? micro(size === "extended" ? `${microLabel}\n${fullText}` : compactText) : stacked ? compactText : fullText
    textFormat: microStack ? Text.RichText : Text.PlainText
    leftPadding: useIcon && !vertical ? iconItem.width + (iconText ? 6 : 0) : sigil && sigilStyle === "led" ? 14 : 0
    topPadding: useIcon && vertical ? iconItem.height + (iconText ? 2 : 0) : 0
    font.pixelSize: microStack ? 12 : sigil ? (sigilStyle === "led" ? 14 : 12) : vertical || stacked ? theme.font.sizeS : theme.font.sizeM
    font.weight: sigil && sigilStyle === "phosphor" ? Font.DemiBold : Font.Normal
    font.letterSpacing: sigil ? (sigilStyle === "phosphor" ? 1 : 0.6) : 0
    // Façade: a status that's off dims (the VFD's unlit segments).
    opacity: sigil && sigilStyle === "phosphor" && level === "off" ? 0.45 : 1

    // Modulaire: the status LED (on: ok, off: dark, alert: urgent), a soft
    // halo when lit.
    Item {
        visible: parent.sigil && parent.sigilStyle === "led"
        width: 8
        height: 8
        anchors.verticalCenter: parent.verticalCenter

        readonly property color lit: parent.level === "alert" ? parent.theme.color.urgent : parent.theme.color.ok

        Repeater {
            model: parent.parent.level !== "off" ? [{ s: 16, a: 0.18 }, { s: 12, a: 0.3 }] : []
            Rectangle {
                required property var modelData
                anchors.centerIn: parent
                width: modelData.s
                height: width
                radius: width / 2
                color: Qt.alpha(parent.lit, modelData.a)
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 4
            color: parent.parent.level === "off" ? "#3B2A24" : parent.lit
        }
    }
    // (Every size: extended keeps one line, in the same mono capitals.)
    font.family: microStatus || sigilStyle === "phosphor" ? theme.font.mono : theme.font.family
    font.capitalization: microStatus || sigil ? Font.AllUppercase : Font.MixedCase
    lineHeight: stacked || microStack ? 0.9 : 1
    horizontalAlignment: Text.AlignHCenter
    width: vertical && crossSize > 0 ? crossSize : implicitWidth
    elide: Text.ElideRight

    Icon {
        id: iconItem

        visible: parent.useIcon
        name: parent.icon
        filled: parent.iconFilled
        color: parent.color
        size: parent.vertical ? 20 : parent.theme.font.sizeL + 3
        x: parent.vertical ? (parent.width - width) / 2 : 0
        y: parent.vertical ? 0 : (parent.height - height) / 2
    }
}
