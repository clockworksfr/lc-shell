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
    // "openmeteo": forecast and conditions from Open-Meteo. "local": a
    // Météo-villes site (meteo-biarritz.com…, `weather.localSite`) for the
    // live station readings and the rain within the hour (its umbrellas,
    // Météo-France style levels), over Open-Meteo's forecast (the same
    // AROME model those sites show); Open-Meteo whenever the site is silent.
    readonly property string source: Config.get("weather.source") ?? "openmeteo"
    readonly property string localSite: (Config.get("weather.localSite") ?? "").replace(/\/+$/, "")
    readonly property bool useStation: source === "local" && /^https:\/\/[a-z0-9.-]+$/i.test(localSite)

    // { temp, feels, code, wind, isDay } of the last reading.
    property var current: null
    // Next 12 hours: [{ time (ms), temp, rain (%), code, isDay }].
    property var hourly: []
    // Today and the next 5 days: [{ time (ms), max, min, code, rain (%) }].
    property var daily: []
    // When the reading was taken (ms since epoch), 0 = none.
    property real updated: 0
    // Live station reading (source "local"): { temp, feels, wind, windDir,
    // gusts, pressure, humidity, name, time } or null.
    property var station: null
    // Station readings older than an hour aren't shown.
    readonly property bool stationLive: !!station && Date.now() - station.time < 3600 * 1000
    // What to show now: Open-Meteo's conditions, with the station's live
    // readings over them when there are some (`station` set to its name).
    readonly property var now: {
        if (!current)
            return null;
        if (!stationLive)
            return current;
        const s = station;
        return Object.assign({}, current, {
            temp: s.temp,
            feels: s.feels,
            wind: s.wind ?? current.wind,
            windDir: s.windDir || current.windDir,
            gusts: s.gusts ?? current.gusts,
            pressure: s.pressure ?? current.pressure,
            humidity: s.humidity ?? current.humidity,
            station: s.name,
            stationTime: s.time
        });
    }
    // Wind, gusts, pressure in one line ("O 41 km/h · raf. 58 · 1026 hPa").
    readonly property string windLine: {
        if (!now)
            return "";
        const parts = [`${now.windDir ?? ""} ${Math.round(now.wind ?? 0)} ${windUnit}`.trim()];
        if (now.gusts && now.gusts > (now.wind ?? 0) + 5)
            parts.push(I18n.tr("weather.gusts", { value: Math.round(now.gusts) }));
        if (now.pressure)
            parts.push(`${Math.round(now.pressure)} hPa`);
        return parts.join(" · ");
    }

    // Next hour's rain: [{ time, level (0 dry … 3 heavy), desc }], from the
    // local site (5–10 min steps) or Open-Meteo (quarter hours).
    property var nowcast: []
    property var siteNowcast: []
    property var modelNowcast: []
    onSiteNowcastChanged: nowcast = siteNowcast.length ? siteNowcast : modelNowcast
    onModelNowcastChanged: nowcast = siteNowcast.length ? siteNowcast : modelNowcast
    // "dry" | "soon" (starts within the hour) | "now" (raining) | ""
    readonly property string rainSoon: {
        if (!nowcast.length)
            return "";
        if (nowcast[0].level > 0)
            return "now";
        return nowcast.some(q => q.level > 0 && q.time - Date.now() < 3600 * 1000) ? "soon" : "dry";
    }
    // The quarter it starts (soon) or stops (now) in, as a time; 0 if none.
    readonly property real rainChange: {
        if (rainSoon === "soon")
            return nowcast.find(q => q.level > 0)?.time ?? 0;
        if (rainSoon === "now")
            return nowcast.find(q => q.level === 0)?.time ?? 0;
        return 0;
    }
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

    // Compass point (N, NE…) of a wind direction in degrees.
    function compass(degrees: real): string {
        return I18n.tr(`weather.dir.${["N", "NE", "E", "SE", "S", "SW", "W", "NW"][Math.round(((degrees % 360) + 360) % 360 / 45) % 8]}`);
    }

    // "Pas de pluie dans l'heure", "Pluie vers 20:15", "Pluie jusqu'à 20:30".
    // The next rain episode within the hour: { start, end (0: lasts past
    // the hour), level (its heaviest), desc }, or null.
    readonly property var rainEpisode: {
        const steps = nowcast.filter(q => q.time - Date.now() < 3600 * 1000);
        const i = steps.findIndex(q => q.level > 0);
        if (i < 0)
            return null;
        let j = i;
        while (j < steps.length && steps[j].level > 0)
            j++;
        const wet = steps.slice(i, j);
        const top = wet.reduce((a, b) => b.level > a.level ? b : a, wet[0]);
        return { start: steps[i].time, end: j < steps.length ? steps[j].time : 0, level: top.level, desc: top.desc || I18n.tr(`weather.rain.level${top.level}`) };
    }

    // "Pas de pluie dans l'heure", "Pluie faible de 21:05 à 21:30",
    // "Pluie modérée jusqu'à 21:30", "Pluie forte toute l'heure".
    function rainText(): string {
        if (rainSoon === "dry")
            return I18n.tr("weather.rain.dry");
        const e = rainEpisode;
        if (!e)
            return "";
        const t = ms => I18n.locale.toString(new Date(ms), "HH:mm");
        if (rainSoon === "now")
            return e.end ? I18n.tr("weather.rain.until", { desc: e.desc, end: t(e.end) }) : I18n.tr("weather.rain.allHour", { desc: e.desc });
        return e.end ? I18n.tr("weather.rain.between", { desc: e.desc, start: t(e.start), end: t(e.end) }) : I18n.tr("weather.rain.from", { desc: e.desc, start: t(e.start) });
    }

    // A Météo-villes home page: the station's "realtimeReport" and the
    // "rain" list (umbrellas) of its Next.js flight data (self.__next_f).
    function parseStation(html: string): void {
        const chunks = [];
        const re = /self\.__next_f\.push\(\[1,"((?:[^"\\]|\\.)*)"\]\)/g;
        let m;
        while ((m = re.exec(html)) !== null)
            chunks.push(JSON.parse(`"${m[1]}"`));
        const flight = chunks.join("");
        const rain = /\{"rain":(\[[^\]]*\])/.exec(flight);
        siteNowcast = rain ? JSON.parse(rain[1]).map(q => ({ time: Date.parse(q.dt), level: Math.max(0, Math.min(3, (q.rain ?? 1) - 1)), desc: q.desc ?? "" })).filter(q => q.time + 600 * 1000 > Date.now()) : [];
        const r = /"(?:realtimeReport|report)":(\{[^{}]*\})/.exec(flight);
        if (!r) {
            station = null;
            return;
        }
        const d = JSON.parse(r[1]);
        if (d.out_of_service || d.temperature === null || d.temperature === undefined) {
            station = null;
            return;
        }
        const title = /<title>Météo ([^<0-9–]+?)\s+\d{5}/.exec(html);
        station = {
            temp: d.temperature,
            feels: d.windchill ?? d.humidex ?? d.temperature,
            wind: d.wind_speed ?? null,
            windDir: d.wind_direction && I18n.has(`weather.dir.${d.wind_direction}`) ? I18n.tr(`weather.dir.${d.wind_direction}`) : (d.wind_direction_label ?? ""),
            gusts: d.gust ?? null,
            pressure: d.pressure ?? null,
            humidity: d.humidity ?? null,
            name: title ? title[1].trim() : localSite.replace(/^https:\/\/(www\.)?/, ""),
            time: Date.parse(d.updated_at)
        };
    }

    function refreshStation(): void {
        if (!enabled || !useStation || stationFetch.running)
            return;
        // A generic client name; nothing about the user is sent.
        stationFetch.command = ["curl", "-fsSL", "--max-time", "20", "-A", "Mozilla/5.0 (X11; Linux x86_64) lc-shell", `${localSite}/`];
        stationFetch.running = true;
    }

    function refresh(): void {
        if (!enabled || fetch.running)
            return;
        const p = location;
        const units = imperial ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : "";
        fetch.command = ["curl", "-fsS", "--max-time", "15", `https://api.open-meteo.com/v1/forecast?latitude=${p.latitude}&longitude=${p.longitude}&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m,wind_direction_10m,wind_gusts_10m,relative_humidity_2m,pressure_msl,is_day&minutely_15=precipitation&forecast_minutely_15=8&hourly=temperature_2m,precipitation_probability,weather_code,is_day&forecast_hours=13&daily=temperature_2m_max,temperature_2m_min,weather_code,precipitation_probability_max&forecast_days=6&timeformat=unixtime&timezone=auto${units}`];
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
        daily = [];
        updated = 0;
        Qt.callLater(refresh);
    }

    function parse(text: string): void {
        const d = JSON.parse(text);
        const c = d.current;
        current = { temp: c.temperature_2m, feels: c.apparent_temperature, code: c.weather_code, wind: c.wind_speed_10m, windDir: compass(c.wind_direction_10m ?? 0), gusts: c.wind_gusts_10m, humidity: c.relative_humidity_2m, pressure: c.pressure_msl, isDay: !!c.is_day };
        const q = d.minutely_15 ?? { time: [], precipitation: [] };
        const quarters = [];
        for (let i = 0; i < q.time.length; i++) {
            const mm = q.precipitation[i] ?? 0;
            if (q.time[i] + 900 > Date.now() / 1000)
                quarters.push({ time: q.time[i] * 1000, level: mm < 0.05 ? 0 : mm < 0.5 ? 1 : mm < 2 ? 2 : 3, desc: "" });
        }
        modelNowcast = quarters;
        const h = d.hourly;
        const now = Date.now() / 1000;
        const hours = [];
        for (let i = 0; i < h.time.length && hours.length < 12; i++) {
            if (h.time[i] + 3600 <= now)
                continue;
            hours.push({ time: h.time[i] * 1000, temp: h.temperature_2m[i], rain: h.precipitation_probability[i] ?? 0, code: h.weather_code[i], isDay: !!h.is_day[i] });
        }
        hourly = hours;
        const d6 = d.daily ?? { time: [] };
        const days = [];
        for (let i = 0; i < d6.time.length; i++)
            days.push({ time: d6.time[i] * 1000, max: d6.temperature_2m_max[i], min: d6.temperature_2m_min[i], code: d6.weather_code[i], rain: d6.precipitation_probability_max?.[i] ?? 0 });
        daily = days;
    }

    onUseStationChanged: {
        station = null;
        siteNowcast = [];
        Qt.callLater(refreshStation);
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
                    cache.setText(JSON.stringify({ updated: root.updated, location: root.location, current: root.current, hourly: root.hourly, daily: root.daily }));
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
        id: stationFetch
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.parseStation(text);
                } catch (e) {
                    root.station = null;
                    root.siteNowcast = [];
                }
            }
        }
    }

    // The station reports every few minutes; the rain within the hour moves
    // in 5–10 min steps.
    Timer {
        running: root.enabled && root.useStation
        interval: 5 * 60 * 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshStation()
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
                    root.daily = d.daily ?? [];
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
