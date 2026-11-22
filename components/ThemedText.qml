import QtQuick
import qs.theme

// Base text: every label in the shell goes through this.
Text {
    color: Theme.color.fg
    font.family: Theme.font.family
    font.pixelSize: Theme.font.sizeM
    verticalAlignment: Text.AlignVCenter
}
