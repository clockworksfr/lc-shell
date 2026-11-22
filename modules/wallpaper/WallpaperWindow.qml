import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.theme

// Wallpaper of one screen, on the background layer. A new image loads in
// the hidden layer, then fades in over the current one.
PanelWindow {
    id: win

    property var theme: Themes.fallback
    property string source

    // The layer currently shown.
    property Image front: null

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: theme.color.bg
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "lc-wallpaper"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region {}

    onSourceChanged: load()
    Component.onCompleted: load()

    function load(): void {
        const target = front === layerA ? layerB : layerA;
        target.source = source ? `file://${source}` : "";
        if (!source && front) {
            front.opacity = 0;
            front = null;
        }
    }

    function shown(layer: Image): void {
        if (layer === front || layer.source.toString() !== (source ? `file://${source}` : ""))
            return;
        const previous = front;
        layer.z = 1;
        if (previous)
            previous.z = 0;
        front = layer;
        fade.target = layer;
        fade.restart();
    }

    component Layer: Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        // Decode at screen size, not at the file's size.
        sourceSize.width: parent?.width ?? 0
        sourceSize.height: parent?.height ?? 0
        asynchronous: true
        cache: false
        opacity: 0
    }

    Layer {
        id: layerA
        onStatusChanged: if (status === Image.Ready) win.shown(layerA)
    }

    Layer {
        id: layerB
        onStatusChanged: if (status === Image.Ready) win.shown(layerB)
    }

    NumberAnimation {
        id: fade
        property: "opacity"
        from: 0
        to: 1
        duration: 600
        easing.type: Easing.InOutQuad
        // Once the new layer is opaque, the old one can go.
        onFinished: {
            const old = win.front === layerA ? layerB : layerA;
            old.opacity = 0;
            old.source = "";
        }
    }
}
