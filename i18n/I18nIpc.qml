import QtQuick
import Quickshell.Io

// qs -c lc ipc call i18n <set|get>
IpcHandler {
    target: "i18n"

    // "en" | "fr" | "auto"
    function set(code: string): string {
        return I18n.setLanguage(code) ? `language: ${code}` : `unknown language: ${code} (${I18n.languages.join(", ")}, auto)`;
    }
    function get(): string {
        return `${I18n.language} (setting: ${I18n.setting})`;
    }
}
