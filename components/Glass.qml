import QtQuick
import Quickshell
import qs.theme

// Glass highlight: the top 58 % of a rounded surface gets a soft white
// sheen (theme color `glass`), no blur. Drawn only when the theme's
// style.glass is on. Put it inside the surface, after its background.
Rectangle {
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    height: parent.height * 0.58
    radius: parent.radius
    visible: theme.style.glass === true
    gradient: Gradient {
        GradientStop {
            position: 0
            color: theme.color.glass
        }
        GradientStop {
            position: 1
            color: "transparent"
        }
    }
}
