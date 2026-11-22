pragma Singleton

import QtQuick
import Quickshell

// Runtime state shared across screens (not persisted).
Singleton {
    property bool barVisible: true
}
