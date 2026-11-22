"""Procedural wallpapers for lc-shell, one per theme and variant (5120 x 2160).

Only primitives Qt SVG renders (rect, circle, path, line, linear/radial
gradients, opacity): no pattern, mask, filter or clipPath.
Quiet zones: the top band (bar, drawers) and the top-right corner
(notifications) stay plain; the details sit low and in the middle, inside
the centred 16:10 crop (x 832..4288)."""
import math, os, random

W, H = 5120, 2160
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'wallpapers')
os.makedirs(OUT, exist_ok=True)


def quiet(x, y):
    """0 in the quiet zones, 1 elsewhere (smooth)."""
    top = min(1, max(0, (y - 260) / 420))
    dx, dy = max(0, x - 3500) / 1200, max(0, 1000 - y) / 800
    corner = 1 - min(1, math.hypot(min(dx, 1), min(dy, 1)) * 1.0) if x > 3500 and y < 1000 else 1
    return top * max(0, min(1, corner))


def svg(body, defs=''):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" '
            f'preserveAspectRatio="xMidYMid slice"><defs>{defs}</defs>{body}</svg>')


def lin(id_, stops, x1=0, y1=0, x2=0, y2=1):
    s = ''.join(f'<stop offset="{o}" stop-color="{c}" stop-opacity="{a}"/>' for o, c, a in stops)
    return f'<linearGradient id="{id_}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">{s}</linearGradient>'


def rad(id_, cx, cy, r, stops, fx=None, fy=None):
    s = ''.join(f'<stop offset="{o}" stop-color="{c}" stop-opacity="{a}"/>' for o, c, a in stops)
    f = f' fx="{fx}" fy="{fy}"' if fx is not None else ''
    return f'<radialGradient id="{id_}" gradientUnits="userSpaceOnUse" cx="{cx}" cy="{cy}" r="{r}"{f}>{s}</radialGradient>'


def base(top, bottom):
    return lin('bg', [(0, top, 1), (1, bottom, 1)]), f'<rect width="{W}" height="{H}" fill="url(#bg)"/>'


def glow(id_, cx, cy, r, color, a, sx=1.0):
    d = rad(id_, 0, 0, r, [(0, color, a), (0.55, color, a * 0.35), (1, color, 0)])
    return d, f'<ellipse cx="0" cy="0" rx="{r}" ry="{r}" fill="url(#{id_})" transform="translate({cx} {cy}) scale({sx} 1)"/>'


# ---------------------------------------------------------------- classic
def classic(dark):
    R = random.Random(11)
    bg, top, bot = ('#0F1114', '#12151A', '#0C0E11') if dark else ('#E7EAEE', '#EDF0F3', '#E1E5EA')
    acc = '#5FD0A8' if dark else '#0E7A5C'
    d0, b0 = base(top, bot)
    d1, b1 = glow('g1', 2300, 1900, 1700, acc, 0.10 if dark else 0.09, 1.6)
    d2, b2 = glow('g2', 3600, 2250, 1100, '#5AA0C8' if dark else '#3A7FA8', 0.05, 1.4)
    # topographic contours: distorted ellipses around a low centre
    lines = []
    for k in range(26):
        r = 260 + k * 120
        pts = []
        ph = R.random() * 6.28
        for i in range(181):
            a = i / 180 * 2 * math.pi
            rr = r * (1 + 0.08 * math.sin(3 * a + ph) + 0.05 * math.sin(5 * a + k * 0.4))
            x, y = 2350 + rr * 1.75 * math.cos(a), 1950 + rr * 0.75 * math.sin(a)
            pts.append((x, y))
        q = sum(quiet(x, y) for x, y in pts) / len(pts)
        op = (0.14 if dark else 0.10) * (1 - k / 30) * (0.35 + 0.65 * q)
        p = 'M' + ' L'.join(f'{x:.0f} {y:.0f}' for x, y in pts) + 'Z'
        lines.append(f'<path d="{p}" fill="none" stroke="{acc}" stroke-opacity="{op:.3f}" stroke-width="2"/>')
    return svg(b0 + b1 + b2 + ''.join(lines), d0 + d1 + d2)


