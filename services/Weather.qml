pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.i18n

// Weather from open-meteo.com (no key, no account), every 15 minutes.
// Off until a place is chosen in Settings › General (weather.location:
// { name, latitude, longitude }): no location is ever guessed or sent
// by default. The last reading is cached and shown, dated, when offline.
// Config: weather.enabled (true), weather.units ("metric" | "imperial").
Singleton {
    id: root

    readonly property var location: Config.get("weather.location") ?? null
    readonly property bool enabled: !!location && (Config.get("weather.enabled") ?? true)
    readonly property bool imperial: Config.get("weather.units") === "imperial"

    // { temp, feels, code, wind, isDay } of the last reading.
    property var current: null
    // Next 6 hours: [{ time (ms), temp, rain (%), code, isDay }].
    property var hourly: []
    // When the reading was taken (ms since epoch), 0 = none.
    property real updated: 0
    property bool failed: false
    readonly property bool ready: enabled && !!current
    // Older than an hour (offline): shown with its time.
    readonly property bool stale: updated > 0 && Date.now() - updated > 3600 * 1000

    // Place search (settings): [{ name, region, country, latitude, longitude }].
    property var results: []
    property bool searching: false

    readonly property string unit: imperial ? "°F" : "°C"
    readonly property string windUnit: imperial ? "mph" : "km/h"

    // Material Symbols name for a WMO weather code.
    function icon(code: int, isDay: bool): string {
        if (code === 0)
            return isDay ? "sunny" : "bedtime";
        if (code <= 2)
            return isDay ? "partly_cloudy_day" : "partly_cloudy_night";
        if (code === 3)
            return "cloud";
        if (code === 45 || code === 48)
            return "foggy";
        if (code >= 51 && code <= 57)
            return "rainy_light";
        if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82))
            return "rainy";
        if ((code >= 71 && code <= 77) || code === 85 || code === 86)
            return "weather_snowy";
        if (code >= 95)
            return "thunderstorm";
        return "cloud";
    }

    // i18n key of a WMO weather code's condition.
    function condition(code: int): string {
        if (code === 0)
            return "weather.clear";
        if (code <= 2)
            return "weather.partlyCloudy";
        if (code === 3)
            return "weather.cloudy";
        if (code === 45 || code === 48)
            return "weather.fog";
        if (code >= 51 && code <= 57)
            return "weather.drizzle";
        if (code >= 61 && code <= 67)
            return "weather.rain";
        if (code >= 80 && code <= 82)
            return "weather.showers";
        if ((code >= 71 && code <= 77) || code === 85 || code === 86)
            return "weather.snow";
        if (code >= 95)
            return "weather.storm";
        return "weather.cloudy";
    }

    function temp(value: real): string {
        return `${Math.round(value)}°`;
    }

    function refresh(): void {
        if (!enabled || fetch.running)
            return;
        const p = location;
        const units = imperial ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : "";
        fetch.command = ["curl", "-fsS", "--max-time", "15", `https://api.open-meteo.com/v1/forecast?latitude=${p.latitude}&longitude=${p.longitude}&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m,is_day&hourly=temperature_2m,precipitation_probability,weather_code,is_day&forecast_hours=7&timeformat=unixtime&timezone=auto${units}`];
        fetch.running = true;
    }

    function search(name: string): void {
        const q = name.trim();
        if (!q) {
            results = [];
            return;
        }
        searching = true;
        geocode.command = ["curl", "-fsS", "--max-time", "10", `https://geocoding-api.open-meteo.com/v1/search?count=6&format=json&language=${I18n.language}&name=${encodeURIComponent(q)}`];
        geocode.running = true;
    }

    function choose(place: var): void {
        Config.set("weather.location", { name: place.name, latitude: place.latitude, longitude: place.longitude });
        results = [];
        current = null;
        hourly = [];
        updated = 0;
        Qt.callLater(refresh);
    }

    function parse(text: string): void {
        const d = JSON.parse(text);
        const c = d.current;
        current = { temp: c.temperature_2m, feels: c.apparent_temperature, code: c.weather_code, wind: c.wind_speed_10m, isDay: !!c.is_day };
        const h = d.hourly;
        const now = Date.now() / 1000;
        const hours = [];
        for (let i = 0; i < h.time.length && hours.length < 6; i++) {
            if (h.time[i] + 3600 <= now)
                continue;
            hours.push({ time: h.time[i] * 1000, temp: h.temperature_2m[i], rain: h.precipitation_probability[i] ?? 0, code: h.weather_code[i], isDay: !!h.is_day[i] });
        }
        hourly = hours;
    }

    onEnabledChanged: if (enabled) refresh()
    onLocationChanged: if (enabled) Qt.callLater(refresh)
    onImperialChanged: Qt.callLater(refresh)

    Process {
        id: fetch
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.parse(text);
                    root.updated = Date.now();
                    root.failed = false;
                    cache.setText(JSON.stringify({ updated: root.updated, location: root.location, current: root.current, hourly: root.hourly }));
                } catch (e) {
                    root.failed = true;
                }
            }
        }
        onExited: code => {
            if (code !== 0)
                root.failed = true;
        }
    }

    Process {
        id: geocode
        stdout: StdioCollector {
            onStreamFinished: {
                root.searching = false;
                try {
                    root.results = (JSON.parse(text).results ?? []).map(r => ({ name: r.name, region: r.admin1 ?? "", country: r.country ?? "", latitude: r.latitude, longitude: r.longitude }));
                } catch (e) {
                    root.results = [];
                }
            }
        }
        onExited: root.searching = false
    }

    // Last reading, shown until a fresh one comes (offline at start…).
    FileView {
        id: cache
        path: Quickshell.cachePath("weather.json")
        atomicWrites: true
        printErrors: false
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (root.location && d.location?.latitude === root.location.latitude && d.location?.longitude === root.location.longitude && !root.current) {
                    root.current = d.current;
                    root.hourly = (d.hourly ?? []).filter(h => h.time + 3600 * 1000 > Date.now());
                    root.updated = d.updated;
                }
            } catch (e) {}
        }
    }

    Timer {
        running: root.enabled
        interval: 15 * 60 * 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
