pragma Singleton

import QtQuick
import Quickshell

// Sunrise and sunset, computed locally (sunrise equation, ~1 min accuracy).
Singleton {
    function times(date: date, latitude: real, longitude: real): var {
        const rad = Math.PI / 180;
        // The local calendar day (its noon), not the current instant: the
        // Julian day turns at 12:00 UTC, which gave tomorrow's times every
        // afternoon (and so a dark theme in broad daylight).
        const noon = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 12);
        const julianDate = noon.getTime() / 86400000 + 2440587.5;

        // Mean solar noon at this longitude (east positive).
        const n = Math.round(julianDate - 2451545.0 + longitude / 360);
        const meanNoon = n - longitude / 360;
        const anomaly = (357.5291 + 0.98560028 * meanNoon) % 360;
        const center = 1.9148 * Math.sin(anomaly * rad) + 0.02 * Math.sin(2 * anomaly * rad) + 0.0003 * Math.sin(3 * anomaly * rad);
        const eclipticLongitude = (anomaly + center + 180 + 102.9372) % 360;
        const transit = 2451545.0 + meanNoon + 0.0053 * Math.sin(anomaly * rad) - 0.0069 * Math.sin(2 * eclipticLongitude * rad);

        const declination = Math.asin(Math.sin(eclipticLongitude * rad) * Math.sin(23.4397 * rad));
        const cosHourAngle = (Math.sin(-0.833 * rad) - Math.sin(latitude * rad) * Math.sin(declination)) / (Math.cos(latitude * rad) * Math.cos(declination));

        // Polar day / night.
        if (cosHourAngle < -1)
            return { polar: "day" };
        if (cosHourAngle > 1)
            return { polar: "night" };

        const hourAngle = Math.acos(cosHourAngle) / rad;
        const toDate = julian => new Date((julian - 2440587.5) * 86400000);
        return {
            sunrise: toDate(transit - hourAngle / 360),
            sunset: toDate(transit + hourAngle / 360)
        };
    }
}