# ---------------------------------------------------------- constellation
def constellation(dark):
    R = random.Random(7)
    top, bot = ('#0B0E1A', '#111733') if dark else ('#EEF0F8', '#E6E9F6')
    a1, a2 = ('#9FB8FF', '#F2A7D8') if dark else ('#4255C8', '#C2408F')
    d0, b0 = base(top, bot)
    d1, b1 = glow('n1', 2000, 1750, 1500, a1, 0.13 if dark else 0.07, 1.5)
    d2, b2 = glow('n2', 3100, 1900, 1100, a2, 0.09 if dark else 0.05, 1.5)
    star = '#FFFFFF' if dark else '#3A4690'
    out, pts = [], []
    for _ in range(900):
        x, y = R.random() * W, R.random() * H
        q = quiet(x, y)
        if R.random() > 0.15 + 0.85 * q:
            continue
        r = R.choice([1.2, 1.5, 1.8, 2.2, 2.6, 3.4]) * (1 if dark else 0.9)
        op = (R.uniform(0.18, 0.6) if dark else R.uniform(0.10, 0.28)) * (0.4 + 0.6 * q)
        out.append(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{r}" fill="{star}" fill-opacity="{op:.2f}"/>')
        if r >= 2.6 and q > 0.8 and 900 < x < 4200 and y > 900:
            pts.append((x, y))
    # a few faint links between bright stars (no known figure: random walk)
    pts.sort()
    links = []
    for i in range(0, len(pts) - 1, 2):
        (x1, y1), (x2, y2) = pts[i], pts[i + 1]
        if math.hypot(x2 - x1, y2 - y1) < 420:
            links.append(f'<line x1="{x1:.0f}" y1="{y1:.0f}" x2="{x2:.0f}" y2="{y2:.0f}" stroke="{star}" stroke-opacity="{0.10 if dark else 0.12}" stroke-width="1.6" stroke-dasharray="6 10"/>')
    # a few soft glints
    gl = ''
    for k, (x, y, r) in enumerate([(1500, 1500, 9), (2900, 1250, 7), (3700, 1700, 8)]):
        dd, bb = glow(f's{k}', x, y, r * 9, star if dark else a1, 0.35 if dark else 0.2)
        d1 += dd
        gl += bb + f'<circle cx="{x}" cy="{y}" r="{r / 3:.1f}" fill="{star}" fill-opacity="{0.8 if dark else 0.45}"/>'
    return svg(b0 + b1 + b2 + ''.join(out) + ''.join(links) + gl, d0 + d1 + d2)


# ---------------------------------------------------------------- facade
def facade(dark):
    R = random.Random(5)
    top, bot = ('#111516', '#0A0D0E') if dark else ('#CFD2CC', '#C2C5BF')
    d0, b0 = base(top, bot)
    # brushed horizontal grain
    grain = []
    y = 0
    while y < H:
        h = R.choice([1, 1, 2, 3])
        op = R.uniform(0.01, 0.035)
        col = '#FFFFFF' if R.random() < 0.5 else '#000000'
        grain.append(f'<rect y="{y}" width="{W}" height="{h}" fill="{col}" fill-opacity="{op:.3f}"/>')
        y += h + R.randint(2, 7)
    # smoked glass window low in the middle, with a faint phosphor haze
    gx, gy, gw, gh = 1060, 1480, 3000, 440
    glass = '#030505' if dark else '#B6BEA1'
    d1 = lin('gl', [(0, glass, 0.55 if dark else 0.45), (1, glass, 0.75 if dark else 0.6)])
    win = (f'<rect x="{gx}" y="{gy}" width="{gw}" height="{gh}" rx="10" fill="url(#gl)"/>'
           f'<rect x="{gx}" y="{gy}" width="{gw}" height="{gh}" rx="10" fill="none" stroke="{"#000" if dark else "#8F9295"}" stroke-opacity="0.5" stroke-width="4"/>'
           f'<rect x="{gx + 6}" y="{gy + 6}" width="{gw - 12}" height="3" fill="#FFFFFF" fill-opacity="{0.05 if dark else 0.25}"/>')
    d2, b2 = glow('ph', gx + gw * 0.42, gy + gh * 0.55, 900, '#6EF3D6' if dark else '#1E8C7B', 0.07 if dark else 0.06, 2.2)
    # unlit segment cells inside the window (a quiet bargraph)
    cells = []
    ink = '#6EF3D6' if dark else '#1D2618'
    for c in range(48):
        for r in range(6):
            x = gx + 90 + c * 58
            yy = gy + 90 + r * 46
            lit = r >= 6 - int(2.5 + 2.4 * abs(math.sin(c * 0.37 + 0.6)) * (1 - c / 70))
            op = (0.16 if lit else 0.04) if dark else (0.13 if lit else 0.04)
            cells.append(f'<rect x="{x}" y="{yy}" width="46" height="34" rx="2" fill="{ink}" fill-opacity="{op}"/>')
    # two screws at the bottom corners of the plate
    sc = ''.join(f'<circle cx="{x}" cy="{2040}" r="16" fill="{"#000" if dark else "#7c807c"}" fill-opacity="0.35"/>' for x in (760, 4360))
    return svg(b0 + ''.join(grain) + win + b2 + ''.join(cells) + sc, d0 + d1 + d2)


# ------------------------------------------------------------- modulaire
def modulaire(dark):
    R = random.Random(3)
    top, bot = ('#17191A', '#101112') if dark else ('#DAD7D0', '#CCC8C0')
    d0, b0 = base(top, bot)
    grain = []
    y = 0
    while y < H:
        h = R.choice([1, 1, 2])
        op = R.uniform(0.012, 0.04)
        col = '#FFFFFF' if R.random() < 0.5 else '#000000'
        grain.append(f'<rect y="{y}" width="{W}" height="{h}" fill="{col}" fill-opacity="{op:.3f}"/>')
        y += h + R.randint(1, 5)
    # Eurorack-like panel seams (varied widths), screws only at the bottom rail
    seams, screws = [], []
    x = 0
    widths = [240, 400, 160, 560, 320, 240, 480, 160, 400, 320, 640, 240, 400, 560]
    i = 0
    while x < W:
        w = widths[i % len(widths)]
        i += 1
        x += w
        seams.append(f'<rect x="{x - 2}" y="0" width="2" height="{H}" fill="#000" fill-opacity="{0.35 if dark else 0.18}"/>'
                     f'<rect x="{x}" y="0" width="2" height="{H}" fill="#FFF" fill-opacity="{0.09 if dark else 0.35}"/>')
        for sx in (x - w + 40, x - 40):
            if 0 < sx < W:
                screws.append(f'<circle cx="{sx}" cy="2100" r="13" fill="#000" fill-opacity="{0.35 if dark else 0.22}"/>'
                              f'<rect x="{sx - 9}" y="2099" width="18" height="2.5" fill="#FFF" fill-opacity="{0.12 if dark else 0.4}"/>')
    d1, b1 = glow('am', 2600, 1950, 1300, '#FF8A2A', 0.07 if dark else 0.06, 1.9)
    d2, b2 = glow('gr', 1500, 2100, 700, '#46C46A', 0.03 if dark else 0.03, 1.6)
    # a few unlit LEDs and one jack row, low in the middle (quiet)
    leds = ''.join(f'<circle cx="{1400 + k * 330}" cy="1880" r="9" fill="{"#3b2a24" if dark else "#9b8f84"}" fill-opacity="0.8"/>' for k in range(8))
    leds += f'<circle cx="{1400 + 3 * 330}" cy="1880" r="9" fill="#FF8A2A" fill-opacity="{0.55 if dark else 0.7}"/>'
    jacks = ''.join(f'<circle cx="{1400 + k * 330}" cy="1990" r="26" fill="#000" fill-opacity="{0.45 if dark else 0.25}"/><circle cx="{1400 + k * 330}" cy="1990" r="11" fill="#000" fill-opacity="0.6"/>' for k in range(8))
    return svg(b0 + ''.join(grain) + ''.join(seams) + b1 + b2 + leds + jacks + ''.join(screws), d0 + d1 + d2)


# ---------------------------------------------------------------- matrix
def matrix(dark):
    top, bot = ('#0A0A0A', '#060606') if dark else ('#E8E8E6', '#E0E0DE')
    d0, b0 = base(top, bot)
    ink = '#F2F2F2' if dark else '#111111'
    step = 32
    dots = []
    cx, cy = 2560, 1650
    for j in range(H // step + 1):
        for i in range(W // step + 1):
            x, y = i * step + step / 2, j * step + step / 2
            # a large soft ring field low in the middle
            r = math.hypot((x - cx) / 1.9, (y - cy))
            ring = math.exp(-((r - 620) / 170) ** 2) + 0.55 * math.exp(-((r - 980) / 120) ** 2)
            q = quiet(x, y)
            op = (0.05 + 0.42 * ring * q) if dark else (0.065 + 0.30 * ring * q)
            rr = 2.2 + 1.6 * ring * q
            dots.append(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{rr:.1f}" fill="{ink}" fill-opacity="{op:.3f}"/>')
    d1, b1 = glow('mg', cx, cy, 1400, ink, 0.06 if dark else 0.0, 1.9)
    return svg(b0 + b1 + ''.join(dots), d0 + d1)


GEN = {'classic': classic, 'constellation': constellation, 'facade': facade, 'modulaire': modulaire, 'matrix': matrix}
for th, f in GEN.items():
    for va in ('dark', 'light'):
        s = f(va == 'dark')
        p = os.path.join(OUT, f'{th}-{va}.svg')
        open(p, 'w').write(s)
        print(p, len(s) // 1024, 'KB')
