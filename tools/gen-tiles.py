"""Seamless wallpaper tiles for lc-shell, one per theme and variant.

design/wallpapers/<theme>-<variant>-tile.svg + design/wallpapers/tiles.json
({key: {base, size, opacity}}). The shell paints `base`, then the tile with
Image.Tile. Qt SVG primitives only (rect, circle, path, line, opacity):
no pattern, mask, filter or clipPath. Anything crossing an edge is drawn
again on the opposite side (the viewport clips it), so the tile has no seam.

Tones: away from the theme's bg / surface / surface2 on purpose, so the bar,
panels, windows and modules stand out. Dark variants: a lighter, hue-shifted
mid-dark; light variants: a darker, tinted mid-light."""
import json, os, random

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'wallpapers')
os.makedirs(OUT, exist_ok=True)

# theme -> variant -> (base, size, motif color, motif opacity, why)
SPEC = {
    'classic': {
        'dark': ('#22343A', 64, '#FFFFFF', 0.10, 'ardoise sarcelle, plus claire et plus froide que le graphite neutre de l\'interface'),
        'light': ('#B7C9C6', 64, '#0B2A26', 0.12, 'sauge grisée, plus sombre que les surfaces quasi blanches'),
    },
    'constellation': {
        'dark': ('#2B2552', 128, '#FFFFFF', 0.45, 'violet profond, plus clair et plus chaud que le bleu nuit des îlots'),
        'light': ('#C8C2E6', 128, '#FFFFFF', 0.75, 'lavande moyenne, nettement plus sombre que le blanc bleuté'),
    },
    'facade': {
        'dark': ('#2C3538', 48, '#000000', 0.26, 'gris acier bleuté, plus clair que la façade noire et les afficheurs'),
        'light': ('#9AA5A7', 48, '#1B2426', 0.15, 'gris bleu, plus sombre et plus froid que l\'aluminium clair'),
    },
    'modulaire': {
        'dark': ('#3A342E', 96, '#000000', 0.26, 'brun fumé, plus clair et plus chaud que l\'anthracite des panneaux'),
        'light': ('#9CA6AC', 96, '#1A1F22', 0.15, 'acier froid, sous le beige chaud des panneaux'),
    },
    'matrix': {
        'dark': ('#25272B', 64, '#FFFFFF', 0.16, 'gris froid moyen, bien au-dessus du quasi-noir des surfaces'),
        'light': ('#BBBCB8', 64, '#000000', 0.16, 'gris moyen, sous le blanc cassé des surfaces'),
    },
}


