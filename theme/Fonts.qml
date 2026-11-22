pragma Singleton

import QtQuick
import Quickshell

// Registers the bundled fonts (assets/fonts, static files, OFL) so themes
// can name their families without them being installed system-wide.
Singleton {
    id: root

    readonly property var files: [
        "figtree/Figtree-Regular.ttf",
        "figtree/Figtree-Medium.ttf",
        "figtree/Figtree-SemiBold.ttf",
        "figtree/Figtree-Bold.ttf",
        "jetbrains-mono/JetBrainsMono-Regular.ttf",
        "jetbrains-mono/JetBrainsMono-Medium.ttf",
        "jetbrains-mono/JetBrainsMono-SemiBold.ttf"
    ]

    Instantiator {
        model: root.files

        FontLoader {
            required property string modelData
            source: `file://${Quickshell.shellDir}/assets/fonts/${modelData}`
            onStatusChanged: {
                if (status === FontLoader.Error)
                    console.warn(`font not loaded: ${modelData}`);
            }
        }
    }
}
