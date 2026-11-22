pragma Singleton

import QtQuick
import Quickshell

// Runtime state shared across screens (not persisted).
Singleton {
    property bool barVisible: true

    // Ask the bar block of `type` on screen `screenName` (focused screen if
    // empty) to toggle its panel: keyboard binds, scripts, reviews.
    signal panelRequested(string type, string screenName)
}
