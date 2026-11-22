import QtQuick
import Quickshell
import qs.modules.bar
import qs.modules.osd
import qs.services

// Everything that lives on one screen. Each module is only instantiated
// when the layout enables it for this screen.
Scope {
    id: root

    required property ShellScreen modelData
    readonly property var layout: Layout.forScreen(modelData.name)

    LazyLoader {
        active: !!root.layout.bar && ShellState.barVisible

        Bar {
            screen: root.modelData
            config: root.layout.bar
        }
    }

    LazyLoader {
        active: !!root.layout.osd && Osd.shown && Osd.screenName === root.modelData.name

        OsdWindow {
            screen: root.modelData
            config: root.layout.osd
        }
    }
}