def svg(n, body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{n}" height="{n}" viewBox="0 0 {n} {n}">{body}</svg>'


def wrap(n, x, y, r):
    """Copies of a point so that a shape of radius r crossing an edge wraps."""
    out = [(x, y)]
    for dx in (-n, 0, n):
        for dy in (-n, 0, n):
            if (dx or dy) and -r <= x + dx <= n + r and -r <= y + dy <= n + r:
                out.append((x + dx, y + dy))
    return out


def classic(n, c, a):
    # a fine cross weave: a small + at the centre, a smaller one at the corners
    s = f'<g stroke="{c}" stroke-opacity="{a}" stroke-width="1.5" stroke-linecap="round">'
    s += f'<line x1="{n/2 - 5}" y1="{n/2}" x2="{n/2 + 5}" y2="{n/2}"/><line x1="{n/2}" y1="{n/2 - 5}" x2="{n/2}" y2="{n/2 + 5}"/>'
    for x, y in [(0, 0), (n, 0), (0, n), (n, n)]:
        s += f'<line x1="{x - 3}" y1="{y}" x2="{x + 3}" y2="{y}" stroke-opacity="{a * 0.6:.3f}"/><line x1="{x}" y1="{y - 3}" x2="{x}" y2="{y + 3}" stroke-opacity="{a * 0.6:.3f}"/>'
    return s + '</g>'


def constellation(n, c, a, seed):
    R = random.Random(seed)
    s = ''
    for _ in range(14):
        x, y = R.uniform(0, n), R.uniform(0, n)
        r = R.choice([0.6, 0.8, 0.8, 1.0, 1.2])
        op = a * R.uniform(0.35, 0.8)
        for px, py in wrap(n, x, y, r):
            s += f'<circle cx="{px:.1f}" cy="{py:.1f}" r="{r}" fill="{c}" fill-opacity="{op:.2f}"/>'
    # two four-point sparkles (thin diamonds), kept away from the edges
    for x, y, k in [(R.uniform(24, n - 24), R.uniform(24, n - 24), 4.5), (R.uniform(24, n - 24), R.uniform(24, n - 24), 3)]:
        d = f'M{x} {y - k}Q{x} {y} {x + k} {y}Q{x} {y} {x} {y + k}Q{x} {y} {x - k} {y}Q{x} {y} {x} {y - k}Z'
        s += f'<path d="{d}" fill="{c}" fill-opacity="{a:.2f}"/><circle cx="{x}" cy="{y}" r="{k * 1.6}" fill="{c}" fill-opacity="{a * 0.12:.3f}"/>'
    return s


def facade(n, c, a):
    # speaker grille: staggered round holes, 12 px pitch
    s, p = '', 12
    for j in range(n // p):
        for i in range(n // p):
            x = i * p + (p / 2 if j % 2 else 0)
            y = j * p + p / 2
            for px, py in wrap(n, x, y, 3):
                s += f'<circle cx="{px}" cy="{py}" r="2.6" fill="{c}" fill-opacity="{a}"/>'
    # a faint highlight under each hole row (pressed metal)
    return s


def modulaire(n, c, a, light):
    # rack cage nut holes: square, rounded, 24 px pitch; a light lip under each
    s, p, h = '', 24, 8
    lip = '#FFFFFF'
    for j in range(n // p):
        for i in range(n // p):
            x, y = i * p + (p - h) / 2, j * p + (p - h) / 2
            s += f'<rect x="{x}" y="{y}" width="{h}" height="{h}" rx="1.6" fill="{c}" fill-opacity="{a}"/>'
            s += f'<rect x="{x}" y="{y + h}" width="{h}" height="1" fill="{lip}" fill-opacity="{0.10 if light else 0.06}"/>'
    return s


def matrix(n, c, a):
    # dot screen, 16 px pitch; every fourth dot a small cross
    s, p = '', 16
    for j in range(n // p):
        for i in range(n // p):
            x, y = i * p + p / 2, j * p + p / 2
            if (i + j) % 4 == 0 and i % 2 == 0:
                s += f'<g stroke="{c}" stroke-opacity="{a}" stroke-width="1.2"><line x1="{x - 2.5}" y1="{y}" x2="{x + 2.5}" y2="{y}"/><line x1="{x}" y1="{y - 2.5}" x2="{x}" y2="{y + 2.5}"/></g>'
            else:
                s += f'<circle cx="{x}" cy="{y}" r="1.3" fill="{c}" fill-opacity="{a}"/>'
    return s


meta = {}
for th, vs in SPEC.items():
    for va, (base, n, c, a, why) in vs.items():
        if th == 'classic':
            body = classic(n, c, a)
        elif th == 'constellation':
            body = constellation(n, c, a, 7 if va == 'dark' else 9)
        elif th == 'facade':
            body = facade(n, c, a)
        elif th == 'modulaire':
            body = modulaire(n, c, a, va == 'light')
        else:
            body = matrix(n, c, a)
        # the base colour is painted inside the tile too (usable alone)
        s = svg(n, f'<rect width="{n}" height="{n}" fill="{base}"/>' + body)
        p = os.path.join(OUT, f'{th}-{va}-tile.svg')
        open(p, 'w').write(s)
        meta[f'{th}-{va}'] = {'base': base, 'size': n, 'motif': c, 'opacity': a, 'why': why}
        print(f'{th}-{va}-tile.svg', n, 'px', len(s), 'B')
json.dump(meta, open(os.path.join(OUT, 'tiles.json'), 'w'), indent=1, ensure_ascii=False)
