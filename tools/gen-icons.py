#!/usr/bin/env python3
"""Build lc-shell's icon fonts from Material Symbols Rounded (Apache 2.0).

Qt ignores the axes of variable fonts, so this makes two static instances
(outlined FILL 0 and filled FILL 1, wght 400, GRAD 0, opsz 24), keeps only the
icons listed in tools/icons.txt, and renames the families so they can't clash
with an installed Material Symbols:
    assets/fonts/symbols/lcSymbols-Outlined.ttf  family "lc Symbols"
    assets/fonts/symbols/lcSymbols-Filled.ttf    family "lc Symbols Filled"
    assets/fonts/symbols/icons.json              { name: codepoint }

Needs fontTools. Usage:
    gen-icons.py "MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf" \\
        "MaterialSymbolsRounded[FILL,GRAD,opsz,wght].codepoints"
The codepoints file comes from github.com/google/material-design-icons
(variablefont/).
"""

import json
import os
import sys

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "fonts", "symbols")


def read_names():
    with open(os.path.join(ROOT, "tools", "icons.txt"), encoding="utf-8") as f:
        return [line.strip() for line in f if line.strip() and not line.startswith("#")]


def rename(font, family):
    for record in font["name"].names:
        if record.nameID in (1, 16):
            record.string = family
        elif record.nameID == 4:
            record.string = family
        elif record.nameID == 6:
            record.string = family.replace(" ", "")
        elif record.nameID == 17:
            record.string = "Regular"


def main():
    variable_path, codepoints_path = sys.argv[1:3]
    table = {}
    with open(codepoints_path, encoding="utf-8") as f:
        for line in f:
            name, code = line.split()
            table.setdefault(name, int(code, 16))
    names = read_names()
    missing = [n for n in names if n not in table]
    if missing:
        sys.exit(f"unknown icons: {', '.join(missing)}")
    codepoints = sorted({table[n] for n in names})

    os.makedirs(OUT, exist_ok=True)
    for fill, file, family in ((0, "lcSymbols-Outlined.ttf", "lc Symbols"), (1, "lcSymbols-Filled.ttf", "lc Symbols Filled")):
        font = TTFont(variable_path)
        font = instancer.instantiateVariableFont(font, {"FILL": fill, "wght": 400, "GRAD": 0, "opsz": 24})
        options = subset.Options()
        options.layout_features = []  # no ligatures: icons are used by codepoint
        options.name_IDs = ["*"]
        subsetter = subset.Subsetter(options)
        subsetter.populate(unicodes=codepoints)
        subsetter.subset(font)
        rename(font, family)
        font.save(os.path.join(OUT, file))

    with open(os.path.join(OUT, "icons.json"), "w", encoding="utf-8") as f:
        json.dump({n: f"{table[n]:x}" for n in names}, f, indent=1, sort_keys=True)
        f.write("\n")


if __name__ == "__main__":
    main()
