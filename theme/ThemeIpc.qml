import QtQuick
import Quickshell.Io

// qs -c lc ipc call theme <function>
IpcHandler {
    target: "theme"

    // Theme of normal screens (bar).
    // Next theme, on every screen (normal and modules).
    function next(): string {
        const ids = Object.keys(Themes.definitions);
        const id = ids[(ids.indexOf(Themes.themeFor("normal")) + 1) % ids.length];
        Themes.setTheme("normal", id);
        Themes.setTheme("modules", id);
        return id;
    }
    function set(id: string): string {
        return Themes.setTheme("normal", id) ? `normal: ${id}` : `unknown theme: ${id}`;
    }
    // Theme of "modules" screens.
    function setModules(id: string): string {
        return Themes.setTheme("modules", id) ? `modules: ${id}` : `unknown theme: ${id}`;
    }
    // "dark" | "light" | "auto"
    function variant(mode: string): string {
        return Themes.setVariant(mode) ? `variant: ${mode}` : `unknown variant: ${mode}`;
    }
    function toggleVariant(): void {
        Themes.toggleVariant();
    }
    function list(): string {
        return Object.keys(Themes.definitions).join(" ");
    }
}
