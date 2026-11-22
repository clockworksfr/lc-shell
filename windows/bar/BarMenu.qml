import QtQuick
import qs.components
import qs.i18n
import qs.services
import qs.settings

// Right-click menu of the bar: edit the bar, bar settings, settings.
MenuPopup {
    id: root

    actions: [
        { id: "edit", icon: "edit", text: I18n.tr("bar.menu.edit") },
        { id: "bar", icon: "tune", text: I18n.tr("bar.menu.barSettings") },
        { id: "settings", icon: "settings", text: I18n.tr("bar.menu.settings") }
    ]

    onPicked: id => {
        if (id === "edit")
            ShellState.editing = true;
        else if (id === "bar")
            Settings.open("bar");
        else
            Settings.open("appearance");
    }
}
