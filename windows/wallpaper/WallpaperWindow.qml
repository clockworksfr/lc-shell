import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.components
import qs.theme
import qs.windows.dashboard

// Wallpaper of one screen, on the background layer. A new image loads in
// the hidden layer, then fades in over the current one.
PanelWindow {
    id: win

    property var theme: Themes.fallback
    property string source
    // > 0: the source is a tile repeated over the screen at that size.
    property int tileSize: 0

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

    readonly property string workspace: Hyprland.monitorFor(screen)?.activeWorkspace?.name ?? ""

    // Right click on the background of any workspace: its modules
    // (edit, apply a preset or none, save as…), the wallpaper.
    MouseArea {
        anchors.fill: parent
        z: 10
        acceptedButtons: Qt.RightButton
        onClicked: mouse => {
            menu.actions = DashboardMenu.actions(win.workspace);
            menu.openAt(mouse.x, mouse.y);
        }
    }

    MenuPopup {
        id: menu
        host: win
        onPicked: id => DashboardMenu.pick(id, win.workspace, win.screen.name)
    }

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
        // A theme tile repeats; an image fills the screen.
        fillMode: win.tileSize > 0 ? Image.Tile : Image.PreserveAspectCrop
        // Decode at screen size (or the tile's), not at the file's size.
        sourceSize.width: win.tileSize > 0 ? win.tileSize : (parent?.width ?? 0)
        sourceSize.height: win.tileSize > 0 ? win.tileSize : (parent?.height ?? 0)
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
