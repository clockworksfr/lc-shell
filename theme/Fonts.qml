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
        "jetbrains-mono/JetBrainsMono-SemiBold.ttf",
        "outfit/Outfit-ExtraLight.ttf",
        "outfit/Outfit-Light.ttf",
        "outfit/Outfit-Regular.ttf",
        "outfit/Outfit-Medium.ttf",
        "outfit/Outfit-SemiBold.ttf",
        "geist-mono/GeistMono-Regular.ttf",
        "geist-mono/GeistMono-Medium.ttf",
        "space-grotesk/SpaceGrotesk-Regular.ttf",
        "space-grotesk/SpaceGrotesk-Medium.ttf",
        "space-grotesk/SpaceGrotesk-Bold.ttf",
        "space-mono/SpaceMono-Regular.ttf",
        "space-mono/SpaceMono-Bold.ttf",
        "doto/DotoMatrix.ttf",
        "ibm-plex-sans-condensed/IBMPlexSansCondensed-Regular.ttf",
        "ibm-plex-sans-condensed/IBMPlexSansCondensed-Medium.ttf",
        "ibm-plex-sans-condensed/IBMPlexSansCondensed-SemiBold.ttf",
        "ibm-plex-sans-condensed/IBMPlexSansCondensed-Bold.ttf",
        "ibm-plex-mono/IBMPlexMono-Regular.ttf",
        "ibm-plex-mono/IBMPlexMono-Medium.ttf",
        "dseg/DSEG7Classic-Bold.ttf",
        "dseg/DSEG7Classic-BoldItalic.ttf",
        // Façade's VFD text (14 segments: letters too).
        "dseg/DSEG14Classic-Bold.ttf",
        "dseg/DSEG14Classic-BoldItalic.ttf",
        "barlow-condensed/BarlowCondensed-Regular.ttf",
        "barlow-condensed/BarlowCondensed-Medium.ttf",
        "barlow-condensed/BarlowCondensed-SemiBold.ttf",
        "michroma/Michroma-Regular.ttf",
        "nixie-one/NixieOne-Regular.ttf",
        "doto/DotoLCD.ttf",
        "symbols/lcSymbols-Outlined.ttf",
        "symbols/lcSymbols-Filled.ttf"
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
